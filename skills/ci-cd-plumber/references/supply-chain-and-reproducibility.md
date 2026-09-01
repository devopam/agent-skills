# Supply Chain & Reproducibility

Whether the pipeline produces **the same bytes from the same inputs**, and
whether those bytes can be traced to source with integrity metadata.

Closely related to [security-and-permissions](security-and-permissions.md)
(identity and triggers) but focused on **what is being executed and
published**: actions, base images, language dependencies, SBOMs, and
provenance.

## Table of Contents

- [Goals](#goals)
- [Pinning](#pinning)
- [Lockfiles and installs](#lockfiles-and-installs)
- [SBOM](#sbom)
- [Provenance and attestations (SLSA-oriented)](#provenance-and-attestations-slsa-oriented)
- [Hermeticity and trust boundaries](#hermeticity-and-trust-boundaries)
- [Maturity expectations](#maturity-expectations)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Goals

1. **Reproducible installs** — lockfiles honored; no floating `latest`.
2. **Immutable third-party CI components** — actions/images pinned to digests.
3. **Inventory** — SBOM for released artifacts where consumers or policy need it.
4. **Provenance** — verifiable statement of how/where an artifact was built.

---

## Pinning

### GitHub Actions

Prefer full commit SHA over mutable tags:

```yaml
# Prefer:
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# Avoid as the only pin:
- uses: actions/checkout@v4
```

Operational tips:

- Keep the human version in a trailing comment for readability.
- Use Dependabot/Renovate (or equivalent) to propose SHA bumps deliberately.
- Treat PRs that only change action SHAs as security-sensitive reviews.

### Container images

Pin base images by digest (`image@sha256:...`) in Dockerfiles and in
`image:` fields for CI jobs when the platform allows it.

### GitLab CI / others

Same principle: prefer immutable references for include files, component
versions, and job images.

---

## Lockfiles and installs

| Ecosystem | Prefer |
|---|---|
| Node | `npm ci`, `pnpm install --frozen-lockfile`, `yarn install --frozen-lockfile` |
| Python | `uv sync --frozen` / poetry install with lock / pip + committed requirements hash workflow |
| Go | committed `go.sum`; avoid ad-hoc `go get` in CI without tidy discipline |
| Rust | committed `Cargo.lock` for apps/binaries |
| Docker | pinned bases; fewer `apt-get` unbounded upgrades in builder stages |

Findings:

- CI runs `npm install` without a lockfile → Important/Critical depending
  on whether this produces the release artifact.
- Lockfile present but CI ignores it → Important.

---

## SBOM

Software Bill of Materials (CycloneDX or SPDX) for released artifacts is
increasingly expected by consumers and procurement.

Recommendations:

- Generate SBOM in the **main/release** pipeline for publishable artifacts.
- Store as a release asset or alongside the image (registry SBOM tools).
- Do not claim compliance you have not verified; generating a file is
  necessary but not sufficient for every regulatory regime.

Tools commonly seen: Syft, Trivy, native ecosystem exporters, registry-side
generators.

---

## Provenance and attestations (SLSA-oriented)

SLSA (Supply-chain Levels for Software Artifacts) provides a vocabulary for
build integrity. Exact level claims require care; this skill focuses on
**practical controls**:

- Signed attestations binding artifact digest → source repo/commit/workflow.
- Hosted builder with ephemeral environment (GitHub-hosted runners, etc.).
- Isolation of provenance generation from untrusted build steps where
  aiming at stronger guarantees (reusable workflows / dedicated builders).

On GitHub Actions, artifact attestations / `actions/attest-build-provenance`
(and related SLSA generators) are the pragmatic path for many projects.

Audit stance:

- **Prototype:** pinning + lockfiles may be enough.
- **Standard service:** add SBOM for published artifacts; prefer attestations
  when publishing shared libraries or container images.
- **High-assurance:** require provenance verification in promotion gates;
  document the intended SLSA-oriented posture honestly.

---

## Hermeticity and trust boundaries

- Network egress during release builds should be intentional (dependency
  proxies, fixed registries), not "whatever the script downloads."
- Caching must not allow a low-trust job to poison caches used by
  high-trust release jobs (platform-specific cache key and scope rules).
- Rebuilding third-party code from floating branches inside CI is a supply
  chain smell unless pinned.

---

## Maturity expectations

| Control | Prototype | Standard | High-assurance |
|---|---|---|---|
| Lockfile-honoring installs | Required | Required | Required |
| Action/image digest pinning | Recommended | Required | Required |
| SBOM on release artifacts | Optional | Recommended | Required |
| Signed provenance/attestations | Optional | Recommended for publishable artifacts | Required |
| Promotion verifies provenance | Optional | Optional | Required |

---

## Concrete checks

1. Are third-party Actions pinned to full SHAs?
2. Are CI container images pinned by digest?
3. Does install use lockfiles in frozen mode?
4. Is the release artifact built once and reused?
5. Is an SBOM produced for published artifacts?
6. Are attestations/provenance generated and stored?
7. Can a fork PR influence release-job dependencies or caches?

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| `uses: org/action@main` | Fully floating; any push changes your CI |
| `image: node:latest` | Non-reproducible; surprise breakages and silent trust shifts |
| Generating SBOM only on developer laptops | Not tied to the release builder identity |
| Claiming "SLSA 3" without isolation guarantees | Overclaim; erodes trust when audited |
| Dependency install with `curl | sh` in release path | Opaque supply chain step |

---

## Sources

- SLSA specification and get-started guidance — levels, provenance purpose.
- GitHub Docs — artifact attestations; pinning actions; dependency
  security features.
- OpenSSF / community hardening guides — SHA pinning as highest-impact
  CI supply-chain control.
- Ecosystem package manager docs — frozen/lockfile install modes.

Synthesized for this skill 2026-09-01. When vendor docs and blog posts
disagree, prefer vendor primary documentation.
