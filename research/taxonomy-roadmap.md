# Taxonomy Roadmap

Tracks stack categories beyond the original v1 scope (5 categories + the
software/non-software fork, see `skill-flow-decisions.md` #3). These were
confirmed as worth adding, deferred until v1 was researched, authored, and
stable. **Developer Tooling & Libraries (item #4 below) was promoted to
`project-incubation`'s 6th stack category on 2026-08-31**, and
**Infrastructure & Platform Engineering (item #1 below) was promoted to
its 7th on the same date** — see `research/stacks/{developer-tooling-
libraries,infrastructure-platform-engineering}/` and
`skills/project-incubation/references/{stacks,preferred-libraries}/
{developer-tooling-libraries,infrastructure-platform-engineering}.md`;
both entries below are kept for history, not still pending. The remaining
3 categories are not yet researched or authored.

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

2. **ML / AI Model Development** — training, fine-tuning, experiment
   tracking, model evaluation. Data-science/research-heavy, distinct from
   Data & Analytics Platforms (which leans BI/reporting/analytics-consumer
   facing) and from Agentic & MCP Platforms (serving/orchestration, not
   model-building) — this was the specific gap that surfaced the roadmap
   need.

3. **MLOps / ML Platform Engineering** — the operational discipline once a
   model exists: model registries, feature stores, serving infrastructure,
   drift monitoring, retraining triggers, canary rollouts for models.
   Related to both #1 (Infrastructure & Platform Engineering, generically)
   and #2 (ML / AI Model Development, the artifact being operated) but with
   its own concern set. **Open question for when this gets researched**:
   confirm whether it stays a separate category or merges into #1 or #2
   once real content is drafted and the overlap can be judged concretely —
   don't force a three-way split if two of these end up mostly the same
   guidance with different nouns.

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
