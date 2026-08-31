# Baseline: ML / AI Model Development — Preferred Libraries
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This is category #2 from `research/taxonomy-roadmap.md` — the model-*building*
side of the ML lifecycle (training, fine-tuning, experiment tracking, model
evaluation), distinct from Data & Analytics Platforms (BI/reporting-facing,
already shipped) and from Agentic & MCP Platforms (serving/orchestration of
already-built models, already shipped). A parallel `stack.md` in this same
directory covers architecture/decision-criteria; this file names specific
tools/products with license and maintenance-signal detail only, matching this
repo's `libraries.md` convention.

Two genuinely fresh governance events landed inside this exact snapshot
window and are load-bearing findings, not background color: **Kubeflow
graduated to CNCF Graduated status on 2026-08-17** (14 days before this
pass) and **Anaconda acquired Outerbounds (Metaflow's commercial steward) in
May 2026** — both change what "the current recommendation" is for
ML-specific pipeline orchestration, not just trivia.

## Local precedent — none found, confirmed by search

Checked directly this pass, matching `backend-api-services/libraries.md`'s
own "none found" convention rather than forcing a weak analogy:

- `find /Users/devopammittra/GitHub/ubi-csr-tmf /Users/devopammittra/GitHub/agent-skills -iname "*.ipynb"` — **zero results**.
- `find ... -iname "train*.py"` — **zero results**.
- `find ... -iname "*.dvc" -o -iname "mlflow*" -o -iname "wandb*"` — **zero results**: no MLflow/W&B/DVC config anywhere on this machine.
- `find ... \( -iname "*.pt" -o -iname "*.ckpt" -o -iname "*.safetensors" -o -iname "*.onnx" -o -iname "*.h5" \)` — **zero results**: no model-weight files.
- `grep -riE "torch|tensorflow|transformers|peft|mlflow|wandb|dvc==|jax"` across `ubi-csr-tmf`'s dependency manifests (`*.txt`, `*.toml`, `*.cfg`, `package.json`) — **zero hits**.

`ubi-csr-tmf`'s `agents/` component is an LLM-agent *application* (consumes a
hosted model API), not a model-training codebase — it does not count as
precedent for this category, and is named here only to head off a false
analogy. Every entry below is externally sourced with a direct fetch of the
repo/package page where practical, not cross-checked against a local
production choice.

## Ecosystem choice

**Python, overwhelmingly** — every tool in this category ships a
Python-first (often Python-only) interface; no TypeScript/Node split exists
here the way it does for Backend & API Services. HCL/Rego-style DSLs (per
Infrastructure & Platform Engineering) also don't apply — the closest thing
to a second "language surface" is YAML-driven config (Axolotl's training
configs, Kubeflow Pipelines' compiled YAML) layered on top of Python, not a
competing ecosystem. Because of this, tables below use GitHub stars/forks/
`pushed_at`/latest-release-tag as the primary adoption signal (direct `gh
api repos/<owner>/<repo>` fetches), supplemented by PyPI/download signal and
CNCF/foundation-governance status where that's the more load-bearing fact
(as it is for MLflow, PyTorch, and Kubeflow specifically).

## In scope

### Deep learning frameworks — impact: high — depth: table + decision rule

**PyTorch's license, verified precisely rather than assumed**: GitHub's
repo-metadata API reports `license.spdx_id: NOASSERTION` for
`pytorch/pytorch` (the same detection artifact this repo's other baselines
have flagged repeatedly for Terraform/Conftest/Vault); a direct fetch of the
repo's own `LICENSE` file confirms it is a **modified BSD-3-Clause-style
license** (the original Facebook/Torch/Caffe2-era license text, not a
standard SPDX-tagged BSD-3-Clause), not proprietary and not source-available
in the BSL sense. Governance is now the more interesting fact than the
license text: PyTorch moved to the **PyTorch Foundation, hosted by the
Linux Foundation**, with a governing board drawn from AMD, AWS, Google
Cloud, Meta, Microsoft Azure, and Nvidia, plus a Technical Advisory Council
— nine new member organizations joined the Foundation since December 2025,
confirming this is an actively growing multi-vendor governance body, not a
one-time announcement gathering dust.

**Current relative adoption/momentum, verified live rather than assumed
from stale training-data intuition**: 2026 sources converge that PyTorch
now accounts for roughly **85% of deep-learning research papers** (up from
~80% at NeurIPS 2023) and powers the large majority of current open-weight
LLM releases (Llama, Mistral, Qwen, DeepSeek) and the PyTorch-native
inference stack (vLLM, TensorRT-LLM). TensorFlow retains a distinct,
real lane rather than fading to irrelevance: it remains the stronger choice
for **edge/mobile deployment (TFLite)** and is cited as still holding a
larger enterprise-production-market-share figure in some counts, with a
more mature end-to-end MLOps tooling story at large existing TensorFlow
shops. JAX's real, current differentiator is **TPU-native performance and
Google's own internal usage** — Google's Gemini models are trained on JAX,
not TensorFlow — making JAX the right choice specifically for a team on
Google Cloud TPUs or doing research requiring JAX's functional
transform/compile model, not a general-purpose PyTorch alternative for most
teams. Frameworks are also visibly converging: `torch.compile()` brings
graph-compilation benefits PyTorch previously lacked, and Keras 3 now runs
on PyTorch/TensorFlow/JAX backends interchangeably.

| Framework | License | Governance | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **PyTorch** (`pytorch/pytorch`) — **default** | Modified BSD-3-style (own `LICENSE` file; GitHub metadata misreports `NOASSERTION`) | **PyTorch Foundation / Linux Foundation**, multi-vendor governing board (AMD/AWS/Google Cloud/Meta/Microsoft Azure/Nvidia) | The 2026 greenfield default for new deep-learning/generative-AI work: dominant research-paper share, the ecosystem essentially every current open-weight LLM and PEFT/fine-tuning tool in this doc targets first | 2026-08-31 | Direct GitHub fetch: 102,696 stars, 29,049 forks, 17,483 open issues, pushed 2026-08-31 (very active); latest release `v2.13.0` |
| **TensorFlow** (`tensorflow/tensorflow`) | Apache-2.0 | Google-led, no separate foundation | The right choice for edge/mobile deployment (TFLite) or an organization already standardized on TensorFlow's production-serving ecosystem; not the default for new research/greenfield generative-AI work given PyTorch's current research-share dominance | 2026-08-31 | Direct GitHub fetch: 198,080 stars, 76,210 forks, 3,003 open issues, pushed 2026-08-31 (active); highest raw star count of the three, reflecting age/history more than current momentum |
| **JAX** (`jax-ml/jax`, renamed from `google/jax`) | Apache-2.0 | Google-led, no separate foundation | The right choice specifically for TPU-targeted training or research needing JAX's functional/composable-transform model (`jit`/`grad`/`vmap`) — Google's own Gemini models train on JAX; not a general PyTorch replacement for most teams | 2026-08-31 | Direct GitHub fetch: 36,229 stars, 3,751 forks, 2,493 open issues, pushed 2026-08-31 (active); latest release `jax-v0.11.1` |

**Decision rule**: new generative-AI/LLM or general deep-learning project →
**PyTorch** by default; TPU-targeted training or JAX-specific research
methodology → **JAX**; edge/mobile deployment target or an existing large
TensorFlow-standardized production estate → **TensorFlow**. Do not default
to TensorFlow for a new research-shaped project on adoption grounds alone —
its higher star count reflects longer history, not current research
momentum.

### Experiment tracking — impact: high — depth: table + commercial-tier trap

**Commercial-tier trap, W&B's free tier — verified via direct fetch, not
assumed**: `wandb/wandb` (the client SDK) is genuinely **MIT-licensed**,
confirmed via direct fetch of its own `LICENSE` file. But the hosted SaaS
platform the SDK talks to by default is a **separate commercial product**,
and its free tier's own terms **explicitly bar corporate/commercial use** —
it is scoped to personal/academic projects only, capped at 3 concurrent
runs. A team building a real product on the free tier is out of compliance
by definition, not merely constrained by a usage quota; the first
commercially-usable tier (Pro) starts at **$60/user/month**, with
organizations over ~50 employees required to move to Enterprise pricing.
This is the same shape of trap this repo's other baselines call out for
HCP Terraform/Vault (BSL) and LangGraph — "free tier looks fine until you
read the terms," here on a *use-case* restriction rather than a resource
cap.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **MLflow** (`mlflow/mlflow`) — **default for self-hosted/open tracking** | Experiment tracking, model packaging, model registry (model-dev-stage), a UI for comparing runs | Apache-2.0 | **Linux Foundation top-level project** (joined June 2020) — the only fully open, vendor-neutral-governed option in this table; 13M+ monthly downloads and 415 active contributors in the last quarter per LFX Insights, confirming this isn't a dormant donated project | 2026-08-31 | Direct GitHub fetch: 27,741 stars, 6,234 forks, 2,057 open issues, pushed 2026-08-31 (very active); latest release `v3.15.2` |
| Weights & Biases (`wandb/wandb`, client SDK) | Experiment tracking + hosted dashboards with a strong UI/collaboration layer | Client SDK: **MIT**; hosted SaaS platform: **proprietary, commercial** — see trap callout above | The strongest UI/collaboration experience of the options here, but commit to it only with the license/free-tier trap above priced in — not a drop-in free replacement for MLflow for any real commercial project | 2026-08-31 | Direct GitHub fetch (SDK repo): 11,244 stars, 892 forks, 958 open issues, pushed 2026-08-31 (active) |
| **Aim** (`aimhubio/aim`) | Fully open-source experiment tracking with a comparable UI to W&B, self-hosted only | Apache-2.0 | The genuinely current open alternative to W&B for a team that wants a polished comparison/visualization UI with zero licensing ambiguity — no commercial-tier gate of any kind | 2026-08-31 | Direct GitHub fetch: 6,245 stars, 410 forks, 470 open issues, pushed 2026-08-30 (active) |
| ClearML (`allegroai/clearml`) | Broader MLOps suite bundling experiment tracking + orchestration + data/artifact management in one tool | Apache-2.0 | Named for completeness as the "one tool covers tracking + orchestration + data versioning" alternative to composing MLflow/DVC/Kubeflow separately — a real trade-off between convenience and being locked into one vendor's opinionated stack | 2026-08-31 | Direct GitHub fetch: 6,847 stars, 797 forks, pushed 2026-08-30 (active) |

**Decision rule**: default to **MLflow** for a self-hosted, license-clean
choice with genuine multi-vendor governance; reach for **W&B** only after
confirming the team's usage is commercially licensed (Pro/Enterprise, not
the free tier); **Aim** is the right pick for a team that wants W&B-like UI
polish without any commercial dependency at all; **ClearML** is worth
naming when a team explicitly wants one consolidated tool rather than
composing MLflow + a separate orchestrator + a separate data-versioning
tool.

### Fine-tuning / PEFT tooling — impact: high — depth: table

**This moved fast 2023-2025 and has now genuinely consolidated around a
small, current set of tools rather than staying fragmented, verified this
pass**: Hugging Face's `transformers`/`peft`/`trl` remain the institutional
base layer everything else builds on, while three purpose-built
fine-tuning frameworks — Unsloth, Axolotl, LLaMA-Factory — now cover the
practical LoRA/QLoRA workflow end-to-end, each with a distinct niche
(speed-on-consumer-hardware, YAML-driven-pipelines, and
broadest-model-coverage-plus-web-UI respectively) rather than being
redundant with each other. A 2026 comparison benchmark cited fine-tuning
Llama-3.1-8B via QLoRA taking 3.2 hours on Unsloth vs. 5.8 hours on Axolotl
on an identical configuration — a real, current performance gap, not a
stale claim.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Hugging Face `transformers`** (`huggingface/transformers`) — **base layer** | The model-architecture/tokenizer/training-loop library nearly every other tool in this table builds on top of | Apache-2.0 | The de facto standard interface to load, run, and fine-tune essentially any current open-weight model architecture | 2026-08-31 | Direct GitHub fetch: 164,645 stars, 34,401 forks, 2,404 open issues, pushed 2026-08-31 (very active) |
| **`peft`** (`huggingface/peft`) | Parameter-efficient fine-tuning methods (LoRA, QLoRA, prefix-tuning, and others) as a `transformers`-compatible library | Apache-2.0 | The reference implementation of LoRA/QLoRA that the more specialized frameworks below either wrap or reimplement for speed | 2026-08-31 | Direct GitHub fetch: 21,610 stars, 2,462 forks, 84 open issues, pushed 2026-08-28 (active); latest release `v0.20.0` |
| **`trl`** (`huggingface/trl`) | Post-training objectives beyond plain supervised fine-tuning: DPO, PPO/GRPO, reward modeling, RLHF | Apache-2.0 | The institutional pick for advanced training objectives (per 2026 comparison sources) — the tool to reach for once fine-tuning needs to go beyond next-token SFT | 2026-08-31 | Direct GitHub fetch: 19,182 stars, 2,944 forks, 300 open issues, pushed 2026-08-31 (very active); latest release `v1.12.0` |
| **Unsloth** (`unslothai/unsloth`) | Speed/VRAM-optimized LoRA/QLoRA fine-tuning kernels, single-GPU/consumer-hardware focus | Apache-2.0 | The current fastest option for consumer-hardware fine-tuning per multiple 2026 benchmarks; also usable as LLaMA-Factory's backend for a speed boost with only ~6% training-time overhead vs. running Unsloth natively | 2026-08-31 | Direct GitHub fetch: 75,296 stars, 6,830 forks, 1,418 open issues, pushed 2026-08-31 (very active); highest star count of any fine-tuning-specific tool in this table |
| **Axolotl** (`axolotl-ai-cloud/axolotl`) | YAML-config-driven fine-tuning pipelines, broad technique/architecture coverage | Apache-2.0 | The "quiet workhorse" pick per 2026 comparisons — the right choice for a team wanting declarative, reproducible YAML training configs rather than hand-written training scripts | 2026-08-31 | Direct GitHub fetch: 12,428 stars, 1,418 forks, pushed 2026-08-31 (very active) |
| **LLaMA-Factory** (`hiyouga/LLaMA-Factory`) | Broadest model-architecture coverage plus a web UI for no-code fine-tuning | Apache-2.0 | The right choice when breadth-of-supported-models and a web UI matter more than lowest-level performance tuning; can use Unsloth as its own backend for near-native speed | 2026-08-31 | Direct GitHub fetch: 74,455 stars, 9,120 forks, pushed 2026-08-31 (very active) |
| **torchtune** (`pytorch/torchtune`) | PyTorch-native, first-party fine-tuning recipes (no third-party framework dependency) | BSD-3-Clause | The right choice for a team that wants fine-tuning to stay inside the plain PyTorch/Meta-maintained ecosystem rather than adopting a third-party framework, at the cost of the broader model/technique coverage the tools above offer | 2026-08-31 | Direct GitHub fetch: 5,801 stars, pushed 2026-08-30 (active) — meaningfully smaller adoption footprint than the tools above, named for completeness not as the default |

**Decision rule**: base fine-tuning capability on any project → `peft`/`trl`
underneath regardless of which higher-level framework is chosen; single-GPU
or consumer-hardware speed priority → **Unsloth**; declarative YAML-driven
reproducible pipelines → **Axolotl**; broadest model coverage plus a web UI
for less code-first teams → **LLaMA-Factory**; staying strictly inside the
PyTorch/Meta-maintained stack → **torchtune**.

### Data versioning for ML — impact: med — depth: table + maintenance-cadence note

**DVC's company situation, checked honestly rather than assumed dramatic**:
this pass found DVC's steward company (Iterative, later branded as the
"DVC" org on Crunchbase/Tracxn) to be a small, Series-A-funded team (~10-11
employees as of the most recent 2026 counts found) — real, but genuinely
small, not a company in visible crisis. The more concrete, direct-fetch-
verified signal is a **release-cadence gap worth flagging plainly**: DVC's
GitHub repo shows commit activity as recently as this pass's snapshot date
(`pushed_at: 2026-08-31`), but its **last tagged release, `3.67.1`, shipped
2026-03-31** — roughly five months stale relative to this pass, a real gap
worth a light flag for a project this central to a team's data-versioning
choice, though not itself evidence of abandonment given the active commit
history.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **DVC** (`iterative/dvc`) — **default** | Git-native versioning of datasets/model files too large for git itself, plus pipeline/experiment reproducibility (`dvc.yaml` stages) | Apache-2.0 (confirmed via direct `LICENSE` fetch) | Still the dominant, most-integrated choice for a team already using git as its source of truth — genuinely `git`-workflow-shaped rather than a separate system to learn | 2026-08-31 | Direct GitHub fetch: 15,850 stars, 1,326 forks, 201 open issues, pushed 2026-08-31 (active); **latest release `3.67.1`, published 2026-03-31 — ~5 months stale, see callout above** |
| **lakeFS** (`treeverse/lakeFS`) | Git-like versioning (branch/commit/merge semantics) applied directly to object storage (S3/GCS/Azure Blob) at the data-lake level | Apache-2.0 | The right alternative when the unit of versioning is an entire data lake/bucket rather than individual files tracked alongside a git repo — a genuinely different architecture (a proxy/gateway in front of object storage) rather than a DVC competitor on DVC's own terms | 2026-08-31 | Direct GitHub fetch: 5,502 stars, pushed 2026-08-19 (active, though ~12 days stale relative to this pass's own snapshot date — not alarming, just noted) |

### ML-specific pipeline orchestration — impact: med — depth: table + fresh-governance-event callout

**Distinct from the general data-pipeline orchestrators (Airflow/Dagster/
Prefect) already named in Data & Analytics Platforms' own baseline** — this
section covers orchestration purpose-built around the ML training loop
(GPU-scheduling-aware steps, experiment-versioned DAG runs, notebook-first
authoring), not a redundant restatement of the general-purpose tools.

**Kubeflow's CNCF graduation, freshly confirmed this pass**: the CNCF
publicly announced **Kubeflow's graduation to Graduated maturity on
2026-08-17** — 14 days before this baseline's own snapshot date —
following Technical Oversight Committee approval on 2026-07-24. Kubeflow
was accepted to CNCF Incubating in July 2023, so this is a real ~3-year
maturity arc completing inside this exact research window, not a stale
fact carried from memory. Graduation required a completed third-party
security audit and a formal steering committee.

**Metaflow's governance changed hands mid-2026, also fresh**: **Anaconda
acquired Outerbounds (Metaflow's commercial steward) in May 2026**.
Metaflow itself remains Apache-2.0 and Netflix continues to maintain a
dedicated internal team on it per multiple 2026 sources, but the
commercial-platform layer around it has changed ownership within the last
few months — worth naming plainly for a team evaluating Metaflow's
long-term roadmap risk.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Kubeflow Pipelines** (`kubeflow/pipelines`) | Kubernetes-native ML pipeline orchestration — DAGs of containerized training/eval steps, GPU-aware scheduling | Apache-2.0 | **CNCF Graduated as of 2026-08-17** (see callout above) — now the vendor-neutral, foundation-governed default for a team already running Kubernetes and wanting ML-specific (not generic-data) pipeline orchestration | 2026-08-31 | Direct GitHub fetch (`kubeflow/pipelines`): 4,196 stars, 2,099 forks, 471 open issues, pushed 2026-08-31 (active); the broader `kubeflow/kubeflow` umbrella repo: 15,841 stars, pushed 2026-08-21 |
| **Metaflow** (`Netflix/metaflow`) | Python-native, notebook-friendly ML pipeline framework with built-in versioning of code/data/models per run | Apache-2.0 | The right choice for a team wanting a lighter-weight, Python-decorator-based authoring experience (vs. Kubeflow's Kubernetes-YAML-heavier model) and strong AWS-native scaling support; the commercial-steward acquisition above is a real governance-risk data point, not disqualifying | 2026-08-31 | Direct GitHub fetch: 10,251 stars, 1,342 forks, 490 open issues, pushed 2026-08-27 (active); latest release `2.19.38` |

**Decision rule**: already standardized on Kubernetes and want a
CNCF-graduated, vendor-neutral choice → **Kubeflow Pipelines**; want a
lighter-weight, Python-native authoring experience with less YAML/Kubernetes
ceremony, especially on AWS → **Metaflow**, with the Outerbounds/Anaconda
acquisition noted as a roadmap-risk factor to watch rather than a blocker.

### Model evaluation / benchmarking tooling — impact: high — depth: table + scope boundary

**Scope boundary stated explicitly, since this is easy to conflate with
Agentic & MCP Platforms' own eval-tooling section**: that baseline already
covers LLM-*application*/agent evaluation (DeepEval, Inspect AI, Promptfoo,
Langfuse, LangSmith, Arize Phoenix) — tools for testing whether a deployed
agent/prompt pipeline behaves correctly. This section covers the
model-*development*-stage concern instead: standardized benchmark
harnesses for evaluating a model's raw capabilities during/after training,
not an application built on top of one. The two categories are genuinely
distinct and neither list should absorb the other's entries.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **`lm-evaluation-harness`** (`EleutherAI/lm-evaluation-harness`) — **default** | Standardized few-shot/zero-shot benchmark evaluation across hundreds of academic tasks (MMLU, GSM8K, HellaSwag, and others) via one CLI | MIT | The library underlying Hugging Face's own Open LLM Leaderboard and the most widely cited standardized-benchmark tool for comparing model checkpoints during/after training | 2026-08-31 | Direct GitHub fetch: 13,835 stars, 3,528 forks, 918 open issues, pushed 2026-08-29 (active); latest release `v0.4.12` |
| **HELM** (`stanford-crfm/helm`) | Holistic, multi-metric evaluation (accuracy, calibration, robustness, fairness, bias, toxicity, efficiency) across a broad scenario set | Apache-2.0 | The right choice when evaluation needs to go beyond raw accuracy into robustness/fairness/efficiency trade-offs — a research-grade, Stanford-CRFM-maintained standard, smaller adoption footprint than lm-evaluation-harness but a genuinely distinct depth of coverage | 2026-08-31 | Direct GitHub fetch: 2,893 stars, 410 forks, 100 open issues, pushed 2026-08-01 (~4 weeks stale relative to this pass, worth a light flag) |
| **MLPerf / MLCommons** (`mlcommons/inference`, sibling `mlcommons/training`) | Industry-standard hardware/system-level training and inference benchmark suites (not model-quality benchmarks — throughput/latency/efficiency at fixed accuracy targets) | Apache-2.0 | The reference standard when the question is "how fast/efficiently does this hardware+framework combination train/serve," not "how accurate is this model" — the two are frequently confused and are genuinely different measurements | 2026-08-31 | Direct GitHub fetch (`mlcommons/inference`): 1,622 stars, pushed 2026-08-29 (active) |
| **torchmetrics** (`Lightning-AI/torchmetrics`) | A library of standard metric implementations (accuracy, F1, BLEU, FID, and hundreds more) wired directly into a PyTorch training/validation loop | Apache-2.0 | Not a benchmark suite like the three above — the complementary, lower-level tool for computing individual metrics correctly and efficiently (distributed-training-safe) inside a training loop itself | 2026-08-31 | Direct GitHub fetch: 2,465 stars, pushed 2026-08-20 (active) |

### Hugging Face Hub / model registries at the model-development stage — impact: med — depth: paragraph

**Scope boundary stated explicitly**: this section covers the Hub as a
model-*development*-stage artifact store and discovery surface (uploading a
trained checkpoint, attaching a model card, versioning via git-based repo
history) — not the production model-registry concern (promotion gates,
serving-stage lineage, drift-triggered rollback) that belongs to the
still-pending MLOps category. **`huggingface_hub`** (`huggingface/
huggingface_hub`), Apache-2.0, is the current Python client library for
this: it provides `ModelCard`/`ModelCardData` classes (Jinja2-templated,
`push_to_hub()`-able, with `ModelCard.validate()` checking against the
Hub's own metadata-validation rules) and general repo upload/download/
versioning against the Hub's git-backed storage. Direct GitHub fetch:
3,859 stars, 1,178 forks, 213 open issues, pushed 2026-08-29 (active);
latest release `v1.29.0`.

### Model cards / documentation tooling — impact: low — depth: paragraph

Google's own **Model Card Toolkit** (`tensorflow/model-card-toolkit`) is
confirmed **archived** via direct fetch (`archived: true`, last push
2023-07-26) — not a current recommendation, named only to flag its
deprecation for anyone who encounters it in older tutorials. The current,
actively-maintained path is Hugging Face's own tooling named above
(`huggingface_hub`'s `ModelCard` class plus the Hub's YAML-frontmatter model-
card format, both under active development as part of the Hub client
library itself), which has effectively become the de facto model-card
standard given the Hub's dominance as a model-distribution point.

### Compute providers for training — impact: high — depth: table + commercial-tier trap

Named at a "what exists" level since these are hosted services, not
licensable open-source products — matching this repo's own convention for
managed-service rows (e.g. CloudFormation, HCP Terraform in the
Infrastructure & Platform Engineering baseline).

**Major cloud managed-training services** — each remains a **separate,
non-converging** product as of this pass (checked directly, since these
occasionally consolidate/rebrand): **Amazon SageMaker AI** (renamed from
plain "Amazon SageMaker" in December 2024; "Amazon SageMaker" now refers to
a broader unified-studio platform, with SageMaker AI as the specific
model-build/train/deploy service within it), **Google Cloud Vertex AI**,
and **Azure Machine Learning** — no evidence found this pass of an
Azure-AI-Foundry-style rename or cross-platform consolidation among the
three.

**Specialized GPU cloud providers** — real, current market movement worth
naming rather than treating as a static list: **CoreWeave** (NVIDIA's own
first "Elite" cloud-services partner, ~45,000 GPUs across its data
centers, NVIDIA itself among its investors — the largest specialist
"neocloud"), **Lambda Labs** (H100/A100 access, no egress fees, positioned
on reliability/developer-experience), **RunPod** (spot/interruptible
pricing aimed at experimentation, cited around $0.34/hr for RTX 4090 /
$1.99/hr for H100 in mid-2026 comparisons), and **Modal** (serverless,
usage-billed compute rather than persistent instances). **Market
consolidation, current and concrete**: two smaller providers — Paperspace/
DigitalOcean GPU and Jarvis Labs — quietly shut down or froze new signups
in Q1 2026, a real signal that this specific market segment carries
provider-continuity risk worth flagging to a team picking a specialized GPU
vendor over a major cloud's own offering.

**Commercial-tier trap, Google Colab's free tier — verified via direct
fetch of Google's own FAQ, not assumed**: Colab's free tier is explicitly
**dynamic and undisclosed by design** — Google's own FAQ states resource
limits "fluctuate" and that GPU access "varies over time," with premium
hardware "heavily restricted" for non-paying users; account-level usage
heuristics (long sessions, high RAM use, frequent reconnects) reduce
priority in ways Google doesn't document. The trap compounds on the *paid*
tier too: once a paying user's purchased compute-unit balance is exhausted,
they revert to the same free-tier restrictions until they buy more units —
a paid plan does not guarantee resource access the way a fixed-capacity
reservation would. This is directly the kind of "looks fine until you hit
the real, undocumented limit" trap this repo's convention calls out
explicitly for HCP Terraform/Spacelift elsewhere.

## Explicitly out of scope

- **Model-serving/inference infrastructure** (vLLM, TensorRT-LLM, Triton
  Inference Server, KServe) — belongs to Agentic & MCP Platforms (already
  shipped, serving/orchestration-focused) or the still-pending MLOps
  category, not this model-*building* baseline.
- **Model registries, feature stores, drift monitoring, canary rollouts for
  models, retraining triggers** — explicitly the still-pending **MLOps /
  ML Platform Engineering** category's concern (roadmap item #3). This
  baseline names Hugging Face Hub and MLflow's own model-registry *feature*
  only at the model-development-artifact-storage level (uploading/
  versioning a freshly trained checkpoint), not the production-promotion-
  gate/serving-lineage concern MLOps will own. **Clean handoff point for
  that research pass**: MLflow's Model Registry component and any
  dedicated registry tooling (e.g., a deeper look at MLflow Registry
  webhooks/stage-transition APIs, or purpose-built registries like Comet's
  model registry) should be evaluated fresh from the serving/production
  angle, not inherited wholesale from this doc's model-dev-stage framing.
- **LLM-application/agent evaluation tooling** (DeepEval, Inspect AI,
  Promptfoo, Langfuse, LangSmith, Arize Phoenix, Ragas) — already covered
  by Agentic & MCP Platforms' own "Testing / eval tooling for agents"
  section; this baseline's Model Evaluation section covers raw-model
  benchmark harnesses instead (see the explicit scope-boundary callout in
  that section above) and should not duplicate that list.
- **BI/analytics-consumer tooling** (dbt, Airflow/Dagster/Prefect as
  general-purpose data orchestrators, warehouse/lakehouse platforms, BI
  dashboard tools) — owned by Data & Analytics Platforms, already shipped;
  this baseline's own ML-specific-orchestration section names Kubeflow
  Pipelines/Metaflow as the *distinct* ML-training-loop-aware orchestrators,
  not a restatement of Airflow/Dagster/Prefect.
- **Distributed-training infrastructure depth** (Ray Train, Horovod,
  DeepSpeed, FSDP internals) — surfaced during research (`ray-project/ray`:
  Apache-2.0, 43,662 stars, very active) but not independently
  deep-researched this pass; a real gap worth a follow-up if large-scale
  multi-node training infrastructure becomes an explicit ask, distinct from
  the single/few-GPU fine-tuning tooling this pass covers.
- **Data labeling/annotation tooling** (Label Studio, Scale AI, CVAT) — a
  genuinely adjacent but distinct pre-training-data-preparation concern, not
  researched this pass.
- **Synthetic-data-generation tooling** — an emerging, fast-moving adjacent
  area not researched this pass; worth a dedicated look if it becomes a
  recurring project need.
- **Cost/pricing depth beyond the named commercial-tier traps** (W&B's
  exact Enterprise pricing, exact per-hour GPU-cloud rates beyond the
  illustrative figures cited above) — license/terms-of-use status is the
  durable signal per this repo's established convention; exact current
  dollar figures were search-corroborated, not independently verified
  against each vendor's own live pricing page this pass.

## Sources

- Local `find`/`grep` passes (not web sources), 2026-08-31: confirmed
  absence of `.ipynb`, `train*.py`, MLflow/W&B/DVC config, and model-weight
  files under `/Users/devopammittra/GitHub/ubi-csr-tmf` and
  `/Users/devopammittra/GitHub/agent-skills`; confirmed no torch/tensorflow/
  transformers/peft/mlflow/wandb/dvc/jax mention in any local dependency
  manifest.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`, `archived`) for: pytorch/pytorch,
  jax-ml/jax, tensorflow/tensorflow, mlflow/mlflow, wandb/wandb,
  aimhubio/aim, allegroai/clearml, huggingface/transformers,
  huggingface/peft, huggingface/trl, unslothai/unsloth,
  axolotl-ai-cloud/axolotl, hiyouga/LLaMA-Factory, pytorch/torchtune,
  iterative/dvc, treeverse/lakeFS, kubeflow/pipelines, kubeflow/kubeflow,
  Netflix/metaflow, huggingface/huggingface_hub, tensorflow/model-card-
  toolkit, EleutherAI/lm-evaluation-harness, stanford-crfm/helm,
  mlcommons/inference, Lightning-AI/torchmetrics, ray-project/ray,
  determined-ai/determined — retrieved 2026-08-31
- `gh api repos/<owner>/<repo>/releases/latest` (or `/releases` for DVC's
  history) direct fetches for current version tags: pytorch, jax, mlflow,
  peft, trl, unsloth, dvc (last 3 releases), kubeflow/pipelines, metaflow,
  huggingface_hub, lm-evaluation-harness — retrieved 2026-08-31
- `https://raw.githubusercontent.com/pytorch/pytorch/main/LICENSE` — direct
  fetch confirming modified-BSD-3-style license text (correcting GitHub
  metadata's `NOASSERTION` misreport) — retrieved 2026-08-31
- `https://raw.githubusercontent.com/iterative/dvc/main/LICENSE` — direct
  fetch confirming Apache-2.0 — retrieved 2026-08-31
- `https://raw.githubusercontent.com/wandb/wandb/main/LICENSE` — direct
  fetch confirming MIT for the client SDK specifically — retrieved
  2026-08-31
- WebSearch corroboration (not independently direct-fetched primary source
  this pass, flagged inline where used): PyTorch Foundation governance and
  membership growth (linuxfoundation.org, ai.meta.com, pytorch.org/
  foundation); PyTorch/JAX/TensorFlow current adoption-share figures
  (tech-insider.org, secondtalent.com, agntdev.com, python.plainenglish.io);
  MLflow's Linux Foundation status, download/contributor counts
  (linuxfoundation.org, insights.linuxfoundation.org/project/MLF,
  techmonitor.ai); W&B free-tier corporate-use restriction and Pro/
  Enterprise pricing (wandb.ai/site/pricing, zenml.io, xpay.sh); DVC/
  Iterative company headcount (crunchbase.com, tracxn.com); Unsloth/
  Axolotl/LLaMA-Factory/TRL comparative benchmarks and positioning
  (theaiengineer.substack.com, marktechpost.com, dev.to/ultraduneai);
  Kubeflow's CNCF graduation timeline and requirements (cncf.io's own
  2026-08-17 announcement, hpcwire.com, cloudnativenow.com); Metaflow/
  Outerbounds/Anaconda acquisition (opensourceforu.com, community.
  outerbounds.com); GPU-cloud-provider positioning and Q1-2026 market
  consolidation (runpod.io, gpu.fm, dev.to/ultraduneai); Amazon SageMaker
  AI's December-2024 rename and current three-way cloud-ML-platform
  landscape (docs.aws.amazon.com, techtarget.com, truefoundry.com); Colab
  free-tier dynamic-limits behavior (research.google.com/colaboratory/faq.
  html, hivenet.com, thundercompute.com); Hugging Face model-card tooling
  current state (huggingface.co/docs/huggingface_hub, github.com/
  huggingface/huggingface_hub) — all retrieved 2026-08-31
- `research/stacks/data-analytics-platforms/libraries.md` and
  `research/stacks/agentic-mcp-platforms/libraries.md` — read directly to
  confirm this baseline's own out-of-scope boundaries (dbt/Airflow/
  warehouse tooling already owned by the former; DeepEval/Inspect AI/
  Promptfoo/Langfuse/LangSmith/Arize Phoenix agent-eval tooling already
  owned by the latter) — read 2026-08-31

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
for this category, resolved directly rather than left open:

- **Distributed-training infrastructure stays deferred**, matching
  `stack.md`'s own resolution — single/few-GPU fine-tuning tooling is
  sufficient coverage for this doc's first version; most projects
  incubated via this skill won't need multi-node distributed training on
  day one, and the gap is named honestly in Explicitly-out-of-scope rather
  than silently omitted.
- **DVC stays the named default**; lakeFS stays "the alternative for a
  different architecture shape," not elevated to co-equal — the
  release-cadence gap is a light watch-item precisely because commit
  activity is healthy, not evidence the tool is actually stalling, and
  lakeFS solves a genuinely different problem (whole-data-lake versioning
  via a storage-layer proxy) rather than competing with DVC on DVC's own
  git-native-file-tracking terms.
- **ClearML stays a single named row**, not expanded into its own
  decision-rule table — it's a real but secondary option in this category
  (a bundled-suite alternative to composing best-of-breed tools), and
  giving it decision-rule-table treatment would overstate its centrality
  relative to MLflow/Kubeflow/Metaflow/DVC's own combined coverage.
- **MLflow Registry's handoff to MLOps stays exactly as scoped**: named
  here only as a model-dev-stage artifact-versioning feature, with the
  explicit instruction already in place for whoever researches MLOps next
  to re-examine it fresh from the production-promotion-gate angle rather
  than inheriting this doc's framing wholesale.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/ml-model-development.md
  — est. 380–460 lines (9 category sections — deep learning frameworks with
  decision rule, experiment tracking with the W&B commercial-tier trap,
  fine-tuning/PEFT tooling, data versioning with the DVC release-cadence
  note, ML-specific pipeline orchestration with the fresh Kubeflow-CNCF-
  graduation and Metaflow/Anaconda-acquisition callouts, model evaluation/
  benchmarking with an explicit scope boundary against agent-eval tooling,
  Hugging Face Hub/model-card tooling, and compute providers with the
  Colab free-tier commercial-tier trap — plus the Local-precedent section's
  honest "none found" finding carried forward, matching the Backend & API
  Services baseline's structure and rough length).
