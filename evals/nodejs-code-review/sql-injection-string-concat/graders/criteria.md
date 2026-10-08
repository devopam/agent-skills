---
type: llm
weight: 1
---

# Grading criteria: SQL injection via string concat

Pass if the response:

- Critical or Important security finding (injection)
- Mentions parameterized queries / bind variables as direction

Fail if:

- No injection finding

Grounding: the finding must reference the supplied code (e.g. the string-concatenated query in `GET /search`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
