# Baseline: MLOps / ML Platform Engineering — Architecture & Stack
Status: draft      Date: 2026-08-31

## Local precedent — checked directly this pass, a different question than ML/AI Model Development's own check

`ML / AI Model Development`'s own baseline already confirmed a clean absence of
*training*-shaped artifacts on this machine (no notebooks, no `train*.py`, no
MLflow/W&B/DVC config, no weight files). This pass asked the genuinely
different question that category's own baseline flagged as unanswered: is
there any **production/serving-operations** signal — model-serving deployment
config, a feature-store reference, drift-monitoring code, a model-registry
integration, or a retraining-trigger workflow — regardless of whether any
training code exists locally.

**`/Users/devopammittra/GitHub/ubi-csr-tmf`** — searched directly this pass,
`grep -ril` across the whole tree (excluding `.git/`) for
`drift|feature.?store|model.?registry|retrain|canary|shadow.?deploy|mlflow|
seldon|kserve|bentoml|triton|feast|mlops`, plus a targeted `find`/`grep` over
`charts/*/*.yaml` for `rollout|canary|drift`: **zero MLOps-shaped matches**.
The only string hits at all were the bare word "drift" in six unrelated
files, each individually opened and confirmed benign — `migrations/env.py`
uses "drifts out of sync" to describe an Alembic schema-version-table
misconfiguration risk, and `usePhaseTimers.ts`/`StepGenerateDocumentV1.tsx`
use "NTP drift"/`driftSec` to describe client-wall-clock vs. server-clock
skew in a document-generation progress timer — both ordinary software usages
of the word, not model or data drift. No Helm chart carries a
`rollout`/`canary`/`drift` key. This is a genuinely clean absence, the same
"not a weak analogy forced onto an adjacent repo" finding the ML/AI Model
Development baseline reached for training code, now independently confirmed
for the serving/operations half of this category too — worth stating
precisely rather than assuming it from the sibling doc's training-side
finding, since (per this task's own framing) a repo could plausibly have
model-serving infrastructure with zero training code, and this pass checked
that possibility directly rather than skipping it as redundant.

`ubi-csr-tmf`'s own `aws/container/agents/` component remains, as the ML/AI
Model Development baseline already established, an LLM-agent application
calling a hosted model API at inference time — Agentic & MCP Platforms
territory. That finding doesn't change here; this pass's own contribution is
confirming that *even the operational half* of the MLOps concern set
(registries, feature stores, drift monitors, retraining triggers, canary/
shadow rollout mechanics) is absent too, not merely the training half.

**`/Users/devopammittra/GitHub/agent-skills`** (this repo) — no deployment
target of any kind exists here (confirmed by the Infrastructure & Platform
Engineering baseline: no `.github/workflows/`, no Dockerfile, no Helm chart,
no IaC file anywhere in the tree), so by construction there is nothing
MLOps-shaped to find; noted briefly per this pass's own convention of
confirming rather than skipping, not because it adds new information.

Consistent with the `ml-model-development.md` and `backend-api-services.md`
baselines' own convention for this situation: every recommendation below is
backed by external primary sources with direct fetches where possible, not a
local worked example.

## In scope

- **Model drift monitoring: data drift vs. concept drift as genuinely
  different failure modes, and why this is a different kind of "drift" than
  IaC drift** — impact: high — depth: section, anchored on direct fetch of
  Evidently AI's own data-drift documentation
  (`evidentlyai.com/ml-in-production/data-drift`). **Data drift** is "a
  shift in the distributions of the ML model input features" — the
  incoming data a deployed model sees no longer resembles the data it was
  trained on, while the true input→output relationship is unchanged.
  **Concept drift** is a change in that relationship itself: the same input
  now warrants a different prediction than it did at training time — a
  fraud-detection example worth carrying forward as the sharpest available
  illustration: fraudsters actively adapt their behavior specifically to
  evade a deployed model, so the same transaction pattern that was benign
  yesterday can be fraudulent today, with no meaningful shift in the raw
  feature distributions themselves. Evidently's own retail example for data
  drift without concept drift: a shift toward online purchases changes
  input distributions without necessarily changing the underlying
  input→outcome relationship. The two frequently co-occur but are not
  synonymous, and — the operative practical point for an authored doc —
  they call for different responses: data drift alone may or may not
  degrade the model (it depends on whether the shifted region of input
  space is one the model handles well), while concept drift by
  construction means the model's *learned mapping* is now wrong regardless
  of how it currently classifies the shifted inputs, so a
  quality/performance-anchored monitor (Model Evaluation's offline metrics
  applied continuously against fresh ground truth, per the Model-Serving
  section below) is the only detection method that can directly see
  concept drift, whereas both concept and data drift can be *suspected*
  from an input-distribution monitor. **Why this is a genuinely different
  problem from Infrastructure & Platform Engineering's own IaC drift
  detection, not a coincidental reuse of the same word**: that category's
  drift detection (`terraform plan -detailed-exitcode`, CloudFormation's
  `detect-stack-drift` API) has a **single, authoritative ground truth to
  diff against** — the declared configuration — so "is there drift" is a
  binary, mechanically-checkable fact with an exact expected-vs-actual
  property diff. Model drift has **no single ground-truth diff**: there is
  no declared "correct" input distribution to compare live traffic
  against, only a reference distribution (typically the training or a
  recent-past production window) and a *statistical judgment call* about
  whether an observed difference between two distributions is large enough
  to matter — the practical consequence being that model-drift detection
  always resolves to a chosen distance metric plus a chosen alerting
  threshold, both of which are configuration decisions a team makes rather
  than a fact IaC drift detection just reports. This is the same
  same-word-different-meaning discipline the Infrastructure & Platform
  Engineering baseline already applied to "idempotency" (a whole
  re-appliable configuration there, a single non-double-executing request
  in Backend & API Services), now applied to "drift" across this
  category's IaC-provisioning sibling and this one.
  **Statistical detection methods, verified current rather than an
  exhaustive stats-textbook list** (confirmed by direct fetch of
  Evidently's own docs, cross-checked against AWS's current 2026 SageMaker
  monitoring-replacement guidance below): **Population Stability Index
  (PSI)** — originally developed for risk-scorecard monitoring, now used
  broadly across model input/output distributions, valued for returning a
  sample-size-independent (hence more "predictable" and interpretable)
  score, unlike KS; **Kolmogorov-Smirnov (KS) test** — a nonparametric
  hypothesis test for whether two samples come from the same distribution,
  applied per-numeric-feature; **Chi-squared test** — the categorical-
  feature analogue of KS; **KL (Kullback-Leibler) divergence** — measures
  how one distribution diverges from a reference, a reasonable default for
  larger datasets, with a specific, named mechanical caveat worth carrying
  into the authored doc: KL divergence is **not symmetric** and does not
  satisfy the triangle inequality, and can diverge to infinity when a
  region of the reference distribution has zero density where the current
  distribution has nonzero density; **Wasserstein distance** and
  **Jensen-Shannon divergence** are both named current alternatives (JS
  divergence is explicitly the symmetrized, always-finite variant of KL).
  No single canonical alerting threshold exists across sources — Evidently's
  own docs deliberately avoid stating one — but one concrete, current,
  primary-source-confirmed number is worth naming precisely as a real
  worked default rather than an industry standard: AWS's own current
  (2026) open-source SageMaker Model Monitor replacement reference
  implementation (see Model registries/serving section below) ships with a
  default alert threshold of **more than 30% of features drifted** at the
  batch-pipeline level and a `DriftThreshold` default of **0.05** share of
  drifted columns at the lightweight real-time-endpoint level — stated
  explicitly in that source as configurable, per-project defaults in a
  reference implementation, not a universal industry threshold, and named
  here for that reason (a concrete anchor, not a number to present as
  received wisdom).

- **Feature stores: the training/serving skew problem they concretely
  solve, and the offline/online store architecture pattern** — impact:
  high — depth: section, anchored on direct fetch of Uber's own
  Michelangelo platform engineering blog post
  (`uber.com/blog/michelangelo-machine-learning-platform/`) as the
  originating real-world case, corroborated by direct fetch of Feast's own
  architecture and point-in-time-join documentation. **The concrete
  problem**: a feature computed one way for offline model training (e.g. a
  Spark/Hive batch job scanning historical data) and a subtly different way
  for online serving (e.g. a different code path computing the same
  logical feature against live request data) is a real, documented,
  hard-to-debug failure mode — the model was trained on one definition of
  a feature and is served a slightly different one at inference time, and
  because the discrepancy is *subtle* (not a missing column, a genuinely
  different numeric value for what's nominally "the same" feature) it
  frequently manifests only as unexplained accuracy degradation rather
  than an obvious bug. **The offline/online store architecture pattern**,
  confirmed as the shape both Uber's original platform and Feast's current
  open-source implementation converge on: a **batch-computed offline
  store** (Michelangelo: Spark/Hive jobs writing to HDFS; the general
  pattern: a data-warehouse/lake-backed store optimized for large
  historical scans) serves training-time feature retrieval, and a
  **low-latency online store** (Michelangelo: Cassandra; the general
  pattern: a key-value store optimized for single-entity point lookups
  under tight latency budgets) serves inference-time feature retrieval —
  both **derived from the same feature definitions**, not two independently
  maintained implementations of "the same" feature. Michelangelo's own
  documented mechanism for guaranteeing this: feature transformations are
  expressed once in a domain-specific language and "the same data and
  batch pipeline is used for both training and serving" wherever possible,
  with a near-real-time path (Kafka → streaming compute → the online
  store directly) for features that can't wait for a batch cycle — the
  same transformation logic applied at both training time and prediction
  time is explicitly named as what "guarantee[s] that the same final set
  of features is generated." **Point-in-time correctness**, confirmed by
  direct fetch of Feast's own point-in-time-join documentation, is the
  offline store's own distinct mechanical safeguard against a related but
  separate failure mode — **label leakage via backfilled/corrected
  features**: a naive join of "current" feature values against historical
  training labels can silently pull in a feature value that was corrected
  or backfilled *after* the label's event actually occurred, letting the
  model train on information that would not have been available at
  real-world prediction time. Feast's mechanism (`created_timestamp <=
  entity_timestamp`, confirmed by direct fetch) reconstructs "what the
  online store would have served" at each historical event time rather
  than joining against each feature's latest known value — a training-data-
  construction safeguard that pairs with, but is mechanically distinct
  from, the training/serving-skew problem above (skew is about the
  *computation path* differing between training and serving; point-in-time
  correctness is about the *temporal validity* of which feature value gets
  joined into a training row). This pattern (Michelangelo, Feast, and — per
  search corroboration, not independently direct-fetched this pass —
  Airbnb's Zipline and Databricks' own Feature Store) has been
  productionized enough times, by enough independent organizations, that
  it's the settled architectural shape for this concern rather than one
  team's idiosyncratic design; specific current tool comparison (Feast vs.
  Tecton vs. Databricks Feature Store vs. Hopsworks) belongs to the
  companion `libraries.md`, not here.

- **Model registries at the production-promotion stage — distinct from ML/
  AI Model Development's own artifact-storage-stage registry framing** —
  impact: high — depth: section, anchored on direct fetch of MLflow's own
  current Model Registry docs and a follow-up search confirming MLflow's
  own stages→aliases migration. **The dividing line, stated precisely**:
  ML/AI Model Development's own experiment-tracking section already covers
  a run's metadata-store/artifact-store split for *recording* a training
  run's outputs; this category owns what happens **after** a specific
  model version is a registry candidate — the **staging→production
  promotion decision** for a model version that already exists as a
  registered, versioned artifact. Concretely, per MLflow's own docs: every
  registration of a model under a registered-model name **automatically
  increments a version number**, addressable by URI (`models:/MyModel/1`)
  — this versioning-on-registration mechanic is the same regardless of
  whether the version is still under evaluation or already serving
  production traffic, which is exactly why a *separate* promotion signal
  is needed on top of version numbering alone. **MLflow's own promotion
  mechanism has itself changed, and the change is worth naming precisely
  as a same-category example of the "a label naming a pattern isn't the
  same as implementing it" caution the Infrastructure & Platform
  Engineering baseline already gave for its own local precedent's inert
  `release: blue-green` Helm label**: MLflow's older **stages** model
  (None → Staging → Production → Archived, a fixed four-value lifecycle
  field on a model version) is now explicitly being replaced by **model
  version aliases** — "a mutable, named reference to a particular version
  of a registered model" — because, per MLflow's own migration guidance,
  aliases let more than one label apply to a given model version
  simultaneously (search-corroborated: "easier A/B testing and model
  rollout" as the stated reason), which a single fixed `stage` field
  cannot express. The concrete production-promotion workflow this enables:
  assign a `champion` alias to the model version intended to serve the
  majority of production traffic, and **promotion is the act of
  reassigning that alias to a different model version** — a single,
  atomic pointer update rather than a bulk-copy or re-deployment of the
  model artifact itself, addressable afterward via
  `models:/<name>@champion`. **Approval gates**, per this same direct
  fetch, are only partially formalized in MLflow's own current docs: tag-
  based conventions like `validation_status:pending` /
  `validation_status:approved` are named as a pattern, but MLflow's own
  documentation does not describe a built-in, enforced approval workflow
  gating an alias reassignment the way (for comparison) a GitHub
  Environment's required-reviewer rule gates a deployment — an honest
  current-capability gap worth stating rather than glossing over, the same
  way the Infrastructure & Platform Engineering baseline named HCP
  Terraform's Sentinel as the enforced-policy-gate option and OPA/Conftest
  as the portable equivalent for IaC. **Serving-stage lineage**: because a
  version number and an alias are both first-class, queryable registry
  fields, "which exact model version is `champion` right now, and what was
  `champion` before it" is a directly queryable fact rather than something
  reconstructed from deploy logs — the production-serving analogue of the
  experiment-tracking section's own "which run produced this metric"
  traceability goal, now applied to "which registered version is actually
  live" rather than "which run produced a given number." Specific
  registry-product comparison (MLflow Model Registry vs. a cloud-native
  registry vs. Databricks Unity Catalog's own model-governance layer)
  belongs to `libraries.md`.

- **Canary and shadow deployment for models — a distinct pattern shape from
  generic application progressive delivery, and what's genuinely different
  when the promotion signal is a model-quality/drift metric** — impact:
  high — depth: section, anchored on direct fetch of a canary-vs-shadow
  comparison piece cross-checked against direct fetch of Argo Rollouts' own
  AnalysisTemplate documentation. **Shadow deployment** — confirmed
  real, current, and mechanically distinct from canary, not an assumed-to-
  exist pattern: a candidate model receives a **duplicate of production
  traffic** (typically the full volume, not a percentage slice) processed
  **in parallel** with the currently-live model, but the candidate's
  predictions are **never served to users or acted on** — only logged and
  compared offline against the live model's actual served predictions.
  **Canary deployment** for a model, by contrast, routes a genuinely
  **live-serving slice of real traffic** (commonly starting around 1%,
  ramping incrementally) to the candidate, whose predictions *do* reach
  users — meaning canary answers "does this model perform acceptably with
  real users in the loop," a question shadow deployment cannot answer
  because shadow-mode predictions never have real-world consequences to
  observe. The two compose rather than compete in practice: shadow
  deployment is the safer first validation pass (confirms the candidate
  doesn't behave wildly differently against the real production
  distribution, with zero user-facing risk), canary is the subsequent
  pass that validates the candidate's *served* behavior once shadow
  testing has already de-risked it. **How this connects to, without
  duplicating, Infrastructure & Platform Engineering's own
  progressive-delivery mechanics**: that category's baseline already
  covers the generic canary/blue-green mechanism at the Kubernetes-native
  Custom Resource level (Argo Rollouts' `Rollout` CRD, the Flux-family
  Flagger controller), including its own AnalysisTemplate/AnalysisRun
  metric-gate mechanism — a metric provider is queried on an interval,
  and success/failure conditions against that metric's value gate whether
  a canary keeps ramping, holds, or auto-rolls-back. **Confirmed by direct
  fetch of Argo Rollouts' own analysis docs this pass**: this mechanism is
  explicitly **metric-source-agnostic** — Prometheus, Datadog, CloudWatch,
  InfluxDB are built in, and a generic Web provider accepts an arbitrary
  HTTP endpoint plus a JSON-path evaluation for anything not natively
  supported. **This is precisely the layering point this category owns and
  Infrastructure & Platform Engineering does not**: nothing about the
  generic canary-controller mechanism changes when the gating metric is a
  model-quality score or a drift statistic instead of an HTTP error rate
  or p99 latency — what this category adds is *naming that a model-quality/
  drift signal is a valid, real, and increasingly common choice of gating
  metric*, and that computing that signal (a drift score, a live accuracy
  proxy against delayed ground truth, a prediction-confidence-distribution
  shift) is itself the model-monitoring machinery described earlier in
  this doc, wired into the generic canary controller as just another
  metric-provider query rather than a separate rollout mechanism. Seldon
  Core v2's own documented positioning (search-corroborated, not
  independently direct-fetched this pass) names built-in drift detection
  via the open-source **Alibi Detect** library as a first-class capability
  alongside its own canary/A-B-testing rollout support — a real, current
  concrete instance of a model-serving platform treating drift-as-a-gating-
  signal as a native feature rather than a bolted-on integration, worth
  naming as the illustrative anchor for this section's own claim rather
  than an assumed-to-exist capability. KServe similarly documents native
  canary traffic-splitting for an `InferenceService` (a `canaryTrafficPercent`
  field automatically comparing against the last-known-good revision,
  search-corroborated). Specific tool comparison and version/adoption
  detail (Seldon Core vs. KServe vs. BentoML, Alibi Detect vs. Evidently
  for the drift-scoring layer itself) belongs to `libraries.md`.

- **Retraining triggers — the connective tissue between this category's
  monitoring signals and ML/AI Model Development's own training pipeline**
  — impact: high — depth: section, anchored on direct fetch of Google
  Cloud's own "MLOps: Continuous delivery and automation pipelines in
  machine learning" architecture guide — a widely-cited, currently-live
  primary source (not a secondary aggregator) naming five concrete,
  currently-relevant trigger conditions for an automated retraining
  pipeline run: **(1) on-demand** — a manual, ad hoc pipeline invocation;
  **(2) scheduled** — a calendar cadence (daily/weekly/monthly) run
  whenever fresh labeled data is expected to have accumulated;
  **(3) new-training-data availability** — triggered directly by data
  arrival in a source system rather than a fixed clock, avoiding both
  wasted compute on an unchanged-data schedule tick and a missed-update gap
  between ticks; **(4) model-performance degradation** — triggered once a
  live-serving quality signal (the Model-Serving section below's
  performance-monitoring half) crosses a defined threshold; **(5)
  significant data-distribution shifts** — triggered by the drift-detection
  machinery described earlier in this doc crossing its own configured
  threshold, explicitly named in this source as the concept-drift trigger
  case. **The architectural shape this doc's task framing specifically
  asked to name — an event, not a human decision, in a mature setup**:
  this same Google Cloud source describes the monitoring stage's own job
  as collecting "statistics on the model performance based on live data"
  and producing, as its output, "a trigger to execute the pipeline or to
  execute a new experiment cycle" — stated as a direct architectural
  output of monitoring, not a dashboard a human watches and then manually
  kicks off a job from. Concretely, this is the event-driven pattern the
  cross-cutting `architecture-templates.md` catalog already names (an
  event triggering a downstream process) applied at this category's
  specific seam: a drift-detector or performance-monitor crossing its
  threshold **emits an event** (a message on a queue, a webhook call, a
  scheduled-check's own conditional branch) that a training-pipeline
  orchestrator consumes as its own kickoff signal — the same "an event,
  not a human decision" framing ML/AI Model Development's own pipeline-
  specialization section already named as a legitimate downstream
  serverless-shaped component ("a lightweight retraining-trigger function
  reacting to a new-data-arrived event"), now given its concrete trigger
  taxonomy. **Practical default worth stating explicitly**: scheduled
  retraining alone is a reasonable, low-complexity starting point for a
  new project (search-corroborated framing, not independently traced to
  the Google Cloud source specifically), but a maturing platform's real
  goal is drift/performance-threshold-triggered retraining precisely
  because it aligns pipeline execution with when the data or the model's
  behavior has actually changed, rather than running (and paying for)
  retraining on a clock regardless of whether anything changed — the same
  "re-running against an unchanged input should produce zero redundant
  work" idempotency-adjacent framing the Infrastructure & Platform
  Engineering baseline already applies to IaC applies here to compute
  spend on unnecessary retraining runs, though the mechanism achieving it
  (an event trigger vs. IaC's own no-op-detecting `plan`) is different in
  kind, not just domain.

- **Model-serving infrastructure at the general-ML level: batch, online/
  real-time, and streaming inference as three genuinely distinct serving
  shapes** — impact: high — depth: table, cross-checked between Google
  Cloud's own MLOps architecture guide and multiple current secondary
  comparison sources (no single vendor-neutral primary source stating all
  three side by side was found this pass, flagged honestly rather than
  presented as one canonical citation). **Batch inference** — predictions
  computed over an accumulated dataset on a schedule or triggered run, with
  no caller waiting synchronously for an individual result; Google Cloud's
  own framing names this as a model deployed as part of a batch-processing
  system. The architectural consequence: **compute only needs to exist for
  the duration of the batch job**, favoring cost-efficient, elastically-
  scaled batch compute over an always-on serving endpoint, at the cost of
  every prediction being as stale as the last batch run's cutoff. **Online/
  real-time inference** — predictions computed synchronously per-request,
  with an immediate response expected; Google Cloud's own framing names
  this as "microservices with a REST API to serve online predictions," the
  same request/response shape Backend & API Services already owns for
  ordinary application services, here specialized by a **fixed, materially
  higher standing-compute cost** (a real-time serving endpoint has to be
  available continuously to answer requests within a latency budget, not
  spun up on demand for a batch window) and, per the feature-store section
  above, a **hard latency ceiling on the feature-lookup path** that a batch
  job's own feature computation doesn't have to meet at all. **Streaming
  inference** is the genuinely distinct third shape, not a synonym for
  "fast online inference": predictions are computed continuously as events
  arrive from a stream (search-corroborated framing: "sensor readings, log
  events, or clickstream data" as the typical event source), with results
  flowing into downstream systems rather than back to a single synchronous
  caller — architecturally closer to Integration & Event-Driven Systems'
  own event-processing shape than to a request/response service, and
  distinguished from batch by having no natural "end of batch" boundary at
  all. **Decision rule for a new project, synthesized from the above rather
  than lifted verbatim from one source**: batch inference is the right
  default whenever predictions can tolerate being as stale as the last
  scheduled run and no individual caller needs a synchronous answer (the
  common case for large-scale scoring jobs, periodic reports, bulk
  re-scoring after a model update); online/real-time inference is required
  whenever a user-facing or otherwise interactive flow needs a prediction
  before it can proceed; streaming inference is the right shape only when
  predictions genuinely need to react to an unbounded, continuously-
  arriving event source rather than either a fixed batch or a
  caller-initiated request — reaching for it by default when online
  inference would actually suffice adds real architectural complexity
  (a stream-processing runtime, at-least-once/exactly-once delivery
  semantics) for no benefit. This category's serving-shape decision is the
  explicit non-LLM counterpart to whatever Agentic & MCP Platforms already
  covers for LLM-specific serving (already shipped, out of scope here per
  Explicitly-out-of-scope below) — the same three shapes recur for
  general-ML model serving without the LLM-specific concerns (streaming
  token-by-token generation, prompt caching) that category owns instead.

- **How this category specializes the cross-cutting
  `architecture-templates.md` pattern catalog, and how it differs from a
  plain request/response service** — impact: high — depth: section. Every
  other stack baseline in this repo treats "what kind of system is this"
  as answerable with one dominant pattern (Backend & API Services: request/
  response; Data & Analytics Platforms and ML/AI Model Development: a
  pipeline/DAG; Integration & Event-Driven Systems: event-driven). An
  MLOps system is architecturally **at least two of these composed
  together, with a feedback loop connecting them**, which is the concrete
  thing that makes it a distinct architectural shape rather than a variant
  of any single one: **(1)** a request/response (or batch/streaming, per
  the Model-Serving section above) inference-serving component, matching
  Backend & API Services' own request/response framing for the
  online-inference case specifically; **(2)** a continuous
  monitoring/observation loop over that serving component's live traffic
  and outputs — structurally an event-driven consumer of prediction and
  (eventually) ground-truth-label events, not a request/response concern
  at all; **(3)** an **event-triggered connection from (2) back into ML/AI
  Model Development's own training-pipeline DAG** — the retraining-trigger
  mechanism named above — meaning the monitoring loop's output is itself
  the *input event* to a completely different architectural shape (a
  pipeline) owned by a sibling category. This closed loop — serve, watch,
  detect, trigger, retrain, promote, serve-the-new-version — is the
  concrete thing an ML-serving-and-monitoring system has that a plain
  request/response service never needs: an ordinary API service's
  "architecture" stops at request/response plus whatever persistence/
  caching layer it needs; this category's serving component is
  incomplete, not merely simpler, without the monitoring-and-retraining
  loop wired to it, because a model's accuracy silently decays against
  live data in a way a stateless CRUD endpoint's correctness does not.
  Hexagonal/ports-and-adapters applies at two genuinely distinct boundaries
  within this same system, worth naming precisely rather than collapsing
  into one boundary: the **serving component's own inbound adapter**
  (a request handler, or a stream/batch consumer, per whichever serving
  shape applies) and feature-store lookup as an **outbound adapter** (the
  serving code shouldn't need to know whether a feature comes from Feast,
  a cloud-native feature store, or a hand-rolled Redis lookup) — the same
  reasoning ML/AI Model Development's own baseline already applied to a
  training pipeline's dataset-loader/tracker-write boundary, here applied
  to a serving request's feature-read boundary instead — and separately,
  the **monitoring component's own metric-provider adapter** (Argo
  Rollouts' own provider abstraction, confirmed metric-source-agnostic
  above, is a real, concrete instance of exactly this outbound-adapter
  shape already implemented in a shipping tool, not a theoretical
  application of the pattern).

## Explicitly out of scope

- **Model *building* concerns already owned by ML / AI Model Development**
  (already shipped) — experiment tracking, fine-tuning/training decisions,
  data versioning for training data, offline model evaluation methodology,
  reproducibility, model cards, and that category's own artifact-storage-
  stage registry framing (uploading/versioning a freshly trained
  checkpoint). This doc's Model registries section above deliberately
  covers only the **staging→production promotion** angle on top of an
  already-registered version — precisely the boundary that category's own
  Explicitly-out-of-scope section names as the handoff point ("this doc
  owns everything up through producing and evaluating a trained model
  artifact; MLOps owns everything from that artifact being registered and
  served onward").
- **IaC drift detection and generic progressive-delivery mechanics already
  owned by Infrastructure & Platform Engineering** (already shipped) —
  `terraform plan -detailed-exitcode`, CloudFormation's `detect-stack-drift`
  API, and the whole state-management/blast-radius apparatus that doc's own
  drift-detection section covers is a **different phenomenon** from this
  doc's model drift, precisely per this doc's own "IaC drift has a ground
  truth to diff against, model drift has no single ground-truth diff"
  distinction above — not restated here. Similarly, the Argo Rollouts/
  Flagger canary/blue-green controller mechanics, AnalysisTemplate syntax,
  and Kubernetes CRD-level detail already covered there are not re-derived
  here; this doc names only what's different when the gating metric is a
  model-quality/drift signal, per the Canary/shadow-deployment section
  above.
- **LLM-specific model serving** — Agentic & MCP Platforms' own territory
  (already shipped): prompt caching, token-by-token streaming generation,
  RAG-corpus/retrieval-pipeline serving, and any inference-time concern
  specific to a hosted or self-served LLM rather than a general-purpose ML
  model. This doc's Model-Serving section deliberately stays at the
  general-ML batch/online/streaming level applicable to any model type, not
  LLM-specific serving shapes.
- **Specific tool/library names, licenses, and adoption-signal comparisons**
  (Feast vs. Tecton vs. Databricks Feature Store vs. Hopsworks; MLflow
  Model Registry vs. a cloud-native registry vs. Unity Catalog; Seldon Core
  vs. KServe vs. BentoML; Alibi Detect vs. Evidently AI vs. NannyML for the
  drift-scoring layer itself) — belongs entirely to the companion
  `libraries.md` baseline being produced in parallel. This doc names a tool
  only where the tool's own documented behavior *is* the architectural fact
  being described (e.g. MLflow's aliases mechanism, Feast's point-in-time-
  join mechanism, Argo Rollouts' metric-provider abstraction) — illustrative
  anchors for a pattern, not this doc encroaching on `libraries.md`'s
  comparative job.
- **Deep drift-detection algorithm internals beyond naming current methods**
  (the precise mathematics of PSI's binning strategy, KL divergence's
  formal definition, ADWIN/DDM/EDDM-style streaming concept-drift-detector
  internals) — named only at the "what exists and what it's used for"
  depth appropriate for an architecture baseline, not derived from first
  principles; a real, acknowledged depth limit rather than a silently
  covered concern.
- **Model observability beyond drift/quality signals specifically**
  (general infrastructure-level metrics/logging/tracing platform selection
  for a serving endpoint) — the Infrastructure & Platform Engineering
  baseline already named this as belonging to whichever category ends up
  owning cross-cutting observability generally, not duplicated or
  pre-empted here; this doc's own monitoring section stays scoped to
  model-quality/drift-specific signals, not a general observability-stack
  selection.
- **Cost modeling / cloud pricing comparisons** (GPU-backed serving-endpoint
  pricing, feature-store managed-service pricing tiers, model-monitoring
  SaaS pricing) — same no-cost-modeling convention as every other baseline
  in this repo.
- **Numeric benchmark/threshold claims not traceable to a primary source
  as a general recommendation** — the SageMaker replacement reference
  implementation's own default thresholds (30% features drifted; 0.05
  drifted-column share; F1 0.70/Accuracy 0.80/ROC-AUC 0.75 model-quality
  defaults) are kept, explicitly labeled as that one AWS reference
  implementation's own worked-example defaults, not presented as an
  industry-standard number to adopt without configuring for a specific
  project — consistent with the ML/AI Model Development baseline's own
  exclusion of the unsourced "LoRA recovers 90-95%" figure and the
  Infrastructure & Platform Engineering baseline's exclusion of specific
  Kubernetes-adoption service-count thresholds.

## Sources

- Local precedent search (not a web source): direct `grep -ril` across
  `/Users/devopammittra/GitHub/ubi-csr-tmf` (excluding `.git/`) for
  `drift|feature.?store|model.?registry|retrain|canary|shadow.?deploy|
  mlflow|seldon|kserve|bentoml|triton|feast|mlops`, a targeted `find`/`grep`
  over `charts/*/*.yaml` for `rollout|canary|drift`, and direct
  `sed`-read confirmation of each of the six bare "drift" string matches
  (`migrations/env.py`, `usePhaseTimers.ts`, `StepGenerateDocumentV1.tsx`,
  plus three more instances of the same clock-drift/schema-drift usages) —
  none MLOps-related — searched and read 2026-08-31
- https://www.evidentlyai.com/ml-in-production/data-drift — direct fetch:
  data-drift definition ("a shift in the distributions of the ML model
  input features"), the data-drift-vs-concept-drift distinction with the
  retail example, and the named detection-method list (summary statistics,
  KS test, chi-squared, Wasserstein distance, Jensen-Shannon divergence,
  PSI) with an explicit absence of a universal numeric threshold —
  retrieved 2026-08-31
- https://docs.feast.dev/getting-started/architecture/overview and
  https://docs.feast.dev/getting-started/concepts/point-in-time-joins —
  direct fetch: online-store real-time low-latency serving framing, the
  unified-feature-definition claim underlying skew prevention, and the
  point-in-time join mechanism (`created_timestamp <= entity_timestamp`)
  preventing backfilled-feature label leakage in training data — retrieved
  2026-08-31. Note: the architecture-overview fetch returned only an index
  page rather than full explanatory prose on training/serving skew
  specifically; that half of the claim rests on the Uber Michelangelo
  fetch below and the search-corroborated sources, not this page directly
- https://www.uber.com/blog/michelangelo-machine-learning-platform/ —
  direct fetch: Michelangelo's own offline (Spark/Hive/HDFS) vs. online
  (Cassandra, with a Kafka/Samza near-real-time path) store architecture,
  and its own stated skew-prevention mechanism ("the same data and batch
  pipeline is used for both training and serving," identical feature-
  transformation-DSL expressions applied at training and prediction time)
  — retrieved 2026-08-31
- Training/serving skew as a named, documented failure mode, and Feast/
  Michelangelo's place in a broader multi-organization pattern (Airbnb
  Zipline, Databricks Feature Store, Hopsworks, Tecton) — search-
  corroborated across multiple sources (Aerospike's feature-store writeup,
  a Medium "Solving the Training-Serving Skew Problem with Feast" post,
  applyingml.com's feature-store hierarchy piece), not independently
  direct-fetched for each named platform this pass — retrieved 2026-08-31
- https://mlflow.org/docs/latest/ml/model-registry/ — direct fetch:
  registered-model versioning-on-registration mechanic, the aliases
  mechanism ("a mutable, named reference to a particular version"), the
  `champion` alias worked example and `models:/<name>@champion` URI form,
  and the `validation_status:pending`/`validation_status:approved` tagging
  convention named without a built-in enforced-approval-workflow mechanism
  — retrieved 2026-08-31
- MLflow stages-to-aliases migration (deprecated four-value Stage field vs.
  current multi-alias model) — search-corroborated across MLflow's own
  versioned docs pages surfaced in search results (mlflow.org registry
  docs across several version numbers) quoting MLflow's own migration
  guidance directly ("more than one alias can be applied to any given
  model version, allowing for easier A/B testing and model rollout"; the
  `Production` stage → `champion` alias equivalence example) — not
  independently direct-fetched against one single current migration-guide
  page this pass — retrieved 2026-08-31
- Shadow deployment vs. canary release definitions —
  https://www.qwak.com/post/shadow-deployment-vs-canary-release-of-machine-learning-models
  — direct fetch: shadow deployment's full-duplicate-traffic/predictions-
  never-served mechanism, canary's live-traffic-percentage/predictions-
  served-to-users mechanism, and the "shadow first, then canary" compositional
  framing — retrieved 2026-08-31
- https://argo-rollouts.readthedocs.io/en/stable/features/analysis/ —
  direct fetch: AnalysisTemplate/AnalysisRun mechanism, the interval-based
  metric-provider query and success/failure/inconclusive gating logic, and
  confirmation that the metric-provider abstraction is source-agnostic
  (Prometheus/Datadog/CloudWatch/InfluxDB built in, a generic Web provider
  for anything else, new integrations pushed to a plugin model rather than
  the core controller) — retrieved 2026-08-31
- Seldon Core v2's built-in drift detection via Alibi Detect, and KServe's
  native `canaryTrafficPercent` traffic-splitting against a last-known-good
  revision — search-corroborated across multiple current sources
  (Spheron's KServe/Seldon/BentoML comparison, KServe's own hosted docs
  site `kserve.github.io/website/...rollout-strategies/canary` whose URL
  surfaced in search results but wasn't independently opened this pass, a
  Medium Seldon Core writeup) — retrieved 2026-08-31
- https://docs.cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning
  — direct fetch (via redirect from the `cloud.google.com` canonical URL):
  the five-condition CT-trigger taxonomy (on-demand, scheduled, new-data-
  availability, performance-degradation, data-distribution-shift/concept-
  drift), the model-registry-as-post-pipeline-artifact-repository framing,
  the batch-vs-online-microservice-vs-embedded-model serving-pattern
  framing, and the monitoring-stage-produces-a-pipeline-trigger framing
  quoted directly — retrieved 2026-08-31
- Batch vs. online/real-time vs. streaming inference as three distinct
  serving shapes — search-corroborated across multiple current sources
  (mlinproduction.com's batch-vs-online-inference piece, Conduktor's
  streaming-ML-pipelines glossary entry, Snowflake's own ML-inference
  explainer), cross-checked against the Google Cloud MLOps guide's own
  batch/online split above rather than resting on secondary sources alone
  for that half of the claim — retrieved 2026-08-31
- Amazon SageMaker Model Monitor's current (2026) status and its
  replacement guidance — direct fetch of
  `docs.aws.amazon.com/sagemaker/latest/dg/model-monitor-availability-change.html`
  and `.../model-monitor-model-quality-baseline.html`: confirms Model
  Monitor is "no longer open to new customers" (existing customers
  unaffected, no new features planned), and that AWS's own current
  replacement guidance is an open-source reference stack (SageMaker AI
  MLflow Apps + Evidently AI + QuickSight + CloudWatch) computing PSI and
  KS statistics per feature via Evidently's `DataDriftPreset`, with the
  reference implementation's own named default thresholds (30%-of-features
  drifted at the batch level; 0.05 drifted-column share at the real-time-
  endpoint level; F1 0.70/Accuracy 0.80/ROC-AUC 0.75 model-quality
  defaults) — retrieved 2026-08-31. This is a genuinely current, honest,
  primary-source-confirmed finding worth carrying into the authored doc
  precisely (a major cloud vendor's own managed model-monitoring product
  being wound down for new customers in favor of an open-source-tool-based
  reference architecture), not a stale assumption that SageMaker Model
  Monitor remains each new project's default managed option
- Vertex AI Model Monitoring's own statistical-methods documentation — **not
  independently confirmed this pass**: two direct-fetch attempts
  (`cloud.google.com/vertex-ai/docs/model-monitoring/overview` and its
  redirect target) returned only a navigational index page, not the actual
  skew/drift statistical-method content (Vertex AI's own docs reportedly
  use L-infinity distance and Jensen-Shannon divergence per general
  industry familiarity, but this pass could not verify that claim against
  the vendor's own page and it is therefore **excluded** from this
  baseline's In-scope section rather than asserted on unverified grounds —
  flagged honestly rather than silently carried forward from training-data
  familiarity, consistent with this repo's own no-unverified-claims
  standard
- `research/architecture-templates.md`,
  `research/stacks/infrastructure-platform-engineering/stack.md`,
  `research/stacks/ml-model-development/stack.md`,
  `research/taxonomy-roadmap.md` — read directly this pass (not web
  sources) to confirm this category's scope boundaries against both named
  neighbors and to avoid re-deriving cross-cutting content those docs
  already cover — read 2026-08-31

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
standing for this whole taxonomy-roadmap sweep, resolved directly:

- **Vertex AI's statistical-methods gap stays unfetched and excluded.**
  Two independent primary sources (Evidently, AWS's current replacement
  guidance) already corroborate the PSI/KS/chi-squared/KL/Wasserstein/JS
  method list; a third data point from Google specifically would be nice
  but isn't load-bearing enough to hold up authoring for. Kept excluded per
  the baseline's own no-unverified-claims standard rather than asserted
  from memory.
- **MLflow's approval-gate framing, now updated with a concrete
  mechanism**: the companion `libraries.md`'s own research (independently)
  found that MLflow ships genuine, current, self-hostable **webhooks**
  (`model_version.created`, `model_version_tag.set`, and related events) —
  this is precisely the missing piece this doc's own open question was
  asking about. The authored doc should name the concrete pattern
  explicitly: MLflow's alias/tag mechanism alone has no enforced gate, but
  its webhook feature is exactly what lets a team build one externally (a
  webhook fires on an alias-reassignment attempt, a CI check reads the
  `validation_status` tag before allowing the reassignment to actually
  take effect) — the same external-gate-on-top-of-an-unenforced-primitive
  shape Infrastructure & Platform Engineering's own OPA/Conftest
  pre-`apply` gate already established for IaC. Resolved: yes, name this
  explicitly and concretely in the authored doc, not left purely
  descriptive.
- **Canary/shadow section depth stays as scoped** — thin on Argo Rollouts/
  AnalysisTemplate mechanics (pointing back to the sibling doc), full
  depth spent on what's different when the gating metric is model-quality/
  drift. No implementation-level YAML snippet needed at this
  architecture-level depth; that belongs to `libraries.md` or a future
  deeper pass if ever warranted.
- **Seldon Core's Alibi Detect integration and KServe's canary mechanism
  stay at their current confidence level** — the companion `libraries.md`
  independently direct-fetched Seldon Core's own BSL licensing and its
  native shadow/canary primitives, which corroborates and strengthens this
  doc's own architectural point from a different angle; the specific
  drift-gating integration claim remains search-corroborated only, judged
  sufficient given how many independent sources converge on the same
  underlying architectural point (a serving platform treating drift/
  quality as a first-class gating signal is real and current, even if the
  exact integration mechanics weren't independently re-verified).

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/mlops-platform-engineering.md
  — est. 420–500 lines (6 in-scope subsections per the list above, most at
  section depth given how much of this category's value is in precisely
  drawing boundaries against its two shipped siblings rather than
  introducing entirely new depth; likely shorter overall than the
  Infrastructure & Platform Engineering and ML/AI Model Development
  baselines' own authored length since several sections here are
  explicitly thinner specialization notes on top of sibling-doc content
  rather than freestanding deep-dives).
