# Release notes — agent-skills v0.17.0

**Date:** 2026-09-24

## Highlights

Three new **11-domain** code-review skills, parallel to `python-code-review`:

| Skill | Focus |
|-------|--------|
| `typescript-code-review` | Language, tsconfig, packages, async, supply chain |
| `nodejs-code-review` | HTTP/services, event loop, ops resilience |
| `react-code-review` | Components, hooks, XSS, client perf/testing |

Each includes `SKILL.md`, config + report templates, domain reference files, and evals.

## Docs

- README skill table updated
- CHANGELOG **0.17.0**
- Plugin **0.17.0**
- evals README inventory

## Boundaries

- Reviews suggest scores and findings; they do **not** certify security or compliance.
- `react-code-review` pairs with `ui-system-review` for design-system depth.
- Domain refs are v0 baselines; further depth is backlog.

## Upgrade

Install/update from this repo tag `v0.17.0` or `main`. Point agents at `skills/<name>/`.
