# Grading criteria: retrieval — Backend & API Services

Tests whether `project-incubation` picks the right category for a
service-with-third-party-consumers project and applies the versioning
decision rule correctly — this scenario is specifically designed to
trigger the "broad third-party population" branch, not the default one.

## Must show

- Selects **Backend & API Services** as the category.
- Applies the consumer-population versioning decision rule and lands on
  the correct branch for THIS scenario: a broad, uncoordinated
  third-party/partner population → recommends a Stripe-style per-client
  version-pinning approach (or explicitly reasons through why that fits
  here), not the "evolve in place" default meant for a small number of
  first-party clients.
- Names RFC 9457 (or discusses error-response design) as part of the
  guidance if the conversation reaches that depth — and if it does, does
  NOT cite the obsolete RFC 7807.
- Recommends Envoy Gateway as the named default gateway if gateway
  architecture comes up, not an unopinionated list with no default.

## Should not show

- Defaulting to the "evolve in place, skip versioning" branch — that's
  the wrong decision-rule branch for a broad third-party consumer
  population, and picking it would indicate the skill isn't actually
  applying the decision rule, just pattern-matching on "API."
- Citing RFC 7807 as current (it's obsoleted by RFC 9457).
- Confusing this with Agentic & MCP Platforms or Business Applications.
