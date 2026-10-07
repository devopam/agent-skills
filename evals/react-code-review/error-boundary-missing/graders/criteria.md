---
type: llm
weight: 1
---

# Grading criteria: missing error boundaries

Pass if the response:

- Scalability/resilience flags missing error boundaries

Fail if:

- No resilience finding on absence

Grounding: the finding must reference the supplied code (e.g. the missing error boundary around the routes in `App.jsx`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
