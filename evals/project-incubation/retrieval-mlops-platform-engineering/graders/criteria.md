# Grading criteria: retrieval — MLOps / ML Platform Engineering

Tests whether `project-incubation` picks the right category for an
already-trained, already-serving model's operational concerns (not ML/AI
Model Development, which owns the model-*building* side that this
scenario explicitly says is already done) and correctly identifies
**concept drift** specifically — the prompt's "fraudsters keep changing
their behavior to evade it" line is a direct, deliberate paraphrase of
this skill's own fraud-detection illustration for concept drift (as
opposed to data drift).

## Must show

- Selects **MLOps / ML Platform Engineering** as the category — the model
  is already trained and in production; this is the operate-and-monitor
  side, not model-building (ML/AI Model Development) and not the generic
  IaC/Kubernetes layer (Infrastructure & Platform Engineering).
- Identifies the staleness mechanism as **concept drift** (the
  input→output relationship itself has changed, because fraudsters adapt
  specifically to evade the model) — not just "data drift" or a generic
  "model drift" without the distinction, since the scenario is a textbook
  concept-drift case with no signal of a change in input distributions.
- Recommends **shadow deployment before canary** (or explains the
  shadow-then-canary sequence) for testing a new candidate model safely —
  the scenario's "safely test a new candidate model before it fully takes
  over" framing is exactly what shadow deployment (full duplicate traffic,
  predictions never served) is for, as the safer first validation pass.
- Surfaces the **retraining-trigger taxonomy** for "decide when to kick
  off a retrain automatically" — at minimum naming that this should be an
  event (a drift/performance signal crossing a threshold), not a manual
  decision, in a mature setup.

## Should not show

- Treating this as ML/AI Model Development (the model already exists and
  is deployed — this is not a training-from-scratch or fine-tuning
  scenario).
- Confusing this category's model drift with Infrastructure & Platform
  Engineering's own IaC/config drift detection (`terraform plan`-style).
- Recommending canary deployment as the *first* validation step ahead of
  shadow deployment, or presenting them as interchangeable rather than
  sequential/complementary.
- Citing the AWS SageMaker Model Monitor reference-implementation
  thresholds (30% features drifted, 0.05 drifted-column share) as a
  universal industry standard rather than one vendor's own worked-example
  default.
