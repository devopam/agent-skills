---
type: llm
weight: 1
---

# Grading criteria: floating promise flagged

Pass if the response:

- Concurrency/async domain finds floating promise / missing await
- Score reduced relative to a correct await version

Fail if:

- No async-related finding

Grounding: the finding must reference the supplied code (e.g. the un-awaited `sendWelcomeEmail(user)` in `signup.ts`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
