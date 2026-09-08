# Grading criteria: blast-radius-unfocused-diff

Pass if the response:

1. Explicitly calls out that the PR bundles several unrelated concerns
   (public API rename, unrelated CSS change, risky migration) and flags
   this as a hygiene/reviewability problem — recommends splitting into
   focused PRs rather than reviewing it as one coherent change.
2. Identifies the payments-module public API rename and the NOT NULL
   migration on a high-traffic table as high blast-radius items — per
   change-risk-and-tests.md's "touches auth, payments, migrations...
   public API" criteria — and escalates them to at least Important,
   independent of whether local gates/tests pass.
3. Does not let "local hooks pass and tests exist for the migration"
   alone earn a Ready verdict — the blast-radius and focus concerns
   stand on their own regardless of gate status.
4. Verdict is Not ready or Ready with nits at most, not a clean Ready.

Fail if the response treats this as a normal single-concern PR, ignores
the unfocused-diff problem, or reaches Ready solely because gates pass.
