# Evals: pr-review

Hand-authored cases for the `pr-review` skill (prompt.md + graders/criteria.md).
Not executed via `claude plugin eval` until early-access enrollment allows
(see repo `evals/README.md`).

| Case | Intent |
|---|---|
| `pre-submit-hooks-not-run` | Detect configured hooks not run before PR |
| `missing-tests-for-logic` | Non-trivial logic without tests |
| `changelog-gap-user-facing` | CLI/user-facing change without changelog |
| `merge-ready-clean` | Clean change -> Ready |
| `secret-in-diff` | Hardcoded secret -> Critical / Not ready |
