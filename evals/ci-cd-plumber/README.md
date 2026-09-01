# Evals: ci-cd-plumber

Eval cases for the `ci-cd-plumber` skill. Format matches the repo-wide
convention under `evals/` (prompt.md + graders/criteria.md).

These are hand-authored scaffolding for v0; they have not been executed
via `claude plugin eval` (same early-access constraint noted for other
skills). Expand after the first live smoke test on real repositories.

## Cases

| Case | Intent |
|---|---|
| `inception-github-actions-python` | Green-field inception for a Python + GitHub Actions service |
| `audit-unpinned-actions` | Detect missing SHA pins and overly broad permissions |
| `release-docs-keep-a-changelog` | Check / offer generation of Keep a Changelog structure |
