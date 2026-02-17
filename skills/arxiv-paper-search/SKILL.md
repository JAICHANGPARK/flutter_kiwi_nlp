---
name: arxiv-paper-search
description: Search arXiv papers by keyword, author, category, and date, then
  return ranked results with links, abstracts, and citation metadata. Use when
  a user asks for arXiv paper discovery, "latest papers", topic surveys, or
  Korean prompts such as "arxiv 논문 검색", "최신 arxiv 논문", and "arxiv 추천".
---

# ArXiv Paper Search

## Overview

Find and filter arXiv papers quickly with reproducible API queries.
Use this skill whenever fresh arXiv metadata is required.

## Workflow

1. Capture intent.
- Extract topic keywords, desired date range, categories, and result count.
- If ambiguous, default to the latest 10 papers and note the assumption.

2. Build a structured query.
- Prefer `--query`, `--author`, and `--category`.
- Use `--raw-query` only when exact arXiv syntax is needed.
- See `references/arxiv-query-guide.md` for syntax details.

3. Run the search script.
- Execute `python3 skills/arxiv-paper-search/scripts/search_arxiv.py`.
- Add `--from-date` and `--to-date` for time-bounded results.
- Add `--json` when another step needs machine-readable output.

4. Summarize output for the user.
- Report title, authors, published date, category, and URL.
- If requested, include `--include-abstract` and `--include-bibtex`.

5. Handle errors explicitly.
- If API calls fail, report the exact error and retry guidance.
- Never fabricate papers or metadata.

## Commands

```bash
# Latest papers by topic
python3 skills/arxiv-paper-search/scripts/search_arxiv.py \
  --query "vision-language model" \
  --sort-by submittedDate \
  --max-results 5

# Category + date filter + BibTeX
python3 skills/arxiv-paper-search/scripts/search_arxiv.py \
  --category cs.LG \
  --from-date 2025-01-01 \
  --to-date 2025-12-31 \
  --max-results 10 \
  --include-bibtex
```

## Resources

- Search tool: `scripts/search_arxiv.py`
- Query and category reference: `references/arxiv-query-guide.md`
