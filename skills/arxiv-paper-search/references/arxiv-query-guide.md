# ArXiv Query Guide

## Operational Notes

- Prefer `--days N` for rolling windows when users ask for "latest" papers.
- Prefer `--from-date` and `--to-date` when date ranges are explicit.
- Use `--json` for downstream ranking, table generation, or deduplicated
  summaries.
- Use `--dedupe-by-title` to reduce duplicate title variants in larger pulls.

## Query Fields

Use these field keys inside `search_query` expressions:

- `all`: Search title, abstract, and metadata together.
- `ti`: Search title only.
- `au`: Search author names.
- `abs`: Search abstract text.
- `cat`: Filter by arXiv category.

Combine clauses with `AND`, `OR`, and `ANDNOT`.
Use double quotes for phrases, for example `all:"graph neural network"`.

## Script Argument Mapping

- `--query`: Converts to `all:"..."`.
- `--title`: Converts to `ti:"..."`.
- `--author`: Adds `au:"..."` for each value.
- `--category`: Adds `cat:<value>` for each value.
- `--raw-query`: Sends the provided query string without modification.

If multiple filters are provided, the script joins them with `AND`.

## Query Patterns

- Topic survey: `--query "<topic>" --days 90 --sort-by submittedDate`
- Author watchlist: `--author "<name>" --days 30`
- Category watchlist: `--category cs.CL --days 14`
- Precision query: `--raw-query 'cat:cs.CL AND ti:"korean" AND abs:"morphology"'`

## Common Categories

- `cs.AI`: Artificial Intelligence
- `cs.CL`: Computation and Language
- `cs.CV`: Computer Vision and Pattern Recognition
- `cs.IR`: Information Retrieval
- `cs.LG`: Machine Learning
- `cs.NE`: Neural and Evolutionary Computing
- `cs.RO`: Robotics
- `stat.ML`: Machine Learning (Statistics)

## Sorting Options

ArXiv API supports:

- `relevance`
- `submittedDate`
- `lastUpdatedDate`

Use `--sort-order ascending` or `--sort-order descending`.

## Date Filtering

Date filtering is applied after arXiv API fetch, using each entry's
`published` date (`YYYY-MM-DD`).

When users ask relative dates, convert to exact ranges in your response:

- `today`: exact current date (e.g., `2026-02-17`).
- `this week`: week start date to today.
- `last N days`: `--days N` (inclusive of today).
- `this year`: `YYYY-01-01` to current date.

## Output Fields

Each entry can include:

- `arxiv_id`, `title`, `summary`, `authors`
- `primary_category`, `categories`
- `published`, `updated`
- `paper_url`, `pdf_url`
- `doi`, `journal_ref`, `comment`
- `bibtex` (when `--include-bibtex` is enabled)
