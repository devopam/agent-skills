# Research: postgresql-review

**Status:** coverage baselines only (not yet authored as skill references).  
**Skill name (locked):** `postgresql-review`  
**Retrieval window:** 2026-09-07  

## Why this skill

Portable procedural knowledge for reviewing a live PostgreSQL database
(health, schema integrity, indexes, workload, maintenance, security,
hygiene) with a scored domain report.

**MCPg is the required utility path for a full review.** The skill’s first
phase is **readiness**: confirm MCPg is installed, configured against the
target database, and reachable (including any schema scope the user
chose). Domain scoring proceeds only after readiness passes — or after
the user explicitly accepts a degraded, non-MCPg fallback.

## Documents in this folder

| File | Purpose |
|------|---------|
| [`01-scope-and-mcpg-mapping.md`](01-scope-and-mcpg-mapping.md) | In/out of scope, access-mode, **MCPg readiness gate**, tool map, fallback |
| [`02-domain-baselines.md`](02-domain-baselines.md) | Per-domain coverage baselines for authoring `references/*.md` |
| [`03-mcpg-readiness.md`](03-mcpg-readiness.md) | Install / configure / verify checklist (detail for readiness phase) |

## Decision log

1. **Name:** `postgresql-review` (2026-09-07)
2. **Default scope:** whole database; optional schema when the user narrows (2026-09-07)
3. **Process:** research baselines first (2026-09-07)
4. **MCPg readiness required** before full review; guide install/config/access for the DB (and schemas) under review (2026-09-07)

## Next gate

Human review of `01` + `02` + `03`. After approval, author skill + references + evals (including readiness failure / success cases).

Do **not** skip to authoring on model memory alone.
