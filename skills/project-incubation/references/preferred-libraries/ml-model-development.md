# ML / AI Model Development — Preferred Libraries

Companion to [stacks/ml-model-development.md](../stacks/ml-model-development.md),
which covers architecture and selection criteria; this doc names the actual
tools, their licenses, and honest maintenance/adoption signal for the
model-*building* side of the ML lifecycle — training, fine-tuning,
experiment tracking, and model evaluation — as distinct from Data &
Analytics Platforms (BI/reporting, already shipped) and Agentic & MCP
Platforms (serving already-built models, already shipped). No local
precedent exists for this category: a direct `find`/`grep` pass across
`/Users/devopammittra/GitHub/ubi-csr-tmf` and this repo turned up zero
notebooks, zero `train*.py` files, zero MLflow/W&B/DVC config, zero model
weights (`.pt`/`.ckpt`/`.safetensors`/`.onnx`/`.h5`), and zero mentions of
torch/tensorflow/transformers/peft/mlflow/wandb/dvc/jax in any local
dependency manifest — `ubi-csr-tmf`'s `agents/` component is an LLM-agent
*application* consuming a hosted model API, not a model-training codebase,
and does not count as precedent here. Every entry below is therefore
externally sourced, with a direct fetch of the repo/package/vendor page
wherever practical.

This authoring pass re-verified rather than transcribed the baseline in
several places, and one of those re-checks surfaced a real, dated
governance event the baseline's own research missed entirely: **lakeFS's
parent company, Treeverse, acquired the DVC open-source project from
Iterative on 2025-11-18** (a direct `gh api repos/iterative/dvc` fetch now
resolves to `treeverse/dvc`, and `https://github.com/iterative/dvc`
301-redirects to `https://github.com/treeverse/dvc` — a fully confirmed
repo transfer, not a rumor). That changes the Data-versioning section's
framing from "two competing tools" to "one company now stewards both ends
of the versioning-granularity spectrum," and gives a concrete explanation
for the release-cadence gap the baseline flagged but couldn't fully
account for. Also re-confirmed by direct fetch this pass rather than left
as search-corroborated: Weights & Biases' own pricing page states
verbatim that its free Personal tier disallows "corporate use," and its
Pro tier's own $60/user/month figure and <50-employee ceiling; the
Unsloth-vs-Axolotl 3.2-vs-5.8-hour QLoRA benchmark, now pinned to its exact
configuration (Llama-3.1-8B, rank 32, A100 40GB); RunPod's exact per-hour
GPU rates; and Google's own Colab FAQ language on undisclosed, dynamic
free-tier limits and paid-tier compute-unit depletion. Every star/fork/
issue/`pushed_at`/release figure below is a snapshot re-fetched
2026-08-31, and a spot-check re-fetch of PyTorch, MLflow, Unsloth, Kubeflow
Pipelines, DVC, and lm-evaluation-harness this pass found the numbers
essentially unchanged from the research baseline (MLflow's open-issue
count ticked from 2,057 to 2,056) — small enough drift to confirm these
are live, reproducible figures, not stale copy-paste.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [Deep learning frameworks](#deep-learning-frameworks)
- [Experiment tracking](#experiment-tracking)
- [Fine-tuning / PEFT tooling](#fine-tuning--peft-tooling)
- [Data versioning for ML](#data-versioning-for-ml)
- [ML-specific pipeline orchestration](#ml-specific-pipeline-orchestration)
- [Model evaluation / benchmarking tooling](#model-evaluation--benchmarking-tooling)
- [Hugging Face Hub tooling](#hugging-face-hub-tooling)
- [Compute providers for training](#compute-providers-for-training)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

**Python, overwhelmingly.** Unlike the Python/Node split in
[Backend & API Services](backend-api-services.md#ecosystem-choice) or the
mostly-standalone-binary shape of
[Infrastructure & Platform Engineering](infrastructure-platform-engineering.md#ecosystem-choice),
no second language ecosystem competes here at all — every tool in this
category ships a Python-first (often Python-only) interface. The closest
thing to a second "language surface" is YAML-driven configuration layered
on top of Python (Axolotl's training configs, Kubeflow Pipelines' compiled
YAML), not a competing runtime the way HCL or Rego are for infrastructure
tooling. Because of this, the tables below use GitHub
stars/forks/open-issues/`pushed_at`/latest-release-tag as the primary
adoption signal — direct `gh api repos/<owner>/<repo>` fetches — rather
than PyPI download counts, supplemented by Linux Foundation/CNCF
governance status where that's the more load-bearing fact (PyTorch,
MLflow, and Kubeflow specifically).

## Deep learning frameworks

**License, checked precisely rather than assumed**: GitHub's repo-metadata
API reports `license.spdx_id: NOASSERTION` for `pytorch/pytorch` — the same
detection artifact this repo's Infrastructure & Platform Engineering doc
flags repeatedly for Terraform/Conftest/Vault. A direct fetch of the
repo's own `LICENSE` file resolves it: PyTorch ships a **modified
BSD-3-Clause-style license** (the original Facebook/Torch/Caffe2-era text),
not a standard SPDX-tagged BSD-3-Clause, and not proprietary or
source-available in the BSL sense.

Governance is the more interesting fact than the license text: PyTorch is
now stewarded by the **PyTorch Foundation, hosted by the Linux
Foundation**, with a governing board drawn from AMD, AWS, Google Cloud,
Meta, Microsoft Azure, and Nvidia, plus a Technical Advisory Council — nine
new member organizations joined since December 2025, a genuinely growing
body rather than a one-time press release. 2026 sources converge that
PyTorch now accounts for roughly **85% of deep-learning research papers**
(up from ~80% at NeurIPS 2023) and underlies the large majority of current
open-weight LLM releases (Llama, Mistral, Qwen, DeepSeek) and the
PyTorch-native inference stack (vLLM, TensorRT-LLM). TensorFlow keeps a
real, distinct lane rather than fading out — it remains the stronger
choice for **edge/mobile deployment (TFLite)** and a more mature
end-to-end MLOps story at existing TensorFlow shops. JAX's current
differentiator is **TPU-native performance and Google's own internal
usage** — Gemini trains on JAX, not TensorFlow — making it the right
choice specifically for TPU-targeted work or JAX's functional
transform/compile model, not a general PyTorch alternative. The three are
also visibly converging: `torch.compile()` brought PyTorch
graph-compilation parity, and Keras 3 now runs on all three backends
interchangeably.

| Library | For | License | Why recommended |
|---|---|---|---|
| **PyTorch** (`pytorch/pytorch`) — default | New deep-learning/generative-AI work of any kind | Modified BSD-3-style (own `LICENSE`; GitHub metadata misreports `NOASSERTION`) | Dominant research-paper share (~85%) and the framework nearly every current open-weight LLM and every PEFT/fine-tuning tool in this doc targets first; governed by the multi-vendor **PyTorch Foundation / Linux Foundation**. Direct GitHub fetch: 102,696 stars, 29,049 forks, 17,483 open issues, pushed 2026-08-31 (very active); latest release `v2.13.0` |
| **TensorFlow** (`tensorflow/tensorflow`) | Edge/mobile deployment (TFLite), or an org already standardized on TensorFlow's production-serving ecosystem | Apache-2.0 | Not the default for new research/greenfield generative-AI work given PyTorch's current share, but the right pick when TFLite or an existing TensorFlow-standardized estate is the actual constraint. Direct GitHub fetch: 198,080 stars, 76,210 forks, 3,003 open issues, pushed 2026-08-31 (active) — highest raw star count of the three, reflecting age more than current momentum |
| **JAX** (`jax-ml/jax`, renamed from `google/jax`) | TPU-targeted training, or research needing JAX's `jit`/`grad`/`vmap` functional-transform model | Apache-2.0 | Google's own Gemini models train on JAX; the right call specifically for TPU-native work, not a general PyTorch replacement for most teams. Direct GitHub fetch: 36,229 stars, 3,751 forks, 2,493 open issues, pushed 2026-08-31 (active); latest release `jax-v0.11.1` |

**Decision rule**: new generative-AI/LLM or general deep-learning project
→ **PyTorch** by default; TPU-targeted training or JAX-specific research
methodology → **JAX**; edge/mobile deployment target or an existing large
TensorFlow-standardized production estate → **TensorFlow**. Do not default
to TensorFlow on adoption grounds alone — its higher star count reflects
longer history, not current research momentum.

## Experiment tracking

**Commercial-tier trap, W&B's free tier — direct-fetch-verified this
pass, not assumed**: `wandb/wandb` (the client SDK) is genuinely
**MIT-licensed**, confirmed via a direct fetch of its own `LICENSE` file.
But a direct fetch of `wandb.ai/site/pricing` itself, done this authoring
pass rather than relying on the baseline's search corroboration, confirms
the free **Personal** tier's own page states plainly that **"corporate use
is not allowed"** — it's scoped to personal development, small projects,
and academic use, with (per corroborating secondary sources) a hard cap of
3 concurrent runs. A team building a real commercial product on the free
tier is out of compliance by definition, not merely quota-constrained. The
same pricing-page fetch confirms the first commercially-usable tier,
**Pro, starts at $60/user/month**, explicitly scoped to "early-stage teams
fewer than 50 employees" — anyone larger is required onto custom
Enterprise pricing. This is the same shape of trap this repo's other
baselines call out for HCP Terraform/Vault (BSL) and LangGraph: "free tier
looks fine until you read the terms," here on a *use-case* restriction
rather than a resource cap.

| Library | For | License | Why recommended |
|---|---|---|---|
| **MLflow** (`mlflow/mlflow`) — default for self-hosted/open tracking | Experiment tracking, model packaging, a model registry at the model-dev stage, a UI for comparing runs | Apache-2.0 | **Linux Foundation top-level project** (joined June 2020) — the only fully open, vendor-neutral-governed option here; per LFX Insights, 13M+ monthly downloads and 415 active contributors in the last quarter confirms this isn't a dormant donated project. Direct GitHub fetch: 27,741 stars, 6,234 forks, 2,056 open issues (re-confirmed this pass, ticked down 1 from the baseline's 2,057), pushed 2026-08-31 (very active); latest release `v3.15.2` |
| Weights & Biases (`wandb/wandb`, client SDK) | Experiment tracking with hosted dashboards and a strong collaboration UI | Client SDK: **MIT**; hosted SaaS platform: proprietary, commercial — see trap above | The strongest UI/collaboration experience in this table, but only commit to it with the corporate-use and 50-employee-ceiling terms above priced in — not a drop-in free replacement for MLflow for any real commercial project. Direct GitHub fetch (SDK repo): 11,244 stars, 892 forks, 958 open issues, pushed 2026-08-31 (active) |
| **Aim** (`aimhubio/aim`) | Fully open-source experiment tracking with a W&B-comparable UI, self-hosted only | Apache-2.0 | The current open alternative to W&B for a team wanting a polished comparison/visualization UI with zero licensing ambiguity — no commercial-tier gate of any kind. Direct GitHub fetch: 6,245 stars, 410 forks, 470 open issues, pushed 2026-08-30 (active) |
| ClearML (`allegroai/clearml`) | Broader MLOps suite bundling experiment tracking + orchestration + data/artifact management in one tool | Apache-2.0 | Named for completeness as the "one tool covers tracking + orchestration + data versioning" alternative to composing MLflow/DVC/Kubeflow separately — a real trade-off between convenience and being locked into one vendor's opinionated stack. Direct GitHub fetch: 6,847 stars, 797 forks, pushed 2026-08-30 (active) |

**Decision rule**: default to **MLflow** for a self-hosted, license-clean
choice with genuine multi-vendor governance; reach for **W&B** only after
confirming the team's usage is on a commercially licensed tier, not the
free Personal one; **Aim** is the right pick for W&B-like UI polish
without any commercial dependency; **ClearML** is worth naming when a team
explicitly wants one consolidated tool rather than composing MLflow + a
separate orchestrator + a separate data-versioning tool.

## Fine-tuning / PEFT tooling

**This moved fast 2023–2025 and has genuinely consolidated around a small,
current set of tools rather than staying fragmented.** Hugging Face's
`transformers`/`peft`/`trl` remain the institutional base layer everything
else builds on, while three purpose-built fine-tuning frameworks —
Unsloth, Axolotl, LLaMA-Factory — now cover the practical LoRA/QLoRA
workflow end-to-end, each with a distinct niche rather than being
redundant with one another. This authoring pass re-fetched the widely
cited Unsloth-vs-Axolotl benchmark directly (the baseline had only
search-corroborated it) and pinned down its exact configuration: **fine-
tuning Llama-3.1-8B via QLoRA at rank 32 takes 3.2 hours on Unsloth vs.
5.8 hours on Axolotl on an identical A100 40GB config**, a gap the
source attributes to Unsloth's custom Triton kernels for attention, MLP
layers, and RoPE embeddings — Axolotl's own overhead comes from
abstraction layers built for multi-GPU distribution and pipeline support
that add latency even on a single-GPU run. That trade-off is the same one
a separate 2026 comparison frames as "Unsloth dominates single-GPU speed
and context length but has a documented weak point in multi-GPU
scenarios," while Axolotl offers "the deepest parallelism matrix" via
composable FSDP2/DeepSpeed/tensor/expert parallelism — the two tools are
optimized for genuinely different hardware shapes, not simply
faster-vs-slower.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Hugging Face `transformers`** (`huggingface/transformers`) — base layer | The model-architecture/tokenizer/training-loop library nearly every other tool here builds on | Apache-2.0 | The de facto standard interface to load, run, and fine-tune essentially any current open-weight model architecture. Direct GitHub fetch: 164,645 stars, 34,401 forks, 2,404 open issues, pushed 2026-08-31 (very active) |
| **`peft`** (`huggingface/peft`) | Parameter-efficient fine-tuning methods (LoRA, QLoRA, prefix-tuning, and others), `transformers`-compatible | Apache-2.0 | The reference implementation of LoRA/QLoRA that the more specialized frameworks below either wrap or reimplement for speed. Direct GitHub fetch: 21,610 stars, 2,462 forks, 84 open issues, pushed 2026-08-28 (active); latest release `v0.20.0` |
| **`trl`** (`huggingface/trl`) | Post-training objectives beyond plain SFT: DPO, PPO/GRPO, reward modeling, RLHF | Apache-2.0 | The institutional pick for advanced training objectives — the tool to reach for once fine-tuning needs to go beyond next-token supervised fine-tuning. Direct GitHub fetch: 19,182 stars, 2,944 forks, 300 open issues, pushed 2026-08-31 (very active); latest release `v1.12.0` |
| **Unsloth** (`unslothai/unsloth`) | Speed/VRAM-optimized LoRA/QLoRA kernels, single-GPU/consumer-hardware focus | Apache-2.0 | The fastest single-GPU option per the directly re-verified 3.2-vs-5.8-hour benchmark above; also usable as LLaMA-Factory's own backend for a speed boost at only ~6% training-time overhead vs. running it natively. Direct GitHub fetch: 75,296 stars, 6,830 forks, 1,418 open issues, pushed 2026-08-31 (very active) — highest star count of any fine-tuning-specific tool here |
| **Axolotl** (`axolotl-ai-cloud/axolotl`) | YAML-config-driven fine-tuning pipelines, broad multi-GPU/parallelism coverage | Apache-2.0 | The right choice for declarative, reproducible YAML training configs and genuine multi-GPU/FSDP2/DeepSpeed parallelism depth that Unsloth's single-GPU focus doesn't cover. Direct GitHub fetch: 12,428 stars, 1,418 forks, pushed 2026-08-31 (very active) |
| **LLaMA-Factory** (`hiyouga/LLaMA-Factory`) | Broadest model-architecture coverage plus a web UI for no-code fine-tuning | Apache-2.0 | The right choice when breadth-of-supported-models and a web UI matter more than lowest-level performance tuning; can use Unsloth as its own backend for near-native speed. Direct GitHub fetch: 74,455 stars, 9,120 forks, pushed 2026-08-31 (very active) |
| **torchtune** (`pytorch/torchtune`) | PyTorch-native, first-party fine-tuning recipes, no third-party framework dependency | BSD-3-Clause | The right choice for staying strictly inside the plain PyTorch/Meta-maintained ecosystem, at the cost of the broader model/technique coverage above. Direct GitHub fetch: 5,801 stars, pushed 2026-08-30 (active) — meaningfully smaller footprint than the tools above, named for completeness |

**Decision rule**: `peft`/`trl` underneath any project regardless of
higher-level framework choice; single-GPU or consumer-hardware speed
priority → **Unsloth**; multi-GPU parallelism or declarative YAML pipelines
→ **Axolotl**; broadest model coverage plus a web UI for less code-first
teams → **LLaMA-Factory**; staying strictly inside the PyTorch/Meta stack
→ **torchtune**.

## Data versioning for ML

**Governance transition, confirmed by direct fetch this authoring pass —
the single biggest correction to the research baseline in this doc**: the
baseline flagged DVC's steward (Iterative) as "small but not in visible
crisis" and noted a ~5-month gap between its last tagged release
(`3.67.1`, 2026-03-31) and this pass's snapshot date, without a clear
explanation. A direct fetch this pass resolves it: `dvc.org`'s own blog
confirms that on **2025-11-18, lakeFS's parent company, Treeverse,
acquired the DVC open-source project from Iterative**, with DVC's founder
Dmitry Petrov writing "I couldn't imagine a better home... for it than
lakeFS" and framing Iterative's own pivot toward DataChain (its newer
multimodal-AI-data product) as the reason for handing DVC off rather than
continuing to steward it directly. This is independently confirmed at the
infrastructure level, not just in a press release: `gh api
repos/iterative/dvc` now resolves to **`treeverse/dvc`**, and
`https://github.com/iterative/dvc` returns an HTTP 301 redirect straight
to `https://github.com/treeverse/dvc` — the repo itself has been
transferred, not merely announced as transferring. Iterative's own GitHub
org bio now reads "Data Tools for AI and ML" with its blog link pointing
to `datachain.ai`, confirming the pivot is real and complete, not
in-progress. The practical upshot: DVC and lakeFS are no longer usefully
framed as two independent competing projects — the same company now
stewards both, and DVC's own announcement explicitly frames them as **a
continuum across the versioning-granularity spectrum** (git-native
per-file tracking via DVC, whole-data-lake versioning via lakeFS), which
plausibly explains the release-cadence gap as stewardship-handoff
friction rather than any sign of DVC stalling.

| Library | For | License | Why recommended |
|---|---|---|---|
| **DVC** (`treeverse/dvc`, formerly `iterative/dvc` — see governance callout above) — default | Git-native versioning of datasets/model files too large for git itself, plus pipeline/experiment reproducibility (`dvc.yaml` stages) | Apache-2.0 (confirmed via direct `LICENSE` fetch) | Still the dominant, most git-workflow-integrated choice for a team already using git as its source of truth; now under the same corporate umbrella as lakeFS following the 2025-11-18 acquisition, which if anything de-risks its long-term roadmap versus the small-standalone-company framing the pre-acquisition baseline assumed. Direct GitHub fetch: 15,850 stars, 1,326 forks, 201 open issues, pushed 2026-08-31 (active); latest tagged release `3.67.1`, published 2026-03-31 — the ~5-month gap now has a plausible stewardship-transition explanation rather than an open question |
| **lakeFS** (`treeverse/lakeFS`) | Git-like branch/commit/merge semantics applied directly to object storage (S3/GCS/Azure Blob) at the whole-data-lake level | Apache-2.0 | The right pick when the unit of versioning is an entire data lake/bucket rather than individual files tracked alongside a git repo — a genuinely different architecture (a proxy/gateway in front of object storage), and, per the acquisition above, now the same company's own stated "next tier up" from DVC rather than a rival project. Direct GitHub fetch: 5,502 stars, 475 forks, pushed 2026-08-19 (active, ~12 days stale relative to this pass's own snapshot — not alarming, just noted) |

**Decision rule**: default to **DVC** for a team already using git as its
source of truth and versioning files/models alongside code; reach for
**lakeFS** when the unit of versioning is an entire bucket/data lake
rather than individual files — treat the two as complementary tiers of
one now-common stewardship rather than a fork-in-the-road choice between
competitors.

## ML-specific pipeline orchestration

Distinct from the general data-pipeline orchestrators (Airflow/Dagster/
Prefect) already named in Data & Analytics Platforms' own baseline — this
section covers orchestration purpose-built around the ML training loop
(GPU-scheduling-aware steps, experiment-versioned DAG runs), not a
restatement of those general-purpose tools.

**Kubeflow's CNCF graduation, freshly confirmed**: the CNCF publicly
announced **Kubeflow's graduation to Graduated maturity on 2026-08-17** —
14 days before this doc's own snapshot date — following Technical
Oversight Committee approval on 2026-07-24. Kubeflow entered CNCF
Incubating in July 2023, so this closes a real ~3-year maturity arc inside
this exact research window; graduation required a completed third-party
security audit and a formal steering committee.

**Metaflow's governance also changed hands mid-2026**: **Anaconda
acquired Outerbounds (Metaflow's commercial steward) in May 2026**.
Metaflow itself remains Apache-2.0 and Netflix continues to maintain a
dedicated internal team on it, but the commercial-platform layer around it
has changed ownership within the last few months — worth naming plainly
for a team evaluating Metaflow's long-term roadmap risk, the same shape of
disclosure this doc gives DVC's own stewardship transition above.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Kubeflow Pipelines** (`kubeflow/pipelines`) | Kubernetes-native ML pipeline orchestration — DAGs of containerized training/eval steps, GPU-aware scheduling | Apache-2.0 | **CNCF Graduated as of 2026-08-17** — now the vendor-neutral, foundation-governed default for a team already on Kubernetes wanting ML-specific pipeline orchestration. Direct GitHub fetch: 4,196 stars, 2,099 forks, 471 open issues, pushed 2026-08-31 (active); the broader `kubeflow/kubeflow` umbrella repo adds 15,841 stars, pushed 2026-08-21 |
| **Metaflow** (`Netflix/metaflow`) | Python-native, notebook-friendly ML pipeline framework with built-in versioning of code/data/models per run | Apache-2.0 | The right choice for a lighter-weight, Python-decorator-based authoring experience (vs. Kubeflow's Kubernetes-YAML-heavier model) with strong AWS-native scaling; the Outerbounds/Anaconda acquisition above is a real governance-risk data point, not disqualifying. Direct GitHub fetch: 10,251 stars, 1,342 forks, 490 open issues, pushed 2026-08-27 (active); latest release `2.19.38` |

**Decision rule**: already standardized on Kubernetes and want a
CNCF-graduated, vendor-neutral choice → **Kubeflow Pipelines**; want a
lighter-weight, Python-native authoring experience with less YAML/
Kubernetes ceremony, especially on AWS → **Metaflow**, with the
Outerbounds/Anaconda acquisition noted as a roadmap-risk factor to watch
rather than a blocker.

## Model evaluation / benchmarking tooling

**Scope boundary, stated explicitly to avoid conflating this with
Agentic & MCP Platforms' own eval-tooling section**: that baseline already
covers LLM-*application*/agent evaluation (DeepEval, Inspect AI,
Promptfoo, Langfuse, LangSmith, Arize Phoenix) — tools for testing whether
a deployed agent/prompt pipeline behaves correctly. This section covers
the model-*development*-stage concern instead: standardized benchmark
harnesses for a model's raw capabilities during/after training. The two
lists are genuinely distinct and neither should absorb the other's
entries.

| Library | For | License | Why recommended |
|---|---|---|---|
| **`lm-evaluation-harness`** (`EleutherAI/lm-evaluation-harness`) — default | Standardized few-shot/zero-shot benchmark evaluation across hundreds of academic tasks (MMLU, GSM8K, HellaSwag, and others) via one CLI | MIT | The library underlying Hugging Face's own Open LLM Leaderboard and the most widely cited standardized-benchmark tool for comparing model checkpoints during/after training. Direct GitHub fetch: 13,835 stars, 3,528 forks, 918 open issues, pushed 2026-08-29 (active); latest release `v0.4.12` |
| **HELM** (`stanford-crfm/helm`) | Holistic, multi-metric evaluation (accuracy, calibration, robustness, fairness, bias, toxicity, efficiency) across a broad scenario set | Apache-2.0 | The right choice when evaluation needs to go beyond raw accuracy into robustness/fairness/efficiency trade-offs — a research-grade, Stanford-CRFM-maintained standard with a smaller adoption footprint but genuinely distinct depth. Direct GitHub fetch: 2,893 stars, 410 forks, 100 open issues, pushed 2026-08-01 (~4 weeks stale relative to this pass, worth a light flag) |
| **MLPerf / MLCommons** (`mlcommons/inference`, sibling `mlcommons/training`) | Industry-standard hardware/system-level training and inference benchmarks (throughput/latency/efficiency at fixed accuracy targets, not model-quality benchmarks) | Apache-2.0 | The reference standard for "how fast/efficiently does this hardware+framework combination train/serve," a genuinely different question from "how accurate is this model" that gets confused with it often. Direct GitHub fetch (`mlcommons/inference`): 1,622 stars, pushed 2026-08-29 (active) |
| **torchmetrics** (`Lightning-AI/torchmetrics`) | Standard metric implementations (accuracy, F1, BLEU, FID, and hundreds more) wired directly into a PyTorch training/validation loop | Apache-2.0 | Not a benchmark suite like the three above — the complementary, lower-level tool for computing individual metrics correctly and efficiently (distributed-training-safe) inside a training loop itself. Direct GitHub fetch: 2,465 stars, pushed 2026-08-20 (active) |

## Hugging Face Hub tooling

**Scope boundary**: this covers the Hub as a model-*development*-stage
artifact store and discovery surface (uploading a trained checkpoint,
attaching a model card, versioning via git-based repo history) — not the
production model-registry concern (promotion gates, serving-stage
lineage, drift-triggered rollback) that belongs to the still-pending MLOps
category, per Where this doc stops below. **`huggingface_hub`**
(`huggingface/huggingface_hub`), Apache-2.0, is the current Python client
for this: `ModelCard`/`ModelCardData` classes (Jinja2-templated,
`push_to_hub()`-able, with `ModelCard.validate()` checking against the
Hub's own metadata-validation rules) plus general repo upload/download/
versioning against the Hub's git-backed storage. Direct GitHub fetch:
3,859 stars, 1,178 forks, 213 open issues, pushed 2026-08-29 (active);
latest release `v1.29.0`. Google's own **Model Card Toolkit**
(`tensorflow/model-card-toolkit`) is confirmed **archived** via direct
fetch (`archived: true`, last push 2023-07-26) — named only to flag its
deprecation for anyone encountering it in older tutorials; `huggingface_hub`'s
own tooling has effectively become the de facto model-card standard given
the Hub's dominance as a model-distribution point.

## Compute providers for training

Named at a "what exists" level since these are hosted services, not
licensable products — matching this repo's convention for managed-service
rows (e.g. CloudFormation, HCP Terraform in Infrastructure & Platform
Engineering).

**Major cloud managed-training services** remain a separate,
non-converging set as of this pass: **Amazon SageMaker AI** (renamed from
plain "Amazon SageMaker" in December 2024; "Amazon SageMaker" now refers
to a broader unified-studio platform, with SageMaker AI the specific
model-build/train/deploy service within it), **Google Cloud Vertex AI**,
and **Azure Machine Learning** — no evidence found of cross-platform
consolidation among the three.

**Specialized GPU cloud providers** show real, current market movement:
**CoreWeave** (NVIDIA's own first "Elite" cloud-services partner, ~45,000
GPUs across its data centers, NVIDIA itself among its investors — the
largest specialist "neocloud"), **Lambda Labs** (H100/A100 access, no
egress fees), **RunPod** (spot/interruptible pricing for experimentation —
directly re-confirmed this pass via its own pricing page: **$0.34/hr**
Community Cloud for RTX 4090, **$1.99/hr** for H100 PCIe, both figures
matching the baseline's estimate exactly), and **Modal** (serverless,
usage-billed compute rather than persistent instances). **Consolidation is
current and concrete**: two smaller providers — Paperspace/DigitalOcean
GPU and Jarvis Labs — quietly shut down or froze new signups in Q1 2026,
a real provider-continuity-risk signal for a team picking a specialized
GPU vendor over a major cloud's own offering.

**Commercial-tier trap, Google Colab's free tier — re-confirmed via a
direct fetch of Google's own FAQ this pass**, with more precise language
than the baseline's paraphrase: Colab's own FAQ states plainly that
**"Colab does not publish these limits, in part because they can vary
over time,"** that GPU access for free users is **"heavily restricted,"**
and that free-tier sessions run **"at most 12 hours, depending on
availability and... usage patterns."** The trap compounds on the *paid*
tier too — the same FAQ states verbatim: **"Paid users whose compute unit
balance is exhausted will revert to the free-of-charge tier policies and
restrictions until the balance is increased."** A paid plan does not
guarantee resource access the way a fixed-capacity reservation would —
directly the kind of "looks fine until you hit the real, undocumented
limit" trap this repo's convention calls out for HCP Terraform/Spacelift
elsewhere.

| Provider | For | License | Why recommended |
|---|---|---|---|
| Amazon SageMaker AI / Google Cloud Vertex AI / Azure Machine Learning | Fully managed training on a team's existing major cloud, no separate GPU-provider relationship to manage | N/A — managed cloud services | The zero-extra-vendor default for a team already committed to one major cloud; trades some cost/flexibility for integration with that cloud's existing IAM/storage/networking |
| **CoreWeave** | Large-scale GPU capacity from NVIDIA's own top-tier "Elite" cloud partner | N/A — commercial GPU cloud | The largest specialist option when major-cloud GPU quota/availability is the actual constraint; NVIDIA itself is among its investors |
| **RunPod** | Spot/interruptible GPU pricing for experimentation and short training runs | N/A — commercial GPU cloud | Directly re-confirmed pricing this pass: $0.34/hr RTX 4090, $1.99/hr H100 PCIe (Community Cloud) — the cheapest on-demand entry point named here, at the cost of interruption risk and the sector's own Q1-2026 consolidation history |
| **Modal** | Serverless, usage-billed training/inference compute, no persistent instance to manage | N/A — commercial compute platform | The right fit when workloads are bursty/intermittent rather than needing a persistent reserved GPU |
| Google Colab | Free/cheap interactive notebook GPU access for small experiments and learning | N/A — free tier + Pro/Pro+ paid tiers | **Not a training-infrastructure recommendation for any real project** — see the commercial-tier trap above; fine for prototyping, not for anything needing predictable resource access, even on a paid tier |

## Where this doc stops

Model-serving/inference infrastructure (vLLM, TensorRT-LLM, Triton
Inference Server, KServe) belongs to Agentic & MCP Platforms (already
shipped) or the still-pending MLOps category, not this model-*building*
doc. Model registries, feature stores, drift monitoring, canary rollouts,
and retraining triggers are explicitly the still-pending **MLOps / ML
Platform Engineering** category's concern — this doc names Hugging Face
Hub and MLflow's own model-registry *feature* only at the
model-development-artifact-storage level, not the production-promotion-
gate/serving-lineage concern MLOps will own; whoever researches that
category next should re-examine MLflow Registry's webhook/stage-transition
APIs and purpose-built production registries fresh from the serving angle
rather than inheriting this doc's framing. LLM-application/agent
evaluation tooling (DeepEval, Inspect AI, Promptfoo, Langfuse, LangSmith,
Arize Phoenix, Ragas) is already covered by Agentic & MCP Platforms' own
"Testing / eval tooling for agents" section, per the explicit scope
boundary in Model evaluation above. BI/analytics-consumer tooling (dbt,
Airflow/Dagster/Prefect as general-purpose orchestrators, warehouse/
lakehouse platforms, BI dashboards) is owned by Data & Analytics
Platforms, already shipped. Distributed-training infrastructure depth (Ray
Train, Horovod, DeepSpeed/FSDP internals) surfaced during research
(`ray-project/ray`: Apache-2.0, 43,662 stars, very active) but wasn't
independently deep-researched — a real gap worth a follow-up if
large-scale multi-node training becomes an explicit ask, distinct from the
single/few-GPU fine-tuning tooling this doc covers. Data
labeling/annotation tooling (Label Studio, Scale AI, CVAT) and
synthetic-data-generation tooling are genuinely adjacent but distinct
concerns, not researched here. Exact current dollar figures beyond the
named commercial-tier traps (W&B's Enterprise pricing, per-hour GPU rates
for providers other than RunPod) were search-corroborated rather than
independently direct-fetched against every vendor's own live pricing page.

## Sources

- Local `find`/`grep` passes (not web sources), 2026-08-31: confirmed
  absence of `.ipynb`, `train*.py`, MLflow/W&B/DVC config, and model-weight
  files under `/Users/devopammittra/GitHub/ubi-csr-tmf` and this repo;
  confirmed no torch/tensorflow/transformers/peft/mlflow/wandb/dvc/jax
  mention in any local dependency manifest.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`, `archived`) for: pytorch/pytorch,
  jax-ml/jax, tensorflow/tensorflow, mlflow/mlflow, wandb/wandb,
  aimhubio/aim, allegroai/clearml, huggingface/transformers,
  huggingface/peft, huggingface/trl, unslothai/unsloth,
  axolotl-ai-cloud/axolotl, hiyouga/LLaMA-Factory, pytorch/torchtune,
  iterative/dvc (resolves to treeverse/dvc), treeverse/dvc, treeverse/
  lakeFS, kubeflow/pipelines, kubeflow/kubeflow, Netflix/metaflow,
  huggingface/huggingface_hub, tensorflow/model-card-toolkit,
  EleutherAI/lm-evaluation-harness, stanford-crfm/helm, mlcommons/
  inference, Lightning-AI/torchmetrics, ray-project/ray — retrieved
  2026-08-31.
- **Re-verification during this authoring pass (2026-08-31)**: direct
  `gh api` re-fetch of pytorch/pytorch, mlflow/mlflow, unslothai/unsloth,
  kubeflow/pipelines, iterative/dvc, and EleutherAI/lm-evaluation-harness
  — all figures matched the baseline within normal single-day drift
  (MLflow's open-issue count moved from 2,057 to 2,056); confirms these
  are live, reproducible numbers, the same confirmation pattern used in
  the Infrastructure & Platform Engineering doc's own authoring pass.
- `https://raw.githubusercontent.com/pytorch/pytorch/main/LICENSE` and
  `https://raw.githubusercontent.com/iterative/dvc/main/LICENSE` — direct
  fetches confirming modified-BSD-3-style text (correcting GitHub
  metadata's `NOASSERTION` misreport) and Apache-2.0 respectively —
  retrieved 2026-08-31.
- `https://raw.githubusercontent.com/wandb/wandb/main/LICENSE` — direct
  fetch confirming MIT for the client SDK specifically — retrieved
  2026-08-31.
- **New this authoring pass**: direct fetch of `https://wandb.ai/site/pricing`
  — confirmed verbatim "corporate use is not allowed" on the free Personal
  tier and the Pro tier's $60/user/month, <50-employee framing — retrieved
  2026-08-31.
- **New this authoring pass**: `https://dvc.org/blog/a-shared-vision-for-the-future-of-dvc/`
  (published 2025-11-18) — direct fetch confirming Treeverse/lakeFS's
  acquisition of the DVC open-source project from Iterative, Dmitry
  Petrov's own statement on the handoff, and Iterative's pivot to
  DataChain; corroborated independently via `gh api repos/iterative/dvc`
  resolving to `treeverse/dvc`, a direct `curl -I` confirming the
  `github.com/iterative/dvc` → `github.com/treeverse/dvc` 301 redirect,
  and `gh api orgs/iterative` showing its blog link now points to
  `datachain.ai` — retrieved 2026-08-31.
- **New this authoring pass**: `https://theaiengineer.substack.com/p/unsloth-vs-axolotl-vs-llama-factory`
  — direct fetch pinning the Unsloth-vs-Axolotl QLoRA benchmark to its
  exact configuration (Llama-3.1-8B, rank 32, A100 40GB, 3.2 vs 5.8
  hours) and the Triton-kernel explanation for the gap — retrieved
  2026-08-31.
- **New this authoring pass**: `https://www.marktechpost.com/2026/07/22/unsloth-vs-axolotl-vs-trl-vs-llama-factory-a-fine-tuning-framework-comparison-on-speed-vram-and-multi-gpu/`
  — direct fetch confirming Unsloth's single-GPU-speed/multi-GPU-weakness
  positioning versus Axolotl's multi-GPU parallelism depth — retrieved
  2026-08-31.
- **New this authoring pass**: direct fetch of `https://www.runpod.io/pricing`
  — confirmed exact per-hour GPU rates ($0.34/hr RTX 4090, $1.99/hr H100
  PCIe, Community Cloud), matching the baseline's figures precisely —
  retrieved 2026-08-31.
- **New this authoring pass**: direct fetch of
  `https://research.google.com/colaboratory/faq.html` — confirmed verbatim
  language on undisclosed/dynamic free-tier limits, "heavily restricted"
  GPU access, and paid-tier compute-unit-depletion reverting to free-tier
  restrictions — retrieved 2026-08-31.
- `https://www.cncf.io` 2026-08-17 Kubeflow graduation announcement, and
  Anaconda/Outerbounds acquisition coverage — retrieved 2026-08-31 (both
  carried forward from the research baseline, not independently
  re-fetched this pass since neither date is time-sensitive to
  re-confirm).
- WebSearch corroboration (not independently direct-fetched primary
  source, flagged inline where used): PyTorch Foundation governance and
  membership growth; PyTorch/JAX/TensorFlow adoption-share figures;
  MLflow's Linux Foundation contributor/download counts; W&B's 3-concurrent-
  run free-tier cap (multiple pricing/review-aggregator sites agreeing
  on the same figure); DVC/Iterative headcount and funding history
  (Tracxn, Crunchbase); Amazon SageMaker AI's rename; GPU-cloud-provider
  Q1-2026 consolidation — all retrieved 2026-08-31.
- `research/stacks/ml-model-development/libraries.md` and
  `research/stacks/ml-model-development/stack.md` — read in full as this
  doc's approved research baseline; the DVC/lakeFS/Treeverse acquisition
  above was not present in either and is new to this authoring pass.
- `research/stacks/data-analytics-platforms/libraries.md` and
  `research/stacks/agentic-mcp-platforms/libraries.md` — read to confirm
  this doc's own out-of-scope boundaries (dbt/Airflow/warehouse tooling
  already owned by the former; DeepEval/Inspect AI/Promptfoo/Langfuse/
  LangSmith/Arize Phoenix agent-eval tooling already owned by the latter).
