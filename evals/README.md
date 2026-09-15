# agent-skills evals

Hand-authored eval cases for skills in this repo, one subdirectory per
skill (`evals/<skill-name>/<case-name>/`).

Each case: `prompt.md` + `graders/criteria.md`.

## Inventory

| Skill | Cases | Focus |
|---|---:|---|
| `project-incubation` | 17 | Category retrieval, gaps, license/ADR, handoff |
| `python-code-review` | 13 | Domains, scorecard, tier gating |
| `ci-cd-plumber` | 8 | Inception, audit, baseline |
| `pr-review` | 7 | Pre-submit, tests, secrets, blast radius |
| `postgresql-review` | 6 | MCPg readiness, scorecard |
| `ui-system-review` | 11 | Web/Apple/Android, remediation, fixture |
| `regulatory-compliance-applicability-scan` | 11 | Disclaimer, coverage, GDPR, overlays, domain gates, multi-jurisdiction |

**Total:** 73 hand-authored cases (62 at 0.14.0 + 11 regulatory on main).

## Known limitation

Machine scoring needs `claude plugin eval` early access.
