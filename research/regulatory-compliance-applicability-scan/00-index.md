# regulatory-compliance-applicability-scan — research index

**Skill name:** `regulatory-compliance-applicability-scan`  
**Status:** **Research baseline complete** (2026-09-15). Skeleton skill exists. Obligation-card depth + evals + runnable packs = next phase. **Not released.**

**Goal:** Map researched regimes to repo evidence; **decline** uncovered regions/domains.

## Coverage (summary)

| Axis | First wave |
|------|------------|
| Domains | Healthcare/pharma, Fintech |
| Privacy regions | Europe, India, Americas (US-CA focus, Canada, Brazil), Middle East (UAE, KSA) |
| Explicitly not covered | Japan and any pack without cards+registry |

## Core design docs

| File | Content |
|------|---------|
| [01-scope-and-boundaries.md](01-scope-and-boundaries.md) | Non-goals |
| [02-intake-and-repo-signals.md](02-intake-and-repo-signals.md) | Intake |
| [03-source-strategy-hybrid.md](03-source-strategy-hybrid.md) | Hybrid sources |
| [04-refresh-job.md](04-refresh-job.md) | Monthly PR refresh |
| [05-packs-roadmap.md](05-packs-roadmap.md) | Build order |
| [06-report-shape.md](06-report-shape.md) | Report |
| [07-coverage-matrix.md](07-coverage-matrix.md) | Available vs not covered |

## Pack research (baselines)

| Pack | File |
|------|------|
| privacy-eu | [packs/privacy-eu.md](packs/privacy-eu.md) |
| privacy-in | [packs/privacy-in.md](packs/privacy-in.md) |
| privacy-us | [packs/privacy-us.md](packs/privacy-us.md) |
| privacy-ca | [packs/privacy-ca.md](packs/privacy-ca.md) |
| privacy-br | [packs/privacy-br.md](packs/privacy-br.md) |
| privacy-ae | [packs/privacy-ae.md](packs/privacy-ae.md) |
| privacy-sa | [packs/privacy-sa.md](packs/privacy-sa.md) |
| domain-fintech | [packs/domain-fintech.md](packs/domain-fintech.md) |
| domain-healthcare-pharma | [packs/domain-healthcare-pharma.md](packs/domain-healthcare-pharma.md) |

## Infra already on main

- `compliance-sources/registry.yaml` + refresh script/workflow
- Skill skeleton + `privacy-eu` outline card + templates
