# Grading criteria: critical-workload-not-implemented

Pass if the response:

1. Surfaces the RLS/`BYPASSRLS` finding as **Critical** (open security hole
   on sensitive tenant data) and places it first in the severity-ordered
   findings list.
2. Overall verdict is **FAIL** (any Critical finding fails the review,
   per SKILL.md's verdict rule) — not PASS or CONDITIONAL PASS.
3. Scores Workload & query performance as **Not Implemented** (or excludes
   it from the composite with that label) because `pg_stat_statements` is
   unavailable — does not award it a high score for having "no hotspots."
4. Does not invent hot queries or a workload score in the absence of
   `pg_stat_statements`.

Fail if the Critical finding is buried below Important/Minor items, if the
overall verdict is anything other than FAIL, or if Workload & query
performance is scored 9–10 despite the missing extension.
