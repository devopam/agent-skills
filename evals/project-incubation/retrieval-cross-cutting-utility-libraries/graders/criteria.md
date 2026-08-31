# Grading criteria: retrieval — Cross-Cutting Utility Libraries

Tests whether `project-incubation` reads and applies
`references/cross-cutting-utility-libraries.md` at Phase 6, **in addition
to** the category-specific doc — this scenario (a Backend & API Services
project with a retry need and a variable-sized report-processing need)
deliberately straddles two of that doc's domains (retry & resilience,
structured/tabular data) that don't belong to Backend & API Services'
own preferred-libraries doc at all. It also tests the doc's merit-first
framing: whether the assistant justifies its picks by functional/
architectural reasoning rather than popularity signals.

## Must show

- Selects **Backend & API Services** as the primary category (a REST API
  service, not primarily a data platform).
- Reads `references/cross-cutting-utility-libraries.md` in addition to
  the Backend & API Services docs, and surfaces guidance from it that
  isn't in the category doc itself (retry/resilience and tabular-data
  domains).
- Recommends **tenacity** for the retry logic, with the reasoning
  grounded in its jitter support and composable stop/retry predicates
  (or equivalent functional reasoning) — not "because it's more popular"
  or "because it has more downloads/stars" as the stated justification.
- For the report-processing step, gives workload-shape-aware guidance
  that names the actual mechanism, not just a library name — e.g. pandas
  is fine for the smaller end of the stated range, but flags that a
  multi-GB file justifies **Polars** specifically because of its
  lazy/streaming query engine and multi-threaded execution (or makes an
  equivalent architecturally-grounded case for a different tool) — not a
  recommendation justified by download counts.
- Does not present popularity/download/star counts as the deciding
  factor for either recommendation, even if it mentions them as
  supporting context.

## Should not show

- Recommending `backoff` as the default retry library (it should be
  named only, if at all, as the archived predecessor tenacity has
  superseded on functional grounds).
- Justifying a library choice primarily with "X has more downloads/stars
  than Y" reasoning, rather than a functional/architectural reason.
- Treating pandas as the only option for the report-processing step
  without any acknowledgment that a large-file case might warrant a
  different tool, given the prompt explicitly describes a variable,
  potentially multi-GB file size.
- Skipping the cross-cutting doc entirely and answering only from
  general knowledge or the category-specific doc.
