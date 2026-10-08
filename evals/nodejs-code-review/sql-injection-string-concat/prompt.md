---
name: nodejs-code-review-sql-injection-string-concat
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: Express route builds SQL with string concatenation from `req.query`, tier=web.

Target code (review this; it is the only code available):

```js
// src/routes/search.js
app.get('/search', async (req, res) => {
  const rows = await db.query(
    "SELECT * FROM products WHERE name = '" + req.query.q + "'");
  res.json(rows);
});
```
