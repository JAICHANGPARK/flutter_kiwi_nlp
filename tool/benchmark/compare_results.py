#!/usr/bin/env python3
"""Compare flutter_kiwi_nlp and kiwipiepy benchmark JSON results."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            'Generate a markdown comparison table from benchmark JSON files. '
            'Each input may be a single JSON object or a list of trial '
            'objects.'
        )
    )
    parser.add_argument(
        '--flutter-json',
        type=Path,
        required=True,
        help='Path to flutter benchmark result JSON (dict or list[dict]).',
    )
    parser.add_argument(
        '--kiwi-json',
        type=Path,
        required=True,
        help='Path to kiwipiepy benchmark result JSON (dict or list[dict]).',
    )
    parser.add_argument(
        '--output-md',
        type=Path,
        default=Path('benchmark/results/comparison.md'),
        help='Path to output markdown report.',
    )
    return parser.parse_args()


def load_trials(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(f'Result file not found: {path}')

    raw = json.loads(path.read_text(encoding='utf-8'))
    if isinstance(raw, dict):
        return [raw]
    if isinstance(raw, list) and raw and all(isinstance(x, dict) for x in raw):
        return raw

    raise TypeError(
        f'Invalid result payload: {path}. Expected dict or non-empty list[dict].'
    )


def safe_float(payload: dict[str, Any], key: str) -> float:
    value = payload.get(key)
    if isinstance(value, (int, float)):
        return float(value)
    return 0.0


def summarize_metric(trials: list[dict[str, Any]], key: str) -> tuple[float, float]:
    values = [safe_float(trial, key) for trial in trials]
    mean = statistics.fmean(values)
    stddev = statistics.stdev(values) if len(values) > 1 else 0.0
    return mean, stddev


def percentile(values: list[float], quantile: float) -> float:
    if not values:
        return 0.0
    if quantile <= 0:
        return min(values)
    if quantile >= 1:
        return max(values)

    sorted_values = sorted(values)
    position = (len(sorted_values) - 1) * quantile
    lower_index = math.floor(position)
    upper_index = math.ceil(position)
    if lower_index == upper_index:
        return sorted_values[lower_index]

    lower = sorted_values[lower_index]
    upper = sorted_values[upper_index]
    weight = position - lower_index
    return lower + ((upper - lower) * weight)


def summarize_median_p95(
    trials: list[dict[str, Any]],
    key: str,
) -> tuple[float, float]:
    values = [safe_float(trial, key) for trial in trials]
    if not values:
        return 0.0, 0.0
    return statistics.median(values), percentile(values, 0.95)


def effective_analyses_per_sec(
    init_ms: float,
    warm_analyses_per_sec: float,
    analysis_count: int,
) -> float:
    if analysis_count <= 0 or warm_analyses_per_sec <= 0:
        return 0.0

    total_seconds = (init_ms / 1000.0) + (analysis_count / warm_analyses_per_sec)
    if total_seconds <= 0:
        return 0.0
    return analysis_count / total_seconds


def summarize_effective_analyses_per_sec(
    trials: list[dict[str, Any]],
    analysis_count: int,
) -> tuple[float, float]:
    values = [
        effective_analyses_per_sec(
            init_ms=safe_float(trial, 'init_ms'),
            warm_analyses_per_sec=safe_float(trial, 'analyses_per_sec'),
            analysis_count=analysis_count,
        )
        for trial in trials
    ]
    mean = statistics.fmean(values)
    stddev = statistics.stdev(values) if len(values) > 1 else 0.0
    return mean, stddev


def first_or_mixed(trials: list[dict[str, Any]], key: str) -> str:
    values = [trial.get(key) for trial in trials]
    first = values[0]
    if all(value == first for value in values):
        if first is None:
            return '-'
        return str(first)
    return 'mixed'


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


def format_mean_std(mean: float, stddev: float, decimals: int = 2) -> str:
    return f'{mean:.{decimals}f} ± {stddev:.{decimals}f}'


def safe_divide(numerator: float, denominator: float) -> float:
    if denominator <= 0:
        return 0.0
    return numerator / denominator


def has_numeric_metric(trials: list[dict[str, Any]], key: str) -> bool:
    return any(isinstance(trial.get(key), (int, float)) for trial in trials)


def md_escape(value: object) -> str:
    return str(value).replace('|', '\\|').replace('\n', ' ')


def md_shorten(text: object, max_len: int = 120) -> str:
    raw = str(text).strip()
    if len(raw) <= max_len:
        return raw
    return f'{raw[: max_len - 1]}…'


def trial_sample_outputs(trial: dict[str, Any]) -> list[dict[str, Any]]:
    raw = trial.get('sample_outputs')
    if not isinstance(raw, list):
        return []
    return [item for item in raw if isinstance(item, dict)]


def first_non_empty_sample_outputs(
    trials: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    for trial in trials:
        samples = trial_sample_outputs(trial)
        if samples:
            return samples
    return []


def build_report(
    flutter_trials: list[dict[str, Any]],
    kiwi_trials: list[dict[str, Any]],
) -> str:
    lines: list[str] = []
    lines.append('# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy')
    lines.append('')

    lines.append('## Run Metadata')
    lines.append('')
    lines.append('| Field | flutter_kiwi_nlp | kiwipiepy |')
    lines.append('| --- | --- | --- |')
    lines.append(
        f"| runtime | {first_or_mixed(flutter_trials, 'runtime')}"
        f" | {first_or_mixed(kiwi_trials, 'runtime')} |"
    )
    lines.append(
        f"| platform | {first_or_mixed(flutter_trials, 'platform')}"
        f" | {first_or_mixed(kiwi_trials, 'platform')} |"
    )
    lines.append(
        f"| generated_at_utc (first trial) | {flutter_trials[0].get('generated_at_utc', '')}"
        f" | {kiwi_trials[0].get('generated_at_utc', '')} |"
    )
    lines.append(f'| trials | {len(flutter_trials)} | {len(kiwi_trials)} |')
    lines.append(
        f"| sentence_count | {first_or_mixed(flutter_trials, 'sentence_count')}"
        f" | {first_or_mixed(kiwi_trials, 'sentence_count')} |"
    )
    lines.append(
        f"| sample_count | {first_or_mixed(flutter_trials, 'sample_count')}"
        f" | {first_or_mixed(kiwi_trials, 'sample_count')} |"
    )
    lines.append(
        f"| warmup_runs | {first_or_mixed(flutter_trials, 'warmup_runs')}"
        f" | {first_or_mixed(kiwi_trials, 'warmup_runs')} |"
    )
    lines.append(
        f"| measure_runs | {first_or_mixed(flutter_trials, 'measure_runs')}"
        f" | {first_or_mixed(kiwi_trials, 'measure_runs')} |"
    )
    lines.append(
        f"| top_n | {first_or_mixed(flutter_trials, 'top_n')}"
        f" | {first_or_mixed(kiwi_trials, 'top_n')} |"
    )
    lines.append(
        f"| build_options | {first_or_mixed(flutter_trials, 'build_options')}"
        f" | {first_or_mixed(kiwi_trials, 'build_options')} |"
    )
    lines.append(
        f"| create_match_options | {first_or_mixed(flutter_trials, 'create_match_options')}"
        f" | {first_or_mixed(kiwi_trials, 'create_match_options')} |"
    )
    lines.append(
        f"| analyze_match_options | {first_or_mixed(flutter_trials, 'analyze_match_options')}"
        f" | {first_or_mixed(kiwi_trials, 'analyze_match_options')} |"
    )
    lines.append(
        f"| analyze_impl | {first_or_mixed(flutter_trials, 'analyze_impl')}"
        f" | {first_or_mixed(kiwi_trials, 'analyze_impl')} |"
    )
    lines.append(
        f"| execution_mode | {first_or_mixed(flutter_trials, 'execution_mode')}"
        " | - |"
    )
    lines.append(
        f"| num_threads / num_workers | {first_or_mixed(flutter_trials, 'num_threads')}"
        f" | {first_or_mixed(kiwi_trials, 'num_workers')} |"
    )
    lines.append('')
    flutter_impl = first_or_mixed(flutter_trials, 'analyze_impl')
    kiwi_impl = first_or_mixed(kiwi_trials, 'analyze_impl')
    if flutter_impl != kiwi_impl:
        lines.append(
            '> Caution: `analyze_impl` differs between runtimes, so this '
            'table is not a strict apples-to-apples API-path comparison.'
        )
        lines.append('')
    flutter_platform = first_or_mixed(flutter_trials, 'platform').lower()
    kiwi_platform = first_or_mixed(kiwi_trials, 'platform').lower()
    if (
        flutter_platform in ('ios', 'android')
        and flutter_platform not in kiwi_platform
    ):
        lines.append(
            '> Mobile caveat: Flutter measurements are from the target mobile '
            'runtime, while `kiwipiepy` runs on the host Python environment. '
            'Treat this as a cross-runtime reference, not a same-device '
            'head-to-head.'
        )
        lines.append('')

    if has_numeric_metric(flutter_trials, 'json_overhead_ms'):
        lines.append('## Flutter JSON Serialization/Parsing Overhead')
        lines.append('')
        lines.append('| Metric | flutter_kiwi_nlp (mean ± std) |')
        lines.append('| --- | ---: |')

        overhead_specs: list[tuple[str, str, int]] = [
            ('pure_elapsed_ms', 'Pure processing elapsed (ms)', 2),
            ('full_elapsed_ms', 'Full analyze elapsed (ms)', 2),
            ('json_overhead_ms', 'JSON overhead elapsed (ms)', 2),
            (
                'json_overhead_per_analysis_ms',
                'JSON overhead per analysis (ms)',
                4,
            ),
            (
                'json_overhead_per_token_us',
                'JSON overhead per token (us)',
                4,
            ),
            ('json_overhead_percent', 'JSON overhead ratio (%)', 2),
        ]
        for key, label, decimals in overhead_specs:
            mean, stddev = summarize_metric(flutter_trials, key)
            lines.append(
                f'| {label} | {format_mean_std(mean, stddev, decimals=decimals)} |'
            )
        lines.append('')

    warm_metric_specs: list[tuple[str, str, bool]] = [
        ('analyses_per_sec', 'Throughput (analyses/s, higher better)', False),
        ('chars_per_sec', 'Throughput (chars/s, higher better)', False),
        ('tokens_per_sec', 'Throughput (tokens/s, higher better)', False),
        (
            'avg_latency_ms',
            'Avg warm latency (ms, lower better)',
            True,
        ),
        (
            'avg_token_latency_us',
            'Avg warm token latency (us/token, lower better)',
            True,
        ),
    ]

    lines.append('## Warm Path Comparison (Primary, Init Excluded)')
    lines.append('')
    lines.append(
        '| Metric | flutter_kiwi_nlp (mean ± std) '
        '| kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |'
    )
    lines.append('| --- | ---: | ---: | ---: |')

    for key, label, inverse in warm_metric_specs:
        flutter_mean, flutter_std = summarize_metric(flutter_trials, key)
        kiwi_mean, kiwi_std = summarize_metric(kiwi_trials, key)
        lines.append(
            f'| {label} | {format_mean_std(flutter_mean, flutter_std)} '
            f'| {format_mean_std(kiwi_mean, kiwi_std)} '
            f'| {format_ratio(flutter_mean, kiwi_mean, inverse=inverse)} |'
        )

    if has_numeric_metric(flutter_trials, 'pure_analyses_per_sec'):
        flutter_pure_mean, flutter_pure_std = summarize_metric(
            flutter_trials,
            'pure_analyses_per_sec',
        )
        flutter_full_mean, flutter_full_std = summarize_metric(
            flutter_trials,
            'full_analyses_per_sec',
        )
        kiwi_api_mean, kiwi_api_std = summarize_metric(
            kiwi_trials,
            'analyses_per_sec',
        )
        boundary_loss_percent = max(
            0.0,
            1.0 - safe_divide(flutter_full_mean, flutter_pure_mean)
        ) * 100.0

        lines.append('')
        lines.append('## Layered Throughput Breakdown')
        lines.append('')
        lines.append('| Layer | Throughput (mean ± std, analyses/s) |')
        lines.append('| --- | ---: |')
        lines.append(
            f'| Flutter pure (`token_count`) '
            f'| {format_mean_std(flutter_pure_mean, flutter_pure_std)} |'
        )
        lines.append(
            f'| Flutter full (`json`) '
            f'| {format_mean_std(flutter_full_mean, flutter_full_std)} |'
        )
        lines.append(
            f'| kiwipiepy current API path (`{kiwi_impl}`) '
            f'| {format_mean_std(kiwi_api_mean, kiwi_api_std)} |'
        )
        lines.append('')
        lines.append('| Derived ratio | Value |')
        lines.append('| --- | ---: |')
        lines.append(
            '| Flutter pure / kiwi '
            f'| {format_ratio(flutter_pure_mean, kiwi_api_mean)} |'
        )
        lines.append(
            '| Flutter full / kiwi '
            f'| {format_ratio(flutter_full_mean, kiwi_api_mean)} |'
        )
        lines.append(
            '| Flutter boundary loss (full vs pure) '
            f'| {boundary_loss_percent:.2f}% |'
        )
        lines.append('')

        if (
            flutter_pure_mean >= kiwi_api_mean
            and flutter_full_mean < kiwi_api_mean
        ):
            lines.append(
                '> Reading: Flutter core path is competitive, but boundary '
                'materialization/parsing overhead reduces end-to-end API '
                'throughput.'
            )
            lines.append('')

    flutter_init_median, flutter_init_p95 = summarize_median_p95(
        flutter_trials,
        'init_ms',
    )
    kiwi_init_median, kiwi_init_p95 = summarize_median_p95(
        kiwi_trials,
        'init_ms',
    )

    lines.append('')
    lines.append('## Cold Start Comparison (Reported Separately)')
    lines.append('')
    lines.append('| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |')
    lines.append('| --- | ---: | ---: | ---: |')
    lines.append(
        '| Init time (ms, lower better) '
        f'| median {flutter_init_median:.2f}, p95 {flutter_init_p95:.2f} '
        f'| median {kiwi_init_median:.2f}, p95 {kiwi_init_p95:.2f} '
        f'| {format_ratio(flutter_init_median, kiwi_init_median, inverse=True)} |'
    )

    session_lengths = [1, 10, 100, 1000]
    lines.append('')
    lines.append('## Session-Length Effective Throughput (Init Included)')
    lines.append('')
    lines.append(
        '| Session analyses | flutter_kiwi_nlp effective analyses/s '
        '(mean ± std) | kiwipiepy effective analyses/s (mean ± std) '
        '| Ratio (Flutter mean / Kiwi mean) |'
    )
    lines.append('| ---: | ---: | ---: | ---: |')

    for session_analyses in session_lengths:
        flutter_effective_mean, flutter_effective_std = (
            summarize_effective_analyses_per_sec(
                flutter_trials,
                analysis_count=session_analyses,
            )
        )
        kiwi_effective_mean, kiwi_effective_std = (
            summarize_effective_analyses_per_sec(
                kiwi_trials,
                analysis_count=session_analyses,
            )
        )
        lines.append(
            f'| {session_analyses} '
            f'| {format_mean_std(flutter_effective_mean, flutter_effective_std)} '
            f'| {format_mean_std(kiwi_effective_mean, kiwi_effective_std)} '
            f'| {format_ratio(flutter_effective_mean, kiwi_effective_mean)} |'
        )

    lines.append('')
    lines.append('## Per-Trial Raw Snapshot')
    lines.append('')
    lines.append(
        '| Trial | Flutter init (ms) | Kiwi init (ms) '
        '| Flutter warm analyses/s | Kiwi warm analyses/s |'
    )
    lines.append('| ---: | ---: | ---: | ---: | ---: |')

    min_trials = min(len(flutter_trials), len(kiwi_trials))
    for index in range(min_trials):
        flutter_trial = flutter_trials[index]
        kiwi_trial = kiwi_trials[index]
        lines.append(
            f"| {index + 1} | {safe_float(flutter_trial, 'init_ms'):.2f}"
            f" | {safe_float(kiwi_trial, 'init_ms'):.2f}"
            f" | {safe_float(flutter_trial, 'analyses_per_sec'):.2f}"
            f" | {safe_float(kiwi_trial, 'analyses_per_sec'):.2f} |"
        )

    flutter_samples = first_non_empty_sample_outputs(flutter_trials)
    kiwi_samples = first_non_empty_sample_outputs(kiwi_trials)
    if flutter_samples or kiwi_samples:
        sample_rows = max(len(flutter_samples), len(kiwi_samples))
        lines.append('')
        lines.append('## Sample POS Output Comparison (Top1)')
        lines.append('')
        lines.append(
            '| # | Sentence | flutter_kiwi_nlp top1 | '
            'kiwipiepy top1 | Match |'
        )
        lines.append('| ---: | --- | --- | --- | --- |')
        for index in range(sample_rows):
            flutter_sample = (
                flutter_samples[index]
                if index < len(flutter_samples)
                else {}
            )
            kiwi_sample = kiwi_samples[index] if index < len(kiwi_samples) else {}
            sentence = str(
                flutter_sample.get('sentence') or kiwi_sample.get('sentence') or ''
            )
            flutter_top1 = str(
                flutter_sample.get('top1_text')
                or flutter_sample.get('top1Text')
                or flutter_sample.get('appTop1Text')
                or '(결과 없음)'
            )
            kiwi_top1 = str(
                kiwi_sample.get('top1_text')
                or kiwi_sample.get('top1Text')
                or '(없음)'
            )
            if flutter_top1 == '(결과 없음)' or kiwi_top1 == '(없음)':
                match = 'n/a'
            else:
                match = 'same' if flutter_top1 == kiwi_top1 else 'diff'
            lines.append(
                f'| {index + 1} '
                f'| {md_escape(md_shorten(sentence))} '
                f'| {md_escape(md_shorten(flutter_top1))} '
                f'| {md_escape(md_shorten(kiwi_top1))} '
                f'| {match} |'
            )

    lines.append('')
    lines.append(
        '> Note: Warm metrics are the primary steady-state indicators. '\
        'Cold start is reported separately using median and p95 to reduce '\
        'single-run volatility. Session-length effective throughput includes '\
        'init overhead and illustrates short-session user impact.'
    )

    return '\n'.join(lines) + '\n'


def main() -> int:
    args = parse_args()

    flutter_trials = load_trials(args.flutter_json)
    kiwi_trials = load_trials(args.kiwi_json)

    report = build_report(flutter_trials, kiwi_trials)

    args.output_md.parent.mkdir(parents=True, exist_ok=True)
    args.output_md.write_text(report, encoding='utf-8')

    print(f'Report written: {args.output_md}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
