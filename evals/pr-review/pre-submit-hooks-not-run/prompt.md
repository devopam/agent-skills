---
name: pr-review-pre-submit-hooks-not-run
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the pr-review skill in pre-submit mode. The repo has
`.pre-commit-config.yaml` with ruff and trailing-whitespace hooks. The
user's branch differs from main in `src/app/service.py` (formatting
issues visible: long lines, trailing spaces). User says: "I'm about to
open a PR — anything I should fix first?" They have not mentioned running
pre-commit.

Review for pre-submit readiness.
