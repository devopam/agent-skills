# Research: postgresql-review

**Status:** baselines approved; **skill v0 authored** under `skills/postgresql-review/`.  
**Skill name (locked):** `postgresql-review`  
**Retrieval window:** 2026-09-07  

## Why this skill

Portable procedural knowledge for reviewing a live PostgreSQL database
with a scored domain report. **MCPg is required for a full review**; Phase 0
confirms install, config, and reachability for the target DB/schemas.

## Documents in this folder

| File | Purpose |
|------|---------|
| [`01-scope-and-mcpg-mapping.md`](01-scope-and-mcpg-mapping.md) | Scope, access-mode, tool map |
| [`02-domain-baselines.md`](02-domain-baselines.md) | Domain coverage baselines |
| [`03-mcpg-readiness.md`](03-mcpg-readiness.md) | Install / configure / verify checklist |

## Decision log

1. **Name:** `postgresql-review`
2. **Default scope:** whole database; optional schema narrowing
3. **Research before authoring**
4. **MCPg readiness required** before full review
5. **v0 authored** 2026-09-07 (`skills/postgresql-review/`, evals, plugin 0.12.0)

Authored artifacts must stay aligned with these baselines; deepen references
from live MCPg use rather than inventing thresholds from memory alone.
