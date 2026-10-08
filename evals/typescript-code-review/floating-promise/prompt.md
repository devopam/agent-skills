---
name: typescript-code-review-floating-promise
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the typescript-code-review skill.

Scenario: TypeScript service handler starts `doWork()` without await or void, tier=web.

Target code (review this; it is the only code available):

```ts
// src/handlers/signup.ts
export async function signup(req: Request, res: Response) {
  const user = await createUser(req.body);
  sendWelcomeEmail(user);   // async, returns Promise<void>
  res.status(201).json(user);
}
```
