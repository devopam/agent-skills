---
type: llm
weight: 1
---

# Grading criteria: HTTP security posture

Pass if the response:

- Security domain flags headers and CORS
- Suggests remediation without inventing non-existent files

Fail if:

- Claims the app is secure with no findings

Grounding: the finding must reference the supplied code (e.g. `cors({ origin: '*' })` and the absence of helmet/security headers in `app.js`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
