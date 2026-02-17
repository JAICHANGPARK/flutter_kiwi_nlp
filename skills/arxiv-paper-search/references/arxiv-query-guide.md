# ArXiv Query Guide

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

The script applies `--from-date` and `--to-date` after fetching entries.
Filtering is based on each entry's `published` date (`YYYY-MM-DD`).

When users ask for relative dates such as "today" or "this week", convert them
to exact date ranges in your response.
