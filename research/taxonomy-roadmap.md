# Taxonomy Roadmap

Tracks stack categories beyond the original v1 scope (5 categories + the
software/non-software fork, see `skill-flow-decisions.md` #3). These were
confirmed as worth adding, deferred until v1 was researched, authored, and
stable. **Developer Tooling & Libraries (item #4 below) was promoted to
`project-incubation`'s 6th stack category on 2026-08-31**,
**Infrastructure & Platform Engineering (item #1) was promoted to its
7th on the same date**, **ML / AI Model Development (item #2) was
promoted to its 8th, also 2026-08-31**, and **MLOps / ML Platform
Engineering (item #3) was promoted to its 9th, also 2026-08-31** — see
`research/stacks/{developer-tooling-libraries,infrastructure-platform-
engineering,ml-model-development,mlops-platform-engineering}/` and
`skills/project-incubation/references/{stacks,preferred-libraries}/
{developer-tooling-libraries,infrastructure-platform-engineering,
ml-model-development,mlops-platform-engineering}.md`; all four entries
below are kept for history, not still pending. Only 1 category (Frontend
/ Client Applications) remains not yet researched or authored.

## Why these emerged

While researching Agentic & MCP Platforms (Checkpoint B), its own
`libraries.md` baseline explicitly scoped OUT "fine-tuning, RAG-corpus
construction, training infrastructure" as belonging elsewhere — but no
current category actually claims it. That gap prompted a broader look at
what other common IT-heavy project archetypes the current taxonomy doesn't
cleanly cover.

## Roadmap categories (confirmed 2026-08-19, not yet researched)

1. **Infrastructure & Platform Engineering** *(promoted 2026-08-31 — no
   longer pending, kept here for history)* — IaC (Terraform, Pulumi,
   CloudFormation), Kubernetes/container orchestration, CI/CD platform
   tooling, internal developer platforms. Distinct concerns: idempotency,
   drift detection, blast-radius limiting, state management — not covered
   by any current category.

2. **ML / AI Model Development** *(promoted 2026-08-31 — no longer
   pending, kept here for history)* — training, fine-tuning, experiment
   tracking, model evaluation. Data-science/research-heavy, distinct from
   Data & Analytics Platforms (which leans BI/reporting/analytics-consumer
   facing) and from Agentic & MCP Platforms (serving/orchestration, not
   model-building) — this was the specific gap that surfaced the roadmap
   need. RAG-corpus construction, the other original gap this roadmap's
   "Why these emerged" section named, was resolved during this category's
   own research to belong to Agentic & MCP Platforms instead — assembling
   a retrieval corpus produces no trained artifact.

3. **MLOps / ML Platform Engineering** *(promoted 2026-08-31 — no longer
   pending, kept here for history)* — the operational discipline once a
   model exists: model registries, feature stores, serving infrastructure,
   drift monitoring, retraining triggers, canary rollouts for models.
   Related to both #1 (Infrastructure & Platform Engineering, generically)
   and #2 (ML / AI Model Development, the artifact being operated) but with
   its own concern set. **Separate-vs-merge question resolved 2026-08-31,
   now that #1 and #2 are both drafted**: stays its own category, not
   merged into either. It owns genuinely distinct concerns neither shipped
   category claims — feature stores (a shared training/serving feature
   layer, not IaC-shaped or training-pipeline-shaped); *model* drift
   monitoring (a statistical data/concept-drift concern, a different
   meaning of "drift" than Infrastructure & Platform Engineering's own
   IaC-config-drift, worth the same same-word-different-meaning precision
   that doc already gives "idempotency"); production model-registry
   promotion gates (distinct from ML/AI Model Development's own
   artifact-storage-stage registry framing); and canary/rollback triggers
   keyed on model-quality/drift signals specifically, layered on top of
   (not duplicating) Infrastructure & Platform Engineering's own
   progressive-delivery mechanics (Argo Rollouts/Flagger).

4. **Developer Tooling & Libraries** *(promoted 2026-08-31 — no longer
   pending, kept here for history)* — SDKs, CLI tools, publishable
   packages/libraries consumed by other developers. Distinct concerns from
   building an application: semver discipline, API stability/backward
   compatibility, packaging/publishing (PyPI/npm/crates.io/etc.),
   docs-as-product. Notably self-referential: this very repo
   (`agent-skills`) and MCPg's PyPI package are both this category.

5. **Frontend / Client Applications** — web SPAs, mobile apps, desktop
   apps. Currently implicitly folded into Business Applications, but a pure
   client app with no owned backend has different structural needs (state
   management, offline/sync, app-store distribution, no server-side
   architecture-template question to answer).

## Sequencing

Not committed to a strict order yet — revisit prioritization once v1 (the
current 5 categories + non-software fork) is authored, validated, and in
real use. Adding a category is a `references/stacks/<name>.md` +
`references/preferred-libraries/<name>.md` pair plus a taxonomy-table
update in `SKILL.md`, following the same research-baseline-then-author
workflow documented in `CONTRIBUTING.md`.
