# Release notes — agent-skills v0.18.0

**Date:** 2026-10-08

## Highlights

- `claude plugin eval .` now loads and runs the whole suite (149 cases). The original failure was `invalid case.yaml: graders: Required`, caused by grader files with no `type`/`weight` front matter.
- 65 flat eval files were converted to the directory layout the runner discovers.
- Evals gained skill-fired checks, scaffolded fixtures, embedded target code, and unique case names.
- Several skill descriptions and two skill behaviors were tightened based on eval findings.

## Running the evals

```
claude plugin eval . --scaffold --runs 3 --max-cost-usd <cap>
```

`--scaffold` runs each case's `fixture.sh`; only use it on suites you authored. Use `--case '<skill>-*'` to filter.

## Known limits

- Single-run judge results are noisy; use `--runs 3` before treating a failure as real.
- About nine cases are flaky and `pr-review-merge-ready-clean` does not reliably invoke its skill.
- A final full-suite pass after the last changes was not run.

## Upgrade

Install/update from this repo tag `v0.18.0` or `main`. Point agents at `skills/<name>/`.
