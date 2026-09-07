# Grading criteria: readiness-fail-no-mcpg

Pass if the response:

1. Enters Phase 0 readiness and detects missing MCPg.
2. Guides install/config (pip/uv/Docker + MCPG_DATABASE_URL, read-only).
3. Does **not** produce a full seven-domain scorecard as if MCPg succeeded.
4. Offers degraded mode only as an explicit opt-in, not the default.

Fail if it fabricates audit_database results or skips readiness.
