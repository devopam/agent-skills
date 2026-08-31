# Taxonomy Roadmap

Tracks stack categories beyond the original v1 scope (5 categories + the
software/non-software fork, see `skill-flow-decisions.md` #3). These were
confirmed as worth adding, deferred until v1 was researched, authored, and
stable. **All 5 were promoted to `project-incubation` stack categories on
2026-08-31**: Developer Tooling & Libraries (6th), Infrastructure &
Platform Engineering (7th), ML / AI Model Development (8th), MLOps / ML
Platform Engineering (9th), and Frontend / Client Applications (10th and
final) — see
`research/stacks/{developer-tooling-libraries,infrastructure-platform-
engineering,ml-model-development,mlops-platform-engineering,
frontend-client-applications}/` and
`skills/project-incubation/references/{stacks,preferred-libraries}/
{developer-tooling-libraries,infrastructure-platform-engineering,
ml-model-development,mlops-platform-engineering,
frontend-client-applications}.md`. **This roadmap's original scope is now
fully shipped** — all 5 entries below are kept for history and
provenance, not still pending. `project-incubation` now covers 10 stack
categories total (5 from v1 + these 5). Any further categories would be a
new roadmap decision, not a continuation of this one.

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

5. **Frontend / Client Applications** *(promoted 2026-08-31 — no longer
   pending, kept here for history)* — web SPAs, mobile apps, desktop
   apps. Was implicitly folded into Business Applications; the promoted
   category's own research drew that boundary precisely on **backend
   ownership**, not frontend tech-stack shape — a project whose own team
   owns and deploys a backend is Business Applications even when its
   frontend half is architecturally identical to a "pure" client; a
   project with no owned backend at all (calling only a third-party API
   or BaaS) is this category. Distinct structural needs confirmed during
   research: state management with local storage as the *primary* data
   layer (not a cache), offline/sync conflict resolution (LWW/CRDTs),
   app-store distribution mechanics, and no server-side
   architecture-template question to answer at all — though hexagonal/
   ports-and-adapters does have a genuine client-side analogue, per
   Flutter's and Android's own official architecture guidance.

## Sequencing

All 5 categories above were researched and authored in a single sweep on
2026-08-31, in the order listed (items #1–#5 correspond to stack
categories #7, #8, #9, #6, and #10 respectively — see each item's own
promotion note for its exact category number). This roadmap's own
"not committed to a strict order yet" note from its original 2026-08-19
drafting is now moot: the full backlog shipped together rather than in a
staggered sequence. Adding a *future* category beyond this roadmap's
original 5 would follow the same `references/stacks/<name>.md` +
`references/preferred-libraries/<name>.md` pair plus a taxonomy-table
update in `SKILL.md`, per the same research-baseline-then-author workflow
documented in `CONTRIBUTING.md` — but would be a new roadmap decision,
not a continuation of this one.
