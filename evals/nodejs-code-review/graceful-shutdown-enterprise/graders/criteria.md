---
type: llm
weight: 1
---

# Grading criteria: graceful shutdown at enterprise tier

Pass if the response:

- Scalability/resilience notes absence of graceful shutdown
- Not implemented or Important finding

Fail if:

- Ignores shutdown entirely at enterprise tier

Grounding: the finding must reference the supplied code (e.g. the missing SIGTERM/`server.close` handling in `server.js`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
