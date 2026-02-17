#!/usr/bin/env python3
"""Run a `kiwipiepy` benchmark with the same corpus as Flutter benchmark."""

from __future__ import annotations

import argparse
import json
import platform
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class BenchmarkConfig:
    corpus_path: Path
    output_path: Path | None
    warmup_runs: int
    measure_runs: int
    top_n: int
    num_workers: int
    model_path: str


@dataclass(frozen=True)
class RunStats:
    elapsed_ms: float
    total_analyses: int
    total_chars: int
    total_tokens: int


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
        default=0,
        help='`num_workers` for `Kiwi` (0 lets kiwi decide).',
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

    return BenchmarkConfig(
        corpus_path=args.corpus,
        output_path=args.output,
        warmup_runs=args.warmup_runs,
        measure_runs=args.measure_runs,
        top_n=args.top_n,
        num_workers=args.num_workers,
        model_path=args.model_path,
    )


def load_sentences(path: Path) -> list[str]:
    if not path.exists():
        raise FileNotFoundError(f'Corpus not found: {path}')

    sentences = [line.strip() for line in path.read_text().splitlines()]
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

    kwargs: dict[str, Any] = {'num_workers': config.num_workers}
    if config.model_path:
        kwargs['model_path'] = config.model_path

    try:
        return Kiwi(**kwargs)
    except TypeError:
        kwargs.pop('num_workers', None)
        return Kiwi(**kwargs)


def run_measurement(
    kiwi: Any,
    sentences: list[str],
    *,
    runs: int,
    top_n: int,
) -> RunStats:
    total_analyses = 0
    total_chars = 0
    total_tokens = 0

    started = time.perf_counter()

    for _ in range(runs):
        for sentence in sentences:
            result = kiwi.analyze(sentence, top_n=top_n)
            total_analyses += 1
            total_chars += len(sentence)
            total_tokens += count_best_candidate_tokens(result)

    elapsed_ms = (time.perf_counter() - started) * 1000.0
    return RunStats(
        elapsed_ms=elapsed_ms,
        total_analyses=total_analyses,
        total_chars=total_chars,
        total_tokens=total_tokens,
    )


def count_best_candidate_tokens(result: Any) -> int:
    if not result:
        return 0

    first_candidate = result[0]
    if isinstance(first_candidate, tuple) and first_candidate:
        tokens = first_candidate[0]
        if hasattr(tokens, '__len__'):
            return len(tokens)

    tokens = getattr(first_candidate, 'tokens', None)
    if tokens is not None and hasattr(tokens, '__len__'):
        return len(tokens)

    return 0


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
        'sentence_count': sentence_count,
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
    }


def main() -> int:
    config = parse_args()
    sentences = load_sentences(config.corpus_path)

    init_started = time.perf_counter()
    kiwi = create_kiwi(config)
    init_ms = (time.perf_counter() - init_started) * 1000.0

    run_measurement(
        kiwi,
        sentences,
        runs=config.warmup_runs,
        top_n=config.top_n,
    )

    stats = run_measurement(
        kiwi,
        sentences,
        runs=config.measure_runs,
        top_n=config.top_n,
    )

    payload = to_payload(
        config=config,
        sentence_count=len(sentences),
        init_ms=init_ms,
        stats=stats,
    )

    encoded = json.dumps(payload, ensure_ascii=False)
    print(f'KIWI_BENCHMARK_JSON={encoded}')

    if config.output_path is not None:
        config.output_path.parent.mkdir(parents=True, exist_ok=True)
        config.output_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2)
        )

    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as error:  # pragma: no cover - CLI failure path
        print(f'KIWI_BENCHMARK_ERROR={error}', file=sys.stderr)
        raise
