# agent-skills evals

Hand-authored eval cases for skills in this repo, one subdirectory per
skill (`evals/<skill-name>/<case-name>/`).

Each case: `prompt.md` + `graders/criteria.md`.

## Inventory

| Skill | Cases (approx.) | Focus |
|---|---:|---|
| `project-incubation` | 16 | Category retrieval, gaps, handoff to ci-cd-plumber |
| `python-code-review` | 11 | Domain detection, mechanisms, scorecard verdict |
| `ci-cd-plumber` | 6 | Inception, audit, scorecard, baseline close-out |
| `pr-review` | 5 | Pre-submit hooks, tests, changelog, secrets |
| `postgresql-review` | 4 | MCPg readiness, wrong schema, scorecard shape, no-apply DDL |

## Known limitation

Cases are hand-authored; machine scoring needs `claude plugin eval` early
access. From repo root when available:

```bash
claude plugin eval . --ablation with-without --runs 1 --no-publish
# --case 'postgresql-review/*'
```
