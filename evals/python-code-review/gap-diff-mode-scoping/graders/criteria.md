---
type: llm
weight: 1
---

# Grading criteria: gap — diff-mode scope

Pass if the response:

1. States that this is a diff-mode review against `main`, not a full-project review.
2. Reviews only `app/utils/formatting.py` (the changed file).
3. Does not report findings in the other files, which are unrelated and out of scope.

Fail if it reviews the whole repo, or never acknowledges the diff-mode scope.
