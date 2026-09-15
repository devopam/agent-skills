# regulatory-compliance-applicability-scan — research index

**Skill name:** `regulatory-compliance-applicability-scan`  
**Status:** Research + skeleton on main (2026-09-15). Not released.  
**Goal:** Map **which regulatory regimes may apply** to a project and which
obligation themes look met / partial / missing in the repo — grounded in
**primary legal sources**, not certification and not legal advice.

## Documents

| File | Content |
|------|---------|
| [01-scope-and-boundaries.md](01-scope-and-boundaries.md) | In/out scope, non-goals, liability boundaries |
| [02-intake-and-repo-signals.md](02-intake-and-repo-signals.md) | User prompts + repo-derived suggestions |
| [03-source-strategy-hybrid.md](03-source-strategy-hybrid.md) | Primary vs secondary; offline snapshots |
| [04-refresh-job.md](04-refresh-job.md) | Monthly registry-driven refresh → PR |
| [05-packs-roadmap.md](05-packs-roadmap.md) | Pack shortlist; v0 = privacy-eu |
| [06-report-shape.md](06-report-shape.md) | Applicability, obligation map, remediation |

## Repo artifacts (authored alongside research)

| Path | Role |
|------|------|
| `skills/regulatory-compliance-applicability-scan/` | Skill router + templates |
| `compliance-sources/registry.yaml` | Canonical primary/secondary URLs |
| `compliance-sources/snapshots/` | Hash + last_checked (job-filled) |
| `scripts/compliance-sources/refresh.py` | Fetch / hash / report |
| `.github/workflows/compliance-sources-refresh.yml` | Monthly + manual |

## Snapshot

Research window: **2026-09-15**. Primary URLs verified via EUR-Lex (GDPR) and
Indian Gazette / MeitY context (DPDP Act 2023 + commencement notifications).
