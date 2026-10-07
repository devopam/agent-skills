---
name: nodejs-code-review-graceful-shutdown-enterprise
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the nodejs-code-review skill.

Scenario: HTTP server with no SIGTERM/`server.close` handling, tier=enterprise.

Target code (review this; it is the only code available):

```js
// server.js
const app = require('./app');
app.listen(3000, () => console.log('listening'));
// no signal handlers; open DB pool in ./db
```
