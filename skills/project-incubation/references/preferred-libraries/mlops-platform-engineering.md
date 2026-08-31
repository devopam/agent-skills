# MLOps / ML Platform Engineering — Preferred Libraries

Companion to [stacks/mlops-platform-engineering.md](../stacks/mlops-platform-engineering.md),
which covers architecture and selection criteria; this doc names the actual
tools, their licenses, and honest maintenance/adoption signal for the
*operational* discipline once a model already exists — production model
registries, feature stores, general-ML model serving, drift monitoring,
retraining triggers, and model-quality-driven canary rollouts — as distinct
from [ML / AI Model Development](ml-model-development.md) (model-*building*:
training, fine-tuning, experiment tracking, already shipped),
[Agentic & MCP Platforms](agentic-mcp-platforms.md) (LLM-specific serving and
LLM-application/agent observability, already shipped), and
[Infrastructure & Platform Engineering](infrastructure-platform-engineering.md)
(generic Kubernetes/IaC/progressive-delivery mechanics, already shipped). No
local precedent exists for this category either: a direct `find`/`grep` pass
across `/Users/devopammittra/GitHub/ubi-csr-tmf` and this repo for
feature-store, drift, registry, and canary-shaped files or dependencies
turned up zero hits — `ubi-csr-tmf`'s backend is a document-processing
FastAPI/Flask service and its agents component depends on `strands-agents`
(an LLM-agent SDK), neither of which runs a trained-model production-serving
stack. Every entry below is externally sourced, with a direct fetch of the
repo/license/docs page wherever practical.

This authoring pass re-verified rather than transcribed the baseline in
several places. The most material correction is to **Hopsworks**, which the
baseline named only as "open-core (AGPL-licensed core per public listings;
not independently LICENSE-fetched this pass)." A direct fetch this pass
confirms the license (AGPL-3.0, via GitHub's own repo metadata for
`logicalclocks/hopsworks`) but also surfaces a maintenance signal the
baseline never checked: that platform repo's `pushed_at` is **2025-02-10**
(~18.5 months stale relative to this pass) and its latest tagged release,
`v3.7.0`, dates to **2024-03-02** (~2.5 years stale) — a real staleness flag
the baseline's placeholder entry missed entirely. A second fetch found the
nuance behind it: the Python/Scala client library teams actually install to
talk to a Hopsworks feature store, `logicalclocks/feature-store-api` (the
`hsfs` package), is a **separate repo under a separate, more permissive
license — Apache-2.0** — and was pushed far more recently, 2025-09-24. Also
re-confirmed by direct fetch this pass rather than left as
search-corroborated: KServe's `canaryTrafficPercent` field is real,
Knative/serverless-mode-only exactly as the baseline stated, and — a fresh
finding — its extension to `RawDeployment` mode is tracked in a still-open
GitHub issue (`kserve/kserve#5335`, opened 2026-04-02, last updated
2026-06-12), concrete evidence this is a live gap rather than settled
behavior; and Seldon Core's Alibi Detect integration is confirmed to be a
declarative dependency pattern (`requirements: [alibi-detect]` on a standard
Model CRD, run asynchronously inside a Pipeline) rather than a bespoke
built-in mechanism, worth stating precisely rather than the vaguer "native
integration" framing found in secondary sources. A spot-check re-fetch of
MLflow, Feast, KServe, BentoML, Seldon Core, Evidently, NannyML, and Alibi
Detect this pass found the numbers essentially unchanged from the research
baseline (MLflow's open-issue count ticked from 2,057 to 2,058) — small
enough drift to confirm these are live, reproducible figures, not stale
copy-paste.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [Production model registries](#production-model-registries)
- [Feature stores](#feature-stores)
- [Model serving frameworks (general ML)](#model-serving-frameworks-general-ml)
- [Drift detection / monitoring tooling](#drift-detection--monitoring-tooling)
- [ML observability platforms](#ml-observability-platforms)
- [Retraining-pipeline trigger mechanics](#retraining-pipeline-trigger-mechanics)
- [Canary/shadow-deployment tooling for models](#canaryshadow-deployment-tooling-for-models)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

**Mostly Python, with a real second surface this category's siblings don't
share to the same degree.** Two of the four general-ML serving frameworks
below deploy as **Kubernetes CRDs/YAML**, not pip-installed libraries —
KServe's `InferenceService` and Seldon Core's `SeldonDeployment`/pipeline
resources — closer in shape to
[Infrastructure & Platform Engineering](infrastructure-platform-engineering.md#ecosystem-choice)'s
Helm/Kustomize surface than to
[ML / AI Model Development](ml-model-development.md#ecosystem-choice)'s
Python-only world. Because of this split, the tables below use GitHub
stars/forks/open-issues/`pushed_at`/latest-release-tag as the primary
adoption signal — direct `gh api repos/<owner>/<repo>` fetches — supplemented
by CNCF/LF-foundation maturity level and commercial-tier/licensing-trap flags
where those are the more load-bearing fact, as they are for KServe, Feast,
Seldon Core, and Alibi Detect specifically.

## Production model registries

**Scope boundary**: [ML / AI Model Development](ml-model-development.md)
named MLflow's Model Registry only at the model-development-artifact-storage
level (uploading/versioning a freshly-trained checkpoint) and explicitly
deferred the production-promotion-gate angle to this category. Re-examined
fresh here.

**MLflow's stage-based lifecycle is deprecated**, verified via MLflow's own
current docs rather than assumed from older tutorials: the classic
four-stage model (`None`→`Staging`→`Production`→`Archived`) is marked
deprecated and slated for removal in a future major release, replaced by
**model version tags and aliases** — a `champion` alias can be reassigned to
a new model version to signal a promotion, without a rigid single-path stage
machine. Critically for the promotion-gate use case this category cares
about, **MLflow ships first-class webhooks**: registering a model, creating
a new version, or reassigning a tag/alias can fire an HTTP POST to a
configured endpoint, enabling a promotion event to trigger a CI/CD pipeline
with a human-approval gate in front of it. A direct fetch of
`mlflow.org/docs/latest/self-hosting/webhooks/` confirms this is documented
under MLflow's own **self-hosting** doc tree — a genuine, current,
self-hostable OSS feature, not gated to Databricks-managed MLflow.

| Library | For | License | Why recommended |
|---|---|---|---|
| **MLflow Model Registry** (`mlflow/mlflow`) — default | Production promotion gating via aliases/tags (not the deprecated stage model) plus webhook-driven CI/CD triggering, on the same instance a team already uses for experiment tracking | Apache-2.0, Linux Foundation top-level project | The only registry here with genuine vendor-neutral governance, a real webhook-based promotion-gate mechanism, and zero incremental tooling cost for a team already on MLflow. Direct GitHub fetch: 27,747 stars, 6,236 forks, 2,058 open issues (re-confirmed this pass, up from the baseline's 2,057), pushed 2026-08-31 (very active); latest release `v3.15.2` |
| Comet Model Registry (part of Comet ML's commercial platform) | A governed, central registry with an explicit audit trail from training data → registered model → deployed artifact, aimed at compliance use cases | Proprietary/commercial SaaS | Right for a team already paying for Comet's experiment-tracking platform wanting a more polished compliance/audit-trail UI than MLflow's own registry; not a reason to adopt Comet from scratch. Not independently fetched (commercial SaaS, no public repo); freemium pricing search-corroborated at paid tiers starting ~$39/user/month |
| Cloud-native registries (SageMaker Model Registry, Vertex AI Model Registry, Azure ML Model Registry) | Bundled model-registry features inside each hyperscaler's managed ML platform | N/A — managed cloud services | Named for completeness at a "these exist and are current" level; the right default only for a team fully standardized on that cloud's managed ML platform, not independently deep-researched this pass |
| Purpose-built standalone OSS production registries | — | — | **None found genuinely current.** `VertaAI/modeldb` (Apache-2.0) was checked and ruled out: `pushed_at` 2024-07-23, over two years stale. MLflow's bundled registry, or a cloud platform's bundled one, is the category's real answer — not a gap this doc is glossing over |
| MLRun (`mlrun/mlrun`, Iguazio) — bundled-suite alternative, not registry-only | Broader open-source MLOps orchestration platform (pipelines + serving + monitoring) that includes its own model-artifact registry as one feature | Apache-2.0 | The same "one tool covers a lot" trade-off ML/AI Model Development already names for ClearML — worth naming for a team wanting registry+orchestration+serving bundled rather than composed. Direct GitHub fetch: 1,694 stars, 318 forks, pushed 2026-08-31 (very active) |

**Decision rule**: default to **MLflow Model Registry**, using aliases/tags
(not the deprecated stage API) plus webhooks for promotion gating; reach for
**Comet** only if already paying for its platform; use a **cloud-native
registry** only when fully committed to that cloud's managed ML platform
end-to-end; reach for **MLRun** only when the team explicitly wants one
bundled platform over composing best-of-breed tools.

## Feature stores

**Feast's governance, verified precisely.** Feast joined the **LF AI & Data
Foundation as an Incubation-stage project in November 2020** and, per LF AI
& Data's own project page, **remains at Incubation maturity as of this
pass** — nearly six years without graduating, the same "still Incubating"
framing this repo's Infrastructure & Platform Engineering doc already gives
Backstage and KServe. This is not evidence of neglect — Feast's own repo
shows very current activity (see table) — but it hasn't reached the
vendor-neutral graduation milestone Kubeflow, OPA, Helm, or Argo have.

**Tecton's status changed materially in the last year.** Tecton — the
commercial feature-store platform founded by Feast's original creators —
was **acquired by Databricks in August 2025**, its low-latency
feature-pipeline technology folding directly into **Databricks Feature
Store** (which released Declarative Feature APIs post-acquisition). Search
corroboration found no evidence Tecton is still sold as an independent
standalone product in 2026 — the "managed commercial feature store" market
has consolidated into hyperscaler-platform features rather than remaining a
separate product category.

**Hopsworks' license and staleness, corrected this pass — the single
biggest strengthening in this doc versus the baseline.** A direct `gh api`
fetch of `logicalclocks/hopsworks` confirms **AGPL-3.0** for the core
platform repo (the baseline had only search-corroborated "AGPL-licensed").
But the same fetch surfaces a real watch-item the baseline never checked:
`pushed_at` **2025-02-10** and latest release `v3.7.0` published
**2024-03-02** — 18.5 and 30 months stale, respectively, relative to this
pass, against an org where sibling infra-fork repos (`hive`, `spark`) are
pushed same-day. A second fetch clarifies the practical picture: the
Python/Scala client a team actually installs to talk to a Hopsworks feature
store, `logicalclocks/feature-store-api` (`hsfs` on PyPI), lives in a
**separate repo under Apache-2.0**, not AGPL-3.0, and was pushed far more
recently — 2025-09-24 (~11 months stale, still worth noting but a
meaningfully fresher signal than the core platform repo's near-2.5-year-old
release). A team evaluating Hopsworks should treat the client library and
the self-hosted platform as separately licensed and separately paced, not
one monolithic "AGPL, actively maintained" story.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Feast** (`feast-dev/feast`) — default for self-hosted/open | Open-source feature store: online/offline store abstraction over Redis/DynamoDB/Snowflake/BigQuery/etc., feature serving for both training and inference | Apache-2.0 | The only fully open, vendor-neutral-governed (LF AI & Data) feature store still independently developed as its own project — still Incubation-stage after ~6 years (see callout), but genuinely active. Direct GitHub fetch: 7,240 stars, 1,418 forks, 416 open issues, pushed 2026-08-30 (very active); latest release `v0.66.0`, published 2026-08-21 |
| Databricks Feature Store (bundled into Databricks/Unity Catalog, absorbing Tecton's technology post-acquisition) | Managed feature engineering/serving for a team already on the Databricks Lakehouse platform, now including Tecton's former low-latency real-time pipeline capability | Proprietary/commercial — bundled into a Databricks workspace subscription | The practical current answer to "what replaced Tecton as the managed option," for a team already on or willing to adopt Databricks specifically — not a drop-in for a different cloud/warehouse. Not independently fetched — managed platform feature, positioning search-corroborated post-acquisition |
| Hopsworks (`logicalclocks/hopsworks` platform; `logicalclocks/feature-store-api` client) | Open-core feature store with its own managed offering, bundling more of the MLOps stack (also includes model registry/serving) than Feast alone | Core platform: **AGPL-3.0** (direct-fetch confirmed); client library (`hsfs`): **Apache-2.0** (separate repo) | Worth naming as a genuinely current alternative that bundles more of the stack into one platform, but the core platform repo's near-2.5-year-stale latest release and 18.5-month-stale last push (see callout) are a real reason to weigh Feast first for a self-hosted, actively-developed default |
| AWS SageMaker Feature Store / GCP Vertex AI Feature Store | Hyperscaler-bundled feature stores for teams already standardized on that cloud's ML platform | N/A — managed cloud services | Named for completeness, matching this doc's own cloud-registry rows above; not independently deep-researched |

**Decision rule**: default to **Feast** for a self-hosted, vendor-neutral,
actively-developed choice, treating its still-Incubation LF AI & Data status
as a watch-item rather than a blocker; a team wanting a fully managed
feature layer is now best served by whichever hyperscaler platform it's
already standardized on (Databricks Feature Store being the closest thing to
"the new Tecton"); reach for **Hopsworks** only with the license-split and
staleness finding above priced in, not as a Feast-equivalent default.

## Model serving frameworks (general ML)

**Scope boundary**: [Agentic & MCP Platforms](agentic-mcp-platforms.md)
already owns LLM-specific serving (vLLM, TensorRT-LLM) — this section covers
general/traditional ML model serving (classification, regression, tabular,
CV models, and any framework-agnostic model artifact), a genuinely distinct
concern with different tools.

**BentoML's ownership changed within this exact pass window**: BentoML was
**acquired by Modular (maker of Mojo/MAX) on 2026-02-10**. Per Modular's own
announcement, the project **stays Apache-2.0** and Modular is "doubling down
on OSS" — pairing BentoML's deployment platform with MAX/Mojo's
hardware-optimization layer, not discontinuing it.

**Seldon Core's BSL status, direct-fetch confirmed.** `SeldonIO/seldon-core`'s
own `LICENSE` file (GitHub's metadata API reports `NOASSERTION`, the same
detection gap this repo's other docs flag repeatedly) confirms **Business
Source License 1.1**, licensor Seldon Technologies Limited, in effect since
**January 2024** — and the license text is scoped to "Seldon Core v1"
specifically, meaning the BSL move applies to **both v1 and v2**, not only
the newer architecture as some older summaries suggest. Non-production use
is free; production/commercial use requires a purchased license unless
covered by the non-profit-educational carve-out. Each version converts to
Apache-2.0 four years after its own release date — a rolling per-version
clock, the same shape as Terraform's own BSL conversion.

**Triton's branding shifted, not its license.** NVIDIA folded Triton into
its broader "Dynamo" inference platform in March 2025 — the product is now
also marketed as **NVIDIA Dynamo-Triton**, though both names remain in
active use in NVIDIA's own current docs. License and repo are unchanged.

| Library | For | License | Why recommended |
|---|---|---|---|
| **KServe** (`kserve/kserve`) | Online/real-time, Kubernetes-native serving via `InferenceService` CRDs and Knative-style serverless autoscaling | Apache-2.0, **CNCF Incubating** (accepted 2025-09-29, spun out of Kubeflow into its own CNCF project, not yet Graduated) | The vendor-neutral, Kubernetes-native default for a team wanting a CRD-first serving layer with built-in traffic-split canary rollout (see Canary section) — that rollout confirmed this pass to be serverless-mode-only, with `RawDeployment` support still an open feature request (`kserve/kserve#5335`, opened 2026-04-02). Direct GitHub fetch: 5,844 stars, 1,644 forks, 199 open issues, pushed 2026-08-30 (active); latest release `v0.20.0`, published 2026-08-06 |
| **BentoML** (`bentoml/BentoML`) | Online/real-time, also batch-friendly — Python-native "Bento" packaging format wraps a model + its runtime/dependencies into one deployable unit | Apache-2.0 (confirmed unchanged post-acquisition per Modular's own announcement) | The right choice for a Python-first team wanting the lowest-friction path from a trained model to a deployable service, without committing to Kubernetes; **BentoCloud** (commercial, Starter/Enterprise-BYOC tiers) is optional, not required. Direct GitHub fetch: 8,814 stars, 1,020 forks, 212 open issues, pushed 2026-08-28 (active); latest release `v1.4.39`, published 2026-05-07 |
| Seldon Core (`SeldonIO/seldon-core`, spans v1 and v2 in one repo) | Online/real-time, Kubernetes-native — the only framework here with built-in shadow-deployment and canary-deployment pipeline primitives purpose-built for model comparison (see Canary section) | **BSL 1.1** (non-production free; production/commercial requires a purchased license — see callout above) | Named as the honest incumbent for a team already invested in Seldon's pipeline model, not the default for a new project given the BSL production-use gate — weigh the commercial license cost against KServe/BentoML's fully open alternatives first. Direct GitHub fetch: 4,779 stars, 868 forks, 396 open issues, pushed 2026-03-23 (~5 months stale relative to this pass, worth a light flag); latest release `v2.10.2`, published 2025-12-19 |
| **Triton Inference Server** (`triton-inference-server/server`, also marketed as **NVIDIA Dynamo-Triton** since March 2025) | The most versatile of the four — genuinely fits batch, online/real-time, and streaming (audio/video) serving via dynamic/continuous batching | BSD-3-Clause, NVIDIA-led | Right when GPU-optimized, multi-framework (ONNX/TensorRT/PyTorch/TensorFlow) serving performance matters more than deployment-format simplicity — deepest NVIDIA-hardware optimization here, at the cost of a steeper configuration model. Direct GitHub fetch: 10,952 stars, 1,832 forks, 887 open issues, pushed 2026-08-31 (very active); latest release `v2.71.0`, published 2026-07-29 |

**Decision rule**: Kubernetes-native deployment with vendor-neutral
governance and built-in traffic-split canary support → **KServe**;
Python-first packaging with the lowest friction from notebook to deployable
service, Kubernetes optional → **BentoML**; GPU-heavy, multi-framework,
highest-throughput serving including streaming workloads →
**Triton/Dynamo-Triton**; already invested in Seldon's own pipeline model
and prepared to either stay non-production or purchase a commercial license
→ **Seldon Core**, not a first choice for a new greenfield project given the
BSL gate.

## Drift detection / monitoring tooling

**Alibi Detect's license changed at the same time as Seldon Core's.** A
direct fetch of `SeldonIO/alibi-detect`'s own `LICENSE` file confirms it is
**also BSL 1.1**, licensor Seldon Technologies Limited, effective since
January 2024 — the same non-production-free/production-paid structure and
four-year-per-release Apache-2.0 conversion clock as Seldon Core itself.
This pass also confirms *how* Alibi Detect plugs into Seldon Core 2
specifically: it is a **declarative dependency pattern**, not a bespoke
integration — a drift/outlier detection model is deployed as a standard
Seldon `Model` CRD with `alibi-detect` added to its `requirements`, then
wired into a Pipeline's async processing path (e.g., reading results off
Kafka rather than contributing to the synchronous prediction output). Worth
stating plainly: Alibi Detect is often cited in older tutorials as a plain
Apache-2.0 library; that stopped being accurate for any release from 2024
onward.

**WhyLabs/whylogs's history compressed into one clean but stale story.**
WhyLabs was **acquired by Apple in January 2025**; its commercial hosted
observability platform was then discontinued outright, and the company
open-sourced its entire platform codebase (`whylabs/whylabs-oss`) alongside
the pre-existing `whylogs` profiling library — no open-core gating left to
navigate. The less refreshing finding: both repos have seen essentially no
activity since — `whylogs` last pushed 2025-01-10 (latest release `v1.6.4`,
2024-12-03) and `whylabs-oss` last pushed 2025-01-24, both roughly 19 months
stale. This reads as a product line that went fully open the moment it also
went quiet, not a thriving actively-maintained project.

**Evidently's open-core split, verified precisely.** The `evidentlyai/
evidently` **core library is Apache-2.0 with no feature-gating on
evaluation/metrics/drift-detection capability itself** — Evidently's own
docs state the OSS library has "no artificial feature limits" on its core
evaluation functionality. What's gated behind the separate commercial
**Evidently Cloud** product is specifically collaboration (multi-user
dataset/project management), threshold alerting, a hosted dashboard, and
no-code evaluation workflows.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Evidently AI** (`evidentlyai/evidently`) — default | Statistical data/concept-drift detection, data-quality checks, and model-performance evaluation reports — the fully-open core, not gated | Apache-2.0 (open-core; see callout for exactly what Cloud adds) | The most actively developed, fully-open-for-its-core-use-case option here — the right default when a team doesn't need Cloud's collaboration/alerting layer on day one. Direct GitHub fetch: 7,866 stars, 905 forks, 299 open issues, pushed 2026-08-05 (active, ~4 weeks stale); latest release `v0.7.21`, published 2026-03-10 (~5.5 months stale — worth a light flag) |
| **NannyML** (`NannyML/nannyml`) | Performance-*estimation* without ground-truth labels — a genuinely distinct capability from Evidently's statistical-drift framing: estimates real accuracy/business-metric degradation before labeled outcomes are available | Apache-2.0 | Right specifically when a team needs an accuracy estimate ahead of ground-truth availability (long feedback-loop domains); not a replacement for Evidently's broader data-quality/drift-report feature set. Direct GitHub fetch: 2,151 stars, 192 forks, only 4 open issues, **pushed 2025-07-12 — over 13 months stale**, a real staleness concern worth weighing before adopting as a primary tool; latest release `v0.13.1`, same date |
| Alibi Detect (`SeldonIO/alibi-detect`) | Outlier/adversarial/drift detection algorithms library, deep research-grade coverage of detection methods; plugs into Seldon Core 2 as a declarative Model-CRD dependency (see callout above) | **BSL 1.1** (non-production free; production/commercial requires a purchased license, same terms as Seldon Core) | Named for completeness given its historically strong algorithmic breadth, but **not the default given the BSL gate** now applies to production use — weigh the license cost against Evidently/NannyML's fully-open alternatives first. Direct GitHub fetch: 2,548 stars, 253 forks, 146 open issues, pushed 2025-12-11 (~9 months stale); latest release `v0.13.0`, same date |
| whylogs (`whylabs/whylogs`) | Lightweight, framework-agnostic data-profiling library (statistical summaries of data flowing through a pipeline) | Apache-2.0 (fully open since the WhyLabs/Apple acquisition — no commercial platform left to gate anything, see callout above) | Named for completeness and because the licensing story is now clean, but **flagged plainly as effectively unmaintained post-acquisition** (~19 months without a commit) — only worth adopting if a team needs its lightweight profiling format and is prepared to self-maintain. Direct GitHub fetch: 2,831 stars, 144 forks, only 5 open issues, pushed 2025-01-10 (~19 months stale); latest release `v1.6.4`, published 2024-12-03 (~21 months stale) |

**Decision rule**: default to **Evidently** for drift/data-quality detection
given its active development and genuinely open core; add **NannyML**
specifically when ground-truth-free performance estimation is needed; treat
**Alibi Detect** as BSL-gated for production the same way Seldon Core itself
is gated, not a free default; treat **whylogs** as a legacy-but-license-clean
option only, given its near-two-year staleness.

## ML observability platforms

**Scope boundary, stated precisely.** [Agentic & MCP Platforms](agentic-mcp-platforms.md#testing-and-eval-tooling-for-agents)
already owns **Arize Phoenix** — that doc's own direct `LICENSE` fetch,
dated 2026-08-20, correctly states Phoenix is **Elastic License 2.0 (ELv2)**,
not Apache-2.0. Nothing about that entry needs revisiting here; Phoenix and
Arize's commercial platform ("Arize AX") are **genuinely separate products**,
so naming Arize below does not duplicate that doc's Phoenix entry. Phoenix
is open-source, self-hosted (SQLite/Postgres), development/debugging-
oriented. **Arize AX** is the proprietary, production-scale SaaS platform,
split into an **AX-Generative** edition (LLM/agent observability — the one
that would overlap with Agentic & MCP Platforms, out of scope here) and an
**AX-ML & CV** edition (traditional ML/computer-vision model monitoring at
production scale — the edition actually relevant to this category).

**Fresh, load-bearing event**: Dynatrace announced a definitive agreement to
**acquire Arize for $915M on 2026-08-13** — 18 days before this snapshot,
deal not yet closed as of this pass — a real, current ownership-transition
risk worth flagging to any team evaluating Arize AX today, not a settled
fact to treat as background.

**Fiddler AI** remains a fully proprietary SaaS observability/monitoring
platform (SaaS, on-prem, and self-hosted deployment options, but no
open-source component at all) — named as a comparable enterprise-tier
alternative to Arize AX, covering model performance, bias detection, and
explainability (Shapley-value-based) for both traditional ML and generative
workloads in one platform. Neither Arize AX (AX-ML & CV edition) nor Fiddler
publishes a public repo or license to direct-fetch — both are named at the
"what exists and is current" level, the same convention this doc's own
cloud-registry and cloud-feature-store rows use, rather than forced into a
license/stars table that doesn't apply to either.

**Decision rule**: a team already on Arize (any edition) should treat the
Dynatrace acquisition as an open risk to monitor, not a reason to switch
today; a team choosing fresh between the two should weigh Arize AX's
broader ML+CV+LLM edition split against Fiddler's single unified platform
and its lack of any acquisition overhang.

## Retraining-pipeline trigger mechanics

**No dedicated, libraries-table-worthy tool exists for this — verified by
explicit search, not assumed.** What connects a drift-monitoring signal to a
training-pipeline kickoff in current practice is an **event-driven sensor
pattern layered on top of already-covered general orchestrators**, not a
purpose-built product: a drift-detection tool (Evidently/NannyML above)
crosses a configured threshold, fires a webhook or writes a signal file, and
a sensor already native to whichever orchestrator a team runs
(Airflow/Dagster/Prefect sensors, already named in
[Data & Analytics Platforms](data-analytics-platforms.md); or Argo
Workflows/Kubeflow Pipelines, already named in
[ML / AI Model Development](ml-model-development.md#ml-specific-pipeline-orchestration))
picks it up and kicks off a versioned retraining run. This is genuinely more
of an architecture question — its right home is the companion
[stacks/mlops-platform-engineering.md](../stacks/mlops-platform-engineering.md)'s
decision-criteria treatment, not a forced table row here. Most current
production write-ups converge on running both a fixed-cadence scheduled
retrain *and* an event-triggered on-demand retrain side by side, not one
mechanism replacing the other.

## Canary/shadow-deployment tooling for models

**Scope boundary**: [Infrastructure & Platform Engineering](infrastructure-platform-engineering.md)
already covers generic Kubernetes progressive-delivery mechanics (Argo
Rollouts, Flagger) — this section asks specifically whether anything
purpose-built for *model-quality-driven* canary judgment (not just
HTTP-traffic-percentage splitting) exists and is current.

**Kayenta, the one tool that historically did this, is retired as a
standalone project — confirmed via direct fetch, not assumed**:
`spinnaker/kayenta` (Netflix/Spinnaker's automated canary-analysis service,
which computed a statistical judgment of whether a canary was degraded
relative to a baseline) shows `archived: true`, last pushed **2025-12-20**.
Its functionality has been folded into the main Spinnaker monorepo rather
than continuing as a separately maintained repo — the project's *capability*
persists inside Spinnaker, but there is no longer a standalone Kayenta to
recommend as its own entry.

**What exists today instead is native-but-metrics-agnostic traffic
splitting**, re-verified this pass for both Kubernetes-native serving
frameworks named above. **KServe**'s `InferenceService` supports a real,
built-in `canaryTrafficPercent` field: KServe automatically tracks the last
known-good revision at 100% traffic and splits traffic to a new revision
according to the configured percentage — but this is confirmed
**serverless/Knative-mode-only** (via Istio `VirtualService` revision
weights), with no built-in model-quality-metric judge and, as of this pass,
no `RawDeployment`-mode equivalent: extending it there via Gateway API
`HTTPRoute` weights is tracked in a **still-open** GitHub issue
(`kserve/kserve#5335`, opened 2026-04-02, last updated 2026-06-12) — a
concrete, current gap, not a settled feature. A real quality-driven
promotion decision still requires querying an external metrics source
(Evidently/NannyML/Arize AX above) and gating the rollout from outside.
**Seldon Core** goes one step further architecturally: it has native
**shadow-deployment** (mirrors live traffic to a candidate model without
serving its predictions, for offline comparison) and **canary-deployment**
(percentage-split live A/B) primitives built directly into its pipeline
model — genuinely more purpose-built for model comparison than KServe's flat
traffic-split, though the same BSL production-use gate named above applies
to it.

**Honest conclusion, stated plainly rather than forcing an entry**: no
current tool provides fully automated statistical model-quality canary
judgment out of the box the way Kayenta once did. Current practice is a
metrics-provider query (from this doc's own drift/observability tooling)
layered on top of either KServe's or Seldon's native traffic-shifting
primitives, or on the generic Argo Rollouts/Flagger mechanics
Infrastructure & Platform Engineering already covers — a real gap in the
current tooling landscape, not an oversight in this doc's research.

## Where this doc stops

LLM-specific serving infrastructure (vLLM, TensorRT-LLM) and
LLM-application/agent observability (Langfuse, DeepEval, Promptfoo,
LangSmith, and Arize Phoenix specifically) belong to
[Agentic & MCP Platforms](agentic-mcp-platforms.md), already shipped — this
doc's serving section covers general/traditional ML model serving only, and
its ML-observability section names the genuinely separate Arize AX (AX-ML &
CV edition) and Fiddler AI instead, with the Phoenix-vs-AX distinction
stated explicitly to avoid duplication. Generic Kubernetes
progressive-delivery mechanics (Argo Rollouts, Flagger) and IaC/config drift
detection belong to
[Infrastructure & Platform Engineering](infrastructure-platform-engineering.md),
already shipped — this doc's own drift section covers the statistically
distinct *model*-drift concern, and its canary section explicitly builds on
top of (not duplicating) that doc's traffic-shifting tooling.
Model-development-stage MLflow framing and Hugging Face Hub tooling belong
to [ML / AI Model Development](ml-model-development.md), already shipped —
this doc's registry section re-examines MLflow specifically from the
production-promotion-gate angle per that doc's own explicit handoff. General
data-pipeline orchestrators (Airflow, Dagster, Prefect) and ML-specific
pipeline orchestrators (Kubeflow Pipelines, Metaflow) belong to
[Data & Analytics Platforms](data-analytics-platforms.md) and
[ML / AI Model Development](ml-model-development.md) respectively, both
already shipped — this doc's retraining-trigger section points to their
existing sensor/event-trigger mechanics rather than re-listing them.
Retraining-pipeline architecture depth (exactly how a drift signal should be
wired to a specific orchestrator, what threshold/hysteresis logic to use) is
a `stacks/mlops-platform-engineering.md`-shaped architecture question, not a
specific-tool question — named honestly as "pattern, not product" above
rather than forced into a table. Hopsworks' commercial-tier feature depth
beyond the license/staleness finding above, and SageMaker/Vertex AI Feature
Store's exact feature parity with Feast, were named at a one-line existence
level only, not independently deep-researched — a real gap worth a
follow-up if a project's stack is specifically hyperscaler-committed. Exact
current dollar figures beyond the named commercial-tier/licensing traps
(Comet ML's exact enterprise pricing, exact BentoCloud/Databricks Feature
Store pricing, Seldon's unpublished commercial pricing) were
search-corroborated where cited, not independently direct-fetched against
every vendor's own live pricing page.

## Sources

- Local `find`/`grep`/direct-read passes (not web sources), 2026-08-31:
  confirmed absence of any feature-store/drift/registry/canary-shaped file
  or dependency under `/Users/devopammittra/GitHub/ubi-csr-tmf` and this
  repo; full direct read of `ubi-csr-tmf/aws/container/{backend/app,
  agents}/requirements.txt`.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`, `archived`) for: kserve/kserve,
  bentoml/BentoML, SeldonIO/seldon-core, triton-inference-server/server,
  mlflow/mlflow, feast-dev/feast, evidentlyai/evidently, NannyML/nannyml,
  SeldonIO/alibi-detect, whylabs/whylogs, whylabs/whylabs-oss,
  Arize-ai/phoenix, spinnaker/kayenta, VertaAI/modeldb, mlrun/mlrun —
  retrieved 2026-08-31.
- **Re-verification during this authoring pass (2026-08-31)**: direct `gh
  api` re-fetch of mlflow/mlflow, feast-dev/feast, kserve/kserve,
  bentoml/BentoML, SeldonIO/seldon-core, evidentlyai/evidently,
  NannyML/nannyml, and SeldonIO/alibi-detect — all figures matched the
  baseline within normal single-day drift (MLflow's open-issue count moved
  from 2,057 to 2,058), confirming these are live, reproducible numbers.
- **New this authoring pass**: `gh api repos/logicalclocks/hopsworks`
  (license `AGPL-3.0`, `pushed_at` 2025-02-10) and `gh api
  repos/logicalclocks/hopsworks/releases/latest` (`v3.7.0`, published
  2024-03-02), plus a direct fetch of
  `https://raw.githubusercontent.com/logicalclocks/hopsworks/master/LICENSE`
  confirming the AGPLv3 header text; and `gh api
  repos/logicalclocks/feature-store-api` (license `Apache-2.0`,
  `pushed_at` 2025-09-24) — establishing the platform-vs-client
  license/staleness split named in the Feature stores section above —
  retrieved 2026-08-31.
- **New this authoring pass**: `gh api repos/kserve/kserve/issues/5335`
  (state `open`, created 2026-04-02, updated 2026-06-12) — confirming
  `RawDeployment`-mode canary support remains an open feature request, not
  shipped behavior — retrieved 2026-08-31.
- **New this authoring pass**: WebSearch corroboration of Seldon Core 2's
  Alibi Detect integration mechanism (`docs.seldon.ai` drift/outlier-
  detection pages, `docs.seldon.io/projects/seldon-core` outlier-detection
  docs) — confirming the declarative `requirements: [alibi-detect]`
  Model-CRD pattern and async Pipeline/Kafka wiring described above —
  retrieved 2026-08-31.
- `https://mlflow.org/docs/latest/self-hosting/webhooks/` — direct fetch
  confirming MLflow's webhook feature (`model_version.created`,
  `model_version_tag.set`, and related events; HMAC signature verification,
  admin-only when Auth is enabled) is documented under MLflow's own
  self-hosting doc tree, not gated to Databricks-managed MLflow — retrieved
  2026-08-31.
- `https://raw.githubusercontent.com/SeldonIO/seldon-core/master/LICENSE`
  and `https://raw.githubusercontent.com/SeldonIO/alibi-detect/master/
  LICENSE` — direct fetches confirming BSL 1.1 text, January 2024 effective
  date, four-year-per-release Apache-2.0 conversion clause for both —
  retrieved 2026-08-31.
- `https://raw.githubusercontent.com/evidentlyai/evidently/main/LICENSE`,
  `.../NannyML/nannyml/main/LICENSE`, `.../whylabs/whylogs/mainline/LICENSE`
  — direct fetches confirming Apache-2.0 for each — retrieved 2026-08-31.
- `https://lfaidata.foundation/projects/feast/` — direct fetch/search
  confirming current Incubation-stage maturity, not yet Graduated —
  retrieved 2026-08-31.
- `skills/project-incubation/references/preferred-libraries/
  agentic-mcp-platforms.md` — read directly to confirm the Phoenix-vs-Arize-
  AX scope boundary and reconfirm that doc's own already-correct
  Elastic License 2.0 citation for Phoenix (dated 2026-08-20) needs no
  follow-up patch — read 2026-08-31.
- WebSearch corroboration (not independently direct-fetched primary source,
  flagged inline where used): Dynatrace/Arize acquisition terms and
  2026-08-13 announcement date (dynatrace.com, businesswire.com,
  forbes.com, msspalert.com); BentoML/Modular acquisition and
  OSS-commitment statement (Modular's own posts, bentoml.com); Tecton/
  Databricks acquisition and Feature-Store-API consolidation (databricks.com,
  fenwick.com, mitsloanme.com); WhyLabs/Apple acquisition and platform
  open-sourcing (appsecsanta.com); MLflow stage-deprecation/aliases-tags
  current docs (mlflow.org, github.com/mlflow/mlflow issue #14677); Comet
  Model Registry positioning and pricing (capterra.com, pricingsaas.com);
  KServe CNCF Incubating acceptance date (cncf.io's own KServe project
  page, thenewstack.io, redhat.com); KServe canary-rollout mechanics
  (kserve.github.io's own docs, github.com/kserve/kserve); Triton/
  Dynamo-Triton rebranding (nvidia.com, docs.nvidia.com); Evidently
  open-core feature split (docs.evidentlyai.com's own OSS-vs-Cloud FAQ);
  Arize Phoenix-vs-AX product-split framing (atlan.com); Fiddler AI current
  positioning (fiddler.ai); Kayenta archival into the Spinnaker monorepo
  (spinnaker.io, github.com/spinnaker/kayenta); retraining-trigger
  event-sensor patterns (123ofai.com, mlopslab.org, devopsroles.com) — all
  retrieved 2026-08-31.
- `research/stacks/mlops-platform-engineering/libraries.md` — read in full
  as this doc's approved research baseline; the Hopsworks license-split/
  staleness finding, the KServe `RawDeployment`-canary open-issue finding,
  and the Seldon/Alibi-Detect integration-mechanism precision above are new
  to this authoring pass and were not present in the baseline.
- `research/stacks/ml-model-development/libraries.md` and
  `research/stacks/infrastructure-platform-engineering/libraries.md` —
  read to confirm this doc's own scope boundaries and exact handoff points.
