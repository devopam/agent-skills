---
type: llm
weight: 1
---

# Grading criteria: merge-ready-clean

Pass if the response:

1. Gives a verdict of Ready, or Ready with nits only.
2. Acknowledges that the change has a regression test, an updated CHANGELOG entry, and pre-commit hooks.
3. Raises no Critical or Important findings. Minor tips and clearly non-blocking repo-level notes are fine.

Fail if it blocks the PR or demands unrelated refactors or new CI.
