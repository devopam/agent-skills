# Research: ci-cd-plumber

Provenance record for the `ci-cd-plumber` skill (v0). Research and domain
synthesis occurred 2026-09-01; reference docs under
`skills/ci-cd-plumber/references/` were authored from this pass.

This skill is intentionally narrower than `project-incubation`: it owns
CI/CD pipeline structure, security/permissions, supply-chain controls,
speed, quality gates, artifacts/promotion, progressive-delivery *at the
pipeline layer*, observability signals that support DORA, and release
documentation/versioning automation. It does not own application
architecture, IaC design, or app-level observability.

## Status

| Area | Status | Notes |
|---|---|---|
| Scope & dual-mode design | promoted | Inception vs Audit; baseline at `docs/ci-cd-baseline.md` |
| Pipeline structure | promoted | PR / main / release layering; trunk-based default |
| Security & permissions | promoted | least privilege, OIDC, dangerous triggers |
| Supply chain & reproducibility | promoted | SHA pinning, lockfiles, SBOM, SLSA-style provenance |
| Speed & efficiency | promoted | caching, path filters, budgets |
| Testing & quality gates | promoted | blocking vs advisory |
| Artifacts & promotion | promoted | build-once-promote-always |
| Progressive delivery | promoted | pipeline-level canary/blue-green/flags |
| Pipeline observability | promoted | notifications, retries, DORA-supporting signals |
| Release documentation | promoted | Conventional Commits, Keep a Changelog, automation |
| Anti-patterns | promoted | common failure modes |
| Platform: GitHub Actions | promoted | layout, permissions, OIDC, pinning, release hooks |
| Platform: GitLab CI | promoted | stages, rules, cache, environments |
| Example workflows | added | assets/example-workflows/ |
| Evals | scaffolded | see `evals/ci-cd-plumber/` |
| Audit report shape | promoted | domain 0–10 scorecard, severity-ordered findings, required baseline close-out |

## Key sources (synthesized 2026-09)

- GitHub Docs: workflow syntax, permissions, OIDC, environments, hardening
  Actions, artifact attestations.
- GitLab Docs: `rules`, caching, protected variables/environments, CI/CD
  components, security best practices.
- SLSA / supply-chain: provenance, SBOM practices, immutable digests.
- Conventional Commits + Keep a Changelog + release-please / semantic-release
  ecosystem patterns.
- DORA metrics framing applied only to pipeline-visible signals (not full
  org metrics programs).
- 2026 hardening practice: pin third-party actions/images to full commit
  SHAs; prefer OIDC over long-lived cloud secrets; avoid unsafe
  `pull_request_target` + untrusted checkout combinations.

## Design decisions carried into SKILL.md

1. **Dual mode via baseline file** — same pattern as project-incubation;
   enables hand-off and ongoing audits without re-asking context.
2. **Strict CI/CD boundary** — release docs are in-scope because they are
   pipeline outputs; app architecture and infra design are out.
3. **Plain-text, one-question-at-a-time** — portable across agentskills.io
   clients; no host-specific interactive widgets.
4. **Opinionated defaults with recorded opt-outs** — pinning, OIDC, SBOM
   are defaults; user declines are written into the baseline Drift Log.
5. **Sequential domain audit** — fixed order reduces missed domains and
   keeps reports comparable over time.
6. **Scored tabular report** — each domain 0–10 vs maturity target;
   composite average; findings ordered Critical → Important → Minor →
   Not Implemented; baseline close-out required after every audit.

## Follow-ups beyond v0

- Additional platform stubs (CircleCI, Azure Pipelines, Buildkite) as demand
  appears.
- Deeper progressive-delivery recipes once exercised on real monorepos.
- Expanded eval suite after further live use (including a grader for the
  required scorecard + severity ordering).
