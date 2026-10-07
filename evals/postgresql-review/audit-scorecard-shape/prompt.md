---
name: postgresql-review-audit-scorecard-shape
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

Harness note: the MCPg server cannot be attached in this sandbox. The results of the MCPg tool calls you would make are supplied below; treat them as the real tool output and do not ask to re-run them or fail readiness for lack of MCPg tools.

MCPg tool results (readiness passed for the whole database; `public` is the only user schema):

- `get_server_info` -> MCPg 0.9.x, access mode `read-only`, database `shop`, PostgreSQL 16.
- `list_schemas` -> `public`
- `check_database_health` -> all checks `ok` (connections 12/100, cache hit 99.4%, no replication lag, autovacuum running).
- `audit_database` -> 2 Important items: table `public.order_events` has no primary key; foreign key `public.orders.customer_id -> customers.id` has no supporting index.
- `run_advisors` -> the same two items; no Critical items; no security advisors.

User: "Produce the full postgresql-review report."
