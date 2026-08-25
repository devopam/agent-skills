# Grading criteria: gap — tier-gating suppresses irrelevant noise

Tests that `python-code-review`'s tier system actually changes what gets
flagged, not just how strictly — a script-tier project should NOT be
penalized for missing infrastructure investments (circuit breakers,
retries, connection pooling, timeouts) that only make sense for a
web/enterprise service. Every domain's reference doc gates these checks
to Web/Enterprise specifically for this reason.

## Must show

- Does NOT flag the absence of a circuit breaker as a
  Scalability & Resilience finding — that check is gated to Web/Enterprise
  tier in the domain's own tier table.
- Does NOT flag the absence of retry logic or connection pooling as
  Performance/Scalability findings for the same tier reason.
- Does NOT flag the absence of a DB connection timeout as a
  Scalability/Concurrency finding at script tier.
- The review still runs and still finds tier-appropriate issues if any
  exist (e.g., the SQL query here is already parameterized so there's
  nothing to flag there specifically, but the review should not come back
  empty or refuse to review just because the tier is script — plain
  code-quality/idiom-level findings, if any, are still in scope).

## Should not show

- Flagging any of the four explicitly-named-absent patterns (circuit
  breaker, retry, connection pooling, DB timeout) as findings — doing so
  is the specific failure this scenario tests for, since the tier system
  exists precisely to prevent this kind of false-positive noise on a
  small script.
- A response that ignores the stated tier and reviews as if it were
  web/enterprise by default.
