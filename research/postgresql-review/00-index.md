# Research: postgresql-review

**Status:** coverage baselines only (not yet authored as skill references).  
**Skill name (locked):** `postgresql-review`  
**Retrieval window:** 2026-09-07  

## Why this skill

Portable procedural knowledge for reviewing a live PostgreSQL database
(health, schema integrity, indexes, workload, maintenance, security,
hygiene) with a scored domain report. Preferred execution path is
[MCPg](https://github.com/devopam/MCPg) (read capability); fallback is
generic catalog/`pg_stat_*` SQL when MCPg is unavailable.

## Documents in this folder

| File | Purpose |
|------|---------|
| [`01-scope-and-mcpg-mapping.md`](01-scope-and-mcpg-mapping.md) | In/out of scope, access-mode decision, MCPg tool map, fallback posture |
| [`02-domain-baselines.md`](02-domain-baselines.md) | Per-domain coverage baselines for authoring `references/*.md` |

## Decision log (user-confirmed 2026-09-07)

1. **Name:** `postgresql-review`
2. **Default scope:** whole database; prompt for a specific schema if the user supplies one (or asks to narrow).
3. **Process:** research baselines first; do not author SKILL.md / references until baselines are reviewed.

## Next gate

Human review of `01` + `02`. After approval, author:

- `skills/postgresql-review/SKILL.md`
- domain `references/` (one file per domain or merged packs)
- `assets/report-template.md`
- `evals/postgresql-review/*`
- README / plugin / CHANGELOG bump

Do **not** skip to authoring on model memory alone.
