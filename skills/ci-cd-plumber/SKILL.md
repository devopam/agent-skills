---
name: ci-cd-plumber
description: Scaffolds production-grade CI/CD pipelines and audits existing ones for structure, security, speed, reproducibility, progressive delivery, and release documentation. Use when setting up CI/CD for a new project, hardening or reviewing an existing pipeline, improving release automation, or generating/checking changelogs and release notes.
---

# CI/CD Plumber

Keeps the delivery pipes flowing. Scaffolds a production-grade CI/CD
pipeline at project inception, and audits an existing pipeline against a
recorded baseline throughout its lifecycle. Strictly focused on CI/CD and
the release artifacts the pipeline produces — not application architecture,
infrastructure-as-code design, or app-level observability.

Two modes, detected automatically at the start of every invocation:
**Inception** (new/near-empty CI) and **Audit** (existing pipeline with or
without a baseline record).

Ask questions one at a time, in plain text. Do not assume any specific
interactive tool exists — this skill must behave identically on any
agentskills.io-compliant client.

This skill can be invoked standalone or handed off from
`project-incubation` (which scaffolds only a minimal CI stub). When a
`docs/project-incubation-baseline.md` is present, read it for language,
stack category, compliance signals, and monorepo shape — do not re-ask
what is already answered there unless the user wants to override.

## Detecting which mode applies

Check the repo for both of:

1. CI/CD config files (any of: `.github/workflows/*.yml`, `.gitlab-ci.yml`,
   `.circleci/config.yml`, `azure-pipelines.yml`, `Jenkinsfile`,
   `.buildkite/`, `tekton/`, or equivalent).
2. A baseline record at `docs/ci-cd-baseline.md`.

Decision:

- **Baseline exists** → go to [Audit mode](#audit-mode).
- **No baseline, and no (or only trivial scaffold) CI config** → go to
  [Inception mode](#inception-mode).
- **No baseline, but real CI config is present** → infer platform and
  current shape from the files, **confirm the inference with the user in
  plain text**, write the baseline record (Inception mode's
  [Phase 6](#phase-6-write-the-baseline-record)), then proceed to Audit
  mode using it.

## Inception mode

### Phase 1: Context gathering

Ask, one at a time (skip any answer already present in a
`docs/project-incubation-baseline.md`):

1. **Primary CI/CD platform** — GitHub Actions, GitLab CI, or other
   (name it). v0 has strong opinionated defaults for GitHub Actions and
   GitLab CI; other platforms are supported via extensible patterns in
   `references/platforms/`.
2. **Language / runtime and packaging** (e.g. Python + uv/poetry, Node +
   pnpm, Go modules, multi-language monorepo).
3. **Repo shape** — single deployable, or monorepo with multiple
   independently-deployable packages? (Reuse the same bar as
   project-incubation: "do these get deployed separately, on separate
   schedules?")
4. **Deployment target type** — container image, serverless function,
   static site, library/package only, VM/binary, or mixed.
5. **Maturity / risk posture** — prototype (lighter gates), standard
   service, or high-assurance / regulated (stricter supply-chain and
   approval expectations).
6. **Compliance or policy constraints** that affect the pipeline (e.g.
   required SAST, SBOM, signed artifacts, change-advisory board).
7. **Release documentation today** — do you already use Conventional
   Commits? Is there a `CHANGELOG.md`? Any existing release automation
   (release-please, semantic-release, manual GitHub Releases, etc.)?

### Phase 2: Pipeline structure recommendation

Read [`references/pipeline-structure.md`](references/pipeline-structure.md).

Recommend a layered pipeline:

- **PR / merge-request validation** — fast feedback (lint, unit tests,
  lightweight SAST/secret scan). Target: keep under a tight time budget.
- **Main / trunk pipeline** — full checks, build immutable artifact,
  generate SBOM / provenance where applicable.
- **Release / promotion** — version bump, changelog, publish artifact,
  optional progressive delivery hooks.

State the recommendation and the reasoning (platform, target type,
maturity). Record it for the baseline.

### Phase 3: Security & supply-chain defaults

Read:

- [`references/security-and-permissions.md`](references/security-and-permissions.md)
- [`references/supply-chain-and-reproducibility.md`](references/supply-chain-and-reproducibility.md)

Apply the skill's opinionated defaults for the chosen platform:

- Least-privilege permissions (e.g. `contents: read` at workflow level on
  GitHub Actions; write scopes only where needed).
- Pin third-party actions/images to full-length immutable digests (SHA),
  not floating tags.
- Prefer OIDC / workload identity over long-lived cloud or registry
  secrets.
- Avoid dangerous patterns (notably unsafe `pull_request_target` +
  untrusted checkout combinations).
- Generate SBOM; add SLSA-style provenance/attestations when the platform
  supports them with reasonable effort.
- Lockfile-based, reproducible installs.

Call out any default the user is explicitly opting out of and record it.

### Phase 4: Speed, testing gates, and progressive delivery

Read:

- [`references/speed-and-efficiency.md`](references/speed-and-efficiency.md)
- [`references/testing-and-quality-gates.md`](references/testing-and-quality-gates.md)
- [`references/progressive-delivery.md`](references/progressive-delivery.md)
- [`references/artifacts-and-promotion.md`](references/artifacts-and-promotion.md)

Recommend:

- Caching strategy (with security-aware cache keys).
- Path filters / change detection where useful.
- Which checks are blocking vs advisory at each layer.
- Artifact immutability ("build once, promote always").
- Whether progressive delivery (canary, blue/green, feature-flag
  decoupling) is warranted for this maturity level — stay at the
  *pipeline* level; do not design application feature-flag systems.

### Phase 5: Release documentation & versioning

Read [`references/release-documentation.md`](references/release-documentation.md).

Decide and scaffold:

- Whether to adopt Conventional Commits (strongly preferred for
  automation).
- `CHANGELOG.md` following Keep a Changelog structure (with an
  `[Unreleased]` section).
- Release automation approach appropriate to the platform and ecosystem
  (e.g. release-please, semantic-release, or a thin custom workflow).
- Tagging and GitHub/GitLab Release creation.

If the user already has a changelog or commit style, audit it lightly and
offer to align rather than replace without consent.

### Phase 6: Write the baseline record

Copy [`assets/baseline-template.md`](assets/baseline-template.md) to
`docs/ci-cd-baseline.md` and fill in every field from Phases 1–5. This
file is what every future audit-mode invocation reads first — complete it
now.

### Phase 7: Scaffold the pipeline files

Using the platform-specific guidance in
`references/platforms/<platform>.md` and the decisions above, create or
update the actual workflow/config files. Prefer small, reviewable diffs.
Never overwrite existing non-trivial workflows without showing the user
the plan and getting explicit go-ahead.

Also create or update:

- `CHANGELOG.md` (if missing or empty of structure)
- Any release-config files the chosen automation needs
- A short note in `CONTRIBUTING.md` or `docs/` on how releases work (only
  if the repo already has contributor docs, or the user asks)

### Phase 8: Wrap up

Summarize:

- What was scaffolded and where
- Where the baseline lives
- How to re-invoke this skill later for an audit
- Any manual follow-ups (e.g. adding repository secrets, enabling
  required status checks, installing a GitHub App for release-please)

## Audit mode

Read `docs/ci-cd-baseline.md` first. If it is missing, create it from the
inferred current state (see mode detection) before continuing.

Work through the domains below **sequentially**. For each domain, read
the corresponding reference file, compare the live pipeline against both
the baseline and the reference guidance, and record findings.

### Domains (in order)

1. [Pipeline structure & layering](references/pipeline-structure.md)
2. [Security & permissions](references/security-and-permissions.md)
3. [Supply chain & reproducibility](references/supply-chain-and-reproducibility.md)
4. [Speed & efficiency](references/speed-and-efficiency.md)
5. [Testing & quality gates](references/testing-and-quality-gates.md)
6. [Artifacts & promotion](references/artifacts-and-promotion.md)
7. [Progressive delivery](references/progressive-delivery.md)
8. [Pipeline observability & reliability](references/pipeline-observability.md)
9. [Release documentation & versioning](references/release-documentation.md)

Also consult [`references/anti-patterns.md`](references/anti-patterns.md)
and the platform file under `references/platforms/` for the detected
platform.

### Severity

| Level | Meaning |
|---|---|
| Critical | Secrets exposure risk, untrusted-code execution path, missing required compliance control, or broken release integrity |
| Important | Missing pinning, overly broad permissions, non-reproducible builds, absent SBOM/provenance where expected, broken or missing changelog automation |
| Minor | Speed/cache improvements, clearer structure, documentation polish |
| Not Implemented | A recommended pattern for this maturity level is simply absent (especially progressive-delivery or release automation) |

### Report and fixes

Present a single checklist of findings grouped by severity, then domain.
Offer to fix items **individually** on request — never bulk-apply.

When the audit finishes (whether or not fixes were applied):

- Update `docs/ci-cd-baseline.md` "Last audited" date
- Append material changes to its Drift Log
- If release documentation was generated or substantially rewritten,
  note that in the Drift Log

## Release documentation add-on (available in both modes)

At any point the user may ask to:

- Check an existing `CHANGELOG.md` / release notes for Keep a Changelog
  structure, human readability, and alignment with commits/tags
- Generate or refresh a changelog from git history (prefer Conventional
  Commits when present; otherwise be honest about limits)
- Wire or adjust release automation (release-please, semantic-release,
  etc.)

Always read [`references/release-documentation.md`](references/release-documentation.md)
before generating or rewriting release docs. Prefer additive, reviewable
changes.

## Reference files

| File | Covers |
|---|---|
| [`references/pipeline-structure.md`](references/pipeline-structure.md) | Layering (PR / main / release), trunk-based defaults, time budgets |
| [`references/security-and-permissions.md`](references/security-and-permissions.md) | Least privilege, OIDC, dangerous trigger patterns, secret hygiene |
| [`references/supply-chain-and-reproducibility.md`](references/supply-chain-and-reproducibility.md) | Pinning, lockfiles, SBOM, SLSA provenance/attestations |
| [`references/speed-and-efficiency.md`](references/speed-and-efficiency.md) | Caching, path filters, parallelism, timeouts |
| [`references/testing-and-quality-gates.md`](references/testing-and-quality-gates.md) | What runs where; blocking vs advisory gates |
| [`references/artifacts-and-promotion.md`](references/artifacts-and-promotion.md) | Immutable artifacts, promote-always, environment promotion |
| [`references/progressive-delivery.md`](references/progressive-delivery.md) | Canary / blue-green / feature-flag decoupling at pipeline level |
| [`references/pipeline-observability.md`](references/pipeline-observability.md) | Notifications, retries, basic DORA-supporting signals |
| [`references/release-documentation.md`](references/release-documentation.md) | Conventional Commits, Keep a Changelog, release automation |
| [`references/anti-patterns.md`](references/anti-patterns.md) | Common failure modes and why they hurt |
| `references/platforms/<platform>.md` | Concrete patterns for GitHub Actions, GitLab CI, … |
| [`assets/baseline-template.md`](assets/baseline-template.md) | Record structure for `docs/ci-cd-baseline.md` |

Reference files are loaded on demand. Keep SKILL.md as the router; put
depth in the references.
