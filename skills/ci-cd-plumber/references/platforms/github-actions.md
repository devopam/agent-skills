# Platform: GitHub Actions

Concrete patterns for repositories using GitHub Actions as the primary CI/CD
platform. General principles still come from the parent reference domains;
this file maps them onto Actions YAML and GitHub product features.

## Table of Contents

- [Recommended layout](#recommended-layout)
- [Permissions](#permissions)
- [Checkout and trust](#checkout-and-trust)
- [OIDC](#oidc)
- [Pinning](#pinning)
- [Environments and protection](#environments-and-protection)
- [Caching](#caching)
- [Release automation hooks](#release-automation-hooks)
- [Starter skeleton (illustrative)](#starter-skeleton-illustrative)
- [Sources](#sources)

---

## Recommended layout

```text
.github/workflows/
  ci.yml           # PR + main verification
  release.yml      # tag / release-please / publish
  # optional: codeql.yml, dependency-review.yml
```

Split when release permissions or triggers differ materially from PR CI.

---

## Permissions

```yaml
permissions:
  contents: read
```

at workflow top. Elevate per job:

```yaml
jobs:
  release:
    permissions:
      contents: write
      id-token: write
      packages: write  # if publishing to ghcr/npm with GITHUB_TOKEN
```

---

## Checkout and trust

- Default PR CI: `on: pull_request` (and `push` to main if desired).
- Avoid `pull_request_target` unless the workflow is strictly metadata-only
  or otherwise proven safe.
- `actions/checkout` should pin to SHA; `persist-credentials: false` when
  later steps should not push with the default token.

---

## OIDC

```yaml
permissions:
  id-token: write
  contents: read
```

Use cloud-provider official actions to assume roles; constrain role trust
to `repo:ORG/REPO:environment:prod` (or equivalent).

---

## Pinning

Pin every `uses:` to a full commit SHA with a version comment. Prefer
Dependabot `github-actions` ecosystem updates.

---

## Environments and protection

Use GitHub Environments (`environment: production`) for prod deploys:

- Required reviewers when human gates are needed.
- Environment secrets distinct from general repository secrets.
- Deployment branches restricted to main or tags.

---

## Caching

`actions/cache` with keys incorporating lockfile hashes. Be aware of cache
scope differences across PRs from forks vs same-repo branches.

---

## Release automation hooks

- **release-please**: workflow on push to main that creates/updates Release
  PR; merge emits tags/releases.
- **semantic-release**: job on main with permissions to push tags and create
  releases; needs careful permission scoping.
- Artifact attestations: `actions/attest-build-provenance` (or current
  equivalent) on built artifacts when publishing shared binaries/images.

---

## Starter skeleton (illustrative)

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>  # pin
      - name: Set up runtime
        run: echo "setup"
      - name: Install (frozen)
        run: echo "locked install"
      - name: Test
        run: echo "test"
```

Expand with real setup actions pinned by SHA; add a separate release
workflow rather than stuffing publish into PR jobs.

---

## Sources

- GitHub Docs: workflow syntax, permissions, OIDC, environments, security
  hardening for Actions.
- GitHub changelog 2026: trigger policies and supply-chain hardening.

Synthesized 2026-09-01.
