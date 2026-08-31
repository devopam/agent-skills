# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- `project-incubation` skill: `references/preferred-libraries/
  infrastructure-platform-engineering.md` was missing its Progressive
  Delivery / Canary Controllers section — the companion stack doc names
  Flagger and Argo Rollouts as concept anchors and explicitly defers their
  license/adoption comparison to this file, but that table was never
  actually added at initial publish. Added now (Flagger, Argo Rollouts,
  and Kayenta flagged as archived/do-not-adopt), discovered while
  researching the sibling MLOps / ML Platform Engineering category.

### Added
- `project-incubation` skill: **ML / AI Model Development**, an 8th stack
  category (training, fine-tuning, experiment tracking, model evaluation —
  the model-*building* side of the ML lifecycle) — the third category
  promoted from `research/taxonomy-roadmap.md`'s v2 backlog. Two authored
  reference docs: `references/stacks/ml-model-development.md` (pipeline/DAG
  specialization with checkpointing and distributed-training coordination
  as the distinctive concerns; experiment tracking's architectural role;
  the fine-tuning/full-training/PEFT decision axis anchored on the
  original LoRA paper's own reported figures; data versioning via content-
  hash fingerprinting; model evaluation methodology including benchmark
  contamination as a real documented failure mode and Hugging Face's own
  Open LLM Leaderboard retirement as a first-party cautionary precedent; a
  NeurIPS-checklist-anchored reproducibility section; a compute/
  infrastructure decision table; and model cards anchored on Mitchell et
  al.'s original paper) and
  `references/preferred-libraries/ml-model-development.md` (deep learning
  frameworks, experiment tracking, fine-tuning/PEFT tooling, data
  versioning, ML-specific pipeline orchestration, model evaluation/
  benchmarking tooling, Hugging Face Hub tooling, and compute providers for
  training). Two category-boundary questions were resolved directly during
  research review rather than left open: RAG-corpus construction belongs to
  Agentic & MCP Platforms, not this category, since assembling a retrieval
  corpus produces no trained artifact; and the MLOps boundary is confirmed
  at "producing/evaluating a trained artifact" (this category) versus
  "registration and serving onward" (the still-pending MLOps category). A
  genuinely clean "no local precedent" finding is documented throughout: no
  notebook, training script, tracker config, or model-weight file exists
  anywhere on this machine, and `ubi-csr-tmf`'s `agents/`-named component
  was directly confirmed to be an inference-time LLM-agent application, not
  training code.
- `research/stacks/ml-model-development/` provenance record for both
  baselines, including a follow-up direct-fetch verification pass
  (Mitchell et al.'s own paper, Kubeflow Pipelines' own docs) and a fresh
  governance-event finding made during authoring: lakeFS's parent company
  Treeverse acquired the DVC open-source project from Iterative on
  2025-11-18, confirmed independently via GitHub's own repository-transfer
  redirect.
- `project-incubation` skill: **Infrastructure & Platform Engineering**, a
  7th stack category (IaC provisioning, Kubernetes/container
  orchestration, CI/CD at the platform layer, internal developer
  platforms) — the second category promoted from
  `research/taxonomy-roadmap.md`'s v2 backlog. Two authored reference
  docs: `references/stacks/infrastructure-platform-engineering.md`
  (IaC tool selection with **OpenTofu named as the default** over the now
  BSL-licensed/IBM-owned Terraform — while keeping Terraform fully
  legitimate for an existing HCP/Sentinel investment; state management,
  drift detection, blast-radius/policy-as-code gating; a new secrets
  management section naming the identical BSL-vs-open-fork split recurring
  for HashiCorp Vault vs. its own fork OpenBao; a Kubernetes-vs-simpler-
  targets decision rule; CI/CD platform-layer concerns; internal developer
  platforms; and how this category owns "infra-as-a-deployment-target," a
  cross-cutting specialization no other category claims) and
  `references/preferred-libraries/infrastructure-platform-engineering.md`
  (IaC/state/policy/secrets/Kubernetes/registry/IDP/CI-scanning tooling,
  including corrected facts found only by direct-fetching each tool's own
  source — CDKTF's archival, tfsec's deprecation into Trivy, Lens's death
  in favor of the FreeLens fork, and a real pricing correction: Spacelift's
  actual lowest paid tier is $20,000/year, not the initial research pass's
  ~$250/month estimate). Real, partial local precedent throughout both
  docs: a sibling repo on the same machine (`ubi-csr-tmf`) has genuine
  Helm charts and OIDC-based EKS deploy workflows, but zero IaC files —
  its IAM role is literally named `GitHubActionsTerraformRole`, implying
  provisioning happens in a separate repo not present on this machine —
  plus a `release: blue-green` Helm label with no actual blue-green
  mechanism behind it, a genuinely useful cautionary example.
- `research/stacks/infrastructure-platform-engineering/` provenance record
  for both baselines, including a follow-up verification pass (OpenTofu's
  S3-lockfile parity confirmed via its own release notes, HCP Terraform's
  pricing confirmed via HashiCorp's own pricing page, a correction that
  Flagger and Argo Rollouts are NOT independently CNCF Graduated — they
  inherit maturity through their parent projects) and a user-requested
  scope expansion (a full secrets-management subsection) before authoring.
- `project-incubation` skill: **Developer Tooling & Libraries**, a 6th
  stack category (SDKs, CLI tools, publishable packages/libraries
  consumed by other developers) — the first category promoted from
  `research/taxonomy-roadmap.md`'s v2 backlog now that v1's original 5
  categories are stable and in use. Two authored reference docs:
  `references/stacks/developer-tooling-libraries.md` (semver discipline
  across Python/npm/Rust, API-stability marking including a brand-new
  PEP 844, deprecation mechanics, the cross-ecosystem shift to OIDC
  trusted publishing, docs-as-product, release automation with a named
  default per repo shape, module-boundary/dependency-minimalism design,
  CLI-UX conventions, and LSP/IDE-tooling architecture) and
  `references/preferred-libraries/developer-tooling-libraries.md`
  (build backends, publishing mechanics, release-automation tooling,
  docs generators, API-stability/compat-checking tooling, CLI and
  LSP-server framework libraries, cross-version testing, changelog
  tooling, and Claude Code plugins/MCP registries as a distribution
  channel). Notably self-referential: this repo's own
  `.claude-plugin/plugin.json`-based distribution (no `pyproject.toml`/
  `package.json`) is real, directly-inspected local precedent cited
  throughout both docs.
- `research/stacks/developer-tooling-libraries/` provenance record for
  both baselines, including a follow-up direct-fetch verification pass
  (PEP 8/387/702, crates.io's Trusted Publishing rollout) and a
  user-requested scope expansion (CLI-UX and LSP/IDE-tooling
  subsections, a named release-automation default) before authoring.
- `python-code-review` skill: `SKILL.md` (portable sequential-review
  router — no subagent dispatch, no host-specific slash command) + 11
  authored reference docs + 2 assets (`report-template.md`,
  `review-config-template.toml`). A portable rebuild of an existing
  Claude-Code-native tool (`python-code-review-skill-v1.1.tgz`), not a
  from-scratch build — every domain was verified/expanded against
  current sources, not just ported.
- 11 review domains: the original tool's 9 (Standards Compliance, Code
  Quality, Security, Performance, Idioms & Patterns, Architecture,
  Observability, Scalability & Resilience, and a newly-added Testing
  domain) plus 2 real gaps found by a dedicated domain-scoping research
  pass (Dependency & Supply Chain Security, Concurrency & Async
  Correctness) — see `research/python-code-review-domain-scoping.md`.
- `research/python-code-review/` provenance record for all 11 domain
  baselines, plus the original tool's extracted source preserved at
  `research/python-code-review/original-tool/` for reference.
- `project-incubation` skill, v1 complete: `SKILL.md` (inception + audit
  modes, a software/non-software top-level fork, category selection for
  5 stack archetypes), 13 authored reference docs (3 cross-cutting +
  5 stack categories × 2), and 3 assets (`adr-template.md`,
  `baseline-template.md`, `license-guide.md`).
- 5 stack categories: Data & Analytics Platforms, Business Applications,
  Integration & Event-Driven Systems, Backend & API Services, Agentic &
  MCP Platforms. 5 more confirmed for later addition — see
  `research/taxonomy-roadmap.md`.
- `evals/` suite: 5 retrieval scenarios (one per category) + 3 gap
  scenarios, hand-authored against the documented eval format (not yet
  executed — `claude plugin eval` requires early-access enrollment not
  available at authoring time; see `evals/README.md`).
- `research/` provenance record for all 13 baseline areas, kept
  indefinitely per this repo's retention policy (see `CONTRIBUTING.md`).

### Notes
- Every recommendation in the shipped reference docs was verified by
  direct fetch (GitHub API, PyPI, official docs) at authoring time, not
  carried from secondary sources — this surfaced and corrected several
  real errors along the way, including a mis-cited LangGraph star count,
  an incorrect Arize Phoenix license, and a disconfirmed Kong
  licensing-change claim.
- `python-code-review`'s research surfaced its own real corrections: the
  OWASP Top 10 moved 2021→2025 and OWASP's LLM Top 10 moved to a 2026
  edition published weeks before this research; a Django 6.1
  deprecation and a deprecated Uvicorn import path the original tool's
  content predated; and a precise resolution of Python's free-threading
  rollout status (PEP 703 vs. PEP 779's phased plan) that a naive read
  of PEP 703 alone gets wrong.
