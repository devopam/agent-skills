# Grading criteria: retrieval — Data & Analytics Platforms

Tests whether `project-incubation` picks the right category for an
analytics-consumer-facing pipeline and applies the batch-vs-streaming
decision rule correctly — the scenario explicitly states a ~24-hour
latency tolerance, which should land on "batch," not streaming.

## Must show

- Selects **Data & Analytics Platforms** as the category — not Integration
  & Event-Driven Systems (a plausible but wrong pick, since this is
  moving data between systems on the surface, but the destination is a
  warehouse for analytical query, which is this category's territory per
  the destination-based boundary rule).
- Recommends **batch** processing, reasoning from the stated latency
  tolerance (daily is fine) rather than defaulting to streaming because
  the sources are APIs.
- Recommends **ELT** over ETL as the default pattern (load raw, transform
  in the warehouse) unless a stated constraint argues otherwise.
- If library recommendations come up: pandas as the dataframe default
  (not polars, since nothing in the scenario indicates a memory/CPU
  pressure signal that would justify switching) and dbt for transformation.

## Should not show

- Recommending a streaming pipeline or message-broker architecture for a
  scenario that explicitly has no real-time requirement.
- Routing this to Integration & Event-Driven Systems.
- Recommending polars over pandas with no stated reason (dataset size,
  CPU-bound transform) that would justify the switch per the decision
  rule.
