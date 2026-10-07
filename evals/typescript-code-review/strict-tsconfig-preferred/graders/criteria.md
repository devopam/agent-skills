---
type: llm
weight: 1
---

# Grading criteria: strict tsconfig preferred

Pass if the response:

- Standards or quality domain scores reduced
- Finding cites lack of strict / any usage
- No certification language

Fail if:

- Ignores tsconfig entirely

Grounding: the finding must reference the supplied code (e.g. `"strict": false` in `tsconfig.json` and the `any` usage in `util.ts`) with file/line or identifier; a generic statement of the category without citing the snippet does not pass.
