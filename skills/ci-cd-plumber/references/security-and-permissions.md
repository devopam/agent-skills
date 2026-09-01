# Security & Permissions

How the pipeline authenticates, what identity it runs as, and whether
untrusted code can reach secrets or write access. This is the highest-impact
domain in `ci-cd-plumber`: a structurally beautiful pipeline that runs with
broad write tokens and unpinned actions is still a liability.

Sibling domains own adjacent territory:

- [Supply chain & reproducibility](supply-chain-and-reproducibility.md) —
  pinning digests, SBOM, provenance/attestations, lockfiles.
- [Pipeline structure](pipeline-structure.md) — which jobs exist and in what
  order; this file owns *who those jobs run as*.

## Table of Contents

- [Review mindset](#review-mindset)
- [Permissions: least privilege](#permissions-least-privilege)
- [Triggers and untrusted code](#triggers-and-untrusted-code)
- [Secrets handling](#secrets-handling)
- [OIDC and cloud identity](#oidc-and-cloud-identity)
- [Runners](#runners)
- [Script injection and untrusted input](#script-injection-and-untrusted-input)
- [Maturity expectations](#maturity-expectations)
- [Concrete checks](#concrete-checks)
- [Common anti-patterns](#common-anti-patterns)
- [Sources](#sources)

---

## Review mindset

For every workflow/job, answer:

1. **What identity does this job hold?** (GITHUB_TOKEN scopes, cloud role, registry creds)
2. **Who can trigger it?** (fork PR, internal PR, workflow_dispatch, schedule)
3. **Does any step execute code from an untrusted ref while secrets are present?**
4. **Are third-party actions/images immutable and reviewed?**
5. **Would a compromised action or dependency be able to push code, mint releases, or exfiltrate secrets?**

If any answer is uncomfortable, that is a finding — not a style note.

---

## Permissions: least privilege

### GitHub Actions

Set a **workflow-level floor** of read-only (or narrower), then grant write
scopes only on the jobs that need them:

```yaml
permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps: [...]

  release:
    needs: test
    permissions:
      contents: write
      id-token: write   # only if OIDC / attestations needed
    steps: [...]
```

Rules of thumb:

- Prefer `permissions:` at workflow top over relying on repo/org defaults
  (defaults still vary across older repos).
- Never grant `write-all` or broad `contents: write` at workflow level "for
  convenience."
- Jobs that only build/test often need nothing beyond `contents: read`
  (and sometimes not even that on public repos with anonymous checkout).
- `id-token: write` only on jobs that perform OIDC federation or
  attestations.
- `packages: write`, `pages: write`, `pull-requests: write`, etc. only on
  the specific job that needs them.

### GitLab CI

- Prefer job-level or masked/protected variables over project-wide secrets
  visible to every pipeline.
- Use protected branches/tags so production credentials are not available
  to feature-branch pipelines.
- Restrict who can run pipelines on protected refs; separate "push code"
  from "deploy with prod credentials" where the product allows it.

---

## Triggers and untrusted code

### The classic failure: `pull_request_target` + untrusted checkout

`pull_request_target` runs in the context of the **base** repository and
can access secrets. If the workflow then checks out and executes code from
the PR head (the fork), an attacker-controlled PR can read those secrets.

**Default stance for this skill:**

- Prefer `pull_request` for CI on external contributions.
- If `pull_request_target` is required (e.g. labeling, safe metadata-only
  automation), **do not** check out and run untrusted workflow code or
  build scripts from the head ref.
- Treat any `pull_request_target` workflow that runs `npm install` /
  `pip install` / build steps on PR head code as **Critical** until proven
  otherwise.

### Other trigger hygiene

- Limit `workflow_dispatch` on sensitive deploy/release workflows to
  trusted roles where the platform supports it.
- Be cautious with `workflow_run` chaining that elevates privileges from a
  low-trust workflow into a high-trust one.
- Schedule (`cron`) workflows should not carry broader credentials than
  their job requires.

---

## Secrets handling

- Prefer **OIDC / workload identity** over long-lived cloud keys stored as
  repository secrets.
- Long-lived secrets that remain should be: masked, protected (branch/tag
  restricted where available), rotated, and scoped to the minimum job set.
- Never echo secrets into logs; avoid passing them on process command lines
  when env vars or files are an option.
- Do not store production credentials in variables available to
  unprotected feature branches.
- Rotate any secret that may have appeared in logs or PR output.

---

## OIDC and cloud identity

Modern default for AWS, GCP, Azure, and many package registries:

1. Job requests a short-lived OIDC token (`id-token: write` on GitHub).
2. Cloud role trust policy restricts `sub` / `aud` to the specific repo,
   environment, and optionally workflow ref.
3. No static access key in GitHub/GitLab secrets.

Audit checks:

- Is OIDC used for cloud deploy/publish jobs?
- Is the trust policy tight (repo + environment), or does any workflow in
  the org assume the role?
- Are static keys still present "as backup"? (Usually a finding.)

---

## Runners

- Prefer **ephemeral** hosted runners for untrusted or open-source PR
  traffic.
- Self-hosted runners that are shared, persistent, or over-privileged are
  a standing risk — especially if labels allow pull_request jobs from forks
  onto them.
- Harden-runner / egress controls are worth recommending at standard and
  high-assurance maturity; not mandatory for pure prototype private repos.

---

## Script injection and untrusted input

GitHub Actions expression contexts (`github.event.issue.title`, PR titles,
branch names, etc.) can carry attacker-controlled strings.

- Do **not** interpolate untrusted values directly into `run:` scripts.
- Pass them via `env:` and reference as shell variables, or use dedicated
  actions that treat inputs as data.
- Same idea applies to GitLab CI variables derived from MR titles/descriptions.

---

## Maturity expectations

| Control | Prototype | Standard service | High-assurance |
|---|---|---|---|
| Workflow-level least-privilege permissions | Recommended | Required | Required |
| No unsafe `pull_request_target` + untrusted code | Required | Required | Required |
| OIDC instead of static cloud keys | Nice | Required for cloud deploy | Required |
| Protected/prod secrets only on protected refs | Recommended | Required | Required |
| Egress / runner hardening | Optional | Recommended | Required |
| Central trigger policies (org/enterprise) | Optional | Recommended | Required |

---

## Concrete checks

When auditing, look for:

1. Missing top-level `permissions:` (or equivalent) on GitHub workflows.
2. `contents: write` (or broader) at workflow level without justification.
3. `pull_request_target` workflows that check out PR head and run build/test.
4. `uses: some/action@v4` style tags without SHA pin (detail in supply-chain domain; still flag here when the action has write permissions available).
5. Static `AWS_ACCESS_KEY_ID` / similar where OIDC is feasible.
6. Secrets used in jobs triggered by fork PRs.
7. `run:` lines embedding `${{ github.event... }}` untrusted fields.
8. Self-hosted runners accepting jobs from untrusted events.

---

## Common anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Workflow `permissions: write-all` | Any compromised step can push code, create releases, or change settings |
| One deploy job with every secret in the environment | Lateral movement after a single step compromise |
| "We'll pin actions later" | Tag-moving attacks are routine; later often means never |
| Using `pull_request_target` because "we need secrets to comment" | Usually solvable with a safer split workflow or `pull_request` + limited bot token |
| Long-lived PATs in secrets for push-back to the repo | Prefer `GITHUB_TOKEN` with tight permissions or a fine-scoped bot identity |

---

## Sources

- GitHub Docs — Secure use of GitHub Actions; permissions for the
  `GITHUB_TOKEN`; OIDC with cloud providers. Practices current as of 2026.
- GitHub Blog — Actions security roadmap 2026 (trigger policies, safer
  defaults around `pull_request_target` and cache poisoning).
- Community hardening guides (StepSecurity, safeguard.sh, CNCF-oriented
  recipe cards) — SHA pinning + least privilege + OIDC as the recurring
  triad.
- GitLab Docs — protected variables, pipeline security, protected branches.

Retrieved and synthesized for this skill 2026-09-01. Prefer primary vendor
docs when a detail conflicts with a secondary blog post.
