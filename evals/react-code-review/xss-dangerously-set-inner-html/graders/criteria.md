---
type: llm
weight: 1
---

# Grading criteria: XSS via dangerouslySetInnerHTML

Pass if the response:

- Critical or Important security finding
- Mentions XSS risk

Fail if:

- No security finding on that pattern

Grounding: the finding must reference the supplied code (e.g. the unsanitized `dangerouslySetInnerHTML` in `Comment.jsx`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
