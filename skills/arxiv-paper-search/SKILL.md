---
name: arxiv-paper-search
description: Search arXiv papers by keyword, author, category, and date, then
  return ranked results with links, abstracts, and citation metadata. Use when
  a user asks for arXiv paper discovery, latest papers, related work curation,
  author/category monitoring, or Korean prompts such as "arxiv 논문 검색",
  "최신 arxiv 논문", "arxiv 추천", and "관련 연구 찾아줘".
---

# ArXiv Paper Search

Find and filter arXiv papers with reproducible API queries and explicit date
boundaries. Use this skill whenever fresh arXiv metadata is required.

## Workflow

1. Resolve the script path for cross-session use.
- Prefer `"$CODEX_HOME/skills/arxiv-paper-search/scripts/search_arxiv.py"`.
- Fallback to `skills/arxiv-paper-search/scripts/search_arxiv.py` for
  repository-local use.

2. Capture user intent.
- Extract topic keywords, date window, category/author filters, and result
  count (`N`).
- If `N` is not specified, default to 10 and explicitly report the assumption.
- Convert relative expressions ("today", "this week", "last 30 days") into
  exact calendar dates in the final response.

3. Build a structured query.
- Prefer `--query`, `--author`, and `--category`.
- Use `--raw-query` only for exact arXiv syntax.
- Use `--days N` for rolling windows, or `--from-date/--to-date` for fixed
  windows.
- See `references/arxiv-query-guide.md` for syntax patterns and categories.

4. Execute the script.
- Run with `--json` when the result will be post-processed.
- Add `--include-bibtex` when users need references.
- Use `--require-pdf`, `--dedupe-by-title`, and `--max-abstract-chars` when
  cleaning large result sets.

5. Summarize for the user.
- Report `title`, `authors`, `published date`, `primary category`, and `URL`.
- Mention selected filters, date window, and any dropped-result counts.
- Never fabricate papers, metadata, or citations.

6. Handle errors explicitly.
- If API calls fail, report exact stderr and retry guidance.
- If no results are found, suggest one or two query refinements.

## Commands

```bash
# Resolve a reusable path first (global skill install -> local fallback)
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills/arxiv-paper-search"
if [ ! -f "$SKILL_ROOT/scripts/search_arxiv.py" ]; then
  SKILL_ROOT="skills/arxiv-paper-search"
fi

# Latest papers by topic (machine-readable output)
N=20
python3 "$SKILL_ROOT/scripts/search_arxiv.py" \
  --query "vision-language model" \
  --sort-by submittedDate --sort-order descending \
  --days 30 \
  --max-results "$N" \
  --dedupe-by-title \
  --json

# Category + absolute date window + BibTeX
python3 "$SKILL_ROOT/scripts/search_arxiv.py" \
  --category cs.LG \
  --query "korean morphology" \
  --from-date 2025-01-01 \
  --to-date 2025-12-31 \
  --max-results 10 \
  --require-pdf \
  --max-abstract-chars 600 \
  --include-bibtex
```

## Table Output (Variable N)

Use the user-requested paper count directly via `--max-results N`.

```bash
N=12
python3 "$SKILL_ROOT/scripts/search_arxiv.py" \
  --query "korean morphological analyzer" \
  --category cs.CL \
  --days 365 \
  --sort-by submittedDate \
  --max-results "$N" \
  --dedupe-by-title \
  --json
```

When summarizing, provide a Markdown table with one row per returned entry:

```markdown
| # | Title | Authors | Published | Category | URL |
|---|---|---|---|---|---|
| 1 | ... | ... | 2026-02-17 | cs.CL | https://arxiv.org/abs/... |
```

## Resources

- Search tool: `scripts/search_arxiv.py`
- Query and category reference: `references/arxiv-query-guide.md`
