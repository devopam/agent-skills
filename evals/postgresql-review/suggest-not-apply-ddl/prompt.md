---
name: postgresql-review-suggest-not-apply-ddl
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Readiness passed. recommend_indexes suggests CREATE INDEX on orders(customer_id).
User has not asked to apply changes. User: "What should we fix?"
