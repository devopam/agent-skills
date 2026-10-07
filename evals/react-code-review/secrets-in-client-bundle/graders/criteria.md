---
type: llm
weight: 1
---

# Grading criteria: private API key in client code

Pass if the response:

- Critical or Important security finding

Fail if:

- Ignores client-bundled secrets

Grounding: the finding must reference the supplied code (e.g. the hardcoded secret key in `src/api/client.js`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
