<!--
Template for docs/ci-cd-baseline.md — the record ci-cd-plumber writes at the
end of inception mode and reads at the start of every audit-mode invocation.
Copy this file to <repo-root>/docs/ci-cd-baseline.md and fill in every field.
Remove this comment block once filled in.

Field-filling notes:
- Dates are ISO 8601 (YYYY-MM-DD).
- Prefer reading docs/project-incubation-baseline.md (if present) for language,
  stack category, compliance, and monorepo shape rather than re-deriving them.
- "Maturity / risk posture" drives how strictly supply-chain and approval
  controls are expected — prototype is lighter; high-assurance is stricter.
- Pinning, OIDC, and SBOM/provenance entries should reflect what was actually
  scaffolded or observed, not aspirational defaults the user declined.
- "Last audit scores" is optional but recommended after each Audit-mode run
  so successive composites can be compared without re-reading conversation
  history.
-->

# CI/CD Baseline

**Project:** <name>
**Baseline created:** <YYYY-MM-DD>
**Last audited:** <YYYY-MM-DD, or "never" if this is the freshly-created record>
**ci-cd-plumber skill version:** <version or commit date of the skill when this baseline was written>

## Context

- **Primary platform:** GitHub Actions | GitLab CI | other (<name>)
- **Language / runtime / packaging:** <e.g. Python 3.12 + uv, Node 22 + pnpm>
- **Repo shape:** single deployable | monorepo
- **Deployment target type:** container | serverless | static | library/package | VM/binary | mixed
- **Maturity / risk posture:** prototype | standard service | high-assurance / regulated
- **Compliance / policy constraints affecting the pipeline:** <none, or named requirements>
- **Linked project-incubation baseline:** <path if present, else "none">

## Pipeline structure

- **Layers present:** PR/MR validation | main/trunk | release/promotion | other (<name>)
- **Branching model assumed:** trunk-based (preferred) | other (<describe>)
- **Notable structural decisions:** <e.g. path-filtered jobs per package in a monorepo>

## Security & permissions

- **Permissions model:** <e.g. workflow-level contents: read; job-level write only for release>
- **OIDC / workload identity in use:** yes | no | partial (<where>)
- **Long-lived secrets remaining:** <none, or list purpose — prefer eliminating>
- **Dangerous patterns explicitly accepted or absent:** <e.g. "no pull_request_target", or exception with reasoning>

## Supply chain & reproducibility

- **Third-party actions/images pinning policy:** full SHA digests | version tags | mixed
- **Lockfile / reproducible install:** yes | no | partial
- **SBOM generation:** yes (format/tool) | no
- **Provenance / attestations (SLSA-style):** yes (level/tool if known) | no
- **Notable exceptions:** <none, or list with reasoning>

## Speed & efficiency

- **Caching strategy summary:** <keys / paths / pull-push policy>
- **Path filters / change detection:** yes | no
- **Target feedback budgets (if set):** PR <N min>, main <N min>

## Testing & quality gates

- **Blocking checks on PR:** <list>
- **Blocking checks on main:** <list>
- **Advisory-only checks:** <list>

## Artifacts & promotion

- **Artifact type(s):** <container image, wheel, tarball, …>
- **Immutability rule:** build once, promote always | other (<describe>)
- **Promotion path:** <e.g. PR → main artifact → staging → prod>

## Progressive delivery

- **Strategy in pipeline scope:** none | canary | blue-green | feature-flag decoupling | mixed
- **Notes:** <keep at pipeline level only>

## Release documentation & versioning

- **Commit convention:** Conventional Commits | other | none
- **Changelog:** Keep a Changelog (`CHANGELOG.md`) | other | missing
- **Release automation:** release-please | semantic-release | manual | other (<name>)
- **Tagging / platform Releases:** <e.g. annotated tags + GitHub Releases>

## Last audit scores

<!-- Optional. Fill or replace after each Audit-mode run (scores 0–10). -->

| Domain | Score |
|---|---:|
| Pipeline structure | <n> |
| Security & permissions | <n> |
| Supply chain & reproducibility | <n> |
| Speed & efficiency | <n> |
| Testing & quality gates | <n> |
| Artifacts & promotion | <n> |
| Progressive delivery | <n> |
| Pipeline observability | <n> |
| Release documentation | <n> |
| **Composite (average)** | **<n.n>** |

## Drift log

<!-- Append one line per audit-mode invocation where something material changed. -->

- <YYYY-MM-DD>: <what changed>
