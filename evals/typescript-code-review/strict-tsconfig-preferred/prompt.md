---
name: typescript-code-review-strict-tsconfig-preferred
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the typescript-code-review skill.

Scenario: TypeScript web app with `"strict": false` and widespread `any`, tier=web.

Target code (review this; it is the only code available):

```ts
// tsconfig.json
{ "compilerOptions": { "strict": false, "target": "ES2022" } }
// src/util.ts
export function parse(input: any): any { return JSON.parse(input).data as any; }
```
