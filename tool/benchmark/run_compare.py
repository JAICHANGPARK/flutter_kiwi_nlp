#!/usr/bin/env python3
"""Run Flutter and kiwipiepy benchmarks, then generate one comparison table."""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Run both benchmarks and generate markdown comparison.'
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
        help='Flutter build mode for benchmark run.',
    )
    parser.add_argument(
        '--warmup-runs',
        type=int,
        default=3,
        help='Warm-up pass count for both runtimes.',
    )
    parser.add_argument(
        '--measure-runs',
        type=int,
        default=15,
        help='Measured pass count for both runtimes.',
    )
    parser.add_argument(
        '--top-n',
        type=int,
        default=1,
        help='top_n value for both runtimes.',
    )
    parser.add_argument(
        '--num-threads',
        type=int,
        default=-1,
        help='numThreads for flutter_kiwi_nlp benchmark app.',
    )
    parser.add_argument(
        '--num-workers',
        type=int,
        default=-1,
        help='num_workers for kiwipiepy benchmark.',
    )
    parser.add_argument(
        '--build-options',
        type=int,
        default=1039,
        help='Bitwise Kiwi build option value passed to both runtimes.',
    )
    parser.add_argument(
        '--create-match-options',
        type=int,
        default=8454175,
        help='Bitwise create-time match option value for Flutter parity metadata.',
    )
    parser.add_argument(
        '--analyze-match-options',
        '--match-options',
        dest='analyze_match_options',
        type=int,
        default=8454175,
        help='Bitwise analyze-time match option value passed to both runtimes.',
    )
    parser.add_argument(
        '--trials',
        type=int,
        default=5,
        help='Number of repeated benchmark trials per runtime.',
    )
    parser.add_argument(
        '--model-path',
        default='',
        help='Optional shared model path for both runtimes.',
    )
    parser.add_argument(
        '--python-bin',
        default=sys.executable,
        help='Python interpreter used for helper scripts.',
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('benchmark/results'),
        help='Directory for JSON results and markdown report.',
    )
    parser.add_argument(
        '--corpus',
        type=Path,
        default=Path('example/assets/benchmark_corpus_ko.txt'),
        help='Corpus path for kiwipiepy benchmark script.',
    )
    parser.add_argument(
        '--flutter-timeout-seconds',
        type=int,
        default=1800,
        help='Timeout waiting for flutter benchmark JSON output.',
    )
    return parser.parse_args()


def run_command(command: list[str], *, cwd: Path | None = None) -> None:
    print(f"$ {shlex.join(command)}")
    subprocess.run(command, cwd=cwd, check=True)


def run_flutter_benchmark(
    command: list[str],
    *,
    cwd: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    print(f"$ {shlex.join(command)}")

    marker = 'KIWI_BENCHMARK_JSON='
    deadline = time.monotonic() + timeout_seconds

    process = subprocess.Popen(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    payload: dict[str, object] | None = None

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
                        'Flutter benchmark payload must be a JSON object.'
                    )
                payload = parsed
                break

            if time.monotonic() > deadline:
                raise TimeoutError(
                    'Timed out waiting for flutter benchmark output.'
                )

        if payload is None:
            raise RuntimeError('Could not find KIWI_BENCHMARK_JSON in output.')

        return payload
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=10)


def main() -> int:
    args = parse_args()
    if args.trials < 1:
        raise ValueError('--trials must be >= 1')
    if args.build_options < 0:
        raise ValueError('--build-options must be >= 0')
    if args.create_match_options < 0:
        raise ValueError('--create-match-options must be >= 0')
    if args.analyze_match_options < 0:
        raise ValueError('--analyze-match-options must be >= 0')

    repo_root = Path(__file__).resolve().parents[2]
    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    corpus_path = args.corpus
    if not corpus_path.is_absolute():
        corpus_path = repo_root / corpus_path

    flutter_json = output_dir / 'flutter_kiwi_benchmark.json'
    kiwi_json = output_dir / 'kiwipiepy_benchmark.json'
    flutter_trials_json = output_dir / 'flutter_kiwi_benchmark_trials.json'
    kiwi_trials_json = output_dir / 'kiwipiepy_benchmark_trials.json'
    report_md = output_dir / 'comparison.md'

    example_dir = repo_root / 'example'

    flutter_command = [
        'flutter',
        'run',
        '--no-pub',
        '-d',
        args.device,
        '--target',
        'lib/benchmark_main.dart',
        f'--{args.mode}',
        f'--dart-define=KIWI_BENCH_WARMUP_RUNS={args.warmup_runs}',
        f'--dart-define=KIWI_BENCH_MEASURE_RUNS={args.measure_runs}',
        f'--dart-define=KIWI_BENCH_TOP_N={args.top_n}',
        f'--dart-define=KIWI_BENCH_NUM_THREADS={args.num_threads}',
        f'--dart-define=KIWI_BENCH_BUILD_OPTIONS={args.build_options}',
        f'--dart-define=KIWI_BENCH_CREATE_MATCH_OPTIONS={args.create_match_options}',
        f'--dart-define=KIWI_BENCH_ANALYZE_MATCH_OPTIONS={args.analyze_match_options}',
    ]
    if args.model_path:
        flutter_command.append(
            f'--dart-define=KIWI_BENCH_MODEL_PATH={args.model_path}'
        )

    kiwi_command_base = [
        args.python_bin,
        str(repo_root / 'tool/benchmark/kiwipiepy_benchmark.py'),
        '--corpus',
        str(corpus_path.resolve()),
        '--warmup-runs',
        str(args.warmup_runs),
        '--measure-runs',
        str(args.measure_runs),
        '--top-n',
        str(args.top_n),
        '--num-workers',
        str(args.num_workers),
        '--build-options',
        str(args.build_options),
        '--create-match-options',
        str(args.create_match_options),
        '--analyze-match-options',
        str(args.analyze_match_options),
    ]
    if args.model_path:
        kiwi_command_base.extend(['--model-path', args.model_path])

    run_command(['flutter', 'pub', 'get'], cwd=example_dir)

    flutter_trials: list[dict[str, object]] = []
    kiwi_trials: list[dict[str, object]] = []

    for trial_id in range(1, args.trials + 1):
        print(f'\n=== Trial {trial_id}/{args.trials} ===')

        trial_flutter_command = flutter_command + [
            f'--dart-define=KIWI_BENCH_TRIAL_ID={trial_id}'
        ]
        flutter_payload = run_flutter_benchmark(
            trial_flutter_command,
            cwd=example_dir,
            timeout_seconds=args.flutter_timeout_seconds,
        )
        flutter_trials.append(flutter_payload)
        (output_dir / f'flutter_kiwi_benchmark_trial_{trial_id:02d}.json').write_text(
            json.dumps(flutter_payload, ensure_ascii=False, indent=2)
        )

        kiwi_trial_json = output_dir / f'kiwipiepy_benchmark_trial_{trial_id:02d}.json'
        trial_kiwi_command = kiwi_command_base + [
            '--trial-id',
            str(trial_id),
            '--output',
            str(kiwi_trial_json),
        ]
        run_command(trial_kiwi_command, cwd=repo_root)
        kiwi_payload_raw = json.loads(kiwi_trial_json.read_text())
        if not isinstance(kiwi_payload_raw, dict):
            raise TypeError('kiwipiepy benchmark payload must be a JSON object.')
        kiwi_trials.append(kiwi_payload_raw)

    flutter_trials_json.write_text(
        json.dumps(flutter_trials, ensure_ascii=False, indent=2)
    )
    kiwi_trials_json.write_text(
        json.dumps(kiwi_trials, ensure_ascii=False, indent=2)
    )

    # Keep legacy single-run files for compatibility by writing the final trial.
    flutter_json.write_text(
        json.dumps(flutter_trials[-1], ensure_ascii=False, indent=2)
    )
    kiwi_json.write_text(
        json.dumps(kiwi_trials[-1], ensure_ascii=False, indent=2)
    )

    report_command = [
        args.python_bin,
        str(repo_root / 'tool/benchmark/compare_results.py'),
        '--flutter-json',
        str(flutter_trials_json),
        '--kiwi-json',
        str(kiwi_trials_json),
        '--output-md',
        str(report_md),
    ]
    run_command(report_command, cwd=repo_root)

    print(f'\nDone. Open: {report_md}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
