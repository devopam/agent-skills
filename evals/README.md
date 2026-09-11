# agent-skills evals

Hand-authored eval cases for skills in this repo, one subdirectory per
skill (`evals/<skill-name>/<case-name>/`).

Each case: `prompt.md` + `graders/criteria.md`.

## Inventory

| Skill | Cases | Focus |
|---|---:|---|
| `project-incubation` | 17 | Category retrieval, gaps, license/ADR, handoff to ci-cd-plumber |
| `python-code-review` | 13 | Domain detection, mechanisms, scorecard verdict, tier gating |
| `ci-cd-plumber` | 8 | Inception (GHA + GitLab), audit, scorecard, baseline, progressive N/A |
| `pr-review` | 7 | Pre-submit hooks, tests, changelog, secrets, blast radius |
| `postgresql-review` | 6 | MCPg readiness, degraded mode, scorecard, Critical/Not Implemented |
| `ui-system-review` | 10 | Web drift + Apple/Android packs, remediation, evidence, no-UI |

**Total:** 61 hand-authored cases.

## Known limitation

Cases are hand-authored; machine scoring needs `claude plugin eval` early
access. From repo root when available:

```bash
claude plugin eval . --ablation with-without --runs 1 --no-publish
# --case 'ui-system-review/*'
```
