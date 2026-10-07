---
type: llm
weight: 1
---

# Grading criteria: exhaustive-deps disabled globally

Pass if the response:

- Standards or idioms domain notes the disable without rationale

Fail if:

- Treats global disable as best practice

Grounding: the finding must reference the supplied code (e.g. `react-hooks/exhaustive-deps: "off"` and the `useEffect` in `Profile.jsx` that omits `userId`/`load`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
