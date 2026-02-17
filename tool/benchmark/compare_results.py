#!/usr/bin/env python3
"""Compare flutter_kiwi_nlp and kiwipiepy benchmark JSON results."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Generate a markdown comparison table from two JSON files.'
    )
    parser.add_argument(
        '--flutter-json',
        type=Path,
        required=True,
        help='Path to flutter benchmark result JSON.',
    )
    parser.add_argument(
        '--kiwi-json',
        type=Path,
        required=True,
        help='Path to kiwipiepy benchmark result JSON.',
    )
    parser.add_argument(
        '--output-md',
        type=Path,
        default=Path('benchmark/results/comparison.md'),
        help='Path to output markdown report.',
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f'Result file not found: {path}')

    raw = json.loads(path.read_text())
    if not isinstance(raw, dict):
        raise TypeError(f'Invalid result payload: {path}')
    return raw


def format_number(value: Any, decimals: int = 2) -> str:
    if isinstance(value, (int, float)):
        return f'{value:.{decimals}f}'
    return str(value)


def format_ratio(
    flutter_value: float,
    kiwi_value: float,
    *,
    inverse: bool = False,
) -> str:
    if kiwi_value <= 0:
        return 'N/A'

    ratio = flutter_value / kiwi_value
    ratio_text = f'{ratio:.2f}x'

    if ratio == 1:
        return ratio_text

    if inverse:
        faster = 'faster' if ratio < 1 else 'slower'
        return f'{ratio_text} ({faster})'

    faster = 'faster' if ratio > 1 else 'slower'
    return f'{ratio_text} ({faster})'


def safe_float(payload: dict[str, Any], key: str) -> float:
    value = payload.get(key)
    if isinstance(value, (int, float)):
        return float(value)
    return 0.0


def build_report(flutter: dict[str, Any], kiwi: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append('# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy')
    lines.append('')
    lines.append('## Run Metadata')
    lines.append('')
    lines.append('| Field | flutter_kiwi_nlp | kiwipiepy |')
    lines.append('| --- | --- | --- |')
    lines.append(
        f"| runtime | {flutter.get('runtime', '')} | {kiwi.get('runtime', '')} |"
    )
    lines.append(
        f"| platform | {flutter.get('platform', '')} | {kiwi.get('platform', '')} |"
    )
    lines.append(
        f"| generated_at_utc | {flutter.get('generated_at_utc', '')}"
        f" | {kiwi.get('generated_at_utc', '')} |"
    )
    lines.append(
        f"| sentence_count | {flutter.get('sentence_count', '')}"
        f" | {kiwi.get('sentence_count', '')} |"
    )
    lines.append(
        f"| warmup_runs | {flutter.get('warmup_runs', '')}"
        f" | {kiwi.get('warmup_runs', '')} |"
    )
    lines.append(
        f"| measure_runs | {flutter.get('measure_runs', '')}"
        f" | {kiwi.get('measure_runs', '')} |"
    )
    lines.append(
        f"| top_n | {flutter.get('top_n', '')} | {kiwi.get('top_n', '')} |"
    )
    lines.append('')

    init_flutter = safe_float(flutter, 'init_ms')
    init_kiwi = safe_float(kiwi, 'init_ms')
    throughput_flutter = safe_float(flutter, 'analyses_per_sec')
    throughput_kiwi = safe_float(kiwi, 'analyses_per_sec')
    chars_flutter = safe_float(flutter, 'chars_per_sec')
    chars_kiwi = safe_float(kiwi, 'chars_per_sec')
    tokens_flutter = safe_float(flutter, 'tokens_per_sec')
    tokens_kiwi = safe_float(kiwi, 'tokens_per_sec')
    latency_flutter = safe_float(flutter, 'avg_latency_ms')
    latency_kiwi = safe_float(kiwi, 'avg_latency_ms')
    token_latency_flutter = safe_float(flutter, 'avg_token_latency_us')
    token_latency_kiwi = safe_float(kiwi, 'avg_token_latency_us')

    lines.append('## Comparison')
    lines.append('')
    lines.append('| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |')
    lines.append('| --- | ---: | ---: | ---: |')
    lines.append(
        '| Init time (ms, lower better) | '
        f"{format_number(init_flutter)} | {format_number(init_kiwi)} | "
        f"{format_ratio(init_flutter, init_kiwi, inverse=True)} |"
    )
    lines.append(
        '| Throughput (analyses/s, higher better) | '
        f"{format_number(throughput_flutter)}"
        f" | {format_number(throughput_kiwi)}"
        f" | {format_ratio(throughput_flutter, throughput_kiwi)} |"
    )
    lines.append(
        '| Throughput (chars/s, higher better) | '
        f"{format_number(chars_flutter)} | {format_number(chars_kiwi)}"
        f" | {format_ratio(chars_flutter, chars_kiwi)} |"
    )
    lines.append(
        '| Throughput (tokens/s, higher better) | '
        f"{format_number(tokens_flutter)} | {format_number(tokens_kiwi)}"
        f" | {format_ratio(tokens_flutter, tokens_kiwi)} |"
    )
    lines.append(
        '| Avg latency (ms, lower better) | '
        f"{format_number(latency_flutter)} | {format_number(latency_kiwi)}"
        f" | {format_ratio(latency_flutter, latency_kiwi, inverse=True)} |"
    )
    lines.append(
        '| Avg token latency (us/token, lower better) | '
        f"{format_number(token_latency_flutter)}"
        f" | {format_number(token_latency_kiwi)}"
        f" | {format_ratio(token_latency_flutter, token_latency_kiwi, inverse=True)} |"
    )
    lines.append('')
    lines.append('> Note: Use identical corpus, warmup, top_n, and hardware settings.')

    return '\n'.join(lines) + '\n'


def main() -> int:
    args = parse_args()

    flutter = load_json(args.flutter_json)
    kiwi = load_json(args.kiwi_json)

    report = build_report(flutter, kiwi)

    args.output_md.parent.mkdir(parents=True, exist_ok=True)
    args.output_md.write_text(report)

    print(f'Report written: {args.output_md}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
