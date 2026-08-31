# MLOps / ML Platform Engineering — Architecture & Stack

This category covers the operational discipline that begins once a trained
model already exists: model registries at the staging-to-production
promotion stage, feature stores, model-serving infrastructure, drift
monitoring, retraining triggers, and canary/shadow rollouts for models
specifically. It sits between two already-shipped siblings and deliberately
doesn't restate either one. [ML / AI Model
Development](ml-model-development.md) owns everything up through producing
and evaluating a trained artifact — experiment tracking, fine-tuning
decisions, training-data versioning, offline evaluation, reproducibility,
model cards, and that doc's own artifact-storage-stage registry framing
(uploading and versioning a freshly trained checkpoint). This doc picks up
exactly where that one stops: a specific model version already exists as a
registered artifact, and the question becomes whether, when, and how it
gets promoted to serve live traffic, watched once it does, and retrained
when it degrades. [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md) owns the generic
mechanics this category rides on top of rather than reinvents — Kubernetes,
Helm, CI/CD promotion gates, and the Argo Rollouts/Flagger canary
controllers themselves; this doc names only what's genuinely different when
the thing being rolled out or drift-checked is a model rather than an
ordinary application service.

No local repository on this machine currently does MLOps-shaped work, and
that absence was checked directly for the operational half of this concern
— a different question from whether training code exists. `ubi-csr-tmf`
was searched directly for drift-monitoring code, a feature-store
integration, a model-registry client, a retraining-trigger workflow, or
canary/shadow-deployment config, plus a scan of every Helm chart's values
files for a `rollout`/`canary`/`drift` key: zero matches. The word "drift"
appears six times in the codebase, each confirmed by direct read to be an
ordinary software usage unrelated to models (an Alembic schema-version
comment, client/server clock-skew handling in a progress timer). This is a
genuinely clean absence, the same "nothing here" finding [ML / AI Model
Development](ml-model-development.md) already reached for training code,
independently reconfirmed here for the serving/operations half
specifically, since a repository could in principle have model-serving
infrastructure with no training code at all. Every recommendation below is
backed by external primary sources with direct fetches where possible, the
same posture that doc and `backend-api-services.md` already established
for their own local-precedent gaps.

One convention carried through every section below, matching every other
doc in this skill: numeric claims are stated only where a primary source
backs the specific figure — the reference thresholds named in the Model
Drift Monitoring section are attributed to the one implementation that
states them, not presented as an industry standard. Directional claims
sourced only from secondary/aggregator content are named as such rather
than upgraded to settled fact.

## Table of contents

- [How this category specializes the cross-cutting architecture patterns](#how-this-category-specializes-the-cross-cutting-architecture-patterns)
- [Model drift monitoring: data drift vs. concept drift](#model-drift-monitoring-data-drift-vs-concept-drift)
- [Feature stores and the training/serving skew problem](#feature-stores-and-the-trainingserving-skew-problem)
- [Production model registries: the staging-to-production promotion boundary](#production-model-registries-the-staging-to-production-promotion-boundary)
- [Canary and shadow deployment for models](#canary-and-shadow-deployment-for-models)
- [Retraining triggers](#retraining-triggers)
- [Model-serving shapes: batch, online, and streaming inference](#model-serving-shapes-batch-online-and-streaming-inference)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## How this category specializes the cross-cutting architecture patterns

Every other stack doc in this skill answers "what kind of system is this"
with one dominant pattern: Backend & API Services is request/response, Data
& Analytics Platforms and ML/AI Model Development are both a pipeline/DAG,
Integration & Event-Driven Systems is event-driven. MLOps doesn't reduce to
any single one of those — it's **at least two of those patterns composed
together, with a feedback loop connecting them**, which is the concrete
fact that makes it its own category rather than a variant of a sibling:

1. A **request/response or batch/streaming serving component** — matching
   Backend & API Services' own request/response framing for the
   online-inference case, or a batch/streaming shape per [Model-serving
   shapes](#model-serving-shapes-batch-online-and-streaming-inference)
   below.
2. A **continuous monitoring/observation loop** over that serving
   component's live traffic and outputs — structurally an event-driven
   consumer of prediction and, eventually, ground-truth-label events, not a
   request/response concern at all.
3. An **event-triggered connection from (2) back into ML/AI Model
   Development's own training-pipeline DAG** — the retraining-trigger
   mechanism covered below — meaning the monitoring loop's output is itself
   the *input event* to a completely different architectural shape owned by
   a sibling category, not a dashboard a human watches before manually
   kicking off a job.

That closed loop — serve, watch, detect, trigger, retrain, promote,
serve-the-new-version — is what this category's serving component has that
a plain request/response service never needs. An ordinary API service's
architecture stops at request/response plus whatever persistence/caching
layer it needs; this category's serving component is **incomplete, not
merely simpler**, without the monitoring-and-retraining loop wired to it,
because a model's accuracy silently decays against live data in a way a
stateless CRUD endpoint's correctness does not.

Hexagonal/ports-and-adapters applies at two distinct boundaries here, worth
naming separately rather than collapsing into one: the **serving
component's own inbound adapter** (a request handler, or a stream/batch
consumer) plus a **feature-store lookup as an outbound adapter** — serving
code shouldn't need to know whether a feature comes from a dedicated
feature store, a cloud-native equivalent, or a hand-rolled cache, the same
reasoning ML/AI Model Development applies to a training pipeline's own
dataset-loader/tracker-write boundary, here applied to a serving request's
feature-read boundary instead. Separately, the **monitoring component's
own metric-provider adapter** is a real instance of this shape already
implemented in a shipping tool: Argo Rollouts' AnalysisTemplate mechanism
(covered by [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md#cicd-at-the-platform-engineering-layer))
is confirmed, by direct fetch of its own docs, to be metric-source-agnostic
— Prometheus, Datadog, CloudWatch, and InfluxDB are built in, a generic Web
provider covers anything else. That's exactly an outbound adapter for
"where does the gating signal come from," and it's why [Canary and shadow
deployment for models](#canary-and-shadow-deployment-for-models) below
needs no separate rollout mechanism for model-quality gating — only a new
implementation of an adapter interface that already exists.

## Model drift monitoring: data drift vs. concept drift

**Data drift** is, per Evidently AI's own definition, "a shift in the
distributions of the ML model input features" — the data a deployed model
sees no longer resembles its training data, while the underlying
input→output relationship the model learned is unchanged. **Concept
drift** is a change in that relationship itself: the same input now
warrants a different prediction than it did at training time. The
sharpest available illustration: in fraud detection, fraudsters actively
adapt their behavior specifically to evade a deployed model, so a
transaction pattern that was benign yesterday can be fraudulent today with
no meaningful shift in the raw feature distributions at all — pure concept
drift, no data drift. Evidently's own contrasting retail example runs the
other direction: a shift toward online purchases changes input
distributions without necessarily changing the underlying input→outcome
relationship — data drift without concept drift. The two frequently
co-occur but aren't synonymous, and they call for different responses:
data drift alone may or may not degrade the model, depending on whether
the shifted input region is one the model already handles well, while
concept drift by construction means the model's learned mapping is now
wrong regardless of how it currently classifies the shifted inputs. The
practical consequence: a quality/performance-anchored monitor —
continuously applying [ML / AI Model
Development](ml-model-development.md#model-evaluation-methodology)'s own
offline evaluation methodology against fresh, delayed ground truth once it
arrives — is the only detection method that can directly see concept
drift; both concept and data drift can only be *suspected*, not confirmed,
from an input-distribution monitor alone.

**Why this is a genuinely different problem from Infrastructure &
Platform Engineering's own [drift
detection](infrastructure-platform-engineering.md#drift-detection), not a
coincidental reuse of the same word**: that category's IaC drift has a
**single, authoritative ground truth to diff against** — the declared
configuration — so `terraform plan -detailed-exitcode` or CloudFormation's
`detect-stack-drift` reports drift as a binary, mechanically-checkable
fact with an exact expected-vs-actual property diff. Model drift has **no
single ground-truth diff**: there's no declared "correct" input
distribution to compare live traffic against, only a reference
distribution — typically the training set, or a recent-past production
window — and a **statistical judgment call** about whether an observed
difference is large enough to matter. Model-drift detection therefore
always resolves to a chosen distance metric plus a chosen alerting
threshold, both configuration decisions a team makes, not a fact IaC drift
detection just reports — the identical same-word-different-meaning
discipline that doc's own [idempotency
section](infrastructure-platform-engineering.md#idempotency-iac-style)
already applies to "idempotency," now applied to "drift."

**Statistical detection methods currently in use**, confirmed by direct
fetch of Evidently's own docs and cross-checked against AWS's guidance
below: **Population Stability Index (PSI)** — originally built for
risk-scorecard monitoring, valued for a sample-size-independent score that
makes it more predictable to interpret than KS; **Kolmogorov-Smirnov (KS)
test** — a nonparametric hypothesis test for whether two samples come from
the same distribution, applied per numeric feature; **chi-squared test** —
the categorical-feature analogue of KS; **KL (Kullback-Leibler)
divergence** — a reasonable default for larger datasets, with a mechanical
caveat worth stating precisely: it's **not symmetric**, fails the triangle
inequality, and can diverge to infinity where the reference distribution
has zero density and the current one doesn't; and **Wasserstein
distance**/**Jensen-Shannon divergence**, the latter explicitly the
symmetrized, always-finite variant of KL — a common practical substitute
when KL's infinite-divergence edge case is a real risk. No single
canonical alerting threshold exists across sources; Evidently's own docs
deliberately avoid stating one, since the right threshold depends on how
sensitive a given model actually is to a given feature's shift.

One concrete, current, load-bearing finding worth naming precisely:
**Amazon SageMaker Model Monitor is no longer open to new customers**,
confirmed by direct fetch of AWS's own current docs (existing customers
unaffected, no new features planned). AWS's own current replacement
guidance is an open-source reference stack — a SageMaker AI MLflow app
paired with Evidently AI, QuickSight, and CloudWatch — computing PSI and
KS statistics per feature via Evidently's `DataDriftPreset`. That
reference implementation's own named default thresholds are worth stating
as exactly what they are — one AWS reference architecture's own
configurable worked-example defaults, not a received industry standard:
**more than 30% of features drifted** at the batch-pipeline level, and a
`DriftThreshold` default of **0.05** share of drifted columns at the
real-time-endpoint level. The finding itself is the useful part: a major
cloud vendor's own managed model-monitoring product being wound down for
new customers in favor of an open-source reference architecture is a real,
current shift in what "the default managed option" means, not something
safe to assume unchanged from an earlier training cutoff.

## Feature stores and the training/serving skew problem

The concrete problem a feature store solves: a feature computed one way
for offline training (a batch job scanning historical data) and a subtly
different way for online serving (a different code path against live
request data) is a real, documented, hard-to-debug failure mode. The model
was trained on one definition of a feature and served a slightly different
one at inference time, and because the discrepancy is *subtle* — not a
missing column, but a genuinely different numeric value for what's
nominally "the same" feature — it frequently manifests only as unexplained
accuracy degradation rather than an obvious bug.

The **offline/online store architecture pattern** is the shape both the
originating real-world case and the current dominant open-source
implementation converge on. Uber's own Michelangelo platform blog post,
confirmed by direct fetch, describes a **batch-computed offline store**
(Spark/Hive jobs writing to HDFS) serving training-time feature retrieval,
and a **low-latency online store** (Cassandra, with a Kafka/Samza
near-real-time path for features that can't wait for a batch cycle)
serving inference-time retrieval — both derived from **the same feature
definitions**, not two independently maintained implementations of "the
same" feature. Michelangelo's own stated skew-prevention mechanism:
feature transformations are expressed once in a domain-specific language,
and "the same data and batch pipeline is used for both training and
serving" wherever possible. Feast, the current dominant open-source
implementation, converges on the identical offline/online split, confirmed
by direct fetch of its own architecture docs. This has been productionized
enough times by enough independent organizations — Uber, Feast, and, per
search corroboration not independently fetched this pass, Airbnb's Zipline
and Databricks' own Feature Store — that it's the settled architectural
shape for this concern rather than one team's idiosyncratic design.

A **second, mechanically distinct** failure mode this pattern also guards
against is **label leakage via backfilled or corrected features**: a naive
join of "current" feature values against historical training labels can
silently pull in a value that was corrected or backfilled *after* the
label's event actually occurred, letting the model train on information
that wouldn't have been available at real-world prediction time — worth
keeping conceptually separate from skew, since skew is about the
*computation path* differing between training and serving, while this is
about the *temporal validity* of which feature value gets joined into a
training row. Feast's own concrete mechanism, confirmed by direct fetch of
its point-in-time-join documentation, is a join condition of
`created_timestamp <= entity_timestamp` that reconstructs "what the online
store would have served" at each historical event time, rather than
joining against each feature's latest known value. Specific current tool
comparison (Feast vs. other current feature-store products) belongs to the
companion
[preferred-libraries/mlops-platform-engineering.md](../preferred-libraries/mlops-platform-engineering.md).

## Production model registries: the staging-to-production promotion boundary

The dividing line from [ML / AI Model
Development](ml-model-development.md#experiment-tracking)'s own
experiment-tracking section, stated precisely: that doc covers a run's
metadata-store/artifact-store split for *recording* a training run's
outputs, including the moment a checkpoint first gets registered as a
versioned artifact. This category owns what happens **after** — the
**staging-to-production promotion decision** for a version that already
exists as a registered, versioned artifact. Per MLflow's own docs,
confirmed by direct fetch: every registration under a registered-model
name **automatically increments a version number**, addressable by URI
(`models:/MyModel/1`) — identical regardless of whether the version is
still under evaluation or already serving production traffic, which is
exactly why a separate promotion signal is needed on top of version
numbering alone.

MLflow's own promotion mechanism has itself changed, worth naming
precisely as a same-category instance of the caution [Infrastructure &
Platform
Engineering](infrastructure-platform-engineering.md#cicd-at-the-platform-engineering-layer)
already gives its own local precedent's inert `release: blue-green` Helm
label — a name attached to a pattern isn't the same as the pattern being
implemented. MLflow's older **stages** model (None → Staging → Production
→ Archived, a fixed four-value lifecycle field) is now being replaced by
**model version aliases** — "a mutable, named reference to a particular
version of a registered model" — because aliases let more than one label
apply to a given version simultaneously, which a single fixed `stage`
field can't express (corroborated across MLflow's own versioned docs:
"easier A/B testing and model rollout"). The concrete workflow this
enables: assign a `champion` alias to the version intended to serve the
majority of production traffic, and **promotion is the act of reassigning
that alias to a different model version** — a single, atomic pointer
update rather than a bulk-copy or re-deployment of the model artifact
itself, addressable afterward via `models:/<name>@champion`. Because both
a version number and an alias are first-class, queryable registry fields,
"which exact version is `champion` right now, and what was `champion`
before it" is a directly queryable fact rather than something
reconstructed from deploy logs.

**Approval gates are only partially formalized in MLflow's own current
docs**, an honest current-capability gap worth stating rather than
glossing over, the same way Infrastructure & Platform Engineering names
HCP Terraform's Sentinel as the enforced-policy-gate option and
OPA/Conftest as the portable equivalent for IaC. Tag-based conventions
like `validation_status:pending`/`validation_status:approved` are named in
MLflow's own docs as a pattern, but nothing enforces that an alias
reassignment actually respects that tag's value the way a GitHub
Environment's required-reviewer rule gates a deployment. **The concrete
mechanism for building that gate externally is MLflow's webhook feature**,
confirmed by direct fetch of MLflow's own webhook API reference: a
self-hostable webhook system with named, typed event payloads for the
Model Registry — `model_version.created`,
`ModelVersionAliasCreatedPayload`/`ModelVersionAliasDeletedPayload` for
alias changes, `ModelVersionTagSetPayload`/`ModelVersionTagDeletedPayload`
for tag changes — each deliverable via HMAC-signed HTTP POST to a
team-specified endpoint. These fire as **post-hoc notifications**, after a
change has already happened, not as a blocking pre-check, so the enforced
half of a real gate has to live in the promotion pipeline that *calls* the
alias-reassignment API: a CI step reads the `validation_status` tag and
only invokes `set_registered_model_alias` if it reads `approved`. The
webhook's job is the second half of the loop — notifying a serving system
or audit log that a `champion` reassignment actually happened, so
downstream automation can react without polling the registry. This is the
same external-gate-on-top-of-an-unenforced-primitive shape [Infrastructure
& Platform
Engineering](infrastructure-platform-engineering.md#blast-radius-limiting)'s
own OPA/Conftest pre-`apply` gate already established for IaC, applied here
to a model-registry alias instead of a Terraform plan. Specific
registry-product comparison belongs to
[preferred-libraries/mlops-platform-engineering.md](../preferred-libraries/mlops-platform-engineering.md).

## Canary and shadow deployment for models

**Shadow deployment** and **canary deployment** are mechanically distinct
patterns, not two names for the same idea, confirmed by direct fetch of a
canary-vs-shadow comparison alongside Argo Rollouts' own analysis docs. In
**shadow deployment**, a candidate model receives a **duplicate of
production traffic** — typically the full volume, not a percentage slice —
processed in parallel with the currently-live model, but its predictions
are **never served to users or acted on**, only logged and compared
offline against the live model's actual served predictions. In **canary
deployment**, a genuinely **live-serving slice of real traffic** (commonly
starting around 1%, ramping incrementally) is routed to the candidate, and
its predictions *do* reach users. That difference is the whole point:
canary answers "does this model perform acceptably with real users in the
loop," a question shadow deployment structurally cannot answer because
shadow-mode predictions never have real-world consequences to observe. The
two compose rather than compete — shadow deployment is the safer first
validation pass, confirming the candidate doesn't behave wildly
differently against the real production distribution with zero
user-facing risk; canary is the subsequent pass validating the candidate's
*served* behavior once shadow testing has already de-risked it.

**What's genuinely new here versus [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md#cicd-at-the-platform-engineering-layer)'s
own progressive-delivery mechanics is narrow**: that doc already covers the
generic canary/blue-green controller mechanism at the Kubernetes-native
Custom Resource level — Argo Rollouts' `Rollout` CRD, the Flux-family
Flagger controller — including its own AnalysisTemplate/AnalysisRun
metric-gate mechanism, where a metric provider is queried on an interval
and success/failure conditions gate whether a canary keeps ramping, holds,
or auto-rolls-back. Confirmed by direct fetch of Argo Rollouts' own
analysis docs: that mechanism is explicitly **metric-source-agnostic** —
Prometheus, Datadog, CloudWatch, and InfluxDB are built in, and a generic
Web provider accepts an arbitrary HTTP endpoint plus a JSON-path
evaluation for anything not natively supported. Nothing about the generic
canary-controller mechanism changes when the gating metric is a
model-quality score or a drift statistic instead of an HTTP error rate or
p99 latency — what this category adds is naming that a model-quality/drift
signal is a valid, real, and increasingly common choice of gating metric,
and that computing that signal is the model-monitoring machinery described
earlier in this doc, wired into the generic canary controller as just
another metric-provider query, not a separate rollout mechanism this
category has to invent.

Model-serving platforms are already building on exactly this composition.
Seldon Core v2's own documented positioning names built-in drift detection
via the open-source **Alibi Detect** library as a first-class capability
alongside its own canary/A-B-testing rollout support — a real, current
instance of a serving platform treating drift-as-a-gating-signal as a
native feature rather than a bolted-on integration. KServe similarly
documents native canary traffic-splitting for an `InferenceService` — a
`canaryTrafficPercent` field automatically comparing against the
last-known-good revision. Both are search-corroborated rather than
independently direct-fetched this pass; specific tool comparison (Seldon
Core vs. KServe vs. other current serving platforms, Alibi Detect vs.
other drift-scoring libraries) belongs to
[preferred-libraries/mlops-platform-engineering.md](../preferred-libraries/mlops-platform-engineering.md).

## Retraining triggers

This is the connective tissue between this category's own monitoring
signals and ML/AI Model Development's training-pipeline DAG. Google
Cloud's own MLOps architecture guide, a widely-cited and currently-live
primary source confirmed by direct fetch, names five concrete trigger
conditions for an automated retraining pipeline run:

1. **On-demand** — a manual, ad hoc pipeline invocation.
2. **Scheduled** — a calendar cadence run whenever fresh labeled data is
   expected to have accumulated.
3. **New-training-data availability** — triggered directly by data
   arrival rather than a fixed clock, avoiding both wasted compute on an
   unchanged-data tick and a missed-update gap between ticks.
4. **Model-performance degradation** — triggered once a live-serving
   quality signal, per [Model drift
   monitoring](#model-drift-monitoring-data-drift-vs-concept-drift)'s own
   performance-anchored monitor, crosses a defined threshold.
5. **Significant data-distribution shifts** — triggered by the
   drift-detection machinery above crossing its own configured threshold,
   explicitly named in this source as the concept-drift trigger case.

The architectural shape worth naming explicitly is that in a mature setup
this is **an event, not a human decision**. The same Google Cloud source
describes the monitoring stage's own job as collecting "statistics on the
model performance based on live data" and producing, as its output, "a
trigger to execute the pipeline or to execute a new experiment cycle" —
stated as a direct architectural output of monitoring, not a dashboard a
human watches before manually kicking off a job. Concretely, this is the
event-driven pattern [architecture-templates.md](../architecture-templates.md)
already names generally, applied at this category's specific seam: a
drift-detector or performance-monitor crossing its threshold **emits an
event** — a queue message, a webhook call, a scheduled check's own
conditional branch — that a training-pipeline orchestrator consumes as its
own kickoff signal. This is the same "an event, not a human decision"
framing [ML / AI Model
Development](ml-model-development.md#how-this-category-specializes-the-cross-cutting-architecture-patterns)
already names as a legitimate downstream serverless-shaped component ("a
lightweight retraining-trigger function reacting to a new-data-arrived
event"), now given its concrete five-condition taxonomy.

**Practical default worth stating explicitly**: scheduled retraining alone
is a reasonable, low-complexity starting point for a new project, but a
maturing platform's real goal is drift/performance-threshold-triggered
retraining precisely because it aligns pipeline execution with when the
data or model's behavior has actually changed, rather than paying for
retraining on a clock regardless of whether anything changed — the same
"re-running against an unchanged input should produce zero redundant work"
framing [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md#idempotency-iac-style)
already applies to IaC, applied here to compute spend on unnecessary
retraining runs, though the mechanism achieving it (an event trigger
versus IaC's own no-op-detecting `plan`) is different in kind, not just
domain.

## Model-serving shapes: batch, online, and streaming inference

Three genuinely distinct serving architectures exist for a general-purpose
ML model, cross-checked between Google Cloud's own MLOps architecture
guide and multiple current secondary comparison sources — no single
vendor-neutral primary source stating all three side by side was found
this pass, flagged honestly rather than presented as one canonical
citation.

| Shape | What it is | Architectural consequence |
|---|---|---|
| **Batch inference** | Predictions computed over an accumulated dataset on a schedule or triggered run; no caller waiting synchronously for a result — Google Cloud's own framing: a model deployed as part of a batch-processing system | Compute only needs to exist for the batch job's duration, favoring cost-efficient elastic batch compute over an always-on endpoint, at the cost of every prediction being as stale as the last run's cutoff |
| **Online/real-time inference** | Predictions computed synchronously per request with an immediate response expected — Google Cloud's own framing: "microservices with a REST API," the same shape Backend & API Services already owns | A fixed, materially higher standing-compute cost, plus, per the Feature Stores section above, a hard latency ceiling on the feature-lookup path a batch job never has to meet |
| **Streaming inference** | Predictions computed continuously as events arrive from a stream — sensor readings, log events, clickstream data — with results flowing to downstream systems rather than a single synchronous caller | Architecturally closer to [Integration & Event-Driven Systems](integration-event-driven-systems.md)'s own event-processing shape than a request/response service; no natural "end of batch" boundary at all |

**Decision rule for a new project**, synthesized from the above rather
than lifted from one source: batch is the right default whenever
predictions can tolerate being as stale as the last scheduled run and no
caller needs a synchronous answer — large-scale scoring jobs, periodic
reports, bulk re-scoring after a model update. Online/real-time is
required whenever a user-facing or interactive flow needs a prediction
before it can proceed. Streaming is the right shape only when predictions
genuinely need to react to an unbounded, continuously-arriving event
source rather than either a fixed batch or a caller-initiated request —
reaching for it by default when online inference would suffice adds real
architectural complexity (a stream-processing runtime, delivery-semantics
guarantees) for no benefit.

This is the explicit non-LLM counterpart to whatever [Agentic & MCP
Platforms](agentic-mcp-platforms.md) already covers for LLM-specific
serving (already shipped, out of scope here) — the same three shapes
recur for general-ML model serving without the LLM-specific concerns
(streaming token-by-token generation, prompt caching) that category owns
instead.

## Where this doc stops

Specific tool/library names, licenses, and adoption-signal comparisons —
Feast vs. other current feature stores, MLflow Model Registry vs. a
cloud-native or managed governance registry, Seldon Core vs. KServe vs.
other current model-serving platforms, Alibi Detect vs. Evidently AI vs.
other current drift-scoring libraries — belong entirely to the companion
[preferred-libraries/mlops-platform-engineering.md](../preferred-libraries/mlops-platform-engineering.md).
This doc names a tool only where the tool's own documented behavior *is*
the architectural fact being described — MLflow's aliases and webhook
mechanism, Feast's point-in-time-join mechanism, Argo Rollouts' metric-
provider abstraction — not as a comparative recommendation between
products.

**IaC drift detection and generic progressive-delivery mechanics** already
owned by [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md) aren't re-derived
here: `terraform plan -detailed-exitcode`, CloudFormation's
`detect-stack-drift` API, and the state-management/blast-radius apparatus
that doc's own drift-detection section covers is a different phenomenon
from this doc's model drift, precisely per the "IaC drift has a ground
truth to diff against, model drift doesn't" distinction above. The Argo
Rollouts/Flagger controller mechanics and AnalysisTemplate syntax already
covered there also aren't re-derived here; this doc names only what's
different when the gating metric is a model-quality/drift signal.

**LLM-specific model serving** — prompt caching, token-by-token streaming
generation, RAG-corpus/retrieval-pipeline serving, and any inference-time
concern specific to a hosted or self-served LLM — is [Agentic & MCP
Platforms](agentic-mcp-platforms.md)'s own territory, already shipped.
This doc's Model-Serving section deliberately stays at the general-ML
batch/online/streaming level applicable to any model type.

**Deep drift-detection algorithm internals** beyond naming current methods
— PSI's binning strategy, KL divergence's formal definition,
ADWIN/DDM/EDDM-style streaming concept-drift-detector internals — are
named only at the "what exists and what it's used for" depth appropriate
for an architecture baseline; a real, acknowledged depth limit rather than
a silently covered concern.

**Model observability beyond drift/quality signals specifically** —
general infrastructure-level metrics/logging/tracing platform selection
for a serving endpoint — belongs to whichever category ends up owning
cross-cutting observability generally, not this doc.

**Cost modeling and cloud pricing comparisons** — GPU-backed
serving-endpoint pricing, feature-store managed-service tiers,
model-monitoring SaaS pricing — stay out of scope, the same no-cost-
modeling convention as every other doc in this skill.

**Model *building* concerns** — experiment tracking, fine-tuning/training
decisions, training-data versioning, offline model evaluation
methodology, reproducibility, and model cards — are [ML / AI Model
Development](ml-model-development.md)'s own territory, already shipped;
this doc's Model Registries section deliberately covers only the
staging-to-production promotion angle on top of an already-registered
version, precisely the boundary that doc's own closing section names as
the handoff point.

## Sources

- Local precedent (not a web source, read directly): `grep -ril` across
  `/Users/devopammittra/GitHub/ubi-csr-tmf` for
  `drift|feature.?store|model.?registry|retrain|canary|shadow.?deploy|
  mlflow|seldon|kserve|bentoml|triton|feast|mlops`, a scan of every Helm
  chart's values files for `rollout|canary|drift`, and direct read
  confirmation of the six bare "drift" string matches (an Alembic
  schema-version-table comment, client/server clock-drift handling in a
  progress timer) — none MLOps-related — read 2026-08-31
- https://www.evidentlyai.com/ml-in-production/data-drift — direct fetch:
  data-drift definition, the data-drift-vs-concept-drift distinction with
  the retail example, and the detection-method list (KS, chi-squared,
  Wasserstein, Jensen-Shannon, PSI) with no universal threshold stated —
  retrieved 2026-08-31
- https://docs.feast.dev/getting-started/architecture/overview and
  .../concepts/point-in-time-joins — direct fetch: online-store
  low-latency serving framing and the point-in-time join mechanism
  (`created_timestamp <= entity_timestamp`) preventing backfilled-feature
  label leakage — retrieved 2026-08-31
- https://www.uber.com/blog/michelangelo-machine-learning-platform/ —
  direct fetch: Michelangelo's offline (Spark/Hive/HDFS) vs. online
  (Cassandra, Kafka/Samza near-real-time path) store split, and its own
  stated skew-prevention mechanism ("the same data and batch pipeline is
  used for both training and serving") — retrieved 2026-08-31
- Training/serving skew as a documented failure mode, and Feast/
  Michelangelo's place in a broader multi-organization pattern (Airbnb
  Zipline, Databricks Feature Store) — search-corroborated, not
  independently fetched per platform — retrieved 2026-08-31
- https://mlflow.org/docs/latest/ml/model-registry/ — direct fetch:
  versioning-on-registration mechanic, the aliases mechanism, the
  `champion` alias example and `models:/<name>@champion` URI form, and
  the `validation_status:pending`/`approved` tagging convention named
  without a built-in enforced-approval mechanism — retrieved 2026-08-31
- MLflow stages-to-aliases migration — search-corroborated across
  MLflow's own versioned docs, quoting its migration guidance directly
  ("easier A/B testing and model rollout") — not independently fetched
  against one current page this pass — retrieved 2026-08-31
- MLflow webhook event types and mechanism — direct fetch/search of
  MLflow's own webhook API reference
  (`mlflow.org/docs/latest/api_reference/python_api/mlflow.webhooks.html`):
  confirms `model_version.created`,
  `ModelVersionAliasCreatedPayload`/`Deleted`, and
  `ModelVersionTagSetPayload`/`Deleted` payload types, HMAC-signed HTTP
  POST delivery, and that these fire post-hoc, not as a blocking
  pre-check — retrieved 2026-08-31
- Shadow vs. canary release definitions —
  https://www.qwak.com/post/shadow-deployment-vs-canary-release-of-machine-learning-models
  — direct fetch: shadow's full-duplicate/never-served mechanism,
  canary's live-percentage/served-to-users mechanism, and "shadow first,
  then canary" — retrieved 2026-08-31
- https://argo-rollouts.readthedocs.io/en/stable/features/analysis/ —
  direct fetch: AnalysisTemplate/AnalysisRun mechanism, interval-based
  metric queries and success/failure/inconclusive gating, and
  confirmation the metric-provider abstraction is source-agnostic
  (Prometheus/Datadog/CloudWatch/InfluxDB built in, a generic Web
  provider otherwise) — retrieved 2026-08-31
- Seldon Core v2's built-in drift detection via Alibi Detect, and
  KServe's native `canaryTrafficPercent` traffic-splitting — search-
  corroborated, not independently fetched this pass — retrieved
  2026-08-31
- https://docs.cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning
  — direct fetch (via redirect): the five-condition retraining-trigger
  taxonomy, the batch/online-microservice/embedded-model serving-pattern
  framing, and the monitoring-produces-a-pipeline-trigger framing quoted
  directly — retrieved 2026-08-31
- Batch vs. online vs. streaming inference as three distinct serving
  shapes — search-corroborated, cross-checked against the Google Cloud
  guide's own batch/online split rather than resting on secondary sources
  alone — retrieved 2026-08-31
- Amazon SageMaker Model Monitor's current status and replacement
  guidance — direct fetch of
  `docs.aws.amazon.com/sagemaker/latest/dg/model-monitor-availability-change.html`
  and `.../model-monitor-model-quality-baseline.html`: confirms Model
  Monitor is "no longer open to new customers," and that AWS's
  replacement guidance is an open-source stack (SageMaker AI MLflow apps
  + Evidently AI + QuickSight + CloudWatch) computing PSI/KS via
  Evidently's `DataDriftPreset`, with named default thresholds
  (30%-of-features drifted at batch level; 0.05 drifted-column share at
  real-time-endpoint level) — retrieved 2026-08-31
- `research/architecture-templates.md`,
  `research/stacks/infrastructure-platform-engineering/stack.md`,
  `research/stacks/ml-model-development/stack.md`,
  `research/taxonomy-roadmap.md` — read directly to confirm this
  category's scope boundaries against both named neighbors — read
  2026-08-31
