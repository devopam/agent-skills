# Grading criteria: retrieval — Integration & Event-Driven Systems

Tests whether `project-incubation` picks the right category for a
fan-out/pub-sub scenario and correctly identifies it as pub/sub (not
point-to-point) — "each of those needs to know independently" is the
specific signal that should trigger pub/sub, not a work-queue pattern.

## Must show

- Selects **Integration & Event-Driven Systems** as the category — not
  Backend & API Services (even though webhooks are mentioned, the core of
  this scenario is event fan-out between systems, which is this
  category's territory; Backend & API Services explicitly defers webhook
  delivery mechanics here).
- Identifies this as a **pub/sub** topology (multiple independent
  subscribers each need their own copy), not point-to-point — reasoning
  from "billing, shipping, and analytics independently" rather than
  defaulting to a generic "message queue" answer.
- If delivery semantics come up: recommends at-least-once delivery plus
  an idempotent consumer as the practical default, not chasing exactly-once.
- If webhook design comes up: references Stripe-shape mechanics
  (signature verification, retry-with-backoff) rather than inventing an
  ad hoc scheme.

## Should not show

- Recommending a point-to-point work queue for a scenario that explicitly
  needs multiple independent consumers of the same event.
- Routing this to Backend & API Services as the primary category.
- Chasing exactly-once delivery as the default recommendation instead of
  idempotent-consumer-plus-at-least-once.
