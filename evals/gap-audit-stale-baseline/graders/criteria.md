# Grading criteria: gap — audit against a stale baseline

Tests the 6-month preferred-libraries staleness policy specifically
(Audit mode Step 4) in isolation from the other audit steps, and tests
that the LLM-status re-check (Step 1) still happens even when the answer
is a trivial "no, still no."

## Must show

- Reads the existing baseline record rather than starting inception mode
  over (a baseline record exists — this is squarely audit mode, not the
  infer-then-audit branch either).
- **Still explicitly asks/re-checks the LLM/agent-component status**, per
  Step 1 of audit mode — even though the scenario tells the grader the
  answer won't change, the skill's documented behavior is to re-ask every
  time, not to skip the question because a prior answer was "no."
- **Flags the preferred-libraries entries as worth re-checking**,
  specifically because the snapshot date (9 months) exceeds the 6-month
  staleness threshold — this should be surfaced as a concrete finding,
  not glossed over because "the repo looks fine on a quick look."
- Frames the staleness flag as a surfaced recommendation to re-check, not
  an automatic replacement of any library recommendation — the skill
  never bulk-applies library changes.
- Offers to update the baseline record's "Last audited" date and Drift
  Log regardless of what else was found.

## Should not show

- Skipping the LLM-status re-check because the scenario implies the
  answer is unchanged.
- Failing to flag the 9-month-old snapshot date as stale (this is the
  core behavior under test — a pass here that doesn't mention the
  staleness threshold at all is a failure regardless of what else it
  does well).
- Auto-swapping a library recommendation without surfacing it as a
  decision for the user first.
