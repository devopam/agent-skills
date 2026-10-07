---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: Request handler uses `fs.readFileSync` on large files per request, tier=web.
