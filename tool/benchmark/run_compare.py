#!/usr/bin/env python3
"""Run Flutter and kiwipiepy benchmarks, then generate one comparison table."""

from __future__ import annotations

import argparse
import base64
import json
import os
import queue
import shlex
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import TextIO


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
        '--flutter-analyze-impl',
        choices=('json', 'token_count'),
        default='json',
        help='Flutter benchmark analyze path: json(full payload) or token_count.',
    )
    parser.add_argument(
        '--flutter-execution-mode',
        choices=('single', 'batch'),
        default='batch',
        help='Flutter benchmark execution mode: single(sentence loop) or batch.',
    )
    parser.add_argument(
        '--kiwi-analyze-impl',
        choices=('analyze', 'tokenize'),
        default='analyze',
        help='kiwipiepy benchmark API path: analyze(top_n) or tokenize().',
    )
    parser.add_argument(
        '--sample-count',
        type=int,
        default=10,
        help='Number of sample sentences to include with POS outputs.',
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
    print(f"$ {shlex.join(command)}", flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def resolve_flutter_executable() -> str:
    """Resolve flutter executable across Unix/Windows runners."""
    candidates = ['flutter', 'flutter.bat', 'flutter.exe']
    for candidate in candidates:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved

    raise FileNotFoundError(
        'Could not find Flutter executable in PATH. '
        'Expected one of: flutter, flutter.bat, flutter.exe'
    )


def run_flutter_benchmark(
    command: list[str],
    *,
    cwd: Path,
    timeout_seconds: int,
    output_json_path: Path | None = None,
    android_device_id: str | None = None,
) -> dict[str, object]:
    print(f"$ {shlex.join(command)}", flush=True)

    marker = 'KIWI_BENCHMARK_JSON='
    chunk_marker = 'KIWI_BENCHMARK_JSON_B64_CHUNK='
    deadline = time.monotonic() + timeout_seconds
    debug_parser = os.environ.get('KIWI_BENCH_DEBUG_PARSER') == '1'

    process = subprocess.Popen(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding='utf-8',
        errors='replace',
        bufsize=1,
    )

    output_queue: queue.Queue[str | None] = queue.Queue()

    def _pump_stdout(stream: TextIO) -> None:
        try:
            for output_line in stream:
                output_queue.put(output_line)
        finally:
            output_queue.put(None)

    payload: dict[str, object] | None = None
    chunk_total: int | None = None
    chunk_parts: dict[int, str] = {}
    next_logcat_poll_time = 0.0

    def try_load_output_payload() -> dict[str, object] | None:
        if output_json_path is None or not output_json_path.exists():
            return None
        try:
            parsed = json.loads(output_json_path.read_text())
        except (json.JSONDecodeError, OSError):
            return None
        if isinstance(parsed, dict):
            return parsed
        return None

    def try_load_logcat_payload() -> dict[str, object] | None:
        if android_device_id is None:
            return None
        completed = subprocess.run(
            ['adb', '-s', android_device_id, 'logcat', '-d'],
            check=False,
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            return None

        chunk_total_local: int | None = None
        chunk_parts_local: dict[int, str] = {}
        for line in completed.stdout.splitlines():
            marker_index = line.find(marker)
            if marker_index != -1:
                raw_json = line[marker_index + len(marker) :].strip()
                try:
                    parsed = json.loads(raw_json)
                except json.JSONDecodeError:
                    parsed = None
                if isinstance(parsed, dict):
                    return parsed

            chunk_marker_index = line.find(chunk_marker)
            if chunk_marker_index == -1:
                continue

            raw_chunk = line[chunk_marker_index + len(chunk_marker) :].strip()
            slash_index = raw_chunk.find('/')
            colon_index = raw_chunk.find(':')
            if slash_index <= 0 or colon_index <= slash_index + 1:
                continue
            try:
                chunk_index = int(raw_chunk[:slash_index])
                total_count = int(raw_chunk[slash_index + 1 : colon_index])
            except ValueError:
                continue
            if chunk_index <= 0 or total_count <= 0:
                continue
            if chunk_index > total_count:
                continue

            chunk_body = raw_chunk[colon_index + 1 :]
            if not chunk_body:
                continue

            if chunk_total_local is None:
                chunk_total_local = total_count
            elif chunk_total_local != total_count:
                continue

            chunk_parts_local[chunk_index] = chunk_body

        if chunk_total_local is None:
            return None
        if len(chunk_parts_local) != chunk_total_local:
            return None

        joined = ''.join(
            chunk_parts_local[index]
            for index in range(1, chunk_total_local + 1)
        )
        try:
            decoded = json.loads(base64.b64decode(joined).decode('utf-8'))
        except (
            ValueError,
            UnicodeDecodeError,
            json.JSONDecodeError,
        ):
            return None
        if isinstance(decoded, dict):
            return decoded
        return None

    def try_parse_chunk_line(line: str) -> dict[str, object] | None:
        marker_index = line.find(chunk_marker)
        if marker_index == -1:
            return None

        raw_chunk = line[marker_index + len(chunk_marker) :].strip()
        # Format: "<index>/<total>:<base64 chunk>"
        slash_index = raw_chunk.find('/')
        colon_index = raw_chunk.find(':')
        if slash_index <= 0 or colon_index <= slash_index + 1:
            return None

        try:
            chunk_index = int(raw_chunk[:slash_index])
            total_count = int(raw_chunk[slash_index + 1 : colon_index])
        except ValueError:
            return None

        if chunk_index <= 0 or total_count <= 0:
            return None
        if chunk_index > total_count:
            return None

        chunk_body = raw_chunk[colon_index + 1 :]
        if not chunk_body:
            return None

        nonlocal chunk_total
        if chunk_total is None:
            chunk_total = total_count
        elif chunk_total != total_count:
            # Ignore mixed payloads from another app run and keep current set.
            return None

        chunk_parts[chunk_index] = chunk_body
        if debug_parser:
            print(
                f'[parser] chunk {chunk_index}/{chunk_total} '
                f'len={len(chunk_body)} parts={len(chunk_parts)}',
                flush=True,
            )
        if len(chunk_parts) != chunk_total:
            return None

        joined = ''.join(chunk_parts[index] for index in range(1, chunk_total + 1))
        try:
            decoded = json.loads(base64.b64decode(joined).decode('utf-8'))
        except (
            ValueError,
            UnicodeDecodeError,
            json.JSONDecodeError,
        ):
            if debug_parser:
                print(
                    '[parser] failed to decode assembled chunk payload',
                    flush=True,
                )
            return None
        if isinstance(decoded, dict):
            if debug_parser:
                print('[parser] decoded chunk payload', flush=True)
            return decoded
        return None

    try:
        if android_device_id is not None:
            subprocess.run(
                ['adb', '-s', android_device_id, 'logcat', '-c'],
                check=False,
                capture_output=True,
                text=True,
            )
        assert process.stdout is not None
        stdout_reader = threading.Thread(
            target=_pump_stdout,
            args=(process.stdout,),
            daemon=True,
        )
        stdout_reader.start()

        stdout_closed = False
        while True:
            payload = try_load_output_payload()
            if payload is not None:
                break

            if android_device_id is not None:
                now = time.monotonic()
                if now >= next_logcat_poll_time:
                    payload = try_load_logcat_payload()
                    next_logcat_poll_time = now + 1.0
                if payload is not None:
                    break

            has_queue_item = False
            queued_line: str | None = None
            try:
                queued_line = output_queue.get(timeout=0.25)
                has_queue_item = True
            except queue.Empty:
                pass

            if has_queue_item:
                if queued_line is None:
                    stdout_closed = True
                else:
                    print(queued_line, end='')
                    marker_index = queued_line.find(marker)
                    if marker_index != -1:
                        raw_json = queued_line[marker_index + len(marker) :].strip()
                        try:
                            parsed = json.loads(raw_json)
                        except json.JSONDecodeError:
                            if debug_parser:
                                print('[parser] JSON marker line was truncated', flush=True)
                            parsed = None
                        if isinstance(parsed, dict):
                            if debug_parser:
                                print('[parser] decoded direct JSON marker', flush=True)
                            payload = parsed
                            break

                    parsed_chunk = try_parse_chunk_line(queued_line)
                    if parsed_chunk is not None:
                        payload = parsed_chunk
                        break

            if process.poll() is not None and stdout_closed:
                break

            if time.monotonic() > deadline:
                raise TimeoutError(
                    'Timed out waiting for flutter benchmark output.'
                )

        if payload is None:
            payload = try_load_output_payload()

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
    if args.sample_count < 0:
        raise ValueError('--sample-count must be >= 0')

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
    flutter_executable = resolve_flutter_executable()

    flutter_command = [
        flutter_executable,
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
        f'--dart-define=KIWI_BENCH_ANALYZE_IMPL={args.flutter_analyze_impl}',
        f'--dart-define=KIWI_BENCH_EXECUTION_MODE={args.flutter_execution_mode}',
        f'--dart-define=KIWI_BENCH_SAMPLE_COUNT={args.sample_count}',
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
        '--analyze-impl',
        args.kiwi_analyze_impl,
        '--sample-count',
        str(args.sample_count),
    ]
    if args.model_path:
        kiwi_command_base.extend(['--model-path', args.model_path])

    run_command([flutter_executable, 'pub', 'get'], cwd=example_dir)

    flutter_trials: list[dict[str, object]] = []
    kiwi_trials: list[dict[str, object]] = []

    for trial_id in range(1, args.trials + 1):
        print(f'\n=== Trial {trial_id}/{args.trials} ===', flush=True)

        flutter_trial_json = (
            output_dir / f'flutter_kiwi_benchmark_trial_{trial_id:02d}.json'
        )
        flutter_trial_json.unlink(missing_ok=True)
        trial_flutter_command = flutter_command + [
            f'--dart-define=KIWI_BENCH_TRIAL_ID={trial_id}',
            f'--dart-define=KIWI_BENCH_OUTPUT_PATH={flutter_trial_json}',
        ]
        android_device_id: str | None = None
        if args.device.startswith('emulator-'):
            android_device_id = args.device
        flutter_payload = run_flutter_benchmark(
            trial_flutter_command,
            cwd=example_dir,
            timeout_seconds=args.flutter_timeout_seconds,
            output_json_path=flutter_trial_json,
            android_device_id=android_device_id,
        )
        flutter_trials.append(flutter_payload)
        flutter_trial_json.write_text(
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

    print(f'\nDone. Open: {report_md}', flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
