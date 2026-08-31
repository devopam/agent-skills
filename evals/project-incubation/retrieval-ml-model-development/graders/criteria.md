# Grading criteria: retrieval — ML / AI Model Development

Tests whether `project-incubation` picks the right category for a
model-adaptation project (not Agentic & MCP Platforms, which is for
serving/calling an already-built model, and not Data & Analytics
Platforms) and applies this category's central fine-tuning decision rule
correctly for a **single-GPU, modest-budget, existing-pretrained-model**
scenario specifically — designed to trigger the PEFT/LoRA branch, not
full fine-tuning or training-from-scratch.

## Must show

- Selects **ML / AI Model Development** as the category — this is a
  model-*building* task (adapting a model's weights to new data), not an
  application calling a model at inference time.
- Recommends **PEFT (LoRA or QLoRA)** as the fine-tuning approach for this
  scenario specifically (single GPU, modest budget, an existing pretrained
  model already covers most of the target domain) — not full fine-tuning
  and not training from scratch, and not just listing all three options
  with no recommendation.
- Surfaces **reproducibility** requirements given the prompt's explicit
  "answer this months later" framing: at minimum, data version and
  hyperparameters/seed should be mentioned as things to record — not just
  "track your experiments" with no specifics.
- If experiment tracking comes up, names a default (MLflow, self-hosted)
  rather than presenting W&B as a free default without noting its
  commercial-use restriction.
- If a deep learning framework comes up, defaults to **PyTorch** rather
  than TensorFlow or JAX without a reason (this scenario has no TPU or
  edge-deployment signal that would justify either alternative).

## Should not show

- Recommending full fine-tuning or training-from-scratch as the default
  approach for this scenario — the prompt's single-GPU/modest-budget
  framing specifically signals PEFT.
- Treating this as Agentic & MCP Platforms (serving) or Data & Analytics
  Platforms (BI/reporting).
- Citing the specific "LoRA recovers 90-95%, QLoRA 80-90% of full
  fine-tuning quality" figure as settled fact — this skill's own reference
  doc explicitly excludes that claim as unverifiable.
- Recommending Weights & Biases' free tier as a no-strings-attached default
  for what is plausibly commercial/internal work, without at least noting
  its free-tier corporate-use restriction.
