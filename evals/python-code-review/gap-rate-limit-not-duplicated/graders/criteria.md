# Grading criteria: gap — rate limiting is owned once, not duplicated

Tests a domain-boundary decision made during authoring: rate limiting /
brute-force throttling is owned by the **Security** domain (its reference
doc's "Rate limiting & brute-force defense" section), and the
**Scalability & Resilience** domain's Graceful Degradation section
cross-references Security rather than re-deriving its own separate
finding for the same gap. A missing-rate-limit login endpoint should
produce ONE finding, attributed to Security, not two near-duplicate
findings split across domains.

## Must show

- Flags the missing rate limiting / brute-force throttling on `/login` as
  a finding — this is a real, sourced, tier-applicable (web) gap: an
  unthrottled login endpoint is a credential-stuffing / brute-force
  vector.
- Attributes this finding to the **Security** domain's scorecard entry.
- Does NOT also produce a separate, independent Scalability & Resilience
  finding re-deriving the same missing-rate-limiting gap — Scalability &
  Resilience may mention it only as a cross-reference to the Security
  finding (e.g., "see Security: rate limiting"), not as its own scored,
  independent finding duplicating the same content.

## Should not show

- Two independently-scored findings for the same underlying gap, one
  under Security and one under Scalability & Resilience, each counted
  separately toward their domain's score — this is the specific
  double-counting failure this case tests for.
- Missing the finding entirely because of confusion over which domain
  owns it — some finding must show up, and it must be attributable to
  Security.
- Placing the finding under an unrelated domain (e.g., Performance,
  Architecture) instead of Security.
