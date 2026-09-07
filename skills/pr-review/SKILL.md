---
name: pr-review
description: Reviews a local change set or open PR for pre-submit readiness — local quality gates (hooks, lint, tests), intent and blast radius, test coverage for the change, docs/changelog hygiene, CI readiness, and diff-scoped security footguns — producing a merge-readiness report. Use before opening or updating a PR, when reviewing someone else's PR, or when you want to catch rework triggers before CI does.
---

# PR Review

Catches the problems that cause **review and CI rework** before the change
leaves the machine (or before you approve someone else's PR). Language-agnostic
at the change level: it cares about gates, risk, tests, and hygiene — not a
full language scorecard.

For deep Python domain review (security patterns, async correctness, scoring
across 11 domains), hand off to or combine with `python-code-review`. This
skill does not replace that depth.

Two modes, detected from the request and repo state:

- **Pre-submit** — user is about to push / open a PR; emphasize local hooks
  and "would CI pass?"
- **PR review** — an existing branch or PR is in scope; emphasize diff risk,
  missing tests, and reviewer-facing clarity.

Ask questions in plain text, one at a time. Do not assume host-specific UI.

## Scope discovery

1. Identify the **change set**:
   - Prefer `git diff <base>...HEAD` (default base `main`, or the repo's
     default branch / user's stated base).
   - If the user names a PR number or branch, use that.
   - If only a pasted diff is provided, review that and note limits
     (no hook discovery against a live tree).
2. List **changed paths** and group roughly: code, tests, config/CI, docs.
3. Discover **local quality gates** (read configs; do not invent tools):
   - `.pre-commit-config.yaml` / `.pre-commit-config.yml`
   - `Makefile` / `justfile` targets commonly used as gates (`lint`, `test`,
     `check`, `ci`)
   - `package.json` scripts, `pyproject.toml` tool tables, `tox.ini`, etc.
   - CI workflow files only to know **what will run remotely** (do not
     re-audit the whole pipeline — that is `ci-cd-plumber`).
4. Ask only what the request leaves open: base branch, whether hooks were
   already run, and whether the change is meant to be user-facing
   (changelog/docs expectations).

## Review domains (in order)

Read the linked reference before scoring each domain.

1. [Intent & blast radius](references/change-risk-and-tests.md) — Is the
   change coherent? What can break? Risky areas (auth, migrations, public
   API, release paths)?
2. [Pre-submit / local quality gates](references/pre-submit-gates.md) —
   Hooks and local checks exist; were they run; would they pass; gap vs CI.
3. [Tests for this change](references/change-risk-and-tests.md) — New or
   updated tests proportional to risk; obvious untested paths.
4. [Docs & changelog hygiene](references/pr-hygiene.md) — User-facing or
   operator-facing changes reflected; PR description quality if reviewing
   a PR.
5. [CI readiness](references/pre-submit-gates.md) — Likely remote failures
   (format, typecheck, required checks) visible from the diff + configs.
6. [Diff-scoped security footguns](references/change-risk-and-tests.md) —
   Secrets in the diff, unsafe defaults introduced by this change only —
   not a full security audit.

## Severity

| Level | Meaning |
|---|---|
| Critical | Secret in diff, data-loss risk, broken auth/migration path, or required gates clearly failing |
| Important | Missing tests for non-trivial logic, hooks not run / would fail, user-facing change without docs/changelog when the repo uses them |
| Minor | PR description polish, optional checklist items, small hygiene |
| Not Implemented | A recommended gate for this repo (e.g. pre-commit present in docs but config missing) is simply absent |

## Verdict

- **Ready** — no Critical/Important findings; safe to open or approve pending human judgment.
- **Ready with nits** — only Minor / explicit Not Implemented items.
- **Not ready** — any Critical or Important finding; fix or consciously waive before submit/approve.

Offer fixes **individually**. Prefer running or telling the user the exact
local commands (`pre-commit run`, `make lint`, etc.) over rewriting large
swaths of code unasked.

## Output (required)

1. **Header** — mode (pre-submit / PR review), base..HEAD summary, verdict.
2. **Change summary** — short intent restatement + risk hotspots.
3. **Gate status table** — Gate | Detected | Run/status | Notes.
4. **Findings by severity** — Critical → Important → Minor → Not Implemented.
5. **Suggested next actions** — ordered list to reach Ready.
6. Optional file from [`assets/report-template.md`](assets/report-template.md)
   if the user wants a saved report.

## Boundaries

- Does **not** own full CI/CD design (`ci-cd-plumber`).
- Does **not** own full Python domain scoring (`python-code-review`).
- Does **not** merge or approve on the user's behalf.
- Does **not** skip local gate discovery when a real checkout is available.

## Reference files

| File | Covers |
|---|---|
| [`references/pre-submit-gates.md`](references/pre-submit-gates.md) | pre-commit, make/npm scripts, CI parity |
| [`references/change-risk-and-tests.md`](references/change-risk-and-tests.md) | blast radius, tests, diff security |
| [`references/pr-hygiene.md`](references/pr-hygiene.md) | description, changelog, checklist |
| [`assets/report-template.md`](assets/report-template.md) | optional saved report shape |
