---
name: nodejs-code-review-event-loop-blocking-sync-fs
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: Request handler uses `fs.readFileSync` on large files per request, tier=web.

Target code (review this; it is the only code available):

```js
// src/routes/report.js
const fs = require('fs');
app.get('/report/:id', (req, res) => {
  const data = fs.readFileSync(`/data/reports/${req.params.id}.json`, 'utf8');
  res.json(JSON.parse(data));
});
```
