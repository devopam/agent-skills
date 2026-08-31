# Baseline: ML / AI Model Development — Architecture & Stack
Status: draft      Date: 2026-08-31

## Local precedent — none found, confirmed this pass

Checked directly this pass, per this repo's convention of confirming rather
than assuming absence: `find` across `/Users/devopammittra/GitHub/ubi-csr-tmf`
and `/Users/devopammittra/GitHub/agent-skills` for `*.ipynb`, `train*.py`,
MLflow/W&B/DVC config files (`mlflow*`, `wandb`, `dvc.yaml`), and model-weight
artifacts (`*.pt`, `*.onnx`, `*.safetensors`) — **zero matches** on this
machine. This is a genuinely clean absence, not a weak analogy forced onto an
adjacent repo.

**`ubi-csr-tmf`'s `aws/container/agents/` component was specifically checked
and confirmed to be out-of-category, not a weak local example**: it contains
`main.py` (a FastAPI-shaped service, per its `Dockerfile`), `strands_agents/`
(AWS's Strands Agents SDK — an LLM-agent orchestration framework), `sql_tools/`,
`table_reader/`, `routers/`, `schemas/`, and `performance_metrics.py`. This is
an **LLM-agent application that calls pretrained models at inference time** —
Agentic & MCP Platforms territory, already shipped as this repo's own
`ml-model-development` sibling category — not a model-training or
fine-tuning codebase. No training loop, no dataset loader, no checkpoint
directory, no experiment-tracking import anywhere in that tree. There is also
no top-level `agents/` directory in that repo (only `charts/agents/`, a Helm
chart, and `AGENTS.md`, a Claude Code convention file, both unrelated to model
training) — worth naming precisely rather than leaving the "agents" naming
coincidence unexamined.

Consistent with the `backend-api-services.md` baseline's own convention for
this situation: every recommendation below is backed by external primary
sources with direct fetches where possible, not a local worked example.

## In scope

- **How this category specializes the cross-cutting
  `architecture-templates.md` pattern catalog, and the ML-specific
  pipeline/DAG shape underneath it** — impact: high — depth: section. An ML
  training project's default architectural concern is not request/response
  (Backend & API Services) or module-boundary API stability (Developer
  Tooling & Libraries) — it's a **linear-with-branches pipeline**: data
  acquisition → validation → feature/preprocessing → train → evaluate →
  (conditionally) register/export, each stage consuming the prior stage's
  output artifact rather than a live call. This is the same DAG-shaped
  orchestration concern the Data & Analytics Platforms baseline names for
  data pipelines, but with training-specific stages layered on top that a
  generic ETL DAG doesn't have: **checkpointing** (a training run must be
  resumable from a saved mid-run state after a preemption/crash, not just
  re-run from stage zero — this is what distinguishes a training DAG node
  from an ordinary idempotent ETL transform step) and **distributed-training
  coordination** (multi-GPU/multi-node data- or model-parallel training needs
  its own process-group/rendezvous mechanics that a plain task-orchestrator
  scheduler doesn't provide out of the box). Two real, currently-distinct
  orchestrator shapes exist for this (confirmed by direct fetch/search this
  pass): **Kubeflow Pipelines**, a Kubernetes-native DAG runtime where each
  pipeline step is a containerized component (search-corroborated: "Kubeflow
  Pipelines 2.x is healthy as a standalone DAG runtime, while the monolithic
  'all of Kubeflow' install has lost ground to assembled stacks" — a 2026
  framing worth carrying forward, not independently re-verified against a
  Kubeflow-project-authored source this pass); and **Metaflow**, which
  represents a training pipeline as plain Python functions annotated with
  step/resource decorators rather than containers-as-a-first-class-unit
  (search-corroborated: "Metaflow is the simplest operationally... less
  flexibility in DAG topology and fewer built-in integrations compared to
  Kubeflow" as the named trade-off). Both are named here as the *concept
  anchor* for "a DAG orchestrator with ML-training-specific stages," not a
  recommendation between the two specific tools — that comparison belongs to
  the companion `libraries.md`. **Hexagonal/ports-and-adapters still applies
  at the pipeline's data-ingestion boundary** (a dataset loader is an inbound
  adapter, a model-registry/experiment-tracker write is an outbound adapter,
  the training loop in between shouldn't need to know which storage backend
  produced the data or which tracker records the result) — the same
  reasoning the Data & Analytics Platforms and Backend & API Services
  baselines already used for their own inbound/outbound boundaries, here
  applied to a training pipeline's I/O boundary instead of a service's or a
  data platform's. **Microservices/serverless are a poor fit for the training
  loop itself** (a long-running, often multi-GPU, stateful compute job is the
  opposite of what serverless's stateless-short-invocation model is built
  for) but a normal fit for a *downstream* component that isn't training
  itself — an evaluation-report API, a lightweight retraining-trigger
  function reacting to a new-data-arrived event. **CQRS/event sourcing don't
  meaningfully apply here** — this category's closest analogue to the Data &
  Analytics Platforms baseline's "a warehouse is CQRS by construction" framing
  would be "an experiment-tracking store is a read-optimized log of write
  events (runs)," but this pass did not find that framing stated anywhere in
  current sources, so it's named here only as a plausible-but-unverified
  parallel, not asserted as fact.

- **Experiment tracking — what it concretely solves and the current
  landscape** — impact: high — depth: section. The architectural problem:
  answering **"which exact hyperparameters, code version, and data produced
  this specific metric?"** after the fact, for potentially hundreds of runs
  — without this, a team accumulates untraceable metric numbers with no path
  back to what produced them. Confirmed by direct fetch of MLflow's own
  tracking docs (`mlflow.org/docs/latest/ml/tracking/`): the concrete
  metadata an experiment-tracking system captures per **run** (a single
  execution of training code, grouped under an **experiment**, a named
  collection of related runs) is parameters, metrics, start/end times, a run
  ID, artifacts (model weights, plots, other output files — persisted
  separately from the lighter metadata, typically to object storage), and
  — a distinct, newer capability — **dataset references** associated with
  the run, so "which data version trained this" is itself a trackable field
  rather than something inferred separately. Architecturally, this is a
  **separation of a lightweight metadata store (backend store — parameters/
  metrics/run-identity, typically a relational DB) from a heavyweight
  artifact store (object storage — model weights, large files)** — the same
  metadata-vs-blob split the Infrastructure & Platform Engineering baseline
  named for Terraform/Pulumi state vs. artifact storage, here applied to
  training-run records instead of infrastructure state. **Current landscape,
  verified this pass rather than assumed stale**: **MLflow** is open-source
  (backed by Databricks), self-hosted/self-operated — "teams downloading,
  deploying, and operating MLflow infrastructure independently," and has
  expanded well beyond experiment tracking into LLM observability, prompt
  optimization, and model-deployment tooling (search-corroborated, current as
  of this pass) — the trade-off named across multiple sources is more setup/
  maintenance burden and a comparatively basic UI/minimal built-in
  collaboration. **Weights & Biases** is a managed SaaS platform — W&B
  "handling infrastructure, scaling, and availability transparently" — with
  polished visualization, built-in team collaboration (comments on runs),
  and hyperparameter-sweep orchestration, at the cost of vendor dependency
  and (for a data-sensitive team) data leaving self-managed infrastructure.
  Both solve the identical core problem (record, compare, reproduce); the
  architectural choice is infrastructure-control-and-vendor-neutrality
  (MLflow) vs. managed-convenience-and-collaboration (W&B) — specific
  licensing/pricing/newer-entrant comparison belongs to the companion
  `libraries.md`, not here.

- **Fine-tuning vs. training from scratch vs. parameter-efficient
  fine-tuning (PEFT/LoRA-style) — a genuine, current decision axis** —
  impact: high — depth: section, anchored on the original LoRA paper
  (confirmed by direct fetch of `arxiv.org/abs/2106.09685`) and Hugging
  Face's own PEFT library (confirmed by direct fetch of
  `github.com/huggingface/peft`, Apache-2.0) as the primary sources, not
  secondary comparison content. **Training from scratch (full pretraining)**
  is rare and expensive by construction — it means learning all model
  weights from random initialization over a large corpus, and reported cost
  figures across multiple secondary industry sources this pass (not
  independently verified against any lab's own disclosed training budget,
  and consistent with this repo's own no-cost-modeling convention, so named
  only as an order-of-magnitude directional signal, not a specific number to
  carry into the authored doc as fact) range from tens of thousands of
  dollars for a small model up to nine figures for a frontier model —
  justified only when no existing pretrained model is a viable adaptation
  starting point for the task, which is the uncommon case for most projects
  incubated via this skill. **Full fine-tuning** updates all of a pretrained
  model's weights against a smaller, task-specific dataset — meaningfully
  cheaper than pretraining (starting from already-learned representations
  rather than random initialization) but still requires holding a full
  optimizer state and gradient for every parameter, which is the direct
  driver of PEFT's existence. **PEFT (parameter-efficient fine-tuning)** —
  confirmed by direct fetch of the HF PEFT README — freezes the pretrained
  model's original weights and trains only a small number of additional
  parameters; **LoRA** specifically (confirmed by direct fetch of the
  original paper's own abstract) "freezes the pre-trained model weights and
  injects trainable rank decomposition matrices into each layer of the
  Transformer architecture," reporting (against GPT-3 175B in the original
  paper) up to a **10,000× reduction in trainable parameters** and **3×
  lower GPU memory requirement** versus full fine-tuning, with quality
  "on-par or better... on RoBERTa, DeBERTa, GPT-2, and GPT-3" and — a
  specific, load-bearing mechanical detail — **no added inference latency**,
  unlike earlier adapter-layer approaches that insert extra layers into the
  forward pass. The HF PEFT README's own current worked example makes the
  proportion concrete for a smaller, more typical project model: fine-tuning
  Qwen2.5-3B with LoRA trains **0.12% of the model's parameters**
  (3,686,400 of 3,089,625,088), and a comparison table in the same README
  shows full fine-tuning of a 3B model needing 47.14GB GPU memory versus
  14.4GB with PEFT-LoRA. **QLoRA** (LoRA applied on top of a quantized base
  model, further reducing memory) and other PEFT method families (prefix
  tuning, prompt tuning, IA3, adapters) are named in the PEFT README as
  supported method categories, with the mechanical comparison between them
  belonging to the companion `libraries.md`'s adoption/tooling table rather
  than repeated here. **Decision rule for a new project**: default to PEFT
  (LoRA/QLoRA) whenever an existing pretrained model already covers most of
  the target domain/task and compute budget is a real constraint (the
  common case) — full fine-tuning is justified when the task requires
  substantially different behavior than any available pretrained model
  exhibits and the compute budget genuinely allows it; training from scratch
  is justified only when no existing pretrained model is a defensible
  starting point at all (a genuinely new modality/domain with no public
  pretrained analogue, or a deliberate research question about pretraining
  itself). One specific numeric claim this pass found repeated across
  several secondary/course-style sources — "LoRA recovers 90-95% of full
  fine-tuning quality, QLoRA 80-90%" — is **excluded from this baseline**
  per this repo's no-unverified-numbers standard: it traces only to
  aggregator/course content (apxml.com), not the original paper or an
  HF-authored source, and the original LoRA paper's own "on-par or better"
  framing is a different, weaker, and better-sourced claim than a specific
  percentage-recovery figure.

- **Data versioning for ML — a distinct reproducibility concern from
  application code versioning** — impact: high — depth: section. The
  architectural question this section answers, distinct from ordinary git
  history: **"which exact dataset version trained this specific model?"** —
  a dataset can change (new records, corrected labels, a re-scrape) without
  the training code changing at all, and without a data-version record, that
  change is invisible to anyone trying to reproduce a past result or debug a
  regression. **DVC** (confirmed by direct fetch of `doc.dvc.org`) is the
  current concrete mechanism most commonly named for this: `dvc add` moves a
  large file/directory into a content-addressed cache and creates a small
  `.dvc` metadata file (a content hash plus a path) that *is* committed to
  git — so git tracks a pointer to a specific data version, not the data
  itself, and the actual bytes live in configurable remote storage (S3,
  GCS, Azure Blob, etc.), fetched on demand via `dvc pull`. This is the
  identical **metadata-in-git, blobs-in-object-storage** split the
  experiment-tracking section above names for run artifacts, applied here
  to input data instead of output artifacts — the same architectural
  pattern recurring at a different pipeline stage. Why this can't just be
  "git with a bigger repo," concretely: git's diffing/storage model is
  built for line-diffable text and degrades badly on large binary files
  (repo bloat, slow clones, no meaningful diff) — the same limitation the
  cross-cutting `project-structure.md` baseline already names for Git LFS's
  own "few hundred MB per file" practical ceiling; DVC (and similar tools)
  exist specifically for the case where the *dataset itself*, not just an
  occasional large binary, needs first-class versioning. **Content-hash
  fingerprinting is the underlying mechanism making both DVC's data
  versioning and reproducible pipeline re-runs work**: a pipeline stage only
  re-executes when its declared upstream dependency's hash actually changed
  — a direct application of the idempotency principle the Infrastructure &
  Platform Engineering baseline names for IaC ("re-running against an
  unchanged input should produce zero redundant work"), here applied to a
  data pipeline's re-run decision rather than an infrastructure apply.
  **Lineage tracking** — recording which upstream dataset version(s) and
  transformation steps produced a given downstream dataset or model — is
  the same concern the Data & Analytics Platforms baseline's data-contracts
  section names for producer/consumer data ownership, applied here at the
  scope of "this specific training run's full data provenance chain" rather
  than an organization-wide contract between teams. Specific tool names and
  license/adoption comparison (DVC vs. lakeFS vs. other current entrants)
  belong to the companion `libraries.md`.

- **Model evaluation methodology — benchmark selection, contamination, and
  the offline/online boundary** — impact: high — depth: section.
  **Held-out validation/test-set discipline** is the foundational practice:
  a **validation set** is used during development for hyperparameter tuning
  and model selection, while a **test set** is touched only once, at the
  very end, for a final unbiased performance estimate — reusing the test
  set for any tuning decision silently converts it into a second validation
  set and invalidates the "unbiased" property the whole discipline exists
  to provide. **Benchmark contamination (training-data/test-set overlap)**
  is a real, current, well-documented failure mode this pass verified rather
  than assumed from training data: multiple 2026 sources report contamination
  rates ranging from roughly 1% to 45% across popular QA benchmarks, with a
  specific cited figure of MMLU being approximately 29% contaminated in at
  least one 2026 audit (search-corroborated across multiple sources, not
  independently direct-fetched against a single primary contamination-audit
  paper this pass — named here as a directional severity signal, not a
  precisely-verified number) — and, notably, contamination is **not limited
  to verbatim overlap**: paraphrased or translated benchmark items can evade
  naive string-matching decontamination while still inflating a reported
  score. Mitigation approaches active in current research include
  **dynamic benchmarks** (test items refreshed from sources dated after a
  model's training cutoff) and **zero-data-leakage evaluation** (collecting
  and evaluating against exam/test material immediately after its public
  release, before any model could plausibly have been exposed to it). A
  concrete, real, current cautionary precedent worth naming: Hugging Face's
  own **Open LLM Leaderboard officially retired** (confirmed by direct
  search of the project's own retirement discussion thread) — its stated
  reason was that its fixed benchmark suite's metrics "lost their purpose in
  the face of new modalities and long chain-of-thought models" and risked
  "encourag[ing] people to hill climb in irrelevant directions" — a real,
  first-party example of a widely-used standardized benchmark suite being
  deliberately retired rather than patched once gaming/staleness outweighed
  its value, not a hypothetical risk. **lm-evaluation-harness** (EleutherAI,
  confirmed by search: the backend for the now-retired Open LLM Leaderboard,
  covering 60+ academic benchmarks with standardized prompts/scoring, used
  by NVIDIA/Cohere/BigScience/BigCode among others) is the current concrete
  example of "standardized offline evaluation as reusable, shared tooling"
  rather than every project hand-rolling its own benchmark runner — named
  here as the architectural pattern (a shared, versioned evaluation harness
  producing comparable numbers across models/runs), with specific
  tool/library comparison belonging to `libraries.md`. **The offline/online
  evaluation boundary, named but explicitly not owned by this doc**: offline
  evaluation (benchmark suites, held-out test sets, run before a model ships)
  answers "did this model learn its training objective," while online/
  production evaluation (real user interactions, A/B-style comparisons)
  answers "does this model's improvement actually hold once it's serving
  real traffic" — a documented, real gap between the two (offline metrics
  can be misleading precisely because a held-out test set's distribution
  isn't the same as live traffic's). This category owns naming that
  boundary and the offline half; the online/production-evaluation half,
  drift monitoring, and any live-serving evaluation infrastructure belongs
  to the still-pending **MLOps / ML Platform Engineering** roadmap category
  — see Explicitly out of scope below for why that line is drawn precisely
  here rather than left ambiguous.

- **Reproducibility — a genuinely more demanding bar than typical software,
  and why** — impact: high — depth: checklist, anchored on the NeurIPS
  paper checklist (confirmed by direct fetch of `neurips.cc/public/guides/
  PaperChecklist`) as the most concrete, currently-enforced primary source —
  mandatory for every NeurIPS submission since 2019, itself a response to
  "recurrent gaps in experimental methodology found in recent machine
  learning papers." What the checklist concretely requires, and why each
  item maps to a real failure mode ordinary software reproducibility doesn't
  have to think about: **(1) code and environment** — "the code, data, and
  instructions needed to reproduce the main experimental results," with
  exact commands and environment specification (this is the same bar
  ordinary software reproducibility already has — a pinned dependency
  manifest — extended to also cover the run commands, not just the code
  itself); **(2) full training details** — "data splits, hyperparameters,
  and how they were chosen," not merely the final chosen values, since
  *how* a hyperparameter was selected (a documented sweep vs. an undocumented
  hand-tune) is itself part of what makes a result reproducible or not;
  **(3) compute resources** — "type of compute workers, memory, time of
  execution," a category with no real analogue in typical application
  reproducibility, since a training result can be sensitive to hardware
  (numeric non-determinism across GPU architectures/driver versions is a
  documented, real phenomenon, not just a theoretical concern) in a way an
  application's business logic normally isn't; **(4) statistical
  significance** — "error bars suitably and correctly defined," reflecting
  that ML results are frequently *stochastic* (dependent on random
  initialization, data shuffling order, and — for anything using sampling —
  the random seed) in a way deterministic software behavior isn't, so a
  single run's reported number is not, on its own, evidence of anything
  without repeated-run variance reported alongside it. **Random seeds**
  specifically (search-corroborated across multiple current sources, not
  independently confirmed as a standalone NeurIPS checklist line item in
  this pass's direct fetch): fixing and publishing the seed(s) used, and
  running multiple seeds to report variance, is the standard current
  practice for controlling and disclosing this stochasticity rather than
  reporting a single, potentially lucky, run. **The concrete, itemized
  reproducibility bar for a single ML experiment, synthesized from the above
  and worth stating as an explicit checklist in the authored doc**: code
  version (git commit), data version (see Data versioning above), exact
  hyperparameters and how they were chosen, random seed(s) and the number of
  seeds run, hardware/accelerator type, and framework/library versions
  (PyTorch/CUDA/driver version pinning, since numeric results can shift
  across these) — a strictly longer and more demanding list than a typical
  software bug reproduction's "pin the dependency versions and give me the
  input" bar, precisely because ML introduces stochasticity and
  hardware-numeric-sensitivity as first-class reproducibility threats that
  don't exist for deterministic application code.

- **Compute/infrastructure decision axis: local GPU vs. cloud managed
  training vs. specialized GPU cloud providers** — impact: high — depth:
  table, verified this pass rather than assumed stale given how fast this
  market has moved. Three real, currently-distinct options: **local/
  on-prem GPU** — a team-owned workstation or small GPU cluster; zero
  marginal per-hour cost once purchased, full control, but a real capital
  outlay and no elastic scale-up for a large or one-off training run.
  **Hyperscaler managed training platforms** (AWS SageMaker, Google Cloud
  Vertex AI, Azure ML — search-corroborated current GPU support: SageMaker/
  EC2 with H100/A100/L40S/T4, Vertex AI with H100s and TPU v4/v5e, Azure ML
  with H100s and AMD MI300X/L40S) — the value-add named across multiple
  2026 sources is ML-specific managed tooling (experiment tracking,
  pipeline orchestration, one-click deployment) integrated with the rest of
  that cloud's ecosystem (same IAM, same network, no egress charge moving
  data between that cloud's own services), at the cost of the highest
  GPU pricing in the market per multiple 2026 comparison sources and
  constrained on-demand availability for newest-generation hardware — named
  here as a directional signal, not an independently re-verified pricing
  fact, consistent with this repo's no-cost-modeling convention.
  **Specialized GPU cloud providers** (CoreWeave, Lambda Labs, and similar
  current entrants — specific names/comparison belongs to `libraries.md`)
  — search-corroborated as offering meaningfully better GPU pricing and a
  simpler, ML-specific workflow than the hyperscalers for teams that don't
  need the rest of a hyperscaler's ecosystem, at the cost of needing to
  build or buy each supporting piece (data storage, orchestration,
  experiment tracking) separately and paying egress to move data between
  systems that aren't already co-located. **Decision rule**: a small
  one-off fine-tuning job or a team with existing GPU hardware and no
  elastic-scale need → local/on-prem is simplest and cheapest. A team
  already deeply integrated with one cloud's data/identity/networking
  stack, or wanting managed pipeline/tracking tooling bundled in → that
  cloud's managed training platform, accepting the pricing premium as the
  cost of integration. A team whose primary need is raw GPU compute at the
  best available price, willing to independently wire up its own
  storage/orchestration/tracking stack → a specialized GPU cloud provider.
  This is the training-side counterpart to the Infrastructure & Platform
  Engineering baseline's Kubernetes-vs-simpler-alternatives decision table —
  same "match the tool to a real, present constraint, not a default"
  framing, applied to GPU compute procurement instead of container
  orchestration.

- **The notebook-to-production tension, specialized for ML training
  specifically** — impact: high — depth: paragraph, pointing to the Data &
  Analytics Platforms baseline's own notebook-to-production section (hidden-
  state problem, `.ipynb`'s poor git-diffability, the "fragmentation tax"
  framing) for the general case rather than re-deriving it. What's
  genuinely ML-training-specific on top of that general framing, not
  duplicated there: a notebook cell holding a **multi-hour or multi-day
  training run's in-progress state** (an optimizer state, a partially
  trained model, accumulated metrics) is a substantially higher-stakes
  instance of the hidden-state problem than an analytics notebook's
  intermediate dataframe — losing a kernel/session (a Colab disconnect, a
  local machine sleeping, a cloud notebook instance's idle timeout) can mean
  losing hours or days of GPU compute with no checkpoint to resume from,
  which is precisely why the checkpointing concern named in this doc's
  pipeline-specialization section above (resumability from a saved mid-run
  state) matters even more once training moves out of a notebook and into a
  real orchestrated pipeline step. Concrete, ML-specific version of "what
  belongs in a notebook vs. a real module": exploratory data inspection,
  a first small-scale training-loop sanity check, and result visualization
  are legitimate notebook uses; the moment a training run needs to survive
  a preemption, run unattended on a schedule/trigger, or be launched by
  anyone other than the person who wrote the notebook, its training loop
  belongs in a plain Python module invoked by the orchestrator (Kubeflow
  Pipelines/Metaflow step, or a plain script under a job scheduler) — the
  same "papermill-style notebook scheduling is a legitimate stopgap for one
  analyst's recurring report, not a pattern to build a platform's core
  pipelines on" caution the Data & Analytics Platforms baseline already
  states, carried forward rather than re-derived, with "training run" in
  place of "report" as the concrete stakes.

- **Model cards — current, standard practice for documenting a trained
  model** — impact: high — depth: section, anchored on Mitchell et al.'s
  2018/2019 "Model Cards for Model Reporting" paper as the originating
  source and Hugging Face's own current model-card documentation (confirmed
  by direct fetch of `huggingface.co/docs/hub/model-cards`) as the dominant
  current concrete implementation. A model card is a structured document —
  on the HF Hub, literally the model repo's own `README.md` with a YAML
  metadata header — describing, per HF's own stated required content: the
  model itself, its **intended uses and potential limitations, including
  biases and ethical considerations** (explicitly citing Mitchell 2018 for
  this framing), the **training parameters and experimental info** (with an
  explicit, direct architectural link back to this doc's own
  experiment-tracking section: HF's own guidance is to "embed or link to an
  experiment tracking platform for reference" rather than duplicate that
  record by hand), **which datasets were used to train the model** (the
  same direct link to this doc's data-versioning section — HF's metadata
  schema has a dedicated `datasets:` field, resolved against the Hub's own
  dataset registry when available), and the **model's evaluation results**
  in a structured, machine-parseable format (HF's `model-index` schema,
  originally based on Papers with Code's own model-index specification —
  a real, checkable convention for making evaluation numbers filterable/
  comparable across models on the Hub, not just prose claims). A model card
  additionally supports declaring **provenance relationships to a base
  model** — `base_model_relation: finetune | adapter | quantized | merge` —
  a real, current mechanism for the fine-tuning/PEFT decision this doc's own
  earlier section names to be declared machine-readably rather than only in
  prose, directly connecting this section back to the fine-tuning-vs-PEFT
  decision axis above. **Honest current-adoption caveat, stated by HF's own
  documentation and worth carrying forward rather than presenting model
  cards as universally filled out**: per search corroboration of the current
  ML-documentation-tooling landscape, "model cards for the majority of
  existing models do not exist or are incomplete, despite their adoption as
  a best practice in the ML community" — this is a real, acknowledged gap
  between the practice's stated standard-ness and its actual completion
  rate in the wild, not a solved problem. Distinct from ordinary software
  documentation (a README describing installation/usage/API) in what it's
  *for*: a model card's core job is disclosing the training data, evaluation
  scope, and known limitations of a specific artifact whose behavior was
  learned rather than explicitly coded — information a conventional
  software README has no equivalent need to disclose.

## Explicitly out of scope

- **MLOps / ML Platform Engineering** (the still-pending sibling roadmap
  category) — model registries, feature stores, model-serving
  infrastructure, drift monitoring, retraining triggers, and canary rollouts
  **for models specifically** are explicitly that category's job, not this
  one's, per `research/taxonomy-roadmap.md`'s own item #3. The dividing
  line stated precisely, for a clean handoff to whichever agent researches
  that category next: this doc owns everything up through **producing and
  evaluating a trained model artifact** (experiment tracking, fine-tuning/
  training decisions, data versioning, offline evaluation, reproducibility,
  model cards); MLOps owns everything from **that artifact being registered
  and served onward** (where the model lives once trained, how a serving
  endpoint scales, how production drift gets detected and triggers a
  retraining run). Online/production evaluation is named in this doc's
  Model Evaluation section only as a boundary this doc doesn't own, not
  covered at depth here.
- **Model-serving/inference infrastructure** generally — a slice of
  Agentic & MCP Platforms (already shipped) covers the "an application
  calls a model at inference time" side; this category is exclusively the
  model-*building* side. `ubi-csr-tmf`'s own `aws/container/agents/`
  component, examined in Local Precedent above, is a concrete real-world
  instance of exactly this other-category work, not something this doc's
  scope should absorb.
- **BI/reporting/analytics-consumer-facing data work** — Data & Analytics
  Platforms' own territory (warehouses, lakehouses, dashboards, ELT for
  business reporting), already shipped; this doc's Data Versioning section
  deliberately covers only *training-data* versioning, a narrower and
  differently-motivated concern than that category's data-contracts/
  lineage-for-organizational-consumption framing, even where both touch a
  similarly-shaped warehouse/lake.
- **Specific tool/library names, licenses, and adoption-signal comparisons**
  (MLflow vs. W&B vs. newer experiment trackers; DVC vs. lakeFS; specific
  PEFT-adjacent libraries beyond HF's own PEFT, whose README was a primary
  source for this doc's fine-tuning section; Kubeflow vs. Metaflow;
  CoreWeave vs. Lambda Labs vs. other GPU cloud entrants) — belongs entirely
  to the companion `libraries.md` baseline being produced in parallel. This
  doc names a tool only where the tool's own documented behavior *is* the
  architectural fact being described (e.g. LoRA's own parameter-reduction
  mechanism, DVC's content-hash mechanism) — illustrative anchors for a
  pattern, not this doc encroaching on `libraries.md`'s comparative job.
- **Deep distributed-training internals** (DeepSpeed ZeRO stages, FSDP
  sharding mechanics, gradient-accumulation/pipeline-parallelism
  implementation detail, multi-node rendezvous protocol specifics) — named
  only as a real concern this category's pipeline-orchestration section
  flags exists ("distributed-training coordination... needs its own
  process-group/rendezvous mechanics"), not researched at implementation
  depth this pass; a real, named gap rather than a silently-covered concern.
- **RAG-corpus construction and retrieval-pipeline architecture** — this
  was the original gap the Agentic & MCP Platforms baseline's own
  `libraries.md` scoped out ("fine-tuning, RAG-corpus construction, training
  infrastructure") that prompted this whole roadmap category's creation per
  `research/taxonomy-roadmap.md`'s own "Why these emerged" section.
  **Resolved this pass**: it belongs to Agentic & MCP Platforms, not here
  — see the Open Questions section below for the reasoning (assembling a
  retrieval corpus produces no trained artifact, which is this doc's own
  dividing line for what it owns).
- **Full streaming/real-time training** (online learning, continual
  learning against a live data stream) — this doc's default framing assumes
  batch-shaped training runs against a versioned, static dataset snapshot,
  consistent with the Data & Analytics Platforms baseline's own "batch is
  the default, streaming needs a named justification" framing; online/
  continual learning architecture was not researched this pass.
- **Cost modeling / cloud GPU pricing comparisons** — same no-pricing
  convention as every other baseline in this repo; the Compute/Infrastructure
  section above names qualitative pricing-tier positioning (hyperscaler
  premium vs. specialized-provider value) only where multiple sources
  converged on the direction, never a specific number treated as fact.
- **Numeric benchmark/adoption claims not traceable to a primary source** —
  several turned up in this pass's search results and were deliberately
  excluded or explicitly caveated: the "LoRA recovers 90-95%, QLoRA 80-90%
  of full fine-tuning quality" figure (aggregator/course-site-sourced,
  contradicts the better-sourced original paper's own weaker "on-par or
  better" claim, excluded entirely); specific pretraining-cost dollar
  figures (kept only as an order-of-magnitude directional range, not a
  number to present as fact, per this repo's no-cost-modeling convention);
  the specific "MMLU ~29% contaminated" figure (kept with an explicit
  single/multi-secondary-source caveat, not independently direct-fetched
  against one primary contamination-audit paper this pass).

## Sources

- Local precedent search (not a web source): direct `find`/`ls` across
  `/Users/devopammittra/GitHub/ubi-csr-tmf` and `/Users/devopammittra/GitHub/
  agent-skills` for `*.ipynb`/`train*.py`/MLflow-W&B-DVC config/model-weight
  files (none found); direct read of `aws/container/agents/`'s directory
  listing confirming its `strands_agents`/`main.py`/FastAPI shape as an
  inference-time agent application, not a training codebase — searched and
  read 2026-08-31
- https://mlflow.org/docs/latest/ml/tracking/ — direct fetch: run/experiment
  metadata model (parameters, metrics, run ID, timestamps), artifact store
  vs. backend store separation, dataset-tracking capability — retrieved
  2026-08-31
- MLflow vs. Weights & Biases current positioning — search-corroborated
  across multiple 2026 comparison sources (reintech.io, deploybase.ai,
  modern-datatools.com, contracollective.com), not independently
  direct-fetched against a single MLflow- or W&B-authored comparison page:
  MLflow as self-hosted/open with weaker collaboration UI, W&B as managed
  SaaS with built-in collaboration/sweep orchestration — retrieved
  2026-08-31
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
  order-of-magnitude directional range per this repo's no-cost-modeling
  convention, not presented as a specific verified figure — retrieved
  2026-08-31
- Benchmark contamination / data leakage in LLM evaluation — search-
  corroborated across multiple current sources including arXiv preprints
  (2502.00678 "How Contaminated Is Your Benchmark?", 2505.08389 "Towards
  Contamination Resistant Benchmarks," 2605.19999) and a secondary write-up
  (blog.pebblous.ai) citing an approximately 29%-contaminated figure for
  MMLU specifically and a 1%-45% range across popular QA benchmarks more
  broadly — not independently direct-fetched against a single primary
  contamination-audit paper this pass, named with that caveat — retrieved
  2026-08-31
- Open LLM Leaderboard retirement — confirmed via search of the project's
  own retirement discussion thread at
  `huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard/discussions/1135`
  ("It's been a wild ride, folks 🙂 (end of the Open LLM Leaderboard)"),
  stating the leaderboard "is slowly becoming obsolete" and risked
  encouraging "hill climb[ing] in irrelevant directions" as new
  modalities/long-chain-of-thought models emerged — retrieved 2026-08-31,
  the discussion thread's own text surfaced via search snippet, not
  independently opened as a full page this pass
- lm-evaluation-harness (EleutherAI) — confirmed via search of
  `github.com/EleutherAI/lm-evaluation-harness`'s own repository description:
  60+ academic benchmarks, standardized prompts/scoring, backend for the
  now-retired Open LLM Leaderboard, used internally by NVIDIA/Cohere/
  BigScience/BigCode/Nous Research/MosaicML — not independently direct-
  fetched against the repository's own README this pass — retrieved
  2026-08-31
- Held-out validation-vs-test-set discipline and offline-vs-online
  evaluation framing — search-corroborated across multiple sources
  (machinelearningmastery.com, deepchecks.com, shaped.ai, labelstud.io);
  standard, long-established ML practice, not independently traced to one
  single canonical primary source this pass — retrieved 2026-08-31
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
  checklist item in this pass's direct fetch of the checklist page itself
  — retrieved 2026-08-31
- GPU cloud providers 2026 (CoreWeave, Lambda Labs, AWS SageMaker, Google
  Vertex AI, Azure ML) — search-corroborated across multiple 2026 comparison
  sources (northflank.com, runpod.io, gpu.fm), not independently direct-
  fetched against any single provider's own current-hardware-support page:
  CoreWeave as Kubernetes-native/GPU-fleet-focused, Lambda Labs as
  ML-lifecycle-UX-focused (US-only data centers), hyperscalers' named
  current GPU support (H100/A100/L40S/T4 on AWS; H100/TPU v4-v5e on GCP;
  H100/MI300X/L40S on Azure), and the qualitative pricing/integration
  trade-off (hyperscaler ecosystem integration and no intra-cloud egress
  vs. specialized-provider pricing/simplicity at the cost of assembling a
  supporting stack independently) — retrieved 2026-08-31
- Kubeflow Pipelines vs. Metaflow — **direct-fetched, follow-up pass
  2026-08-31**: `kubeflow.org/docs/components/pipelines/overview/` confirms
  KFP describes itself as "a platform for building and deploying portable
  and scalable machine learning workflows using containers on
  Kubernetes-based systems," explicitly confirms it's installable
  standalone ("available as a core component of Kubeflow or as a
  standalone installation," not requiring the full Kubeflow platform), and
  confirms container-per-step execution ("each component execution
  corresponds to a single container execution") — this doc's original
  "healthy as a standalone DAG runtime" framing is now primary-source
  confirmed, not just search-corroborated. Metaflow's own Python-decorator
  positioning remains search-corroborated only (reintech.io, spheron.network)
- https://huggingface.co/docs/hub/model-cards — direct fetch: required
  model-card content (model description, intended uses/limitations/biases
  citing Mitchell 2018, training params with a link-to-experiment-tracker
  convention, training datasets via a `datasets:` metadata field, structured
  evaluation results via a `model-index` schema originally based on Papers
  with Code's own spec), `base_model_relation` provenance field
  (`finetune`/`adapter`/`quantized`/`merge`) — retrieved 2026-08-31
- Mitchell et al., "Model Cards for Model Reporting" — **direct-fetched,
  follow-up pass 2026-08-31**: confirms the paper (Mitchell, Wu, Zaldivar,
  Barnes, Vasserman, Hutchinson, Spitzer, Raji, Gebru) proposes model cards
  as "short documents accompanying trained machine learning models"
  disclosing intended use, performance evaluated across different
  demographic/cultural conditions (not just an aggregate accuracy number),
  and evaluation procedures — framed explicitly around "responsible
  democratization of machine learning," strengthening this doc's original
  reliance on HF's secondhand framing with the paper's own stated purpose
- Model-card current-adoption gap ("cards for the majority of existing
  models do not exist or are incomplete") — search-corroborated via
  `huggingface.co/docs/hub/model-card-landscape-analysis`, not independently
  direct-fetched this pass — retrieved 2026-08-31
- `research/architecture-templates.md`, `research/project-structure.md`,
  `research/stacks/data-analytics-platforms/stack.md`,
  `research/stacks/infrastructure-platform-engineering/stack.md`,
  `research/stacks/backend-api-services/stack.md`,
  `research/taxonomy-roadmap.md` — read directly this pass (not web sources)
  to avoid re-deriving cross-cutting/adjacent-category content already
  covered, and to confirm this category's scope boundaries against its two
  named neighbors — read 2026-08-31

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
for this category, the items below are resolved directly rather than left
open, with the reasoning recorded for anyone auditing the call later:

- **RAG-corpus construction's home, resolved: Agentic & MCP Platforms, not
  this category.** The deciding distinction: RAG-corpus construction
  (chunking, embedding-model choice, vector-index architecture) produces no
  trained artifact and involves no gradient update — it's a data-preparation
  step that feeds an *application's* retrieval step at inference time, the
  same "serving/orchestration of an already-built model" territory
  Agentic & MCP Platforms already owns, not model-*building* work this
  category owns. This doc's own boundary framing (owns "producing and
  evaluating a trained model artifact") makes the call cleanly: nothing
  about assembling a retrieval corpus produces or evaluates a trained
  model. Not retroactively edited into the already-shipped
  `agentic-mcp-platforms.md` this pass — that's a separate, deliberate
  update if this repo's maintainers want RAG-corpus construction added
  there explicitly, out of scope for this category's own authoring.
- **The MLOps boundary line is confirmed as stated**: "through
  producing/evaluating a trained artifact" (this doc) vs. "registration
  and serving onward" (MLOps) is the right cut for a clean handoff, despite
  MLflow itself spanning both in one tool — a tool spanning a boundary
  doesn't mean the boundary is wrong, the same way Terraform's own state
  file touching both "provisioning" and "drift detection" didn't collapse
  those into one Infrastructure & Platform Engineering subsection. Kept
  as-is.
- **Distributed-training internals (DeepSpeed/FSDP/multi-node rendezvous)
  stay an acknowledged, explicitly out-of-scope gap**, not expanded into
  its own subsection — most projects incubated via this skill won't need
  multi-node distributed training on day one, and the existing
  Explicitly-out-of-scope entry already names it honestly rather than
  silently omitting it.
- **The MMLU ~29%-contamination and 1%-45%-range figures stay, with their
  existing multi-secondary-source caveat** — the qualitative point
  (contamination is real, current, and not limited to verbatim overlap) is
  load-bearing enough to keep, and the caveat already distinguishes it from
  a verified fact.
- **Mitchell et al.'s paper and Kubeflow Pipelines' own positioning are now
  direct-fetched** (see Sources above) — both corrections folded in
  directly; Metaflow's own positioning and the CoreWeave/Lambda-vs-
  hyperscaler GPU-cloud comparison remain search-corroborated only, judged
  acceptable given this doc's own no-cost-modeling convention already
  keeps those sections qualitative rather than resting on a specific
  number needing primary-source backing.

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/ml-model-development.md —
  est. 480–560 lines (9 in-scope subsections per the list above, several at
  section depth with worked-example density comparable to the Backend &
  API Services and Data & Analytics Platforms baselines' actual authored
  length; the fine-tuning/PEFT and reproducibility sections likely the
  longest given how concretely they're anchored on primary-source numbers).
