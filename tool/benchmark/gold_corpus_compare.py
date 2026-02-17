#!/usr/bin/env python3
"""Evaluate flutter_kiwi_nlp and kiwipiepy on tab-separated gold corpora."""

from __future__ import annotations

import argparse
import inspect
import json
import platform
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

INTEGRATE_ALLOMORPH = 1
LOAD_DEFAULT_DICT = 2
LOAD_TYPO_DICT = 4
LOAD_MULTI_DICT = 8
MODEL_TYPE_MASK = 0x0F00

MODEL_TYPE_MAP: dict[int, str | None] = {
    0x0000: None,
    0x0100: 'largest',
    0x0200: 'knlm',
    0x0300: 'sbg',
    0x0400: 'cong',
    0x0500: 'cong-global',
}


@dataclass(frozen=True)
class GoldToken:
    form: str
    tag: str

    @property
    def pair(self) -> str:
        return f'{self.form}/{self.tag}'


@dataclass(frozen=True)
class GoldEntry:
    sentence: str
    tokens: list[GoldToken]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            'Run gold-corpus agreement evaluation for flutter_kiwi_nlp and '
            'kiwipiepy.'
        )
    )
    parser.add_argument(
        '--device',
        default='macos',
        help='Flutter device id for `flutter run -d`.',
    )
    parser.add_argument(
        '--mode',
        choices=('debug', 'profile', 'release'),
        default='release',
        help='Flutter build mode.',
    )
    parser.add_argument(
        '--gold-assets',
        nargs='+',
        default=[
            'assets/gold_eval_web_ko.txt',
            'assets/gold_eval_written_ko.txt',
        ],
        help='Gold corpus assets under example/ (tab-separated sentence/gold).',
    )
    parser.add_argument(
        '--top-n',
        type=int,
        default=1,
        help='top_n for both runtimes.',
    )
    parser.add_argument(
        '--num-threads',
        type=int,
        default=-1,
        help='numThreads for flutter_kiwi_nlp evaluator.',
    )
    parser.add_argument(
        '--num-workers',
        type=int,
        default=-1,
        help='num_workers for kiwipiepy evaluator.',
    )
    parser.add_argument(
        '--build-options',
        type=int,
        default=1039,
        help='Bitwise Kiwi build option value.',
    )
    parser.add_argument(
        '--create-match-options',
        type=int,
        default=8454175,
        help='Create-time match option value.',
    )
    parser.add_argument(
        '--analyze-match-options',
        type=int,
        default=8454175,
        help='Analyze-time match option value.',
    )
    parser.add_argument(
        '--model-path',
        default='',
        help='Optional model path override for both runtimes.',
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('benchmark/results/gold_eval'),
        help='Output directory for JSON and markdown report.',
    )
    parser.add_argument(
        '--python-bin',
        default=sys.executable,
        help='Python interpreter for portability.',
    )
    parser.add_argument(
        '--flutter-timeout-seconds',
        type=int,
        default=1800,
        help='Timeout waiting for Flutter evaluator JSON marker.',
    )
    return parser.parse_args()


def run_command(command: list[str], *, cwd: Path | None = None) -> None:
    print(f"$ {shlex.join(command)}")
    subprocess.run(command, cwd=cwd, check=True)


def run_flutter_eval(
    *,
    repo_root: Path,
    asset_path: str,
    dataset_name: str,
    args: argparse.Namespace,
    output_path: Path,
) -> dict[str, Any]:
    command = [
        'flutter',
        'run',
        '--no-pub',
        '-d',
        args.device,
        '--target',
        'lib/gold_eval_main.dart',
        f'--{args.mode}',
        f'--dart-define=KIWI_GOLD_ASSET={asset_path}',
        f'--dart-define=KIWI_GOLD_DATASET_NAME={dataset_name}',
        f'--dart-define=KIWI_EVAL_OUTPUT_PATH={output_path}',
        f'--dart-define=KIWI_BENCH_TOP_N={args.top_n}',
        f'--dart-define=KIWI_BENCH_NUM_THREADS={args.num_threads}',
        f'--dart-define=KIWI_BENCH_BUILD_OPTIONS={args.build_options}',
        (
            '--dart-define='
            f'KIWI_BENCH_CREATE_MATCH_OPTIONS={args.create_match_options}'
        ),
        (
            '--dart-define='
            f'KIWI_BENCH_ANALYZE_MATCH_OPTIONS={args.analyze_match_options}'
        ),
    ]
    if args.model_path:
        command.append(f'--dart-define=KIWI_BENCH_MODEL_PATH={args.model_path}')

    marker = 'KIWI_GOLD_EVAL_JSON='
    deadline = time.monotonic() + args.flutter_timeout_seconds
    process = subprocess.Popen(
        command,
        cwd=repo_root / 'example',
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    payload: dict[str, Any] | None = None
    try:
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end='')
            marker_index = line.find(marker)
            if marker_index != -1:
                raw_json = line[marker_index + len(marker) :].strip()
                parsed = json.loads(raw_json)
                if not isinstance(parsed, dict):
                    raise TypeError(
                        'Flutter evaluator payload must be a JSON object.'
                    )
                payload = parsed
                break

            if time.monotonic() > deadline:
                raise TimeoutError('Timed out waiting for Flutter eval output.')

        if payload is None:
            raise RuntimeError('Could not find KIWI_GOLD_EVAL_JSON marker.')
        return payload
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)


def parse_gold_tokens(raw: str) -> list[GoldToken]:
    tokens: list[GoldToken] = []
    for segment in raw.split():
        split_index = segment.rfind('/')
        if split_index <= 0 or split_index >= len(segment) - 1:
            tokens.append(GoldToken(form=segment, tag='UNK'))
            continue
        tokens.append(
            GoldToken(
                form=segment[:split_index],
                tag=segment[split_index + 1 :],
            )
        )
    return tokens


def load_gold_entries(path: Path) -> list[GoldEntry]:
    entries: list[GoldEntry] = []
    for raw_line in path.read_text(encoding='utf-8').splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if '\t' not in line:
            continue
        sentence, gold_raw = line.split('\t', 1)
        sentence = sentence.strip()
        gold_raw = gold_raw.strip()
        if not sentence or not gold_raw:
            continue
        entries.append(GoldEntry(sentence=sentence, tokens=parse_gold_tokens(gold_raw)))
    if not entries:
        raise ValueError(f'Gold corpus is empty or malformed: {path}')
    return entries


def levenshtein_distance(left: list[str], right: list[str]) -> int:
    if not left:
        return len(right)
    if not right:
        return len(left)

    previous = list(range(len(right) + 1))
    for i in range(1, len(left) + 1):
        current = [i] + [0] * len(right)
        for j in range(1, len(right) + 1):
            substitution_cost = 0 if left[i - 1] == right[j - 1] else 1
            deletion = previous[j] + 1
            insertion = current[j - 1] + 1
            substitution = previous[j - 1] + substitution_cost
            current[j] = min(deletion, insertion, substitution)
        previous = current
    return previous[-1]


def resolve_model_type(build_options: int) -> str | None:
    return MODEL_TYPE_MAP.get(build_options & MODEL_TYPE_MASK)


def create_kiwi(args: argparse.Namespace) -> Any:
    try:
        from kiwipiepy import Kiwi
    except ImportError as error:
        raise RuntimeError(
            'kiwipiepy is not installed. Install with '
            '`python3 -m pip install kiwipiepy`.'
        ) from error

    kwargs: dict[str, Any] = {
        'num_workers': args.num_workers,
        'integrate_allomorph': (args.build_options & INTEGRATE_ALLOMORPH) != 0,
        'load_default_dict': (args.build_options & LOAD_DEFAULT_DICT) != 0,
        'load_typo_dict': (args.build_options & LOAD_TYPO_DICT) != 0,
        'load_multi_dict': (args.build_options & LOAD_MULTI_DICT) != 0,
    }
    model_type = resolve_model_type(args.build_options)
    if model_type is not None:
        kwargs['model_type'] = model_type
    if args.model_path:
        kwargs['model_path'] = args.model_path

    supported = set(inspect.signature(Kiwi.__init__).parameters)
    supported.discard('self')
    filtered_kwargs = {
        key: value for key, value in kwargs.items() if key in supported
    }
    return Kiwi(**filtered_kwargs)


def kiwi_predict_tokens(kiwi: Any, sentence: str, top_n: int, match: int) -> list[GoldToken]:
    analyzed = kiwi.analyze(sentence, top_n=top_n, match_options=match)
    if not analyzed:
        return []
    first = analyzed[0]
    if isinstance(first, tuple):
        token_list = first[0]
    else:
        token_list = getattr(first, 'tokens', [])
    return [
        GoldToken(form=getattr(token, 'form', ''), tag=getattr(token, 'tag', 'UNK'))
        for token in token_list
    ]


def safe_ratio(numerator: int | float, denominator: int | float) -> float:
    if denominator <= 0:
        return 0.0
    return float(numerator) / float(denominator)


def build_eval_payload(
    *,
    runtime: str,
    platform_value: str,
    dataset_name: str,
    asset_path: str,
    args: argparse.Namespace,
    init_ms: float,
    eval_elapsed_ms: float,
    sentence_count: int,
    gold_token_count: int,
    predicted_token_count: int,
    token_edit_distance: int,
    token_edit_denominator: int,
    pos_edit_distance: int,
    pos_edit_denominator: int,
    token_exact_sentence_count: int,
    pos_exact_sentence_count: int,
) -> dict[str, Any]:
    token_agreement = 1.0 - safe_ratio(token_edit_distance, token_edit_denominator)
    pos_agreement = 1.0 - safe_ratio(pos_edit_distance, pos_edit_denominator)
    return {
        'task': 'gold_eval',
        'runtime': runtime,
        'platform': platform_value,
        'generated_at_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'dataset_name': dataset_name,
        'gold_asset': asset_path,
        'top_n': args.top_n,
        'num_workers': args.num_workers,
        'num_threads': args.num_threads,
        'build_options': args.build_options,
        'create_match_options': args.create_match_options,
        'analyze_match_options': args.analyze_match_options,
        'sentence_count': sentence_count,
        'gold_token_count': gold_token_count,
        'predicted_token_count': predicted_token_count,
        'init_ms': init_ms,
        'eval_elapsed_ms': eval_elapsed_ms,
        'token_edit_distance': token_edit_distance,
        'token_edit_denominator': token_edit_denominator,
        'token_agreement': token_agreement,
        'pos_edit_distance': pos_edit_distance,
        'pos_edit_denominator': pos_edit_denominator,
        'pos_agreement': pos_agreement,
        'token_sequence_exact_count': token_exact_sentence_count,
        'token_sequence_exact_match': safe_ratio(
            token_exact_sentence_count,
            sentence_count,
        ),
        'sentence_exact_count': pos_exact_sentence_count,
        'sentence_exact_match': safe_ratio(pos_exact_sentence_count, sentence_count),
    }


def evaluate_kiwi_gold(
    *,
    args: argparse.Namespace,
    asset_path: str,
    dataset_name: str,
    entries: list[GoldEntry],
) -> dict[str, Any]:
    init_started = time.perf_counter()
    kiwi = create_kiwi(args)
    init_ms = (time.perf_counter() - init_started) * 1000.0

    token_edit_distance = 0
    token_edit_denominator = 0
    pos_edit_distance = 0
    pos_edit_denominator = 0
    token_exact_sentence_count = 0
    pos_exact_sentence_count = 0
    gold_token_count = 0
    predicted_token_count = 0

    eval_started = time.perf_counter()
    for entry in entries:
        predicted = kiwi_predict_tokens(
            kiwi,
            entry.sentence,
            top_n=args.top_n,
            match=args.analyze_match_options,
        )

        gold_forms = [token.form for token in entry.tokens]
        predicted_forms = [token.form for token in predicted]
        gold_pairs = [token.pair for token in entry.tokens]
        predicted_pairs = [token.pair for token in predicted]

        token_edit_distance += levenshtein_distance(gold_forms, predicted_forms)
        pos_edit_distance += levenshtein_distance(gold_pairs, predicted_pairs)
        token_edit_denominator += max(len(gold_forms), len(predicted_forms))
        pos_edit_denominator += max(len(gold_pairs), len(predicted_pairs))
        gold_token_count += len(gold_forms)
        predicted_token_count += len(predicted_forms)

        if gold_forms == predicted_forms:
            token_exact_sentence_count += 1
        if gold_pairs == predicted_pairs:
            pos_exact_sentence_count += 1

    eval_elapsed_ms = (time.perf_counter() - eval_started) * 1000.0

    return build_eval_payload(
        runtime='kiwipiepy',
        platform_value=platform.platform(),
        dataset_name=dataset_name,
        asset_path=asset_path,
        args=args,
        init_ms=init_ms,
        eval_elapsed_ms=eval_elapsed_ms,
        sentence_count=len(entries),
        gold_token_count=gold_token_count,
        predicted_token_count=predicted_token_count,
        token_edit_distance=token_edit_distance,
        token_edit_denominator=token_edit_denominator,
        pos_edit_distance=pos_edit_distance,
        pos_edit_denominator=pos_edit_denominator,
        token_exact_sentence_count=token_exact_sentence_count,
        pos_exact_sentence_count=pos_exact_sentence_count,
    )


def aggregate_payloads(
    runtime: str,
    payloads: list[dict[str, Any]],
) -> dict[str, Any]:
    sentence_count = sum(int(p['sentence_count']) for p in payloads)
    gold_token_count = sum(int(p['gold_token_count']) for p in payloads)
    predicted_token_count = sum(int(p['predicted_token_count']) for p in payloads)
    token_edit_distance = sum(int(p['token_edit_distance']) for p in payloads)
    token_edit_denominator = sum(int(p['token_edit_denominator']) for p in payloads)
    pos_edit_distance = sum(int(p['pos_edit_distance']) for p in payloads)
    pos_edit_denominator = sum(int(p['pos_edit_denominator']) for p in payloads)
    token_exact_sentence_count = sum(
        int(p['token_sequence_exact_count']) for p in payloads
    )
    pos_exact_sentence_count = sum(int(p['sentence_exact_count']) for p in payloads)
    init_ms_values = [float(p['init_ms']) for p in payloads]
    eval_elapsed_ms = sum(float(p['eval_elapsed_ms']) for p in payloads)
    platform_value = str(payloads[0].get('platform', 'unknown'))

    token_agreement = 1.0 - safe_ratio(token_edit_distance, token_edit_denominator)
    pos_agreement = 1.0 - safe_ratio(pos_edit_distance, pos_edit_denominator)

    return {
        'task': 'gold_eval_aggregate',
        'runtime': runtime,
        'platform': platform_value,
        'dataset_name': 'combined',
        'source_datasets': [str(p.get('dataset_name', 'unknown')) for p in payloads],
        'sentence_count': sentence_count,
        'gold_token_count': gold_token_count,
        'predicted_token_count': predicted_token_count,
        'init_ms_mean': safe_ratio(sum(init_ms_values), len(init_ms_values)),
        'eval_elapsed_ms': eval_elapsed_ms,
        'token_edit_distance': token_edit_distance,
        'token_edit_denominator': token_edit_denominator,
        'token_agreement': token_agreement,
        'pos_edit_distance': pos_edit_distance,
        'pos_edit_denominator': pos_edit_denominator,
        'pos_agreement': pos_agreement,
        'token_sequence_exact_count': token_exact_sentence_count,
        'token_sequence_exact_match': safe_ratio(
            token_exact_sentence_count,
            sentence_count,
        ),
        'sentence_exact_count': pos_exact_sentence_count,
        'sentence_exact_match': safe_ratio(pos_exact_sentence_count, sentence_count),
    }


def percent(value: float) -> str:
    return f'{value * 100.0:.2f}%'


def render_markdown_report(
    *,
    flutter_overall: dict[str, Any],
    kiwi_overall: dict[str, Any],
    flutter_per_dataset: list[dict[str, Any]],
    kiwi_per_dataset: list[dict[str, Any]],
) -> str:
    dataset_names = [str(p['dataset_name']) for p in flutter_per_dataset]
    lines: list[str] = []
    lines.append('# Gold Corpus Accuracy Comparison')
    lines.append('')
    lines.append('## Overall')
    lines.append('')
    lines.append(
        '| Metric | flutter_kiwi_nlp | kiwipiepy | Delta (Flutter - Kiwi) |'
    )
    lines.append('| --- | ---: | ---: | ---: |')

    metrics = [
        ('Token agreement', 'token_agreement'),
        ('POS agreement', 'pos_agreement'),
        ('Sentence exact match', 'sentence_exact_match'),
        ('Token-sequence exact match', 'token_sequence_exact_match'),
    ]
    for label, key in metrics:
        flutter_value = float(flutter_overall[key])
        kiwi_value = float(kiwi_overall[key])
        delta = flutter_value - kiwi_value
        lines.append(
            f'| {label} | {percent(flutter_value)} | {percent(kiwi_value)} '
            f'| {delta * 100.0:+.2f} pp |'
        )

    lines.append('')
    lines.append('## Per Dataset')
    lines.append('')
    lines.append(
        '| Dataset | Runtime | Token agreement | POS agreement | '
        'Sentence exact |'
    )
    lines.append('| --- | --- | ---: | ---: | ---: |')
    for name in dataset_names:
        flutter_payload = next(p for p in flutter_per_dataset if p['dataset_name'] == name)
        kiwi_payload = next(p for p in kiwi_per_dataset if p['dataset_name'] == name)
        lines.append(
            f'| {name} | flutter_kiwi_nlp | '
            f'{percent(float(flutter_payload["token_agreement"]))} | '
            f'{percent(float(flutter_payload["pos_agreement"]))} | '
            f'{percent(float(flutter_payload["sentence_exact_match"]))} |'
        )
        lines.append(
            f'| {name} | kiwipiepy | '
            f'{percent(float(kiwi_payload["token_agreement"]))} | '
            f'{percent(float(kiwi_payload["pos_agreement"]))} | '
            f'{percent(float(kiwi_payload["sentence_exact_match"]))} |'
        )

    lines.append('')
    lines.append('## Counts')
    lines.append('')
    lines.append(
        f'- Sentences: {int(flutter_overall["sentence_count"])} '
        '(same gold set for both runtimes).'
    )
    lines.append(f'- Gold tokens: {int(flutter_overall["gold_token_count"])}.')
    lines.append(
        '- Agreement metrics are based on sequence-level Levenshtein distance '
        'normalization.'
    )
    return '\n'.join(lines) + '\n'


def main() -> int:
    args = parse_args()
    if args.top_n < 1:
        raise ValueError('--top-n must be >= 1')
    if args.build_options < 0:
        raise ValueError('--build-options must be >= 0')
    if args.create_match_options < 0:
        raise ValueError('--create-match-options must be >= 0')
    if args.analyze_match_options < 0:
        raise ValueError('--analyze-match-options must be >= 0')

    repo_root = Path(__file__).resolve().parents[2]
    example_dir = repo_root / 'example'

    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    run_command(['flutter', 'pub', 'get'], cwd=example_dir)

    flutter_per_dataset: list[dict[str, Any]] = []
    kiwi_per_dataset: list[dict[str, Any]] = []

    for asset_path in args.gold_assets:
        dataset_name = Path(asset_path).stem
        absolute_gold_path = example_dir / asset_path
        entries = load_gold_entries(absolute_gold_path)

        flutter_output_path = output_dir / f'flutter_{dataset_name}.json'
        kiwi_output_path = output_dir / f'kiwipiepy_{dataset_name}.json'

        flutter_payload = run_flutter_eval(
            repo_root=repo_root,
            asset_path=asset_path,
            dataset_name=dataset_name,
            args=args,
            output_path=flutter_output_path,
        )
        flutter_output_path.write_text(
            json.dumps(flutter_payload, ensure_ascii=False, indent=2),
            encoding='utf-8',
        )
        kiwi_payload = evaluate_kiwi_gold(
            args=args,
            asset_path=asset_path,
            dataset_name=dataset_name,
            entries=entries,
        )
        kiwi_output_path.write_text(
            json.dumps(kiwi_payload, ensure_ascii=False, indent=2),
            encoding='utf-8',
        )

        flutter_per_dataset.append(flutter_payload)
        kiwi_per_dataset.append(kiwi_payload)

    flutter_overall = aggregate_payloads('flutter_kiwi_nlp', flutter_per_dataset)
    kiwi_overall = aggregate_payloads('kiwipiepy', kiwi_per_dataset)

    (output_dir / 'flutter_overall.json').write_text(
        json.dumps(flutter_overall, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    (output_dir / 'kiwipiepy_overall.json').write_text(
        json.dumps(kiwi_overall, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )

    report = render_markdown_report(
        flutter_overall=flutter_overall,
        kiwi_overall=kiwi_overall,
        flutter_per_dataset=flutter_per_dataset,
        kiwi_per_dataset=kiwi_per_dataset,
    )
    (output_dir / 'comparison.md').write_text(report, encoding='utf-8')

    print(f'\nDone. Open: {output_dir / "comparison.md"}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
