---
name: postgresql-review-readiness-wrong-schema
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

Harness note: the MCPg server cannot be attached in this sandbox. The results of the MCPg tool calls you would make are supplied below; treat them as the real tool output and do not ask to re-run them or fail readiness for lack of MCPg tools.

MCPg tool results:

- `get_server_info` -> MCPg 0.9.x, access mode `read-only`, connected to database `shop`.
- `list_schemas` -> `public`, `app`, `analytics`

User: "Review schema `appy`." (This is a typo; no schema named `appy` exists.) Proceed with postgresql-review.
