#!/usr/bin/env python3
"""Collect quantitative maintenance/activity metrics for Kiwi wrappers."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

GITHUB_API_BASE = 'https://api.github.com'
USER_AGENT = 'flutter_kiwi_nlp-wrapper-survey/1.0'
DATE_FMT = '%Y-%m-%d'
LINK_LAST_RE = re.compile(r'[?&]page=(\d+)>;\s*rel="last"')


@dataclass(frozen=True)
class WrapperTarget:
    category: str
    wrapper_name: str
    repo: str
    note: str = ''


TARGETS: list[WrapperTarget] = [
    WrapperTarget(
        category='C# (official GUI)',
        wrapper_name='kiwi-gui',
        repo='bab2min/kiwi-gui',
        note='Official GUI wrapper',
    ),
    WrapperTarget(
        category='C# (community)',
        wrapper_name='NetKiwi',
        repo='EX3exp/NetKiwi',
        note='Community wrapper',
    ),
    WrapperTarget(
        category='Python',
        wrapper_name='kiwipiepy',
        repo='bab2min/kiwipiepy',
        note='Official Python wrapper',
    ),
    WrapperTarget(
        category='Java',
        wrapper_name='Kiwi Java binding',
        repo='bab2min/Kiwi',
        note='bindings/java in Kiwi monorepo',
    ),
    WrapperTarget(
        category='WASM (JS/TS)',
        wrapper_name='Kiwi WASM binding',
        repo='bab2min/Kiwi',
        note='bindings/wasm in Kiwi monorepo',
    ),
    WrapperTarget(
        category='R',
        wrapper_name='elbird',
        repo='mrchypark/elbird',
        note='Community wrapper',
    ),
    WrapperTarget(
        category='Go',
        wrapper_name='kiwigo',
        repo='codingpot/kiwigo',
        note='Community wrapper',
    ),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            'Collect release recency, commit recency, and activity metrics for '
            'upstream Kiwi wrappers.'
        )
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('benchmark/results/wrapper_activity'),
        help='Output directory for survey artifacts.',
    )
    parser.add_argument(
        '--as-of-date',
        default=dt.date.today().isoformat(),
        help='Reference date (YYYY-MM-DD) for recency calculations.',
    )
    return parser.parse_args()


def iso_to_datetime(value: str) -> dt.datetime:
    normalized = value.replace('Z', '+00:00')
    return dt.datetime.fromisoformat(normalized).astimezone(dt.timezone.utc)


def format_date(value: str | None) -> str:
    if not value:
        return 'N/A'
    return iso_to_datetime(value).date().isoformat()


def days_ago(value: str | None, *, as_of: dt.date) -> int | None:
    if not value:
        return None
    target_date = iso_to_datetime(value).date()
    return (as_of - target_date).days


def github_request(url: str) -> tuple[int, dict[str, str], bytes]:
    request = urllib.request.Request(
        url,
        headers={
            'Accept': 'application/vnd.github+json',
            'User-Agent': USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            status = response.status
            headers = {k: v for k, v in response.headers.items()}
            payload = response.read()
            return status, headers, payload
    except urllib.error.HTTPError as error:
        payload = error.read()
        headers = {k: v for k, v in error.headers.items()}
        return error.code, headers, payload


def github_json(url: str) -> dict[str, Any] | None:
    status, _, payload = github_request(url)
    if status == 404:
        return None
    if status >= 400:
        raise RuntimeError(f'GitHub request failed ({status}): {url}')
    return json.loads(payload.decode('utf-8'))


def parse_last_page(link_header: str | None) -> int | None:
    if not link_header:
        return None
    match = LINK_LAST_RE.search(link_header)
    if not match:
        return None
    return int(match.group(1))


def count_commits_since(
    *,
    repo: str,
    branch: str,
    since: dt.datetime,
) -> int:
    query = urllib.parse.urlencode(
        {
            'sha': branch,
            'since': since.isoformat().replace('+00:00', 'Z'),
            'per_page': 1,
            'page': 1,
        }
    )
    url = f'{GITHUB_API_BASE}/repos/{repo}/commits?{query}'
    status, headers, payload = github_request(url)
    if status in (409, 422):
        return 0
    if status >= 400:
        raise RuntimeError(
            f'GitHub commits request failed ({status}) for {repo}: {url}'
        )

    data = json.loads(payload.decode('utf-8'))
    if not isinstance(data, list):
        return 0
    if not data:
        return 0

    link_header = headers.get('Link')
    last_page = parse_last_page(link_header)
    if last_page is not None:
        return last_page
    return len(data)


def safe_int(value: Any) -> int:
    if isinstance(value, bool):
        return 0
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    return 0


def activity_tier(commits_90d: int, days_since_commit: int | None) -> str:
    if days_since_commit is None:
        return 'unknown'
    if commits_90d >= 20 and days_since_commit <= 30:
        return 'high'
    if commits_90d >= 5 and days_since_commit <= 90:
        return 'moderate'
    if commits_90d >= 1 and days_since_commit <= 180:
        return 'low'
    return 'dormant'


def build_report_rows(
    *,
    as_of: dt.date,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    as_of_dt = dt.datetime.combine(as_of, dt.time.min, tzinfo=dt.timezone.utc)
    since_90d = as_of_dt - dt.timedelta(days=90)
    since_365d = as_of_dt - dt.timedelta(days=365)

    for target in TARGETS:
        repo_meta = github_json(f'{GITHUB_API_BASE}/repos/{target.repo}')
        if repo_meta is None:
            rows.append(
                {
                    'category': target.category,
                    'wrapper_name': target.wrapper_name,
                    'repo': target.repo,
                    'note': target.note,
                    'error': 'Repository not found',
                }
            )
            continue

        branch = str(repo_meta.get('default_branch') or 'main')
        pushed_at = repo_meta.get('pushed_at')
        pushed_at_str = pushed_at if isinstance(pushed_at, str) else None
        release_meta = github_json(
            f'{GITHUB_API_BASE}/repos/{target.repo}/releases/latest'
        )
        release_at = release_meta.get('published_at') if release_meta else None
        release_at_str = release_at if isinstance(release_at, str) else None

        commits_90d = count_commits_since(
            repo=target.repo,
            branch=branch,
            since=since_90d,
        )
        commits_365d = count_commits_since(
            repo=target.repo,
            branch=branch,
            since=since_365d,
        )

        last_commit_days = days_ago(pushed_at_str, as_of=as_of)
        release_days = days_ago(release_at_str, as_of=as_of)
        rows.append(
            {
                'category': target.category,
                'wrapper_name': target.wrapper_name,
                'repo': target.repo,
                'note': target.note,
                'default_branch': branch,
                'latest_release_at': release_at_str,
                'latest_release_date': format_date(release_at_str),
                'release_days_ago': release_days,
                'last_commit_at': pushed_at_str,
                'last_commit_date': format_date(pushed_at_str),
                'last_commit_days_ago': last_commit_days,
                'commits_90d': commits_90d,
                'commits_365d': commits_365d,
                'stars': safe_int(repo_meta.get('stargazers_count')),
                'forks': safe_int(repo_meta.get('forks_count')),
                'open_issues': safe_int(repo_meta.get('open_issues_count')),
                'activity_tier': activity_tier(commits_90d, last_commit_days),
            }
        )
    return rows


def markdown_table(rows: list[dict[str, Any]], *, as_of: dt.date) -> str:
    lines: list[str] = []
    lines.append('# Wrapper Activity Survey')
    lines.append('')
    lines.append(f'- As-of date: {as_of.isoformat()}')
    lines.append(
        '- Metrics: latest release date, last commit date, recent commits, '
        'and repository engagement indicators.'
    )
    lines.append('')
    lines.append(
        '| Wrapper | Repo | Latest release | Last commit | '
        'Commits (90d / 365d) | Stars | Open issues | Tier |'
    )
    lines.append('| --- | --- | --- | --- | ---: | ---: | ---: | --- |')
    for row in rows:
        if row.get('error'):
            lines.append(
                f"| {row['wrapper_name']} | {row['repo']} | N/A | N/A | "
                f"N/A | N/A | N/A | error |"
            )
            continue
        latest_release = row['latest_release_date']
        release_days = row.get('release_days_ago')
        if release_days is not None:
            latest_release = f"{latest_release} ({release_days}d ago)"
        last_commit = f"{row['last_commit_date']} ({row['last_commit_days_ago']}d ago)"
        lines.append(
            f"| {row['wrapper_name']} | {row['repo']} | {latest_release} | "
            f"{last_commit} | {row['commits_90d']} / {row['commits_365d']} | "
            f"{row['stars']} | {row['open_issues']} | {row['activity_tier']} |"
        )
    lines.append('')
    return '\n'.join(lines)


def main() -> int:
    args = parse_args()
    as_of = dt.date.fromisoformat(args.as_of_date)
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    rows = build_report_rows(as_of=as_of)
    payload = {
        'generated_at_utc': dt.datetime.now(dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace('+00:00', 'Z'),
        'as_of_date': as_of.isoformat(),
        'rows': rows,
    }

    json_path = output_dir / 'wrapper_activity.json'
    md_path = output_dir / 'wrapper_activity.md'
    json_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    md_path.write_text(markdown_table(rows, as_of=as_of), encoding='utf-8')

    print(f'Wrote: {json_path}')
    print(f'Wrote: {md_path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
