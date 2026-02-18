#!/usr/bin/env python3
"""Run a `kiwipiepy` benchmark with the same corpus as Flutter benchmark."""

from __future__ import annotations

import argparse
import inspect
import json
import platform
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, TextIO


@dataclass(frozen=True)
class BenchmarkConfig:
    corpus_path: Path
    output_path: Path | None
    warmup_runs: int
    measure_runs: int
    top_n: int
    num_workers: int
    build_options: int
    create_match_options: int
    analyze_match_options: int
    analyze_impl: str
    sample_count: int
    trial_id: int
    model_path: str


@dataclass(frozen=True)
class RunStats:
    elapsed_ms: float
    total_analyses: int
    total_chars: int
    total_tokens: int


INTEGRATE_ALLOMORPH = 1
LOAD_DEFAULT_DICT = 2
LOAD_TYPO_DICT = 4
LOAD_MULTI_DICT = 8
MODEL_TYPE_MASK = 0x0F00
_ANALYZE_IMPL_ANALYZE = 'analyze'
_ANALYZE_IMPL_TOKENIZE = 'tokenize'

MODEL_TYPE_MAP: dict[int, str | None] = {
    0x0000: None,
    0x0100: 'largest',
    0x0200: 'knlm',
    0x0300: 'sbg',
    0x0400: 'cong',
    0x0500: 'cong-global',
}


def safe_print_line(line: str, *, stream: TextIO = sys.stdout) -> None:
    """Print a line without failing on Windows console encodings."""
    encoding = stream.encoding or 'utf-8'
    try:
        stream.write(line)
    except UnicodeEncodeError:
        safe_line = line.encode(encoding, errors='backslashreplace').decode(
            encoding,
            errors='replace',
        )
        stream.write(safe_line)
    stream.write('\n')
    stream.flush()


def resolve_model_type(build_options: int) -> str | None:
    return MODEL_TYPE_MAP.get(build_options & MODEL_TYPE_MASK)


def parse_args() -> BenchmarkConfig:
    parser = argparse.ArgumentParser(
        description=(
            'Run `kiwipiepy` benchmark and emit JSON metrics for '
            'cross-runtime comparison.'
        )
    )
    parser.add_argument(
        '--corpus',
        type=Path,
        default=Path('example/assets/benchmark_corpus_ko.txt'),
        help='Sentence corpus file path (one sentence per line).',
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=None,
        help='Optional JSON output path.',
    )
    parser.add_argument(
        '--warmup-runs',
        type=int,
        default=3,
        help='Number of warm-up passes before timed measurement.',
    )
    parser.add_argument(
        '--measure-runs',
        type=int,
        default=15,
        help='Number of timed measurement passes.',
    )
    parser.add_argument(
        '--top-n',
        type=int,
        default=1,
        help='`top_n` for `kiwi.analyze`.',
    )
    parser.add_argument(
        '--num-workers',
        type=int,
        default=-1,
        help='`num_workers` for `Kiwi` (-1 lets kiwi choose available cores).',
    )
    parser.add_argument(
        '--build-options',
        type=int,
        default=1039,
        help='Bitwise `KiwiBuildOption` value aligned with Flutter side.',
    )
    parser.add_argument(
        '--create-match-options',
        type=int,
        default=8454175,
        help=(
            'Bitwise match option value accepted for parity metadata with '
            'Flutter create(). kiwipiepy does not consume this at constructor '
            'time.'
        ),
    )
    parser.add_argument(
        '--analyze-match-options',
        '--match-options',
        dest='analyze_match_options',
        type=int,
        default=8454175,
        help='Bitwise match option value passed to `Kiwi.analyze(match_options=...)`.',
    )
    parser.add_argument(
        '--analyze-impl',
        choices=(_ANALYZE_IMPL_ANALYZE, _ANALYZE_IMPL_TOKENIZE),
        default=_ANALYZE_IMPL_ANALYZE,
        help='kiwipiepy benchmark API path: analyze(top_n) or tokenize().',
    )
    parser.add_argument(
        '--trial-id',
        type=int,
        default=0,
        help='Optional trial id for repeated-measurement orchestration.',
    )
    parser.add_argument(
        '--sample-count',
        type=int,
        default=10,
        help='Number of sample sentences to include with POS outputs.',
    )
    parser.add_argument(
        '--model-path',
        default='',
        help='Optional model path passed to `Kiwi(model_path=...)`.',
    )

    args = parser.parse_args()

    if args.warmup_runs < 0:
        parser.error('--warmup-runs must be >= 0')
    if args.measure_runs < 1:
        parser.error('--measure-runs must be >= 1')
    if args.top_n < 1:
        parser.error('--top-n must be >= 1')
    if args.build_options < 0:
        parser.error('--build-options must be >= 0')
    if args.create_match_options < 0:
        parser.error('--create-match-options must be >= 0')
    if args.analyze_match_options < 0:
        parser.error('--analyze-match-options must be >= 0')
    if args.trial_id < 0:
        parser.error('--trial-id must be >= 0')
    if args.sample_count < 0:
        parser.error('--sample-count must be >= 0')

    return BenchmarkConfig(
        corpus_path=args.corpus,
        output_path=args.output,
        warmup_runs=args.warmup_runs,
        measure_runs=args.measure_runs,
        top_n=args.top_n,
        num_workers=args.num_workers,
        build_options=args.build_options,
        create_match_options=args.create_match_options,
        analyze_match_options=args.analyze_match_options,
        analyze_impl=args.analyze_impl,
        sample_count=args.sample_count,
        trial_id=args.trial_id,
        model_path=args.model_path,
    )


def load_sentences(path: Path) -> list[str]:
    if not path.exists():
        raise FileNotFoundError(f'Corpus not found: {path}')

    sentences = [
        line.strip() for line in path.read_text(encoding='utf-8').splitlines()
    ]
    sentences = [line for line in sentences if line]

    if not sentences:
        raise ValueError(f'Corpus is empty: {path}')

    return sentences


def create_kiwi(config: BenchmarkConfig) -> Any:
    try:
        from kiwipiepy import Kiwi
    except ImportError as error:
        raise RuntimeError(
            'kiwipiepy is not installed. Install it with '
            '`python3 -m pip install kiwipiepy`.'
        ) from error

    kwargs: dict[str, Any] = {
        'num_workers': config.num_workers,
        'integrate_allomorph': (config.build_options & INTEGRATE_ALLOMORPH)
        != 0,
        'load_default_dict': (config.build_options & LOAD_DEFAULT_DICT) != 0,
        'load_typo_dict': (config.build_options & LOAD_TYPO_DICT) != 0,
        'load_multi_dict': (config.build_options & LOAD_MULTI_DICT) != 0,
    }
    model_type = resolve_model_type(config.build_options)
    if model_type is not None:
        kwargs['model_type'] = model_type
    if config.model_path:
        kwargs['model_path'] = config.model_path

    supported = set(inspect.signature(Kiwi.__init__).parameters)
    supported.discard('self')
    filtered_kwargs = {
        key: value for key, value in kwargs.items() if key in supported
    }
    return Kiwi(**filtered_kwargs)


def run_measurement(
    kiwi: Any,
    sentence_rows: list[tuple[str, int]],
    *,
    runs: int,
    top_n: int,
    match_options: int,
    analyze_impl: str,
) -> RunStats:
    total_analyses = 0
    total_chars = 0
    total_tokens = 0

    started = time.perf_counter()

    for _ in range(runs):
        for sentence, sentence_chars in sentence_rows:
            tokens = analyze_sentence_tokens(
                kiwi,
                sentence,
                top_n=top_n,
                match_options=match_options,
                analyze_impl=analyze_impl,
            )
            total_analyses += 1
            total_chars += sentence_chars
            total_tokens += len(tokens)

    elapsed_ms = (time.perf_counter() - started) * 1000.0
    return RunStats(
        elapsed_ms=elapsed_ms,
        total_analyses=total_analyses,
        total_chars=total_chars,
        total_tokens=total_tokens,
    )


def analyze_sentence_tokens(
    kiwi: Any,
    sentence: str,
    *,
    top_n: int,
    match_options: int,
    analyze_impl: str,
) -> list[Any]:
    if analyze_impl == _ANALYZE_IMPL_TOKENIZE:
        return extract_tokenize_tokens(
            kiwi.tokenize(
                sentence,
                match_options=match_options,
            )
        )
    return extract_best_candidate_tokens(
        kiwi.analyze(
            sentence,
            top_n=top_n,
            match_options=match_options,
        )
    )


def extract_best_candidate_tokens(result: Any) -> list[Any]:
    if not result:
        return []

    first_candidate = result[0]
    if isinstance(first_candidate, tuple) and first_candidate:
        tokens = first_candidate[0]
        try:
            return list(tokens)
        except TypeError:
            return []

    tokens = getattr(first_candidate, 'tokens', None)
    if tokens is not None:
        try:
            return list(tokens)
        except TypeError:
            return []

    return []


def extract_tokenize_tokens(result: Any) -> list[Any]:
    if result is None:
        return []

    if isinstance(result, list):
        if result and isinstance(result[0], list):
            return list(result[0])
        return list(result)

    try:
        tokens = list(result)
    except TypeError:
        return []

    if tokens and isinstance(tokens[0], list):
        return list(tokens[0])
    return tokens


def token_to_pair(token: Any) -> tuple[str, str]:
    if isinstance(token, tuple):
        form = str(token[0]) if len(token) > 0 else ''
        tag = str(token[1]) if len(token) > 1 else ''
        return form, tag

    form_any = getattr(token, 'form', None)
    tag_any = getattr(token, 'tag', None)
    form = str(form_any) if form_any is not None else str(token)
    tag = str(tag_any) if tag_any is not None else ''
    return form, tag


def build_top1_text(tokens: list[Any]) -> str:
    if not tokens:
        return '(결과 없음)'
    parts: list[str] = []
    for token in tokens:
        form, tag = token_to_pair(token)
        parts.append(f'{form}/{tag}' if tag else form)
    return ' '.join(parts)


def collect_sample_outputs(
    kiwi: Any,
    sentences: list[str],
    *,
    sample_count: int,
    top_n: int,
    match_options: int,
    analyze_impl: str,
) -> list[dict[str, Any]]:
    if sample_count <= 0 or not sentences:
        return []

    limit = min(sample_count, len(sentences))
    outputs: list[dict[str, Any]] = []
    for index in range(limit):
        sentence = sentences[index]
        tokens = analyze_sentence_tokens(
            kiwi,
            sentence,
            top_n=top_n,
            match_options=match_options,
            analyze_impl=analyze_impl,
        )
        outputs.append(
            {
                'sentence': sentence,
                'top1_text': build_top1_text(tokens),
                'top1_token_count': len(tokens),
            }
        )
    return outputs


def safe_divide(numerator: float, denominator: float) -> float:
    if denominator <= 0:
        return 0.0
    return numerator / denominator


def to_payload(
    *,
    config: BenchmarkConfig,
    sentence_count: int,
    init_ms: float,
    stats: RunStats,
    sample_outputs: list[dict[str, Any]],
) -> dict[str, Any]:
    elapsed_seconds = stats.elapsed_ms / 1000.0
    return {
        'runtime': 'kiwipiepy',
        'platform': platform.platform(),
        'generated_at_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'warmup_runs': config.warmup_runs,
        'measure_runs': config.measure_runs,
        'top_n': config.top_n,
        'num_workers': config.num_workers,
        'build_options': config.build_options,
        'create_match_options': config.create_match_options,
        'analyze_match_options': config.analyze_match_options,
        'analyze_impl': config.analyze_impl,
        'trial_id': config.trial_id,
        'model_type': resolve_model_type(config.build_options) or 'none',
        'sentence_count': sentence_count,
        'sample_count': len(sample_outputs),
        'init_ms': init_ms,
        'elapsed_ms': stats.elapsed_ms,
        'total_analyses': stats.total_analyses,
        'total_chars': stats.total_chars,
        'total_tokens': stats.total_tokens,
        'analyses_per_sec': safe_divide(stats.total_analyses, elapsed_seconds),
        'chars_per_sec': safe_divide(stats.total_chars, elapsed_seconds),
        'tokens_per_sec': safe_divide(stats.total_tokens, elapsed_seconds),
        'avg_latency_ms': safe_divide(stats.elapsed_ms, stats.total_analyses),
        'avg_token_latency_us': safe_divide(
            stats.elapsed_ms * 1000.0,
            stats.total_tokens,
        ),
        'sample_outputs': sample_outputs,
    }


def main() -> int:
    config = parse_args()
    sentences = load_sentences(config.corpus_path)
    sentence_rows = [(sentence, len(sentence)) for sentence in sentences]

    init_started = time.perf_counter()
    kiwi = create_kiwi(config)
    init_ms = (time.perf_counter() - init_started) * 1000.0

    run_measurement(
        kiwi,
        sentence_rows,
        runs=config.warmup_runs,
        top_n=config.top_n,
        match_options=config.analyze_match_options,
        analyze_impl=config.analyze_impl,
    )

    stats = run_measurement(
        kiwi,
        sentence_rows,
        runs=config.measure_runs,
        top_n=config.top_n,
        match_options=config.analyze_match_options,
        analyze_impl=config.analyze_impl,
    )
    sample_outputs = collect_sample_outputs(
        kiwi,
        sentences,
        sample_count=config.sample_count,
        top_n=config.top_n,
        match_options=config.analyze_match_options,
        analyze_impl=config.analyze_impl,
    )

    payload = to_payload(
        config=config,
        sentence_count=len(sentences),
        init_ms=init_ms,
        stats=stats,
        sample_outputs=sample_outputs,
    )

    # Keep stdout payload ASCII-only for robust parsing on Windows runners.
    encoded_stdout = json.dumps(payload, ensure_ascii=True)
    safe_print_line(f'KIWI_BENCHMARK_JSON={encoded_stdout}')

    if config.output_path is not None:
        config.output_path.parent.mkdir(parents=True, exist_ok=True)
        config.output_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding='utf-8',
        )

    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as error:  # pragma: no cover - CLI failure path
        safe_print_line(f'KIWI_BENCHMARK_ERROR={error}', stream=sys.stderr)
        raise
