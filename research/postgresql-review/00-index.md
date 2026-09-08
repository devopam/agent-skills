# Research: postgresql-review

**Status:** baselines approved; **skill v0 authored** under `skills/postgresql-review/`;
**all 7 domain reference docs deepened** to baseline-target depth (2026-09-08).  
**Skill name (locked):** `postgresql-review`  
**Retrieval window:** 2026-09-07 (v0 baselines) / 2026-09-08 (domain deepening pass)  

## Why this skill

Portable procedural knowledge for reviewing a live PostgreSQL database
with a scored domain report. **MCPg is required for a full review**; Phase 0
confirms install, config, and reachability for the target DB/schemas.

## Documents in this folder

| File | Purpose |
|------|---------|
| [`01-scope-and-mcpg-mapping.md`](01-scope-and-mcpg-mapping.md) | Scope, access-mode, tool map |
| [`02-domain-baselines.md`](02-domain-baselines.md) | Domain coverage baselines (v0) |
| [`03-mcpg-readiness.md`](03-mcpg-readiness.md) | Install / configure / verify checklist |
| [`health-and-configuration.md`](health-and-configuration.md) | Deepening pass — provenance for `references/health-and-configuration.md` |
| [`schema-integrity.md`](schema-integrity.md) | Deepening pass — provenance for `references/schema-integrity.md` |
| [`indexing.md`](indexing.md) | Deepening pass — provenance for `references/indexing.md` |
| [`workload-and-query-performance.md`](workload-and-query-performance.md) | Deepening pass — provenance for `references/workload-and-query-performance.md` |
| [`maintenance.md`](maintenance.md) | Deepening pass — provenance for `references/maintenance.md` |
| [`security-and-access.md`](security-and-access.md) | Deepening pass — provenance for `references/security-and-access.md` |
| [`hygiene-and-conventions.md`](hygiene-and-conventions.md) | Deepening pass — provenance for `references/hygiene-and-conventions.md` |

## Decision log

1. **Name:** `postgresql-review`
2. **Default scope:** whole database; optional schema narrowing
3. **Research before authoring**
4. **MCPg readiness required** before full review
5. **v0 authored** 2026-09-07 (`skills/postgresql-review/`, evals, plugin 0.12.0)
6. **Domain deepening pass** 2026-09-08 — v0's 7 reference docs were thin
   (~30-40 lines each) relative to `02-domain-baselines.md`'s own target
   depth. Each domain was independently re-researched against live
   PostgreSQL documentation and MCPg's actual source (`src/mcpg/`, v0.8.x)
   rather than the abbreviated `docs/tools.md` index, surfacing several
   corrections to previously-unverified claims — most notably RLS bypass
   mechanics (`FORCE` only closes the table-owner path, not superuser/
   `BYPASSRLS`) and a `run_advisors`-owned duplicate/redundant-index check
   that wasn't listed under any domain's tool set before. See each
   per-domain file above for its own headline findings.

Authored artifacts must stay aligned with these baselines; deepen references
from live MCPg use rather than inventing thresholds from memory alone.
