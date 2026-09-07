# Evals: ci-cd-plumber

Eval cases for the `ci-cd-plumber` skill. Format matches the repo-wide
convention under `evals/` (prompt.md + graders/criteria.md).

Hand-authored; not executed via `claude plugin eval` until enrollment
allows (see repo `evals/README.md`).

## Cases

| Case | Intent |
|---|---|
| `inception-github-actions-python` | Green-field inception for a Python + GitHub Actions service |
| `audit-unpinned-actions` | Detect missing SHA pins and overly broad permissions |
| `release-docs-keep-a-changelog` | Check / offer generation of Keep a Changelog structure |
| `audit-scorecard-report-shape` | Require domain 0-10 table + severity ordering |
| `audit-baseline-close-out` | Last audited + Drift Log after audit without fixes |
| `progressive-delivery-na-library` | Do not mandate canary for pure library publish |
