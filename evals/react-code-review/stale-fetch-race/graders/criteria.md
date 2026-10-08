---
type: llm
weight: 1
---

# Grading criteria: stale fetch race

Pass if the response:

- Concurrency/async domain flags race / missing abort

Fail if:

- No async correctness finding

Grounding: the finding must reference the supplied code (e.g. the un-aborted `fetch` in `Results.jsx` that can set stale state) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
