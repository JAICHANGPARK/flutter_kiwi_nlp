#!/usr/bin/env python3
"""Search arXiv papers with structured filters."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as et

API_URL = "https://export.arxiv.org/api/query"

NAMESPACES = {
    "atom": "http://www.w3.org/2005/Atom",
    "opensearch": "http://a9.com/-/spec/opensearch/1.1/",
    "arxiv": "http://arxiv.org/schemas/atom",
}


class ArxivSearchError(RuntimeError):
    """Represents failures while calling or parsing the arXiv API."""


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Search arXiv papers by topic, author, and category.",
    )
    parser.add_argument(
        "--query",
        help="General query mapped to all:\"...\" in arXiv syntax.",
    )
    parser.add_argument(
        "--title",
        help="Title query mapped to ti:\"...\" in arXiv syntax.",
    )
    parser.add_argument(
        "--author",
        action="append",
        default=[],
        help="Author filter. Repeat for multiple authors.",
    )
    parser.add_argument(
        "--category",
        action="append",
        default=[],
        help="Category filter such as cs.LG or stat.ML. Repeat as needed.",
    )
    parser.add_argument(
        "--raw-query",
        help="Raw arXiv search_query string passed as-is.",
    )
    parser.add_argument(
        "--from-date",
        type=parse_date_arg,
        help="Published date lower bound in YYYY-MM-DD.",
    )
    parser.add_argument(
        "--to-date",
        type=parse_date_arg,
        help="Published date upper bound in YYYY-MM-DD.",
    )
    parser.add_argument(
        "--days",
        type=int,
        help=(
            "Relative date window (latest N days, including today). "
            "Cannot be combined with --from-date/--to-date."
        ),
    )
    parser.add_argument(
        "--start",
        type=int,
        default=0,
        help="Result offset (default: 0).",
    )
    parser.add_argument(
        "--max-results",
        type=int,
        default=10,
        help="Maximum records to request from API (1-200).",
    )
    parser.add_argument(
        "--sort-by",
        choices=["relevance", "lastUpdatedDate", "submittedDate"],
        help=(
            "Sort mode used by arXiv. Default is submittedDate when "
            "date filters are used, otherwise relevance."
        ),
    )
    parser.add_argument(
        "--sort-order",
        choices=["ascending", "descending"],
        default="descending",
        help="Sort direction used by arXiv.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=20.0,
        help="HTTP timeout in seconds (default: 20).",
    )
    parser.add_argument(
        "--retry",
        type=int,
        default=2,
        help="Retry count for transient API errors (default: 2).",
    )
    parser.add_argument(
        "--retry-backoff",
        type=float,
        default=1.5,
        help="Linear backoff seconds between retries (default: 1.5).",
    )
    parser.add_argument(
        "--include-abstract",
        action="store_true",
        help="Include abstracts in text output.",
    )
    parser.add_argument(
        "--include-bibtex",
        action="store_true",
        help="Include generated BibTeX entries.",
    )
    parser.add_argument(
        "--require-pdf",
        action="store_true",
        help="Only return entries that provide a PDF link.",
    )
    parser.add_argument(
        "--dedupe-by-title",
        action="store_true",
        help="Drop duplicate titles after filtering (keep first occurrence).",
    )
    parser.add_argument(
        "--max-abstract-chars",
        type=int,
        default=0,
        help=(
            "Trim abstract to at most N characters "
            "(0 keeps full text, default: 0)."
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print JSON instead of text.",
    )

    args = parser.parse_args(argv)
    validate_args(parser, args)
    return args


def parse_date_arg(value: str) -> dt.date:
    try:
        return dt.datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError as error:
        raise argparse.ArgumentTypeError(
            "date must use YYYY-MM-DD format",
        ) from error


def validate_args(
    parser: argparse.ArgumentParser,
    args: argparse.Namespace,
) -> None:
    has_raw_query = bool(args.raw_query)
    has_structured_terms = bool(
        args.query or args.title or args.author or args.category,
    )
    if not has_raw_query and not has_structured_terms:
        parser.error("provide at least one search field or use --raw-query")
    if has_raw_query and has_structured_terms:
        parser.error("--raw-query cannot be combined with structured fields")
    if args.max_results < 1 or args.max_results > 200:
        parser.error("--max-results must be between 1 and 200")
    if args.start < 0:
        parser.error("--start must be zero or greater")
    if args.days is not None and args.days < 1:
        parser.error("--days must be at least 1")
    if args.days is not None and (args.from_date or args.to_date):
        parser.error(
            "--days cannot be combined with --from-date or --to-date",
        )
    if args.from_date and args.to_date and args.from_date > args.to_date:
        parser.error("--from-date must be <= --to-date")
    if args.timeout <= 0:
        parser.error("--timeout must be greater than 0")
    if args.retry < 0:
        parser.error("--retry must be zero or greater")
    if args.retry_backoff < 0:
        parser.error("--retry-backoff must be zero or greater")
    if args.max_abstract_chars < 0:
        parser.error("--max-abstract-chars must be zero or greater")


def run_search(args: argparse.Namespace) -> dict[str, object]:
    from_date, to_date = resolve_date_window(
        from_date=args.from_date,
        to_date=args.to_date,
        days=args.days,
    )
    query = args.raw_query or build_query(
        query=args.query,
        title=args.title,
        authors=args.author,
        categories=args.category,
    )
    sort_by = resolve_sort_by(
        sort_by=args.sort_by,
        from_date=from_date,
        to_date=to_date,
    )
    xml_text = fetch_xml(
        query=query,
        start=args.start,
        max_results=args.max_results,
        sort_by=sort_by,
        sort_order=args.sort_order,
        timeout=args.timeout,
        retry=args.retry,
        retry_backoff=args.retry_backoff,
    )
    feed = parse_feed(
        xml_text=xml_text,
        from_date=from_date,
        to_date=to_date,
        include_bibtex=args.include_bibtex,
        require_pdf=args.require_pdf,
        dedupe_by_title=args.dedupe_by_title,
        max_abstract_chars=args.max_abstract_chars,
    )
    feed["query"] = query
    feed["sort_by"] = sort_by
    if args.days is not None:
        feed["date_window"] = {
            "mode": "days",
            "days": args.days,
            "from_date": from_date.isoformat() if from_date else None,
            "to_date": to_date.isoformat() if to_date else None,
        }
    elif from_date or to_date:
        feed["date_window"] = {
            "mode": "absolute",
            "from_date": from_date.isoformat() if from_date else None,
            "to_date": to_date.isoformat() if to_date else None,
        }
    return feed


def resolve_date_window(
    *,
    from_date: dt.date | None,
    to_date: dt.date | None,
    days: int | None,
) -> tuple[dt.date | None, dt.date | None]:
    if days is None:
        return from_date, to_date
    today = dt.date.today()
    start = today - dt.timedelta(days=days - 1)
    return start, today


def resolve_sort_by(
    *,
    sort_by: str | None,
    from_date: dt.date | None,
    to_date: dt.date | None,
) -> str:
    if sort_by:
        return sort_by
    if from_date or to_date:
        return "submittedDate"
    return "relevance"


def build_query(
    *,
    query: str | None,
    title: str | None,
    authors: list[str],
    categories: list[str],
) -> str:
    parts: list[str] = []
    if query:
        parts.append(f'all:"{escape_term(query)}"')
    if title:
        parts.append(f'ti:"{escape_term(title)}"')
    for author in authors:
        parts.append(f'au:"{escape_term(author)}"')
    for category in categories:
        cleaned = category.strip()
        if cleaned:
            parts.append(f"cat:{cleaned}")
    if not parts:
        raise ArxivSearchError("query construction failed: no valid parts")
    return " AND ".join(parts)


def escape_term(value: str) -> str:
    return re.sub(r'"', r'\\"', value.strip())


def fetch_xml(
    *,
    query: str,
    start: int,
    max_results: int,
    sort_by: str,
    sort_order: str,
    timeout: float,
    retry: int,
    retry_backoff: float,
) -> str:
    params = {
        "search_query": query,
        "start": str(start),
        "max_results": str(max_results),
        "sortBy": sort_by,
        "sortOrder": sort_order,
    }
    encoded = urllib.parse.urlencode(params, quote_via=urllib.parse.quote_plus)
    url = f"{API_URL}?{encoded}"
    request = urllib.request.Request(
        url=url,
        headers={
            "User-Agent": (
                "arxiv-paper-search/1.1 "
                "(https://github.com/jaichang/flutter_kiwi_nlp)"
            ),
        },
    )

    attempts = retry + 1
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                body = response.read()
            return body.decode("utf-8", errors="replace")
        except (TimeoutError, urllib.error.URLError) as error:
            last_error = error
            if attempt >= attempts:
                break
            wait_seconds = retry_backoff * attempt
            if wait_seconds > 0:
                time.sleep(wait_seconds)

    raise ArxivSearchError(
        f"arXiv request failed after {attempts} attempt(s): {last_error}",
    ) from last_error


def parse_feed(
    *,
    xml_text: str,
    from_date: dt.date | None,
    to_date: dt.date | None,
    include_bibtex: bool,
    require_pdf: bool,
    dedupe_by_title: bool,
    max_abstract_chars: int,
) -> dict[str, object]:
    try:
        root = et.fromstring(xml_text)
    except et.ParseError as error:
        raise ArxivSearchError(f"invalid XML response: {error}") from error

    total_results = parse_total_results(root)
    entries = [
        parse_entry(
            node,
            include_bibtex=include_bibtex,
            max_abstract_chars=max_abstract_chars,
        )
        for node in root.findall("atom:entry", NAMESPACES)
    ]

    date_filtered = [
        entry
        for entry in entries
        if matches_date_filter(
            published=entry["published"],
            from_date=from_date,
            to_date=to_date,
        )
    ]

    pdf_filtered = [
        entry
        for entry in date_filtered
        if not require_pdf or bool(entry.get("pdf_url"))
    ]

    deduped = pdf_filtered
    dropped_by_dedupe = 0
    if dedupe_by_title:
        deduped, dropped_by_dedupe = dedupe_entries_by_title(pdf_filtered)

    return {
        "total_results": total_results,
        "fetched_results": len(entries),
        "date_filtered_results": len(date_filtered),
        "returned_results": len(deduped),
        "dropped_results": {
            "date_filter": len(entries) - len(date_filtered),
            "require_pdf": len(date_filtered) - len(pdf_filtered),
            "dedupe_title": dropped_by_dedupe,
        },
        "entries": deduped,
    }


def parse_total_results(root: et.Element) -> int:
    node = root.find("opensearch:totalResults", NAMESPACES)
    if node is None or node.text is None:
        return 0
    try:
        return int(node.text)
    except ValueError:
        return 0


def parse_entry(
    node: et.Element,
    *,
    include_bibtex: bool,
    max_abstract_chars: int,
) -> dict[str, object]:
    paper_url = text_or_empty(node.find("atom:id", NAMESPACES))
    arxiv_id = paper_url.rsplit("/", maxsplit=1)[-1] if paper_url else ""

    title = collapse_whitespace(text_or_empty(node.find("atom:title", NAMESPACES)))
    summary = truncate_text(
        collapse_whitespace(text_or_empty(node.find("atom:summary", NAMESPACES))),
        max_chars=max_abstract_chars,
    )

    authors = [
        collapse_whitespace(text_or_empty(author.find("atom:name", NAMESPACES)))
        for author in node.findall("atom:author", NAMESPACES)
    ]

    categories = [
        category.attrib.get("term", "")
        for category in node.findall("atom:category", NAMESPACES)
        if category.attrib.get("term")
    ]

    primary_category = parse_primary_category(node, categories)
    published_raw = text_or_empty(node.find("atom:published", NAMESPACES))
    updated_raw = text_or_empty(node.find("atom:updated", NAMESPACES))
    published = parse_timestamp(published_raw)
    updated = parse_timestamp(updated_raw)

    entry: dict[str, object] = {
        "arxiv_id": arxiv_id,
        "title": title,
        "summary": summary,
        "authors": authors,
        "categories": categories,
        "primary_category": primary_category,
        "published": published,
        "updated": updated,
        "published_raw": published_raw,
        "updated_raw": updated_raw,
        "paper_url": paper_url,
        "pdf_url": find_pdf_url(node),
        "doi": parse_arxiv_text(node, "arxiv:doi"),
        "journal_ref": parse_arxiv_text(node, "arxiv:journal_ref"),
        "comment": parse_arxiv_text(node, "arxiv:comment"),
    }

    if include_bibtex:
        entry["bibtex"] = build_bibtex(entry)

    return entry


def dedupe_entries_by_title(
    entries: list[dict[str, object]],
) -> tuple[list[dict[str, object]], int]:
    deduped: list[dict[str, object]] = []
    seen_titles: set[str] = set()
    dropped = 0

    for entry in entries:
        normalized = normalize_title(str(entry.get("title", "")))
        if normalized and normalized in seen_titles:
            dropped += 1
            continue
        if normalized:
            seen_titles.add(normalized)
        deduped.append(entry)

    return deduped, dropped


def truncate_text(value: str, *, max_chars: int) -> str:
    if max_chars <= 0 or len(value) <= max_chars:
        return value
    if max_chars <= 3:
        return value[:max_chars]
    return value[: max_chars - 3].rstrip() + "..."


def parse_arxiv_text(node: et.Element, path: str) -> str:
    return collapse_whitespace(text_or_empty(node.find(path, NAMESPACES)))


def normalize_title(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def text_or_empty(node: et.Element | None) -> str:
    return (node.text or "").strip() if node is not None else ""


def collapse_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def parse_primary_category(node: et.Element, categories: list[str]) -> str:
    primary = node.find("arxiv:primary_category", NAMESPACES)
    if primary is not None:
        term = primary.attrib.get("term")
        if term:
            return term
    return categories[0] if categories else ""


def parse_timestamp(value: str) -> str:
    if not value:
        return ""
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return value
    return parsed.date().isoformat()


def matches_date_filter(
    *,
    published: object,
    from_date: dt.date | None,
    to_date: dt.date | None,
) -> bool:
    if not from_date and not to_date:
        return True
    if not isinstance(published, str) or not published:
        return False
    try:
        published_date = dt.date.fromisoformat(published)
    except ValueError:
        return False
    if from_date and published_date < from_date:
        return False
    if to_date and published_date > to_date:
        return False
    return True


def find_pdf_url(node: et.Element) -> str:
    for link in node.findall("atom:link", NAMESPACES):
        title = link.attrib.get("title", "")
        href = link.attrib.get("href", "")
        if title == "pdf" and href:
            return href
    return ""


def build_bibtex(entry: dict[str, object]) -> str:
    arxiv_id = str(entry.get("arxiv_id", "unknown"))
    key = "arxiv-" + re.sub(r"[^a-zA-Z0-9]+", "-", arxiv_id).strip("-")
    authors = entry.get("authors", [])
    author_text = " and ".join(authors) if isinstance(authors, list) else ""
    title = str(entry.get("title", "")).replace("{", "\\{").replace("}", "\\}")
    year = str(entry.get("published", ""))[:4]
    paper_url = str(entry.get("paper_url", ""))
    doi = str(entry.get("doi", ""))
    doi_line = f"  doi={{ {doi} }},\n" if doi else ""
    return (
        f"@article{{{key},\n"
        f"  title={{ {title} }},\n"
        f"  author={{ {author_text} }},\n"
        f"  journal={{arXiv preprint arXiv:{arxiv_id}}},\n"
        f"  year={{ {year} }},\n"
        f"{doi_line}"
        f"  url={{ {paper_url} }}\n"
        "}"
    )


def format_text_output(
    *,
    result: dict[str, object],
    include_abstract: bool,
) -> str:
    lines: list[str] = []
    query = result.get("query", "")
    total = result.get("total_results", 0)
    fetched = result.get("fetched_results", 0)
    date_filtered = result.get("date_filtered_results", 0)
    returned = result.get("returned_results", 0)

    lines.append(f"Query: {query}")
    lines.append(f"API total results: {total}")
    lines.append(f"Fetched results: {fetched}")
    lines.append(f"Date-filtered results: {date_filtered}")
    lines.append(f"Returned results: {returned}")

    date_window = result.get("date_window")
    if isinstance(date_window, dict):
        lines.append(
            f"Date window: {json.dumps(date_window, ensure_ascii=False)}",
        )

    dropped = result.get("dropped_results")
    if isinstance(dropped, dict):
        lines.append(f"Dropped results: {json.dumps(dropped, ensure_ascii=False)}")

    lines.append("")

    entries = result.get("entries", [])
    if not isinstance(entries, list) or not entries:
        lines.append("No matching papers found.")
        return "\n".join(lines)

    for index, paper in enumerate(entries, start=1):
        if not isinstance(paper, dict):
            continue
        lines.append(f"[{index}] {paper.get('title', '')}")
        lines.append(f"  Authors: {', '.join(paper.get('authors', []))}")
        lines.append(f"  Category: {paper.get('primary_category', '')}")
        lines.append(f"  Published: {paper.get('published', '')}")
        lines.append(f"  Updated: {paper.get('updated', '')}")
        lines.append(f"  URL: {paper.get('paper_url', '')}")

        pdf = paper.get("pdf_url", "")
        if pdf:
            lines.append(f"  PDF: {pdf}")

        doi = paper.get("doi", "")
        if doi:
            lines.append(f"  DOI: {doi}")

        journal_ref = paper.get("journal_ref", "")
        if journal_ref:
            lines.append(f"  Journal Ref: {journal_ref}")

        comment = paper.get("comment", "")
        if comment:
            lines.append(f"  Comment: {comment}")

        if include_abstract:
            lines.append(f"  Abstract: {paper.get('summary', '')}")

        bibtex = paper.get("bibtex", "")
        if bibtex:
            lines.append("  BibTeX:")
            lines.extend(f"    {line}" for line in str(bibtex).splitlines())

        lines.append("")

    return "\n".join(lines).strip()


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run_search(args)
    except ArxivSearchError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(
            format_text_output(
                result=result,
                include_abstract=args.include_abstract,
            ),
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
