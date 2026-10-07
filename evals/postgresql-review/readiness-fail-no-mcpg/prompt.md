---
name: postgresql-review-readiness-fail-no-mcpg
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

User asks: "Run a full postgresql-review on our production DB."
No MCPg tools are available in the environment (no get_server_info,
list_schemas, audit_database, etc.). User has not consented to degraded mode.
