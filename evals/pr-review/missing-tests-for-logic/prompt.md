---
name: pr-review-missing-tests-for-logic
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Pre-submit review. Diff adds a new function `calculate_discount(price,
customer_tier)` with non-trivial branching (tier maps to percentages,
edge cases for unknown tier). No test files are in the changed set. Repo
normally keeps tests under `tests/`. User asks for a PR readiness check.
