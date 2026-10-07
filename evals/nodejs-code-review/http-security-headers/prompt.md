---
name: nodejs-code-review-http-security-headers
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: Express app with no helmet/security headers, CORS `*`, tier=web.

Target code (review this; it is the only code available):

```js
// app.js
const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());
```
