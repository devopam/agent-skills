# ML / AI Model Development — Architecture & Stack

This category covers the model-*building* side of the ML lifecycle: training
and fine-tuning decisions, experiment tracking, data versioning for training
data specifically, model evaluation methodology, reproducibility, and model
documentation. It is deliberately narrower than "everything with 'ML' in the
name" — two adjacent slices are explicitly someone else's job. Once a model
is trained and needs to be registered, served, monitored for drift, or
retrained on a trigger, that's the still-pending **MLOps / ML Platform
Engineering** roadmap category, not this one; the line is drawn precisely at
*producing and evaluating a trained artifact* (this doc) versus *that
artifact being registered and served onward* (MLOps). For an application
that calls an already-trained model at inference time — including
constructing a RAG retrieval corpus, since chunking/embedding/indexing a
corpus produces no trained artifact and no gradient update — see
[Agentic & MCP Platforms](agentic-mcp-platforms.md); this category is
exclusively about the training pipeline that produces the artifact such an
application later calls. For BI/reporting-facing data work — warehouses,
lakehouses, dashboards, ELT for business consumption — see
[Data & Analytics Platforms](data-analytics-platforms.md); this doc's own
data-versioning section deliberately covers only *training-data* versioning,
a narrower and differently-motivated concern than that category's
data-contracts/lineage-for-organizational-consumption framing, even where
both touch a similarly-shaped object store underneath.

No local repository on this machine currently does model-building work, and
that absence was checked directly rather than assumed: neither
`agent-skills` nor the sibling `ubi-csr-tmf` repository contains a notebook,
a training script, an experiment-tracker config, or a model-weight file
anywhere in its tree. `ubi-csr-tmf`'s own `aws/container/agents/` directory
— the one component whose name might suggest otherwise — was checked
specifically and confirmed to be a FastAPI service built on AWS's Strands
Agents SDK: an LLM-agent application that calls pretrained models at
inference time, squarely the Agentic & MCP Platforms territory named above,
with no training loop, dataset loader, checkpoint directory, or
experiment-tracking import anywhere in it. Every recommendation below is
therefore backed by external primary sources with direct fetches where
possible, not a local worked example — the same posture the
`backend-api-services.md` baseline already used for its own local-precedent
gaps.

One convention carried through every section below, matching every other
doc in this skill: numeric claims are stated only where a primary source
backs the specific figure (LoRA's own reported 10,000× parameter reduction,
HF PEFT's own Qwen2.5-3B worked-example percentage, the NeurIPS checklist's
own itemized requirements), and are otherwise named as a directional signal
from secondary/aggregator sources rather than upgraded to fact — pretraining
cost figures, a widely-repeated "LoRA recovers 90-95% of full fine-tuning
quality" claim, and specific benchmark-contamination percentages all fall
into that latter, explicitly-caveated category and are named as such below
rather than silently presented as settled numbers.

## Table of contents

- [How this category specializes the cross-cutting architecture patterns](#how-this-category-specializes-the-cross-cutting-architecture-patterns)
- [Experiment tracking](#experiment-tracking)
- [Fine-tuning vs. training from scratch vs. parameter-efficient fine-tuning](#fine-tuning-vs-training-from-scratch-vs-parameter-efficient-fine-tuning)
- [Data versioning for ML](#data-versioning-for-ml)
- [Model evaluation methodology](#model-evaluation-methodology)
- [Reproducibility](#reproducibility)
- [Compute and infrastructure decisions](#compute-and-infrastructure-decisions)
- [The notebook-to-production tension for ML training](#the-notebook-to-production-tension-for-ml-training)
- [Model cards](#model-cards)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## How this category specializes the cross-cutting architecture patterns

An ML training project's default architectural shape is not request/response
(Backend & API Services) or module-boundary API stability (Developer
Tooling & Libraries) — it's a **linear-with-branches pipeline**: data
acquisition → validation → feature/preprocessing → train → evaluate →
(conditionally) register/export, each stage consuming the prior stage's
output artifact rather than issuing a live call. That's the same DAG-shaped
orchestration concern [Data & Analytics Platforms](data-analytics-platforms.md)
names for its own ETL/ELT pipelines, but with two training-specific stage
properties a generic ETL DAG doesn't need: **checkpointing** — a training
run must be resumable from a saved mid-run state after a preemption or
crash, not just re-run from stage zero, which is what distinguishes a
training DAG node from an ordinary idempotent ETL transform step — and
**distributed-training coordination** — multi-GPU or multi-node data- or
model-parallel training needs its own process-group/rendezvous mechanics
that a plain task-orchestrator scheduler doesn't provide out of the box.

Two currently-distinct orchestrator shapes anchor this concept rather than
compete for a recommendation here (tool comparison belongs to the companion
[preferred-libraries/ml-model-development.md](../preferred-libraries/ml-model-development.md)):
**Kubeflow Pipelines**, confirmed by direct fetch of its own docs
(`kubeflow.org/docs/components/pipelines/overview/`), describes itself as
"a platform for building and deploying portable and scalable machine
learning workflows using containers on Kubernetes-based systems," is
explicitly installable standalone ("available as a core component of
Kubeflow or as a standalone installation," not requiring the full Kubeflow
platform), and runs each pipeline step as its own container ("each
component execution corresponds to a single container execution"). And
**Metaflow**, which represents a training pipeline as plain Python functions
annotated with step/resource decorators rather than containers as a
first-class unit — search-corroborated as the simpler operational choice,
trading away some DAG-topology flexibility and built-in integrations
compared to Kubeflow's containerized model. Both are named here as the
concept anchor for "a DAG orchestrator with ML-training-specific stages,"
not a recommendation between the two.

**Hexagonal / ports-and-adapters still applies at the pipeline's
data-ingestion boundary**, the same reasoning [Data & Analytics
Platforms](data-analytics-platforms.md#how-the-cross-cutting-architecture-patterns-specialize-here)
and Backend & API Services already used for their own inbound/outbound
boundaries: a dataset loader is an inbound adapter, a model-registry or
experiment-tracker write is an outbound adapter, and the training loop in
between shouldn't need to know which storage backend produced the data or
which tracker records the result. **Microservices and serverless are a poor
fit for the training loop itself** — a long-running, often multi-GPU,
stateful compute job is the opposite of what serverless's
stateless-short-invocation model is built for — but both are a normal fit
for a downstream component that isn't training itself: an evaluation-report
API, or a lightweight retraining-trigger function reacting to a
new-data-arrived event. **CQRS and event sourcing don't meaningfully apply
here.** The closest analogue to Data & Analytics Platforms' own "a warehouse
is CQRS by construction" framing would be "an experiment-tracking store is a
read-optimized log of write events (runs)," but that framing wasn't found
stated anywhere in current sources this pass, so it's named here only as a
plausible-but-unverified parallel, not asserted as fact — the honest
posture the numeric-claims convention above calls for applied to an
architectural framing rather than a number.

## Experiment tracking

The architectural problem experiment tracking solves: answering **"which
exact hyperparameters, code version, and data produced this specific
metric?"** after the fact, for potentially hundreds of runs — without it, a
team accumulates untraceable metric numbers with no path back to what
produced them. Confirmed by direct fetch of MLflow's own tracking docs
(`mlflow.org/docs/latest/ml/tracking/`), the concrete metadata an
experiment-tracking system captures per **run** — a single execution of
training code, grouped under an **experiment**, a named collection of
related runs — is parameters, metrics, start/end times, a run ID, artifacts
(model weights, plots, other output files, persisted separately to object
storage), and, a distinct and newer capability, **dataset references**
associated with the run, so "which data version trained this" is itself a
trackable field rather than something inferred separately.

Architecturally, this is a **separation of a lightweight metadata store**
(parameters, metrics, run identity — typically a relational DB) **from a
heavyweight artifact store** (object storage, for model weights and large
files) — the identical metadata-vs-blob split [Infrastructure & Platform
Engineering](infrastructure-platform-engineering.md#state-management) names
for Terraform/Pulumi state versus artifact storage, here applied to
training-run records instead of infrastructure state.

The current landscape splits on a genuine infrastructure-control-versus-
managed-convenience axis, verified this pass rather than assumed stale.
**MLflow** is open source, backed by Databricks, and self-hosted — teams
download, deploy, and operate MLflow infrastructure independently — and it
has expanded well beyond experiment tracking into LLM observability, prompt
optimization, and model-deployment tooling. The trade-off named across
multiple current sources is more setup and maintenance burden, plus a
comparatively basic UI and minimal built-in collaboration. **Weights &
Biases** is a managed SaaS platform — W&B handles infrastructure, scaling,
and availability transparently — with polished visualization, built-in team
collaboration (comments on runs), and hyperparameter-sweep orchestration, at
the cost of vendor dependency and, for a data-sensitive team, data leaving
self-managed infrastructure. Both solve the identical core problem (record,
compare, reproduce); the architectural choice is infrastructure-control-
and-vendor-neutrality versus managed-convenience-and-collaboration.
Licensing, pricing, and newer-entrant comparison belongs to the companion
[preferred-libraries/ml-model-development.md](../preferred-libraries/ml-model-development.md),
not here.

## Fine-tuning vs. training from scratch vs. parameter-efficient fine-tuning

This is a genuine, current decision axis, anchored on the original LoRA
paper (confirmed by direct fetch of `arxiv.org/abs/2106.09685`) and Hugging
Face's own PEFT library (confirmed by direct fetch of
`github.com/huggingface/peft`, Apache-2.0) as primary sources, not secondary
comparison content.

**Training from scratch** (full pretraining) means learning all of a
model's weights from random initialization over a large corpus. It's rare
and expensive by construction, and justified only when no existing
pretrained model is a viable adaptation starting point for the task —  the
uncommon case for most projects incubated via this skill. Reported cost
figures for this range across multiple secondary industry sources this pass
from tens of thousands of dollars for a small model up to nine figures for a
frontier model; that range is kept only as an order-of-magnitude directional
signal, not independently verified against any lab's own disclosed training
budget, consistent with this repo's no-cost-modeling convention.

**Full fine-tuning** updates all of a pretrained model's weights against a
smaller, task-specific dataset — meaningfully cheaper than pretraining
because it starts from already-learned representations rather than random
initialization, but it still requires holding a full optimizer state and
gradient for every parameter. That memory cost is the direct driver of
PEFT's existence.

**PEFT (parameter-efficient fine-tuning)**, confirmed by direct fetch of the
HF PEFT README, freezes the pretrained model's original weights and trains
only a small number of additional parameters. **LoRA** specifically —
confirmed by direct fetch of the original paper's own abstract — "freezes
the pre-trained model weights and injects trainable rank decomposition
matrices into each layer of the Transformer architecture," reporting, in
the original paper against GPT-3 175B, up to a **10,000× reduction in
trainable parameters** and a **3× lower GPU memory requirement** than full
fine-tuning, with quality "on-par or better... on RoBERTa, DeBERTa, GPT-2,
and GPT-3." A specific, load-bearing mechanical detail worth stating
precisely: LoRA adds **no inference latency**, unlike earlier adapter-layer
approaches that insert extra layers into the forward pass — the low-rank
matrices are merged back into the original weight matrices rather than
staying as a separate computation path at serving time.

The HF PEFT README's own current worked example makes the proportion
concrete for a smaller, more typical project model: fine-tuning Qwen2.5-3B
with LoRA trains **0.12% of the model's parameters** (3,686,400 of
3,089,625,088), and the same README's comparison table shows full
fine-tuning of that 3B model needing **47.14GB** of GPU memory versus
**14.4GB** with PEFT-LoRA — a concrete, single-model illustration of why the
memory argument for PEFT isn't just a theoretical one. **QLoRA** (LoRA
applied on top of a quantized base model, reducing memory further) and other
PEFT method families — prefix tuning, prompt tuning, IA3, adapters — are
named in the PEFT README as supported method categories; the mechanical
comparison between them belongs to the companion `preferred-libraries.md`'s
adoption/tooling table rather than being repeated here.

**Decision rule for a new project**: default to PEFT (LoRA/QLoRA) whenever
an existing pretrained model already covers most of the target domain or
task and compute budget is a real constraint — the common case. Full
fine-tuning is justified when the task requires substantially different
behavior than any available pretrained model exhibits and the compute
budget genuinely allows it. Training from scratch is justified only when no
existing pretrained model is a defensible starting point at all — a
genuinely new modality or domain with no public pretrained analogue, or a
deliberate research question about pretraining itself.

One specific numeric claim worth naming as deliberately excluded rather
than silently omitted: "LoRA recovers 90-95% of full fine-tuning quality,
QLoRA 80-90%" turns up repeated across several secondary/course-style
sources, but it traces only to aggregator/course content, not the original
paper or an HF-authored source — and the original LoRA paper's own "on-par
or better" framing is a different, weaker, and better-sourced claim than a
specific percentage-recovery figure. It's left out on those grounds, not
because the underlying intuition (PEFT trades some quality for large
efficiency gains, in some regimes) is wrong.

## Data versioning for ML

The architectural question this section answers, distinct from ordinary
git history, is **"which exact dataset version trained this specific
model?"** A dataset can change — new records, corrected labels, a
re-scrape — without the training code changing at all, and without a
data-version record, that change is invisible to anyone trying to reproduce
a past result or debug a regression.

**DVC**, confirmed by direct fetch of `doc.dvc.org`, is the current concrete
mechanism most commonly named for this: `dvc add` moves a large file or
directory into a content-addressed cache and creates a small `.dvc`
metadata file — a content hash plus a path — that *is* committed to git, so
git tracks a pointer to a specific data version, not the data itself, while
the actual bytes live in configurable remote storage (S3, GCS, Azure Blob,
etc.), fetched on demand via `dvc pull`. This is the identical
**metadata-in-git, blobs-in-object-storage** split the Experiment Tracking
section above names for run artifacts, applied here to input data instead
of output artifacts — the same architectural pattern recurring at a
different pipeline stage.

Why this can't just be "git with a bigger repo," concretely: git's
diffing and storage model is built for line-diffable text and degrades
badly on large binary files — repo bloat, slow clones, no meaningful diff —
the same limitation the cross-cutting `project-structure.md` baseline
already names for Git LFS's own "few hundred MB per file" practical
ceiling. DVC and similar tools exist specifically for the case where the
*dataset itself*, not just an occasional large binary, needs first-class
versioning.

**Content-hash fingerprinting is the underlying mechanism making both data
versioning and reproducible pipeline re-runs work**: a pipeline stage only
re-executes when its declared upstream dependency's hash actually changed —
a direct application of the idempotency principle [Infrastructure &
Platform Engineering](infrastructure-platform-engineering.md#idempotency-iac-style)
names for IaC ("re-running against an unchanged input should produce zero
redundant work"), here applied to a data pipeline's re-run decision rather
than an infrastructure apply.

**Lineage tracking** — recording which upstream dataset version(s) and
transformation steps produced a given downstream dataset or model — is the
same concern [Data & Analytics Platforms](data-analytics-platforms.md#data-contracts-between-producing-and-consuming-teams)
names for producer/consumer data ownership, applied here at the scope of
"this specific training run's full data provenance chain" rather than an
organization-wide contract between teams. Specific tool names and
license/adoption comparison (DVC vs. lakeFS vs. other current entrants)
belong to the companion `preferred-libraries.md`.

## Model evaluation methodology

**Held-out validation/test-set discipline** is the foundational practice: a
**validation set** is used during development for hyperparameter tuning and
model selection, while a **test set** is touched only once, at the very
end, for a final unbiased performance estimate. Reusing the test set for
any tuning decision silently converts it into a second validation set and
invalidates the "unbiased" property the whole discipline exists to provide.

**Benchmark contamination** — training-data/test-set overlap — is a real,
current, well-documented failure mode, not a hypothetical risk. Multiple
2026 sources report contamination rates ranging from roughly 1% to 45%
across popular QA benchmarks, with a specific cited figure of MMLU being
approximately 29% contaminated in at least one 2026 audit; that figure is
named here as a directional severity signal, not an independently
verified fact — it traces to secondary sources converging on a similar
number, not one primary contamination-audit paper this pass. Notably,
contamination isn't limited to verbatim overlap: paraphrased or translated
benchmark items can evade naive string-matching decontamination while
still inflating a reported score. Mitigation approaches active in current
research include **dynamic benchmarks** (test items refreshed from sources
dated after a model's training cutoff) and **zero-data-leakage evaluation**
(collecting and evaluating against exam/test material immediately after its
public release, before any model could plausibly have been exposed to it).

A concrete, real, first-party cautionary precedent is worth naming rather
than a hypothetical warning: Hugging Face's own **Open LLM Leaderboard was
officially retired**, direct-fetched this pass from the project's own
retirement discussion thread. Its stated reasons were that model
capabilities themselves had moved past what the fixed benchmark suite could
meaningfully measure — "as model capabilities change (hello reasoning and
LM assistants), benchmarks need to follow" — and that the leaderboard was
"slowly becoming obsolete," risking that it would "encourage people to hill
climb irrelevant directions in the field." This is a real, first-party
example of a widely-used standardized benchmark suite being deliberately
retired rather than patched once staleness outweighed its value, not a
theoretical concern about benchmarks aging.

**lm-evaluation-harness** (EleutherAI, MIT-licensed, direct-fetched this
pass from the project's own repository) describes itself as "a unified
framework to test generative language models on a large number of different
evaluation tasks," covering "over 60 standard academic benchmarks for LLMs,
with hundreds of subtasks and variants implemented." It's the backend for
the now-retired Open LLM Leaderboard, and the repository's own description
states it's "used internally by dozens of organizations including NVIDIA,
Cohere, BigScience, BigCode, Nous Research, and Mosaic ML." It's the current
concrete example of "standardized offline evaluation as reusable, shared
tooling" rather than every project hand-rolling its own benchmark runner —
named here as the architectural pattern (a shared, versioned evaluation
harness producing comparable numbers across models and runs), with specific
tool/library comparison belonging to `preferred-libraries.md`.

**The offline/online evaluation boundary is named here but explicitly not
owned by this doc.** Offline evaluation — benchmark suites, held-out test
sets, run before a model ships — answers "did this model learn its training
objective." Online/production evaluation — real user interactions, A/B-style
comparisons — answers "does this model's improvement actually hold once
it's serving real traffic," a documented, real gap from the offline half
precisely because a held-out test set's distribution isn't the same as live
traffic's. This category owns naming that boundary and the offline half;
the online/production-evaluation half, drift monitoring, and any
live-serving evaluation infrastructure belongs to the still-pending **MLOps
/ ML Platform Engineering** roadmap category.

## Reproducibility

Reproducibility here is a genuinely more demanding bar than typical
software reproducibility, anchored on the NeurIPS paper checklist —
confirmed by direct fetch of `neurips.cc/public/guides/PaperChecklist` — the
most concrete, currently-enforced primary source: mandatory for every
NeurIPS submission since 2019, itself a response to "recurrent gaps in
experimental methodology found in recent machine learning papers." Four of
its requirements map directly to real failure modes ordinary software
reproducibility doesn't have to think about:

1. **Code and environment** — "the code, data, and instructions needed to
   reproduce the main experimental results," with exact commands and
   environment specification. This is the same bar ordinary software
   reproducibility already has — a pinned dependency manifest — extended to
   also cover the run commands, not just the code itself.
2. **Full training details** — "data splits, hyperparameters, and how they
   were chosen," not merely the final chosen values, since *how* a
   hyperparameter was selected (a documented sweep versus an undocumented
   hand-tune) is itself part of what makes a result reproducible or not.
3. **Compute resources** — "type of compute workers, memory, time of
   execution," a category with no real analogue in typical application
   reproducibility. A training result can be sensitive to hardware —
   numeric non-determinism across GPU architectures and driver versions is
   a documented, real phenomenon — in a way an application's business logic
   normally isn't.
4. **Statistical significance** — "error bars suitably and correctly
   defined," reflecting that ML results are frequently *stochastic*
   (dependent on random initialization, data shuffling order, and, for
   anything using sampling, the random seed) in a way deterministic
   software behavior isn't. A single run's reported number is not, on its
   own, evidence of anything without repeated-run variance reported
   alongside it.

**Random seeds** specifically — search-corroborated across multiple current
sources, not independently confirmed as a standalone, separately-numbered
NeurIPS checklist line item in this pass's direct fetch of the checklist
page itself — are the standard current mechanism for controlling and
disclosing that stochasticity: fixing and publishing the seed(s) used, and
running multiple seeds to report variance, rather than reporting a single,
potentially lucky, run.

**The concrete, itemized reproducibility bar for a single ML experiment**,
synthesized from the above and worth stating as an explicit checklist:

- Code version (git commit)
- Data version (see [Data versioning for ML](#data-versioning-for-ml) above)
- Exact hyperparameters, and how they were chosen (documented sweep vs.
  hand-tune)
- Random seed(s), and the number of seeds run
- Hardware/accelerator type
- Framework and library versions (PyTorch/CUDA/driver version pinning,
  since numeric results can shift across these)

This is a strictly longer and more demanding list than a typical software
bug reproduction's "pin the dependency versions and give me the input" bar,
precisely because ML introduces stochasticity and hardware-numeric-
sensitivity as first-class reproducibility threats that don't exist for
deterministic application code.

## Compute and infrastructure decisions

Three real, currently-distinct options exist for where training compute
actually runs, verified this pass rather than assumed stale given how fast
this market has moved:

| Option | Value-add | Cost/control trade-off |
|---|---|---|
| **Local/on-prem GPU** | Zero marginal per-hour cost once purchased; full control | Real capital outlay; no elastic scale-up for a large or one-off run |
| **Hyperscaler managed training** (AWS SageMaker, Google Vertex AI, Azure ML) | ML-specific managed tooling (experiment tracking, pipeline orchestration, one-click deployment) integrated with the rest of that cloud's ecosystem — same IAM, same network, no egress charge moving data between that cloud's own services | Highest GPU pricing in the market per multiple 2026 comparison sources; constrained on-demand availability for newest-generation hardware |
| **Specialized GPU cloud providers** (CoreWeave, Lambda Labs, and similar current entrants) | Meaningfully better GPU pricing and a simpler, ML-specific workflow for teams that don't need the rest of a hyperscaler's ecosystem | Needing to build or buy each supporting piece (data storage, orchestration, experiment tracking) separately, and paying egress to move data between systems that aren't already co-located |

Search-corroborated current GPU support, not independently direct-fetched
against any single provider's own current-hardware-support page: SageMaker/
EC2 with H100/A100/L40S/T4, Vertex AI with H100s and TPU v4/v5e, and Azure ML
with H100s and AMD MI300X/L40S.

**Decision rule**: a small one-off fine-tuning job, or a team with existing
GPU hardware and no elastic-scale need, is simplest and cheapest served
locally or on-prem. A team already deeply integrated with one cloud's
data/identity/networking stack, or wanting managed pipeline/tracking
tooling bundled in, should accept that cloud's managed training platform's
pricing premium as the cost of integration. A team whose primary need is
raw GPU compute at the best available price, willing to independently wire
up its own storage/orchestration/tracking stack, is the fit for a
specialized GPU cloud provider. This is the training-side counterpart to
[Infrastructure & Platform Engineering](infrastructure-platform-engineering.md#kubernetes-vs-simpler-deployment-targets)'s
Kubernetes-vs-simpler-alternatives decision table — the same "match the
tool to a real, present constraint, not a default" framing, applied to GPU
compute procurement instead of container orchestration. Specific provider
comparison and current pricing belong to the companion
`preferred-libraries.md`, consistent with this repo's no-cost-modeling
convention.

## The notebook-to-production tension for ML training

[Data & Analytics Platforms](data-analytics-platforms.md#the-notebook-to-production-transition)
already covers the general case in depth — the hidden-state problem, a
`.ipynb`'s poor git-diffability, the "fragmentation tax" framing — and
that section isn't re-derived here. What's genuinely ML-training-specific
on top of that general framing: a notebook cell holding a **multi-hour or
multi-day training run's in-progress state** (an optimizer state, a
partially trained model, accumulated metrics) is a substantially
higher-stakes instance of the hidden-state problem than an analytics
notebook's intermediate dataframe. Losing a kernel or session — a Colab
disconnect, a local machine sleeping, a cloud notebook instance's idle
timeout — can mean losing hours or days of GPU compute with no checkpoint
to resume from, which is precisely why the checkpointing concern named in
[How this category specializes the cross-cutting architecture
patterns](#how-this-category-specializes-the-cross-cutting-architecture-patterns)
above matters even more once training moves out of a notebook and into a
real orchestrated pipeline step.

Concretely, for ML training specifically: exploratory data inspection, a
first small-scale training-loop sanity check, and result visualization are
legitimate notebook uses. The moment a training run needs to survive a
preemption, run unattended on a schedule or trigger, or be launched by
anyone other than the person who wrote the notebook, its training loop
belongs in a plain Python module invoked by the orchestrator — a Kubeflow
Pipelines or Metaflow step, or a plain script under a job scheduler. That's
the same "papermill-style notebook scheduling is a legitimate stopgap for
one analyst's recurring report, not a pattern to build a platform's core
pipelines on" caution Data & Analytics Platforms already states, carried
forward with "training run" in place of "report" as the concrete stakes.

## Model cards

A model card is a structured document describing a trained model's
intended uses, limitations, training data, and evaluation results — current
standard practice for documenting a trained model, anchored on Mitchell et
al.'s "Model Cards for Model Reporting" paper as the originating source
(direct-fetched this pass, confirming the paper proposes model cards as
"short documents accompanying trained machine learning models" disclosing
intended use, performance evaluated across different demographic/cultural
conditions rather than just an aggregate accuracy number, and evaluation
procedures — framed explicitly around "responsible democratization of
machine learning") and Hugging Face's own current model-card tooling as the
dominant concrete implementation (direct-fetched this pass from
`huggingface.co/docs/hub/model-cards`).

On the HF Hub, a model card is literally the model repo's own `README.md`
with a YAML metadata header. Per HF's own stated required content, it
describes: the model itself and its **intended uses and potential
limitations, including biases and ethical considerations** (explicitly
citing Mitchell et al. for this framing); the **training parameters and
experimental info**, with an explicit, direct architectural link back to
this doc's own [Experiment tracking](#experiment-tracking) section — HF's
own guidance is to "embed or link to an experiment tracking platform for
reference" rather than duplicate that record by hand; **which datasets were
used to train the model**, the same direct link to this doc's [Data
versioning for ML](#data-versioning-for-ml) section, since HF's metadata
schema has a dedicated `datasets:` field resolved against the Hub's own
dataset registry when available; and the **model's evaluation results** in
a structured, machine-parseable format — HF's `model-index` schema,
originally based on Papers with Code's own model-index specification, a
real, checkable convention for making evaluation numbers filterable and
comparable across models on the Hub, not just prose claims.

A model card additionally supports declaring **provenance relationships to
a base model** — `base_model_relation: finetune | adapter | quantized |
merge` — a real, current mechanism for the fine-tuning/PEFT decision named
in [Fine-tuning vs. training from scratch vs. parameter-efficient
fine-tuning](#fine-tuning-vs-training-from-scratch-vs-parameter-efficient-fine-tuning)
above to be declared machine-readably rather than only in prose, directly
connecting this section back to that decision axis.

**Honest current-adoption caveat**, stated by HF's own documentation and
worth carrying forward rather than presenting model cards as universally
filled out: per search corroboration of the current ML-documentation-
tooling landscape, "model cards for the majority of existing models do not
exist or are incomplete, despite their adoption as a best practice in the
ML community." That's a real, acknowledged gap between the practice's
stated standard-ness and its actual completion rate in the wild, not a
solved problem. What sets a model card apart from ordinary software
documentation — a README describing installation, usage, and API surface —
is what it's *for*: a model card's core job is disclosing the training
data, evaluation scope, and known limitations of a specific artifact whose
behavior was learned rather than explicitly coded, information a
conventional software README has no equivalent need to disclose.

## Where this doc stops

Specific tool/library names, licenses, and adoption-signal comparisons —
MLflow vs. W&B vs. newer experiment trackers, DVC vs. lakeFS, PEFT-adjacent
libraries beyond HF's own PEFT, Kubeflow vs. Metaflow, CoreWeave vs. Lambda
Labs vs. other GPU cloud entrants — belong entirely to the companion
[preferred-libraries/ml-model-development.md](../preferred-libraries/ml-model-development.md).
This doc names a tool only where the tool's own documented behavior *is*
the architectural fact being described — LoRA's own parameter-reduction
mechanism, DVC's content-hash mechanism, the Open LLM Leaderboard's own
stated retirement reasons — not as a comparative recommendation between
products.

**Deep distributed-training internals** — DeepSpeed ZeRO stages, FSDP
sharding mechanics, gradient-accumulation/pipeline-parallelism
implementation detail, multi-node rendezvous protocol specifics — are named
only as a real concern this doc's pipeline-specialization section flags
exists ("distributed-training coordination... needs its own process-group/
rendezvous mechanics"), not researched at implementation depth. Most
projects incubated via this skill won't need multi-node distributed
training on day one; this is a real, named gap rather than a silently
covered concern.

**MLOps / ML Platform Engineering** — model registries, feature stores,
model-serving infrastructure, drift monitoring, retraining triggers, and
canary rollouts for models specifically — is the still-pending sibling
roadmap category's job, not this one's. The dividing line, stated precisely
for a clean handoff: this doc owns everything up through producing and
evaluating a trained model artifact (experiment tracking, fine-tuning/
training decisions, data versioning, offline evaluation, reproducibility,
model cards); MLOps owns everything from that artifact being registered and
served onward. That a single tool (MLflow) spans both sides of this line
doesn't mean the line is wrong — the same way Terraform's own state file
touching both provisioning and drift detection didn't collapse those into
one Infrastructure & Platform Engineering subsection. Online/production
evaluation is named in this doc's Model Evaluation section only as a
boundary this doc doesn't own, not covered at depth here.

**RAG-corpus construction and retrieval-pipeline architecture** belongs to
[Agentic & MCP Platforms](agentic-mcp-platforms.md), not here: assembling a
retrieval corpus (chunking, embedding-model choice, vector-index
architecture) produces no trained artifact, which is this doc's own
dividing line for what it owns. This wasn't retroactively added to that
already-shipped doc's own text this pass — a separate, deliberate update if
this repo's maintainers want it named there explicitly.

**Full streaming/real-time training** — online learning, continual learning
against a live data stream — is out of scope. This doc's default framing
assumes batch-shaped training runs against a versioned, static dataset
snapshot, consistent with Data & Analytics Platforms' own "batch is the
default, streaming needs a named justification" framing.

**Cost modeling and cloud GPU pricing comparisons** stay out of scope
beyond the qualitative pricing-tier positioning already named in
[Compute and infrastructure decisions](#compute-and-infrastructure-decisions),
consistent with every other doc in this skill.

**BI/reporting/analytics-consumer-facing data work** — warehouses,
lakehouses, dashboards, ELT for business reporting — is Data & Analytics
Platforms' own territory, already shipped; this doc's data-versioning
section deliberately covers only training-data versioning, a narrower and
differently-motivated concern than that category's own data-contracts/
lineage-for-organizational-consumption framing.

For where a single service's own request/response architecture is decided
rather than what feeds or consumes a trained model, see [Backend & API
Services](backend-api-services.md). For where an application calls an
already-trained model at inference time, see [Agentic & MCP
Platforms](agentic-mcp-platforms.md).

## Sources

- Local precedent (not a web source, read directly): `find` across
  `/Users/devopammittra/GitHub/ubi-csr-tmf` and
  `/Users/devopammittra/GitHub/agent-skills` for `*.ipynb`, `train*.py`,
  MLflow/W&B/DVC config files, and model-weight artifacts (`*.pt`, `*.onnx`,
  `*.safetensors`) — zero matches; direct read of
  `aws/container/agents/`'s directory listing confirming its
  `strands_agents`/`main.py`/FastAPI shape as an inference-time agent
  application, not a training codebase — read 2026-08-31
- https://mlflow.org/docs/latest/ml/tracking/ — direct fetch: run/experiment
  metadata model (parameters, metrics, run ID, timestamps), artifact store
  vs. backend store separation, dataset-tracking capability — retrieved
  2026-08-31
- MLflow vs. Weights & Biases current positioning — search-corroborated
  across multiple 2026 comparison sources (reintech.io, deploybase.ai,
  modern-datatools.com, contracollective.com): MLflow as self-hosted/open
  with weaker collaboration UI, W&B as managed SaaS with built-in
  collaboration/sweep orchestration — retrieved 2026-08-31
- https://arxiv.org/abs/2106.09685 (Hu et al., "LoRA: Low-Rank Adaptation of
  Large Language Models") — direct fetch of the paper's own abstract:
  frozen-weights + injected low-rank decomposition-matrix mechanism, 10,000×
  trainable-parameter reduction and 3× GPU-memory reduction versus full
  fine-tuning of GPT-3 175B, "on-par or better" quality claim across
  RoBERTa/DeBERTa/GPT-2/GPT-3, no added inference latency — retrieved
  2026-08-31
- https://github.com/huggingface/peft — direct fetch: Apache-2.0 license,
  supported method families (LoRA, QLoRA, prefix tuning, prompt tuning, IA3,
  adapters), the Qwen2.5-3B worked example (0.12% trainable parameters:
  3,686,400 of 3,089,625,088) and the 47.14GB-vs-14.4GB full-fine-tuning-
  vs-PEFT-LoRA GPU-memory comparison for a 3B model — retrieved 2026-08-31
- https://doc.dvc.org/user-guide/data-management/large-dataset-optimization
  — direct fetch: `.dvc` metadata-file + content-addressed cache + remote
  storage mechanism, the git-tracks-a-pointer/data-lives-in-remote-storage
  architectural split, why this differs from plain git (binary/large-file
  handling) — retrieved 2026-08-31
- Cost-to-pretrain-from-scratch figures — search-corroborated across
  multiple secondary/industry-analysis sources (spheron.network,
  aisuperior.com, cudocompute.com, spendark.com), not independently
  verified against any lab's own disclosed training budget; kept only as an
  order-of-magnitude directional range — retrieved 2026-08-31
- Benchmark contamination/data leakage in LLM evaluation — search-
  corroborated across multiple current sources including arXiv preprints
  (2502.00678 "How Contaminated Is Your Benchmark?", 2505.08389 "Towards
  Contamination Resistant Benchmarks," 2605.19999) and a secondary write-up
  (blog.pebblous.ai) citing an approximately 29%-contaminated figure for
  MMLU specifically and a 1%-45% range across popular QA benchmarks more
  broadly — not independently direct-fetched against a single primary
  contamination-audit paper — retrieved 2026-08-31
- https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard/discussions/1135
  — **direct-fetched this pass** (upgraded from search-snippet-only in an
  earlier pass): confirms the leaderboard's own stated retirement reasons —
  "as model capabilities change (hello reasoning and LM assistants),
  benchmarks need to follow," and that the leaderboard was "slowly becoming
  obsolete," risking it would "encourage people to hill climb irrelevant
  directions in the field" — retrieved 2026-08-31
- https://github.com/EleutherAI/lm-evaluation-harness — **direct-fetched
  this pass** (upgraded from search-corroborated-only in an earlier pass):
  confirms MIT license, "over 60 standard academic benchmarks for LLMs, with
  hundreds of subtasks and variants implemented," backend for the
  now-retired Open LLM Leaderboard, and "used internally by dozens of
  organizations including NVIDIA, Cohere, BigScience, BigCode, Nous
  Research, and Mosaic ML" — retrieved 2026-08-31
- Held-out validation-vs-test-set discipline and offline-vs-online
  evaluation framing — search-corroborated across multiple sources
  (machinelearningmastery.com, deepchecks.com, shaped.ai, labelstud.io) —
  retrieved 2026-08-31
- https://neurips.cc/public/guides/PaperChecklist — direct fetch: the
  current NeurIPS reproducibility checklist items (experimental-result
  reproducibility, open code/data access, full training-detail disclosure
  including data splits and how hyperparameters were chosen, compute-
  resource disclosure, statistical-significance/error-bar reporting) —
  retrieved 2026-08-31
- Random-seed reporting/multi-seed variance as current practice — search-
  corroborated across multiple sources (geeksforgeeks.org, atticusli.com)
  discussing the NeurIPS reproducibility program's own findings; not
  independently confirmed as a standalone, separately-numbered NeurIPS
  checklist item in this pass's direct fetch of the checklist page itself —
  retrieved 2026-08-31
- GPU cloud providers 2026 (CoreWeave, Lambda Labs, AWS SageMaker, Google
  Vertex AI, Azure ML) — search-corroborated across multiple 2026 comparison
  sources (northflank.com, runpod.io, gpu.fm), not independently direct-
  fetched against any single provider's own current-hardware-support page —
  retrieved 2026-08-31
- https://kubeflow.org/docs/components/pipelines/overview/ — direct fetch:
  confirms KFP's own "portable and scalable machine learning workflows
  using containers on Kubernetes-based systems" framing, standalone-
  installable positioning, and container-per-step execution model —
  retrieved 2026-08-31
- Metaflow's own Python-decorator positioning versus Kubeflow — search-
  corroborated only (reintech.io, spheron.network) — retrieved 2026-08-31
- https://huggingface.co/docs/hub/model-cards — direct fetch: required
  model-card content (model description, intended uses/limitations/biases
  citing Mitchell et al., training params with a link-to-experiment-tracker
  convention, training datasets via a `datasets:` metadata field, structured
  evaluation results via a `model-index` schema originally based on Papers
  with Code's own spec), `base_model_relation` provenance field
  (`finetune`/`adapter`/`quantized`/`merge`) — retrieved 2026-08-31
- Mitchell, Wu, Zaldivar, Barnes, Vasserman, Hutchinson, Spitzer, Raji,
  Gebru, "Model Cards for Model Reporting" — direct fetch: confirms the
  paper proposes model cards as "short documents accompanying trained
  machine learning models" disclosing intended use, performance evaluated
  across different demographic/cultural conditions rather than only an
  aggregate accuracy number, and evaluation procedures, framed explicitly
  around "responsible democratization of machine learning" — retrieved
  2026-08-31
- Model-card current-adoption gap ("cards for the majority of existing
  models do not exist or are incomplete") — search-corroborated via
  `huggingface.co/docs/hub/model-card-landscape-analysis` — retrieved
  2026-08-31
- `research/architecture-templates.md`, `research/project-structure.md`,
  `research/stacks/data-analytics-platforms/stack.md`,
  `research/stacks/infrastructure-platform-engineering/stack.md`,
  `research/stacks/backend-api-services/stack.md`,
  `research/taxonomy-roadmap.md` — read directly (not web sources) to avoid
  re-deriving cross-cutting/adjacent-category content already covered, and
  to confirm this category's scope boundaries against its two named
  neighbors — read 2026-08-31
