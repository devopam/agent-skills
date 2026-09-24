# agent-skills evals

Hand-authored eval cases for skills in this repo.

## Inventory (approximate on main)

| Skill | Cases (order of magnitude) |
|---|---:|
| `project-incubation` | ~17 |
| `python-code-review` | ~13 |
| `typescript-code-review` | ~5 |
| `nodejs-code-review` | ~5 |
| `react-code-review` | ~6 |
| `ci-cd-plumber` | ~8 |
| `pr-review` | ~7 |
| `postgresql-review` | ~6 |
| `ui-system-review` | ~11 |
| `regulatory-compliance-applicability-scan` | many (global packs + gates) |

Machine scoring needs `claude plugin eval` early access where available.

## New stack reviews (0.17.0)

- **typescript:** strict tsconfig, floating promises, lockfile, no-certify, sibling pointer
- **nodejs:** CORS/headers, SQL injection, sync fs, graceful shutdown, missing tests
- **react:** XSS innerHTML, exhaustive-deps, error boundaries, stale fetch, client secrets, ui-system boundary
