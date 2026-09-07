Pre-submit review. Diff adds a new function `calculate_discount(price,
customer_tier)` with non-trivial branching (tier maps to percentages,
edge cases for unknown tier). No test files are in the changed set. Repo
normally keeps tests under `tests/`. User asks for a PR readiness check.
