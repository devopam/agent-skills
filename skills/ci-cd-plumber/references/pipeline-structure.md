# Pipeline Structure & Layering

How jobs are organized across PR validation, main/trunk integration, and
release/promotion — and whether that structure matches the project's risk
and speed goals.

This domain answers: **what runs when, on which ref, and why that split
exists.** Security of identities is in
[security-and-permissions](security-and-permissions.md); artifact immutability
in [artifacts-and-promotion](artifacts-and-promotion.md).

## Table of Contents

- [Core model](#core-model)
- [Layer responsibilities](#layer-responsibilities)
- [Trunk-based default](#trunk-based-default)
- [Monorepos](#monorepos)
- [Time budgets](#time-budgets)
- [Required vs advisory gates](#required-vs-advisory-gates)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Core model

Prefer three explicit layers (names vary by platform):

1. **PR / merge-request validation** — fast feedback on the proposed change.
2. **Main / trunk pipeline** — full verification after merge; produce the
   immutable artifact.
3. **Release / promotion** — version, changelog, publish, deploy/promote.

Not every project needs a separate release workflow on day one, but the
*separation of concerns* should be visible even if layers share a file.

**Build once, promote always:** the artifact that passed main should be the
same bytes promoted to staging/production — not rebuilt per environment.

---

## Layer responsibilities

### PR / MR validation

- Lint, unit tests, typecheck, lightweight SAST/secret scan.
- Optional: build a disposable preview artifact (not the release artifact).
- Must not require production secrets.
- Must be safe for fork contributions (`pull_request`, not unsafe
  `pull_request_target` patterns).

### Main / trunk

- Re-run or deepen checks (integration tests, fuller SAST, license/SBOM).
- Build the **release candidate artifact** once.
- Attach SBOM / provenance when in scope (see supply-chain domain).
- Publish to an internal artifact store or registry as needed.

### Release / promotion

- Version bump and changelog (see
  [release-documentation](release-documentation.md)).
- Sign/attest if required.
- Deploy or promote the existing artifact through environments.
- Optional human approval gates for production at higher maturity.

---

## Trunk-based default

Default recommendation: **trunk-based development** with short-lived PR
branches merged to a single mainline, rather than long-lived GitFlow release
branches — consistent with DORA-oriented delivery research and most modern
CI designs.

Exceptions (record in the baseline):

- Strict release-train or regulatory processes that require long-lived
  release branches.
- Multi-version maintenance of libraries (still keep CI layered per branch).

---

## Monorepos

When the repo has multiple independently deployable packages:

- Prefer **path filters / change detection** so unrelated packages do not
  pay full CI cost on every PR.
- Each significant package should map to clear jobs (or a matrix) rather
  than one opaque mega-pipeline with no ownership boundaries.
- Shared workflows/templates are good; shared *mutable* caches across
  trust boundaries are not (see security domain).

Align with any package map already recorded in
`docs/project-incubation-baseline.md` when present.

---

## Time budgets

Budgets are contracts, not aspirations. Reasonable starting targets:

| Layer | Target feedback |
|---|---|
| PR critical path | ≤ 5–10 minutes for standard services; tighter for high-churn repos |
| Main full pipeline | As short as practical; integration tests may dominate |
| Release | Dominated by deploy/propagation, not by rebuild |

If PR CI routinely exceeds ~15–20 minutes without path filtering or
parallelism, treat that as a structural finding under speed **and**
structure (wrong things may be running at the wrong layer).

---

## Required vs advisory gates

- **Blocking on PR:** lint/type errors, unit test failures, high-confidence
  secret scan hits, critical SAST where policy requires.
- **Blocking on main:** full test suite agreed by the team, SBOM generation
  failure if policy requires SBOMs, release-artifact build failure.
- **Advisory:** style nits, coverage thresholds still being rolled out,
  experimental scanners.

Document which checks are required status checks in the baseline so audits
can detect silent removal.

---

## Concrete checks

1. Is there a clear PR-time path distinct from the release path?
2. Does main produce an artifact that later stages reuse (not rebuild)?
3. Are deploy jobs triggered from tags/release events or main with explicit
  promotion logic — or does every branch deploy to prod?
4. For monorepos: do path filters exist, and are they correct?
5. Are workflow files readable (named jobs, stages, modest duplication) or
   a single 500-line job with copy-paste?
6. Do required checks match what the team believes is gating merge?

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Single pipeline that builds, tests, and prod-deploys on every push to any branch | No trust boundary; slow feedback; easy accidental prod push |
| Rebuilding the app in every environment | "Works in staging" ≠ same bits in prod |
| All tests only on main, none on PR | Broken trunk; slow discovery |
| All tests only on PR, none after merge | Misses integration breakage against concurrent merges |
| No path filters in a large monorepo | CI cost and queue time explode; people start bypassing |
| Release process undocumented and only in one person's head | Bus factor; cannot audit |

---

## Sources

- DORA / software delivery performance research — trunk-based development,
  deployment frequency, lead time (elite vs low performer framing).
- Vendor pipeline architectures (GitHub Actions, GitLab CI, Azure Pipelines
  baseline patterns) — PR pipeline vs CI pipeline vs CD/promotion stages.
- "Build once, promote always" as a recurring artifact discipline across
  mature CD write-ups (2024–2026 engineering references).

Synthesized for this skill 2026-09-01.
