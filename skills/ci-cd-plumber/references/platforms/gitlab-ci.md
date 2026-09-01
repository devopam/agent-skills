# Platform: GitLab CI

Concrete patterns for `.gitlab-ci.yml` (and CI/CD components) on GitLab.
General principles remain in the parent domain references.

## Table of Contents

- [Recommended layout](#recommended-layout)
- [Stages](#stages)
- [Rules and trust](#rules-and-trust)
- [Variables and secrets](#variables-and-secrets)
- [Caching](#caching)
- [Pinning images and includes](#pinning-images-and-includes)
- [Environments and deployments](#environments-and-deployments)
- [Release notes](#release-notes)
- [Hygiene defaults](#hygiene-defaults)
- [Sources](#sources)

---

## Recommended layout

Single `.gitlab-ci.yml` with clear `stages`, or a root file that `include:`s
local `/ci/*.yml` fragments for readability. Prefer GitLab CI/CD components
or versioned includes over copy-paste across projects.

---

## Stages

Example stage ordering:

```yaml
stages:
  - validate
  - test
  - build
  - deploy
```

Map `validate`/`test` to PR/MR pipelines; restrict `deploy` jobs with rules
so they do not run on every feature branch.

---

## Rules and trust

- Use `rules:` (not legacy only/except) for MR vs branch vs tag pipelines.
- Avoid duplicate pipelines (MR pipeline + branch pipeline) unless
  intentional — workflow rules can suppress doubles.
- Protected branches/tags for production deploy jobs.
- Merge request pipelines should not access protected production variables.

---

## Variables and secrets

- Mask + protect sensitive variables.
- Prefer external secret stores / OIDC-style federation where available over
  long-lived file variables.
- Scope variables to environments when using GitLab Environments.

---

## Caching

```yaml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - .npm/
```

Respect protected-branch cache separation; do not casually disable it.
Use `interruptible: true` on high-churn MR jobs.

---

## Pinning images and includes

- Job `image:` digests where practical.
- Version pins on `include:` components/templates.
- Avoid `image: node:latest`.

---

## Environments and deployments

Declare `environment:` on deploy jobs for deployment history and stop jobs.
Use protected environments for production.

---

## Release notes

- GitLab Releases can be created from CI on tags.
- Changelog: keep `CHANGELOG.md` in-repo; generation via conventional
  commits tooling or release-cli patterns.
- Cross-link pipeline job that publishes with the Release asset list.

---

## Hygiene defaults

Consider applying (when not already present):

- `default: interruptible: true` for MR-heavy projects
- Reasonable `timeout:` per job
- `retry:` only for runner_system_failure / stuck_or_timeout_failure classes
- `artifacts:expire_in` for non-release artifacts

---

## Sources

- GitLab Docs: `rules`, caching, protected variables, pipeline security,
  environments, CI/CD components.
- GitLab CI best-practice codemods/recipes (workflow rules, interruptible,
  timeouts).

Synthesized 2026-09-01.
