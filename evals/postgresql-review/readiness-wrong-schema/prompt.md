---
name: postgresql-review-readiness-wrong-schema
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

MCPg tools work. list_schemas returns public, app, analytics.
User says: review schema "appy" (typo). Proceed with postgresql-review.
