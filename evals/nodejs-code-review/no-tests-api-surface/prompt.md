---
name: nodejs-code-review-no-tests-api-surface
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: Multiple routes, no test files, tier=web.

Target code (review this; it is the only code available):

```text
src/routes/users.js   (GET/POST/PUT/DELETE /users)
src/routes/orders.js  (GET/POST /orders, POST /orders/:id/refund)
src/routes/auth.js    (POST /login, POST /logout)
package.json          ("scripts": { "start": "node server.js" })   # no test script, no test files
```

The project to review is in the current working directory.
