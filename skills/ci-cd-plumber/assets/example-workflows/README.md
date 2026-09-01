# Example workflows

Illustrative, opinionated starters that embody the defaults in
`references/platforms/` and the domain references. They are **not**
drop-in production configs — treat them as reviewable patterns the skill
may adapt during Inception mode.

| File | Platform | Intent |
|---|---|---|
| `github-actions-ci.yml` | GitHub Actions | PR + main validation (lint/test) with least privilege and SHA pins |
| `github-actions-release.yml` | GitHub Actions | release-please driven release workflow |
| `gitlab-ci.yml` | GitLab CI | stages for validate / test / build with rules and caching |

## Pinning note

SHAs and version comments in the examples are snapshots from research
time (2026-09). Always re-resolve current release SHAs before using in a
real repo (e.g. `git ls-remote` or `pinact` / Dependabot). The skill's
security references require full-length commit SHAs, not floating tags.
