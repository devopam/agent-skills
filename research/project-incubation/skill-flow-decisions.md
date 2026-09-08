# SKILL.md Flow Decisions

Running log of decisions about `project-incubation`'s *behavior* (Q&A flow,
routing logic) made during the research phase — as opposed to reference
*content* decisions, which live in each area's own baseline. Content
baselines get promoted into `references/*.md`; these flow decisions get
promoted directly into `SKILL.md` itself during Phase 2 authoring. This file
(like the rest of `research/`) stays in the repo as a provenance record —
`research/` is retained indefinitely, pruned only much later once the skill
has stabilized (see `CONTRIBUTING.md`). Do not lose these before SKILL.md
is written, even though the file itself won't be deleted immediately after.

## 1. LLM/agent-component detection (Checkpoint A, 2026-08-19)

Ask explicitly during inception ("does this project include an LLM or agent
component?"), captured in the baseline record. **Re-checked on every
audit-mode invocation, not just at inception.** If status changed since the
last baseline (either direction), flag the drift, update the baseline
record, and apply/retire the conditional LLM-specific principles section
(harness, model-switching, provenance, relevance+confidence) accordingly.

## 2. Architecture template output shape (Checkpoint A, 2026-08-19)

Compositional, with a primary pick — recommend one named pattern but
explicitly surface common overlays/combinations (e.g. "modular monolith,
with event-driven overlay for ingestion") rather than forcing a single
pure-pattern answer. The baseline record's "chosen template + reasoning"
field may record more than one composed element.

## 3a. Preferred-libraries staleness threshold (post-Checkpoint-D, 2026-08-19)

Every `preferred-libraries/*.md` entry carries a "last reviewed: YYYY-MM-DD"
date (established during the original portability/versioning decisions).
**New, concrete policy**: audit mode flags any entry whose "last reviewed"
date is **more than 6 months old** as "worth re-checking" — not a hard
block, a surfaced flag alongside the rest of the audit's gap report. Chosen
because Checkpoint D's research itself found real licensing/ownership
changes (dbt's Fusion-engine relicensing, Great Expectations' FICO
acquisition/Fivetran stewardship handoff, NATS's near-relicensing dispute,
Redpanda's BSL terms) landing within a single ~12-month window across just
one category's research pass — a 6-month audit cadence is calibrated to
that real observed churn rate, not a round-number default. Applies
uniformly across all preferred-libraries files, current and future
(including roadmap categories once researched).

## 3. Software vs. non-software top-level fork (post-Checkpoint-A, 2026-08-19)

**The gap:** all 5 stack categories (Data & Analytics Platforms, Business
Applications, Integration & Event-Driven Systems, Backend & API Services,
Agentic & MCP Platforms) assume a software/code project. A documentation,
research, knowledge-base, or dataset-only project doesn't fit any of them,
and forcing it through architecture-template selection or TDD/SDD guidance
would be a category error.

**Decision:** add a first inception question, asked *before* stack-category
selection: "is this primarily a software project, or documentation/
research/knowledge-base/dataset?" This is a **top-level fork in SKILL.md's
routing logic**, not a 6th stack category — no new `stack.md`/`libraries.md`
pair gets researched or authored for it. Instead:

- **Software path** (unchanged): proceeds through category selection →
  `references/stacks/<category>.md` → `references/architecture-templates.md`
  → full principles set (universal + conditional-if-applicable).
- **Non-software path**: skips category selection and
  `references/architecture-templates.md` entirely. Applies only the
  cross-cutting docs' items that are actually universal to *any* repository
  regardless of whether it produces code — concretely, from the three
  already-approved Checkpoint A baselines:
  - `project-structure.md`: root-level files (README/LICENSE/CONTRIBUTING/
    CHANGELOG), docs/ structure, governance (branch protection, PR review,
    LFS for large source documents/datasets) all still apply. `src/`,
    `scripts/` (executables), `tests/` framing does not, or applies loosely
    (e.g. "tests/" might become "validation/" for a dataset project — call
    this out explicitly during authoring rather than silently omitting).
  - `architecture-principles.md`: zero-hardcoding/config-driven, security-
    by-design, and maintainability/simplicity still apply in spirit
    (e.g. no hardcoded credentials in a scripts-adjacent tooling folder even
    in a docs repo). TDD, SDD, testability, scalability/reliability, and
    observability do **not** apply in their software sense and should be
    explicitly marked skipped for this path, not silently dropped (a docs
    project audited later shouldn't get flagged for "missing tests").
    LLM-specific principles (harness, provenance, relevance+confidence)
    **can** still apply to a non-software project if it has an LLM/agent
    component (e.g., a research pipeline that uses an LLM to synthesize
    findings) — the software/non-software fork and the
    LLM-component-detection question (#1 above) are independent axes, not
    mutually exclusive.
- **Cross-checkpoint conflict, resolved (2026-08-19)**: during Checkpoint D
  review, Data & Analytics Platforms and Integration & Event-Driven Systems
  each deferred deep streaming-engine coverage (Kafka Streams, Flink, Spark
  Structured Streaming) to the other — a genuine gap, not a
  default-resolvable overlap. Resolved: **Integration & Event-Driven
  Systems owns this topic** (stream-processing mechanics over a broker's
  event log are closer kin to that category's pub/sub, schema-evolution,
  and delivery-semantics content). Data & Analytics Platforms' stack.md
  keeps its existing brief mention and explicit deferral — now confirmed
  correct rather than provisional. Integration & Event-Driven Systems'
  stack.md/libraries.md should add streaming-engine coverage during Phase 2
  authoring — it wasn't researched at this depth during Checkpoint D
  itself, so this is authoring-time work, not yet baselined.

- **Authoring implication for Phase 2**: `SKILL.md`'s inception-mode
  Q&A phase needs an explicit applicability branch, and each promoted
  `references/*.md` file (project-structure.md, architecture-principles.md)
  should carry a per-item "applies to: software | non-software | both" tag
  so the skill can filter correctly — this is new authoring work, not just
  a content restatement of what Checkpoint A already approved.
