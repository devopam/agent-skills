# agent-skills evals

Hand-authored eval cases for skills in this repo, one subdirectory per
skill (`evals/<skill-name>/<case-name>/`) since a single `.claude-plugin/plugin.json`
manifest covers the whole repo and `claude plugin eval` scans its eval
directory recursively.

Each case is a directory with `prompt.md` (the scenario) and
`graders/criteria.md` (what a pass looks like) — the `prompt.md` +
`graders/*.md` shape `claude plugin eval` documents as one of its two
supported case formats.

## Inventory

| Skill | Cases (approx.) | Focus |
|---|---:|---|
| `project-incubation` | 16 | Category retrieval, multi-category/monorepo gaps, baseline absence/stale audit, handoff to ci-cd-plumber |
| `python-code-review` | 11 | Domain detection (planted issues), tier/diff/absence mechanics, overall scorecard verdict |
| `ci-cd-plumber` | 6 | Inception, unpinned actions audit, release docs, scorecard shape, baseline close-out, progressive-delivery N/A for libraries |
| `pr-review` | 5 | Pre-submit hooks, missing tests, changelog gaps, clean Ready path, secrets in diff |

- **`project-incubation/`** — retrieval scenarios per stack category and
  cross-cutting utilities, plus gap scenarios (secondary category,
  monorepo coequal packages, no baseline, stale baseline, **handoff to
  ci-cd-plumber**).
- **`python-code-review/`** — detection + mechanism scenarios, plus
  **overall scorecard/verdict** shape.
- **`ci-cd-plumber/`** — inception/audit/release-docs, plus **scorecard
  report shape**, **baseline close-out**, and **progressive delivery N/A**
  for pure libraries.
- **`pr-review/`** — pre-submit gates, tests, changelog, clean Ready,
  secret-in-diff.

## Known limitation: not run in this environment

`claude plugin eval` requires early-access enrollment that may not be
available on every account (`claude plugin eval init` can return
`"plugin eval" is currently in early access`). These cases are
hand-authored against the documented format and the actual skill content,
but **have not been machine-scored** until a real run is performed.

Once eval access is available, run from the repo root:

```bash
claude plugin eval . --ablation with-without --runs 3 --no-publish
```

`--ablation with-without` reports the score delta against a no-plugin
baseline. `--no-publish` keeps the report local — never publish without
explicit sign-off (publishing sends results to claude.ai). Iterate with
`--runs 1` and `--case <glob>` to target one case (or
`--case 'project-incubation/*'` / `--case 'pr-review/*'`) while tuning.
