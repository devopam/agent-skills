# Grading criteria: gap — the absence-reporting mechanic

Tests `python-code-review`'s most distinctive mechanic, unique to the
**Scalability & Resilience** domain: reporting the ABSENCE of a resilience
pattern as a real finding, not just flagging what's actively broken. The
prompt explicitly states nothing is "technically broken" — the review
must not let that framing talk it out of flagging real gaps.

## Must show

- Flags the **absence of a circuit breaker** around both external calls
  (fraud-scoring API, banking partner API) as a finding — at
  enterprise tier, with two external dependencies on the critical path
  of every payment, this is exactly the shape the domain's own
  Not-Implemented mechanic exists for.
- Flags the **absence of retry-with-backoff** on both external calls as a
  separate finding.
- Flags **no timeout configured on either `requests.post` call** — this is
  a Critical-severity finding per the domain's own sourced guidance (an
  unbounded external call is the mechanism by which one dependency's
  slowness cascades into total unresponsiveness) — `requests` has no
  default timeout, so this is a real, immediate defect, not a
  hypothetical.
- At least one finding is explicitly framed as reporting an *absent*
  pattern rather than a bug in existing code — language like "not
  implemented," "missing," or equivalent, tied to the tier and the
  concrete risk (a downstream outage in either API cascades into this
  service being fully unresponsive).
- These findings land in the **Scalability & Resilience** domain's
  scorecard (the timeout finding may also reasonably cite Concurrency/
  Performance if the reviewer cross-references, but Scalability &
  Resilience should own at least the circuit-breaker and retry findings).

## Should not show

- Concluding the code is fine because "nothing is technically broken" —
  this is the specific failure mode the prompt is designed to bait, and
  missing all three absence-findings because of it is a clear failure.
- Only flagging the timeout issue and missing the circuit-breaker/retry
  absence findings, or vice versa.
- Treating this project as anything other than enterprise-tier scope for
  these checks — the prompt states enterprise tier explicitly.
