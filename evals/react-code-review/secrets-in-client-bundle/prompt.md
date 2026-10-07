---
name: react-code-review-secrets-in-client-bundle
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the react-code-review skill.

Scenario: Frontend module hardcodes a private API secret (not NEXT_PUBLIC-style publishable key).

Target code (review this; it is the only code available):

```js
// src/api/client.js  (bundled to the browser)
const PAYMENTS_SECRET_KEY = 'example-private-secret-not-a-real-key';
export const charge = (amt) => fetch('https://api.payments.example/v1/charges', {
  method: 'POST', headers: { Authorization: `Bearer ${PAYMENTS_SECRET_KEY}` }, body: ... });
```
