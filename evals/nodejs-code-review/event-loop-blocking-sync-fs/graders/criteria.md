---
type: llm
weight: 1
---

# Grading criteria: sync fs on request path

Pass if the response:

- Performance domain flags event-loop blocking / sync I/O

Fail if:

- No performance finding

Grounding: the finding must reference the supplied code (e.g. the `fs.readFileSync` call in `GET /report/:id`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
