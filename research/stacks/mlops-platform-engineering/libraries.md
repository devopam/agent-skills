# Baseline: MLOps / ML Platform Engineering — Preferred Libraries
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This is category #3 from `research/taxonomy-roadmap.md` — the operational
discipline once a model exists (registries, feature stores, serving,
drift monitoring, retraining triggers, model-quality-driven canary
rollouts), resolved 2026-08-19/2026-08-31 to stay its own category rather
than merge into Infrastructure & Platform Engineering (generic IaC/
Kubernetes/progressive-delivery, already shipped) or ML/AI Model
Development (model-*building*, already shipped). A parallel `stack.md` in
this same directory covers architecture/decision-criteria; this file
names specific tools/products with license and maintenance-signal detail
only, matching this repo's `libraries.md` convention.

**Four genuinely fresh events landed inside or immediately before this
snapshot window and are load-bearing findings, not background color**:
Dynatrace signed a definitive agreement to acquire Arize for **$915M,
announced 2026-08-13** (18 days before this pass, deal not yet closed);
BentoML was **acquired by Modular on 2026-02-10** (stays Apache-2.0 per
Modular's own announcement); Tecton (Feast's original commercial steward)
was **acquired by Databricks in August 2025**, with its capabilities now
folding into Databricks Feature Store rather than remaining a standalone
product; and WhyLabs was **acquired by Apple in January 2025**, after
which its entire commercial platform was discontinued and open-sourced —
but the resulting repos have seen essentially no commits since. A fifth,
carried-forward-but-reconfirmed fact: Seldon Core (and, newly confirmed
this pass, **Alibi Detect too**) moved to the Business Source License 1.1
in January 2024, the same BSL pattern this repo's Infrastructure &
Platform Engineering baseline already found for Terraform and Vault.

## Local precedent — none found, confirmed by search

Checked directly this pass, matching ml-model-development's own "none
found" convention rather than forcing a weak analogy:

- `find ubi-csr-tmf agent-skills -iname "*feature_store*" -o -iname
  "*feast*" -o -iname "*evidently*" -o -iname "*nannyml*" -o -iname
  "*seldon*" -o -iname "*kserve*" -o -iname "*bentoml*" -o -iname
  "*triton*" -o -iname "*drift*" -o -iname "*model_registry*" -o -iname
  "*canary*"` — **zero results**.
- Direct read of `ubi-csr-tmf/aws/container/backend/app/requirements.txt`
  and `ubi-csr-tmf/aws/container/agents/requirements.txt` in full, plus a
  grep of `frontend/package.json` for `feast|evidently|nannyml|
  alibi-detect|whylogs|seldon|kserve|bentoml|triton|arize|fiddler|mlflow`
  — **zero hits**. The backend's dependency list is a genuine production
  FastAPI/Flask document-processing service (PDF/DOCX handling, SAP HANA/
  Oracle/Postgres drivers, boto3, langchain) with no ML-serving,
  feature-store, or model-monitoring library anywhere in it; the agents
  service depends on `strands-agents` (an LLM-agent SDK, already the
  concern of Agentic & MCP Platforms) not a trained-model-serving stack.

This confirms the same finding the ML/AI Model Development baseline
already made for the model-*building* side: this local codebase runs an
LLM-agent *application* against a hosted model API, not a trained-model
production-operations stack. Every entry below is externally sourced,
not cross-checked against a local production choice.

## Ecosystem choice

Mostly Python, but with a real second surface this category's siblings
don't share to the same degree: **Kubernetes CRDs/YAML** as the actual
deployment unit for two of the four serving frameworks below (KServe's
`InferenceService`, Seldon Core's `SeldonDeployment`/pipeline resources) —
closer in shape to Infrastructure & Platform Engineering's Helm/Kustomize
surface than to a pip-installed library. Because of this split, tables
below use **GitHub stars/forks/open-issues/`pushed_at`/latest-release**
(direct `gh api repos/<owner>/<repo>` fetches) as the primary
adoption-signal shape, supplemented by **CNCF/LF-foundation maturity
level** and **commercial-tier/licensing-trap flags** where those are the
more load-bearing fact — as they are for KServe, Feast, Seldon Core, and
Alibi Detect specifically.

## In scope

### Production model registries — impact: high — depth: table + promotion-gate framing

**Scope boundary, per this category's explicit handoff from ML/AI Model
Development**: that baseline named MLflow's Model Registry only at the
model-development-artifact-storage level (uploading/versioning a
freshly-trained checkpoint) and explicitly deferred the
production-promotion-gate angle to this pass. Re-examined fresh here.

**MLflow's stage-based lifecycle is deprecated, verified via MLflow's own
current docs rather than assumed from older tutorials**: the classic
four-stage model (`None`→`Staging`→`Production`→`Archived`) is marked
deprecated and slated for removal in a future major release. It has been
replaced by **model version tags and aliases** — a more flexible labeling
system where, e.g., a `champion` alias can be reassigned to a new model
version to signal a promotion, without the rigid single-path stage
machine. Critically for the promotion-gate use case this category cares
about, **MLflow now ships first-class webhooks**: registering a model,
creating a new version, or reassigning a tag/alias can fire an HTTP POST
to a configured endpoint, enabling a stage-transition (or alias
reassignment) to trigger a CI/CD deployment pipeline with a human-approval
gate in front of it — a real, current promotion-gate mechanism, not a
gap this baseline has to route around.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **MLflow Model Registry** (`mlflow/mlflow`) — **default** | Production promotion gating via aliases/tags (not the deprecated stage model) plus webhook-driven CI/CD triggering, layered on the same MLflow instance a team already uses for experiment tracking | Apache-2.0, Linux Foundation top-level project | The only registry option in this table with genuine vendor-neutral governance, a real webhook-based promotion-gate mechanism, and zero incremental tooling cost for a team already on MLflow for experiment tracking | 2026-08-31 | Direct GitHub fetch: 27,747 stars, 6,236 forks, 2,057 open issues, pushed 2026-08-31 (very active); latest release `v3.15.2`, published 2026-08-26 |
| **Comet Model Registry** (part of Comet ML's commercial platform) | A governed, central registry with an explicit audit trail from training data → registered model → deployed artifact, aimed at compliance/governance use cases | Proprietary/commercial SaaS | The right choice for a team already paying for Comet's experiment-tracking platform that wants a more polished compliance/audit-trail UI than MLflow's own registry provides out of the box; not a reason to adopt Comet from scratch just for the registry feature | 2026-08-31 | Not independently fetched (commercial SaaS, no public repo); freemium pricing search-corroborated at paid tiers starting ~$39/user/month |
| Cloud-native registries (SageMaker Model Registry, Vertex AI Model Registry, Azure ML Model Registry) | Bundled model-registry features inside each hyperscaler's own managed ML platform | N/A — managed cloud services, not licensable/installable software | Named for completeness at a "these exist and are current" level, matching this repo's convention for managed-service rows elsewhere — the right default only for a team already fully standardized on that cloud's managed ML platform, not independently deep-researched this pass | 2026-08-31 | Not independently fetched — existence and current naming confirmed via search, no deeper feature comparison performed |
| **Purpose-built standalone open-source production registries** | — | — | **None found genuinely current and worth naming as a registry-only tool.** This pass searched explicitly for a dedicated open-source production model registry distinct from MLflow's bundled feature and found none actively maintained at comparable adoption — the honest finding is that MLflow's registry (or a cloud platform's bundled one) *is* the category's real answer, not a gap this doc is glossing over. `VertaAI/modeldb` (Apache-2.0) was checked and ruled out: `pushed_at` 2024-07-23, over two years stale | 2026-08-31 | — |
| MLRun (`mlrun/mlrun`, Iguazio) — named as a bundled-suite alternative, not a registry-only pick | Broader open-source MLOps orchestration platform (pipelines + serving + monitoring) that includes its own model-artifact registry as one feature among several | Apache-2.0 | The same "one tool covers a lot" trade-off the ML/AI Model Development baseline already named for ClearML — worth naming for a team that wants registry+orchestration+serving bundled into a single platform rather than composing MLflow with separate serving/orchestration tools, not a registry-specific recommendation on its own | 2026-08-31 | Direct GitHub fetch: 1,694 stars, 318 forks, pushed 2026-08-31 (very active) |

**Decision rule**: default to **MLflow Model Registry**, using aliases/
tags (not the deprecated stage API) plus webhooks for promotion gating —
this is sufficient for most teams and costs nothing extra for a team
already on MLflow; reach for **Comet** only if already paying for its
platform and wanting a more compliance-polished UI; use a **cloud-native
registry** only when a team is already fully committed to that cloud's
managed ML platform end-to-end; reach for **MLRun** only when the team
explicitly wants one bundled platform covering registry+orchestration+
serving rather than composing best-of-breed tools, the same trade-off
ClearML represents in ML/AI Model Development's own experiment-tracking
section.

### Feature stores — impact: high — depth: table + self-hosted-vs-managed decision

**Feast's governance, verified precisely rather than assumed thriving**:
Feast joined the **LF AI & Data Foundation as an Incubation-stage
project in November 2020** and, per LF AI & Data's own project page,
**remains at Incubation maturity as of this pass** — nearly six years
without a Graduation, a real, honest data point worth stating plainly
(the same "still Incubating, not yet Graduated" framing this repo's
Infrastructure & Platform Engineering baseline already gives Backstage
and KServe). This is not evidence of neglect — Feast's own repo shows
very current activity (see table) — but it means Feast has not achieved
the vendor-neutral graduation milestone Kubeflow (ML/AI Model
Development's baseline) or OPA/Helm/Argo (Infrastructure & Platform
Engineering's baseline) have.

**Tecton's status changed materially in the last year, a genuinely fresh
finding**: Tecton — the commercial feature-store platform founded by
Feast's original creators — was **acquired by Databricks in August
2025**. Its low-latency feature-pipeline technology is being folded
directly into **Databricks Feature Store** (which released Declarative
Feature APIs after the acquisition); search corroboration found no
evidence Tecton is still sold as an independent standalone product in
2026 — the practical effect is that the "managed commercial feature
store" market has consolidated into hyperscaler-platform features
(Databricks, AWS, GCP) rather than remaining a separate product
category, worth stating explicitly since it changes what "the managed
alternative to Feast" concretely means today.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Feast** (`feast-dev/feast`) — **default for self-hosted/open** | Open-source feature store: online/offline store abstraction over Redis/DynamoDB/Snowflake/BigQuery/etc., feature serving for both training and inference | Apache-2.0 | The only fully open, vendor-neutral-governed (LF AI & Data) feature store still independently developed as its own project — still Incubation-stage after ~6 years (see callout), but genuinely active, not stalled | 2026-08-31 | Direct GitHub fetch: 7,240 stars, 1,418 forks, 416 open issues, pushed 2026-08-30 (very active); latest release `v0.66.0`, published 2026-08-21 |
| **Databricks Feature Store** (bundled into Databricks/Unity Catalog, absorbing Tecton's technology post-acquisition) | Managed feature engineering/serving for a team already on the Databricks Lakehouse platform, now including Tecton's former low-latency real-time pipeline capability | Proprietary/commercial — bundled into a Databricks workspace subscription | The practical current answer to "what replaced Tecton as the managed option," for a team already on or willing to adopt Databricks specifically — not a drop-in for a team on a different cloud/warehouse | 2026-08-31 | Not independently fetched — managed platform feature, not a separate repo; positioning search-corroborated post-acquisition |
| Hopsworks | Open-source-plus-commercial feature store with its own managed offering, positioned as a Feast alternative with a broader bundled platform (also includes model registry/serving) | Open-core (AGPL-licensed core per public listings; not independently LICENSE-fetched this pass) | Named for completeness as a genuinely current alternative bundling more of the MLOps stack into one platform; not independently deep-researched this pass — a real gap to flag rather than force a full comparison | 2026-08-31 | Not independently fetched this pass |
| AWS SageMaker Feature Store / GCP Vertex AI Feature Store | Hyperscaler-bundled feature stores for teams already standardized on that cloud's ML platform | N/A — managed cloud services | Named for completeness, matching this baseline's own cloud-registry rows above; not independently deep-researched | 2026-08-31 | Not independently fetched this pass |

**Decision rule**: default to **Feast** for a self-hosted, vendor-neutral
choice, with its still-Incubation LF AI & Data status treated as a
watch-item rather than a blocker given genuinely active development; a
team wanting a fully managed feature layer with no self-hosting is now
best served by **whichever hyperscaler platform it's already
standardized on** (Databricks Feature Store being the closest thing to
"the new Tecton" specifically) rather than a standalone commercial
feature-store vendor, since that standalone-vendor category has
concretely consolidated away this year.

### Model serving frameworks (general ML) — impact: high — depth: table + serving-shape decision rule

**Scope boundary, stated explicitly**: Agentic & MCP Platforms already
owns LLM-specific serving (vLLM, TensorRT-LLM) — this section covers
general/traditional ML model serving (classification, regression,
tabular, CV models, and any framework-agnostic model artifact), a
genuinely distinct concern with different tools.

**BentoML's ownership changed within this exact pass window**: BentoML
was **acquired by Modular (maker of Mojo/MAX) on 2026-02-10**. Per
Modular's own announcement, the project **stays Apache-2.0** and Modular
is "doubling down on OSS" — pairing BentoML's deployment platform with
MAX/Mojo's hardware-optimization layer, not discontinuing or closing it.
A real ownership-change data point, not a licensing or availability risk
based on what's been announced so far.

**Seldon Core's BSL status, reconfirmed precisely this pass**: a direct
fetch of `SeldonIO/seldon-core`'s own `LICENSE` file (GitHub's metadata
API reports `NOASSERTION`, the same detection gap this repo's other
baselines have flagged repeatedly) confirms **Business Source License
1.1**, licensor Seldon Technologies Limited, in effect **since January
2024** — and, notably, the license text on the repo's default branch is
scoped to "Seldon Core v1" specifically, meaning **the BSL move applies
to both Seldon Core v1 and v2**, not only the newer v2 architecture as
some older summaries suggest. Non-production use is free; production/
commercial use requires a purchased license unless covered by the
non-profit-educational carve-out. Each version converts to Apache-2.0
four years after its own release date (a rolling per-version clock, the
same shape as Terraform's own BSL conversion this repo's Infrastructure
baseline already documented).

**Triton's branding shifted, not its license**: NVIDIA folded Triton
into its broader "Dynamo" inference platform in March 2025 — the product
is now also marketed as **NVIDIA Dynamo-Triton**, though both names
remain in active use in NVIDIA's own current docs. License and repo are
unchanged.

| Framework | License | Governance | Serving shape it fits best | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|---|
| **KServe** (`kserve/kserve`) | Apache-2.0 | **CNCF Incubating** (accepted 2025-09-29, spun out of the Kubeflow ecosystem into its own CNCF project — not yet Graduated) | Online/real-time, Kubernetes-native — built specifically around K8s `InferenceService` CRDs and Knative-style serverless autoscaling | The vendor-neutral, Kubernetes-native default for a team already standardized on K8s wanting a CRD-first serving layer with built-in traffic-split canary rollout (see Canary section below) | 2026-08-31 | Direct GitHub fetch: 5,844 stars, 1,644 forks, 199 open issues, pushed 2026-08-30 (active); latest release `v0.20.0`, published 2026-08-06 |
| **BentoML** (`bentoml/BentoML`) | Apache-2.0 (confirmed unchanged post-acquisition per Modular's own announcement) | Modular-owned (acquired 2026-02-10), open-source core unaffected | Online/real-time, also batch-friendly — Python-native "Bento" packaging format wraps a model + its runtime/dependencies into one deployable unit, framework-agnostic | The right choice for a Python-first team wanting the lowest-friction path from a trained model to a deployable service, without committing to Kubernetes as the deployment target; **BentoCloud** (commercial, Starter/Enterprise-BYOC tiers) is the managed layer on top, not required to use the OSS core | 2026-08-31 | Direct GitHub fetch: 8,814 stars, 1,020 forks, 212 open issues, pushed 2026-08-28 (active); latest release `v1.4.39`, published 2026-05-07 |
| Seldon Core (`SeldonIO/seldon-core`, now spanning both v1 and v2 in one repo) | **BSL 1.1** (non-production free; production/commercial requires a purchased license — see callout above) | Seldon Technologies Limited (commercial company), no separate foundation | Online/real-time, Kubernetes-native — the only framework in this table with built-in shadow-deployment and canary-deployment pipeline primitives purpose-built for model comparison (see Canary section) | Named as the honest incumbent for a team already invested in Seldon's Kubernetes-native pipeline model, not the default for a new project given the BSL production-use gate — evaluate the commercial license cost against KServe/BentoML's fully open alternatives first | 2026-08-31 | Direct GitHub fetch: 4,779 stars, 868 forks, 396 open issues, pushed 2026-03-23 (~5 months stale relative to this pass, worth a light flag); latest release `v2.10.2`, published 2025-12-19 |
| **Triton Inference Server** (`triton-inference-server/server`, also marketed as **NVIDIA Dynamo-Triton** since March 2025) | BSD-3-Clause | NVIDIA-led, no separate foundation | The most versatile of the four — genuinely fits batch, online/real-time, **and** streaming (audio/video) serving via dynamic/continuous batching and concurrent-execution scheduling | The right choice when GPU-optimized, multi-framework (ONNX/TensorRT/PyTorch/TensorFlow) serving performance matters more than deployment-format simplicity — the deepest NVIDIA-hardware optimization of any tool here, at the cost of a steeper configuration model than BentoML/KServe | 2026-08-31 | Direct GitHub fetch: 10,952 stars, 1,832 forks, 887 open issues, pushed 2026-08-31 (very active); latest release `v2.71.0`, published 2026-07-29 |

**Decision rule**: Kubernetes-native deployment with vendor-neutral
governance and built-in traffic-split canary support → **KServe**;
Python-first packaging with the lowest friction from notebook to
deployable service, Kubernetes optional → **BentoML**; GPU-heavy,
multi-framework, highest-throughput serving (including streaming/audio-
video workloads) → **Triton/Dynamo-Triton**; already invested in
Seldon's own pipeline model and prepared to either stay non-production
or purchase a commercial license → **Seldon Core**, not a first choice
for a new greenfield project given the BSL gate.

### Drift detection / monitoring tooling — impact: high — depth: table + BSL trap + staleness flags

**Alibi Detect's license changed at the same time as Seldon Core's, a
genuinely fresh correction to carry forward precisely**: direct fetch of
`SeldonIO/alibi-detect`'s own `LICENSE` file confirms it is **also BSL
1.1**, licensor Seldon Technologies Limited, effective **since January
2024** — the same terms, same non-production-free/production-paid
structure, same four-year-per-release Apache-2.0 conversion clock as
Seldon Core itself. This is worth stating precisely because Alibi
Detect is often cited in older tutorials as a plain Apache-2.0 library;
that is no longer accurate for any release from 2024 onward.

**WhyLabs/whylogs's history compressed into one clean but stale story**:
WhyLabs was **acquired by Apple in January 2025**; its commercial hosted
observability platform was then **discontinued outright**, and the
company **open-sourced its entire platform codebase** (`whylabs/
whylabs-oss`) alongside the pre-existing `whylogs` profiling library —
so there is, refreshingly, no open-core gating left to navigate here at
all. The less refreshing finding: **both repos have seen essentially no
activity since the acquisition** — `whylogs` last pushed 2025-01-10
(latest release `v1.6.4`, 2024-12-03) and `whylabs-oss` last pushed
2025-01-24, both roughly 19 months stale relative to this pass. This
reads as a product line that went fully open the moment it also went
quiet, not a thriving actively-maintained project — worth a plain,
un-softened flag rather than treating "now fully open-source" as
unambiguously good news.

**Evidently's open-core split, verified precisely**: the `evidentlyai/
evidently` **core library is Apache-2.0 with no feature-gating on
evaluation/metrics/drift-detection capability itself** — Evidently's own
docs state the OSS library has "no artificial feature limits" on its
core evaluation functionality. What's gated behind the separate,
commercial **Evidently Cloud** product is specifically collaboration
(multi-user dataset/project management), alerting on metric thresholds,
a hosted dashboard, and no-code evaluation workflows — a real but
narrower gate than some open-core products in this repo's other
baselines (e.g. W&B's use-case-restricted free tier).

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Evidently AI** (`evidentlyai/evidently`) — **default** | Statistical data/concept-drift detection, data-quality checks, and model-performance evaluation reports — the fully-open core, not gated | Apache-2.0 (open-core; see callout for exactly what Evidently Cloud adds) | The most actively developed, fully-open-for-its-core-use-case option in this table — the right default for a team that doesn't need Cloud's collaboration/alerting layer on day one | 2026-08-31 | Direct GitHub fetch: 7,866 stars, 905 forks, 299 open issues, pushed 2026-08-05 (active, ~4 weeks stale relative to this pass); latest release `v0.7.21`, published 2026-03-10 (~5.5 months stale — worth a light flag) |
| **NannyML** (`NannyML/nannyml`) | Performance-*estimation* without ground-truth labels — a genuinely distinct capability from Evidently's statistical-drift framing: estimates real accuracy/business-metric degradation before labeled outcomes are available | Apache-2.0 | The right complementary choice specifically when a team needs an accuracy estimate ahead of ground-truth availability (e.g. long feedback-loop domains); not a replacement for Evidently's broader data-quality/drift-report feature set | 2026-08-31 | Direct GitHub fetch: 2,151 stars, 192 forks, only 3 open issues, **pushed 2025-07-12 — over 13 months stale relative to this pass**, a real, plain staleness concern worth weighing before adopting as a primary tool; latest release `v0.13.1`, same date |
| Alibi Detect (`SeldonIO/alibi-detect`) | Outlier/adversarial/drift detection algorithms library, deep research-grade coverage of detection methods | **BSL 1.1** (non-production free; production/commercial requires a purchased license — see callout above, same terms as Seldon Core) | Named for completeness given its historically strong reputation for algorithmic breadth, but **not the default given the BSL gate** now applies to production use — a team wanting the algorithmic depth should weigh the license cost against Evidently/NannyML's fully-open alternatives first | 2026-08-31 | Direct GitHub fetch: 2,548 stars, 253 forks, 146 open issues, pushed 2025-12-11 (~9 months stale); latest release `v0.13.0`, same date |
| whylogs (`whylabs/whylogs`) | Lightweight, framework-agnostic data-profiling library (statistical summaries of data flowing through a pipeline) | Apache-2.0 (fully open since the WhyLabs/Apple acquisition — no commercial platform left to gate anything, see callout above) | Named for completeness and because the licensing story is now clean, but **flagged plainly as effectively unmaintained post-acquisition** (~19 months without a commit) — not a start-here default, only worth adopting if a team specifically needs its lightweight profiling format and is prepared to self-maintain | 2026-08-31 | Direct GitHub fetch: 2,831 stars, 144 forks, only 5 open issues, pushed 2025-01-10 (**~19 months stale**); latest release `v1.6.4`, published 2024-12-03 (**~21 months stale**) |

**Decision rule**: default to **Evidently** for drift/data-quality
detection given its active development and genuinely open core; add
**NannyML** specifically when ground-truth-free performance estimation
is needed; treat **Alibi Detect** as BSL-gated for production the same
way Seldon Core itself is gated, not a free default; treat **whylogs**
as a legacy-but-license-clean option only, not a first pick, given its
near-two-year staleness.

### ML observability platforms (broader than drift-detection-only) — impact: med — depth: paragraph + scope boundary vs. Agentic & MCP Platforms

**Correction to this baseline's own first-pass framing, caught during
review rather than left standing**: this section originally claimed to be
"resolving an open license question" the shipped Agentic & MCP Platforms
baseline had left unconfirmed for `Arize-ai/phoenix`. That framing was
checked against the actual shipped file
(`skills/project-incubation/references/preferred-libraries/
agentic-mcp-platforms.md`) during review and found to be **inaccurate**:
that doc already states, correctly and with its own direct-`LICENSE`-fetch
citation dated 2026-08-20, that Phoenix is **Elastic License 2.0 (ELv2)**,
not Apache-2.0 — this pass's own independent direct fetch of the same
`LICENSE` file simply reconfirms an already-correct, already-shipped fact,
not a new correction. No follow-up patch to that file is needed. Recorded
here so the authored doc doesn't overclaim a fix that isn't necessary.

**Phoenix and Arize's commercial platform ("Arize AX") are confirmed
genuinely separate products, not the same tool under two names** — so
naming Arize here does not duplicate Agentic & MCP Platforms' own
Phoenix entry. Phoenix is open-source, self-hosted (SQLite/Postgres),
development/debugging-oriented. **Arize AX** is the proprietary,
production-scale SaaS platform, split into an **AX-Generative** edition
(LLM/agent observability — this is the one that would overlap with
Agentic & MCP Platforms' concerns, out of scope here) and an
**AX-ML & CV** edition (traditional ML/computer-vision model monitoring
at production scale — the edition actually relevant to this MLOps
category). **Fresh, load-bearing event**: Dynatrace announced a
definitive agreement to **acquire Arize for $915M on 2026-08-13** — 18
days before this snapshot, deal not yet closed as of this pass — a real,
current ownership-transition risk worth flagging to any team evaluating
Arize AX today, not a settled fact to treat as background.

**Fiddler AI** remains a fully proprietary SaaS observability/monitoring
platform (SaaS, on-prem, and self-hosted deployment options, but no
open-source component at all) — named for completeness as a comparable
enterprise-tier alternative to Arize AX, covering model performance,
bias detection, and explainability (Shapley-value-based) for both
traditional ML and generative workloads in one platform.

### Retraining-pipeline trigger mechanics — impact: low/med — depth: paragraph, honest "pattern not product" finding

**No dedicated, libraries-table-worthy tool exists for this — verified
by explicit search, not assumed.** What connects a drift-monitoring
signal to a training-pipeline kickoff in current practice is an
**event-driven sensor pattern layered on top of already-covered general
orchestrators**, not a purpose-built product: a drift-detection tool
(Evidently/NannyML above) crosses a configured threshold, fires a
webhook or writes a signal file, and a sensor already native to whichever
orchestrator a team is running (Airflow/Dagster/Prefect sensors, already
named in Data & Analytics Platforms' baseline; or Argo Workflows/
Kubeflow Pipelines, already named in ML/AI Model Development's baseline)
picks it up and kicks off a versioned retraining run. This is genuinely
more of an architecture question — the right home for it is the
companion `stack.md`'s decision-criteria treatment, not a forced table
row here. Most current production write-ups converge on running both a
fixed-cadence scheduled retrain *and* an event-triggered on-demand retrain
side by side, not one mechanism replacing the other.

### Canary/shadow-deployment tooling specifically for models — impact: med — depth: paragraph, honest finding

**Scope boundary**: Infrastructure & Platform Engineering already covers
generic Kubernetes progressive-delivery mechanics (Argo Rollouts,
Flagger) — this section asks specifically whether anything purpose-built
for *model-quality-driven* canary judgment (not just HTTP-traffic-
percentage splitting) exists and is current.

**Kayenta, the one tool that historically did this, is retired as a
standalone project — confirmed via direct fetch, not assumed**:
`spinnaker/kayenta` (Netflix/Spinnaker's automated canary-analysis
service, which computed a statistical judgment of whether a canary was
degraded relative to a baseline) shows `archived: true`, last pushed
**2025-12-20**. Its functionality has been folded into the main
Spinnaker monorepo rather than continuing as a separately maintained
repo — the project's *capability* persists inside Spinnaker, but there
is no longer a standalone Kayenta to recommend as its own entry.

**What exists today instead is native-but-metrics-agnostic traffic
splitting, confirmed for both Kubernetes-native serving frameworks named
above**: **KServe**'s `InferenceService` supports a real, built-in
`canaryTrafficPercent` field with automatic last-known-good-revision
tracking and rollback-on-failed-step — but it is **purely a traffic-
percentage mechanism, available only in serverless deployment mode**,
with no built-in model-quality-metric judge; a real quality-driven
promotion decision still requires querying an external metrics source
(Evidently/NannyML/Arize AX above) and gating the rollout from outside.
**Seldon Core** goes one step further architecturally: it has native
**shadow-deployment** (mirrors live traffic to a candidate model without
serving its predictions, for offline comparison) and **canary-deployment**
(percentage-split live A/B) primitives built directly into its pipeline
model — genuinely more purpose-built for model comparison than KServe's
flat traffic-split, though the same BSL production-use gate named above
applies to it.

**Honest conclusion, stated plainly rather than forcing an entry**: no
current tool provides fully automated statistical model-quality canary
judgment out of the box the way Kayenta once did. Current practice is a
metrics-provider query (from this doc's own drift/observability tooling)
layered on top of either KServe's or Seldon's native traffic-shifting
primitives, or on the generic Argo Rollouts/Flagger mechanics
Infrastructure & Platform Engineering's baseline already covers — a real
gap in the current tooling landscape, not an oversight in this doc's
research.

## Explicitly out of scope

- **LLM-specific serving infrastructure** (vLLM, TensorRT-LLM) — owned by
  Agentic & MCP Platforms, already shipped; this baseline's serving
  section covers general/traditional ML model serving only.
- **Generic Kubernetes progressive-delivery mechanics** (Argo Rollouts,
  Flagger) and **IaC/config drift detection** — owned by Infrastructure &
  Platform Engineering, already shipped; this baseline's own drift
  section covers the statistically distinct *model*-drift concern, and
  its canary section explicitly builds on top of (not duplicating) that
  baseline's traffic-shifting tooling.
- **Model-development-stage MLflow framing and Hugging Face Hub** — owned
  by ML/AI Model Development, already shipped; this baseline's registry
  section re-examines MLflow specifically from the production-promotion-
  gate angle per that baseline's own explicit handoff instruction.
- **LLM-application/agent observability** (Langfuse, DeepEval, Promptfoo,
  LangSmith, and **Arize Phoenix specifically**) — owned by Agentic & MCP
  Platforms, already shipped; this baseline's own ML-observability
  section names the genuinely separate **Arize AX** (AX-ML & CV edition)
  and Fiddler AI instead, with the Phoenix-vs-AX distinction stated
  explicitly to avoid duplication.
- **General data-pipeline orchestrators** (Airflow, Dagster, Prefect) and
  **ML-specific pipeline orchestrators** (Kubeflow Pipelines, Metaflow) —
  owned by Data & Analytics Platforms and ML/AI Model Development
  respectively, both already shipped; this baseline's retraining-trigger
  section explicitly points to their existing sensor/event-trigger
  mechanics rather than re-listing them.
- **Retraining-pipeline architecture depth** (exactly how a drift signal
  should be wired to a specific orchestrator, what threshold/hysteresis
  logic to use) — this is a `stack.md`-shaped architecture question, not
  a specific-tool question; named honestly as "pattern, not product" in
  the Retraining-trigger section above rather than forced into a table.
- **Hopsworks, SageMaker/Vertex AI Feature Store, and cloud-native model
  registries** — named at a one-line existence level only, not
  independently deep-researched this pass; a real gap worth a follow-up
  if a project's stack is specifically hyperscaler-committed.
- **Cost/pricing depth beyond the named commercial-tier/licensing traps**
  (exact Comet ML enterprise pricing, exact BentoCloud/Databricks Feature
  Store pricing) — license/self-hosting status is the durable signal per
  this repo's established convention; specific dollar figures were
  search-corroborated where cited, not independently direct-fetched from
  each vendor's own pricing page.

## Sources

- Local `find`/`grep`/direct-read passes (not web sources), 2026-08-31:
  confirmed absence of any feature-store/drift/registry/canary-shaped
  file or dependency under `/Users/devopammittra/GitHub/ubi-csr-tmf` and
  `/Users/devopammittra/GitHub/agent-skills`; full direct read of
  `ubi-csr-tmf/aws/container/{backend/app,agents}/requirements.txt`.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license,
  stars, forks, open issues, `pushed_at`, `archived`) for: kserve/kserve,
  bentoml/BentoML, SeldonIO/seldon-core, triton-inference-server/server,
  mlflow/mlflow, feast-dev/feast, evidentlyai/evidently, NannyML/nannyml,
  SeldonIO/alibi-detect, whylabs/whylogs, whylabs/whylabs-oss,
  Arize-ai/phoenix, spinnaker/kayenta, VertaAI/modeldb, mlrun/mlrun —
  retrieved 2026-08-31
- `https://mlflow.org/docs/latest/self-hosting/webhooks/` — direct fetch,
  follow-up verification pass: confirms MLflow's webhook feature
  (`model_version.created`, `model_version_tag.set`, and related events;
  HMAC signature verification, admin-only when Auth is enabled) is
  documented under MLflow's own **self-hosting** doc tree, not gated to
  Databricks-managed MLflow — resolving an internal disagreement between
  this pass's own research forks (one flagged the feature as unconfirmed)
  in favor of "genuine, current, self-hostable OSS feature" — retrieved
  2026-08-31
- `gh api repos/<owner>/<repo>/releases/latest` direct fetches for
  current version tags: kserve, bentoml, seldon-core, mlflow, feast,
  evidently, nannyml, alibi-detect, whylogs, triton — retrieved
  2026-08-31
- `https://raw.githubusercontent.com/SeldonIO/seldon-core/master/LICENSE`
  — direct fetch confirming BSL 1.1 text, "Licensed Work: Seldon Core
  v1," January 2024 effective date, four-year-per-release Apache-2.0
  conversion clause — retrieved 2026-08-31
- `https://raw.githubusercontent.com/SeldonIO/alibi-detect/master/LICENSE`
  — direct fetch confirming BSL 1.1, "Licensed Work: Alibi Detect,"
  identical January 2024 terms to Seldon Core — retrieved 2026-08-31
- `https://raw.githubusercontent.com/Arize-ai/phoenix/main/LICENSE` —
  direct fetch confirming Elastic License 2.0 (ELv2), resolving the open
  question the already-shipped Agentic & MCP Platforms baseline left
  unconfirmed on this exact point — retrieved 2026-08-31
- `https://raw.githubusercontent.com/evidentlyai/evidently/main/LICENSE`,
  `.../NannyML/nannyml/main/LICENSE`, `.../whylabs/whylogs/mainline/
  LICENSE` — direct fetches confirming Apache-2.0 for each — retrieved
  2026-08-31
- `https://lfaidata.foundation/projects/feast/` and LF AI & Data's own
  blog announcement of Feast's November 2020 Incubation-project
  acceptance — direct fetch/search confirming current Incubation-stage
  maturity, not yet Graduated — retrieved 2026-08-31
- WebSearch corroboration (not independently direct-fetched primary
  source this pass, flagged inline where used): Dynatrace/Arize
  acquisition terms and 2026-08-13 announcement date (dynatrace.com's own
  press release, businesswire.com, forbes.com, msspalert.com); BentoML/
  Modular acquisition and OSS-commitment statement (Modular's own
  x.com/forum/blog posts, bentoml.com's own announcement); Tecton/
  Databricks acquisition and Feature-Store-API-consolidation narrative
  (databricks.com's own blog, fenwick.com, mitsloanme.com); WhyLabs/Apple
  acquisition and platform open-sourcing (appsecsanta.com); MLflow
  stage-deprecation/aliases-tags/webhooks current docs (mlflow.org/docs/
  latest/ml/model-registry, mlflow.org/docs/latest/ml/webhooks,
  github.com/mlflow/mlflow issue #14677); Comet Model Registry
  positioning and pricing (capterra.com, pricingsaas.com); KServe CNCF
  Incubating acceptance date (cncf.io's own KServe project page,
  thenewstack.io, redhat.com, cncf.io's own 2025-11-11 KServe-Incubating
  blog post); KServe canary-rollout mechanics (kserve.github.io's own
  docs); Seldon Core shadow/canary deployment primitives and BSL history
  (docs.seldon.ai, rfp.wiki, qwak.com); Triton/Dynamo-Triton rebranding
  and batching/streaming capabilities (nvidia.com, docs.nvidia.com);
  Evidently open-core feature split (docs.evidentlyai.com's own OSS-vs-
  Cloud FAQ); Arize Phoenix-vs-AX product-split framing (atlan.com);
  Fiddler AI current positioning (fiddler.ai's own site); Kayenta
  archival into the Spinnaker monorepo (spinnaker.io, github.com/
  spinnaker/kayenta); retraining-trigger event-sensor patterns
  (123ofai.com, mlopslab.org, devopsroles.com) — all retrieved 2026-08-31
- `research/stacks/ml-model-development/libraries.md` and
  `research/stacks/infrastructure-platform-engineering/libraries.md` —
  read directly to confirm this baseline's own out-of-scope boundaries
  and to identify the exact handoff points (MLflow Registry's
  promotion-gate re-examination; Argo Rollouts/Flagger's already-covered
  traffic-shifting mechanics) — read 2026-08-31
- `research/stacks/agentic-mcp-platforms/libraries.md` (the research
  baseline, which did flag the Phoenix license as unconfirmed) and the
  already-**shipped**
  `skills/project-incubation/references/preferred-libraries/
  agentic-mcp-platforms.md` (which already resolved it correctly, ELv2,
  during its own authoring pass, dated 2026-08-20) — both read directly to
  confirm the Phoenix-vs-Arize-AX scope boundary; caught during this
  pass's own review that only the research baseline (not the shipped
  file) still showed the license as unconfirmed, correcting this
  document's own first-draft overclaim above — read 2026-08-31

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
standing for this whole taxonomy-roadmap sweep, resolved directly:

- **Hopsworks stays a one-line, not-deep-researched mention** — a real gap
  named honestly in Explicitly-out-of-scope, consistent with how this
  repo's other baselines (e.g. ML/AI Model Development's own treatment of
  ClearML's full feature depth) accept a shallower mention for a
  secondary/bundled-suite option rather than deep-researching every
  alternative in a first pass.
- **The Dynatrace/Arize acquisition stays flagged as unclosed, not
  revisited** — there's nothing to re-fetch that would change today's
  answer, since the deal genuinely hasn't closed yet; the authored doc
  should carry the same "flagged as a live ownership-transition risk, not
  a settled fact" framing forward rather than waiting on an external event
  this research pass can't accelerate.
- **Seldon Core's exact commercial pricing stays unfetched** — this
  repo's own established convention (already stated in this baseline's
  own Explicitly-out-of-scope section, and matching how HCP
  Terraform/Spacelift's *license and self-hosting status* were the
  durable signal named, with exact pricing figures fetched only where a
  vendor publishes them directly) treats the BSL production-use gate
  itself as the load-bearing fact; Seldon doesn't publish pricing, so
  there's no comparably load-bearing number to fetch the way HCP
  Terraform's public tier table was.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/mlops-platform-engineering.md
  — est. 400–470 lines (7 category sections — production model registries
  with the MLflow stages-deprecated/aliases-webhooks re-examination,
  feature stores with the Tecton/Databricks-acquisition decision
  reframing, general ML model serving frameworks with a serving-shape
  decision rule and the Seldon/Alibi-Detect shared-BSL callout, drift
  detection/monitoring with the whylogs staleness flag and Alibi-Detect
  BSL correction, ML observability platforms with the Phoenix-vs-Arize-AX
  scope-boundary resolution and the fresh Dynatrace acquisition callout,
  retraining-pipeline trigger mechanics as an honest "pattern not
  product" finding, and canary/shadow-deployment tooling with the
  Kayenta-retirement finding — plus the Local-precedent section's honest
  "none found" result carried forward, matching ML/AI Model Development
  and Infrastructure & Platform Engineering's own structure and rough
  length).
