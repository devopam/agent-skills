# Grading criteria: gap — existing repo, no baseline record

Tests the third routing branch in `SKILL.md`'s mode-detection logic:
missing baseline + real existing content → infer, confirm, then audit —
distinct from both inception mode (empty repo) and normal audit mode
(baseline already exists).

## Must show

- Does NOT treat this as inception mode (doesn't try to re-scaffold a
  README/LICENSE/etc. from scratch as if the repo were empty).
- Infers a likely category from the described stack signals (FastAPI +
  Postgres → most plausibly Backend & API Services, though Business
  Applications is defensible if more context suggests a UI) — and
  explicitly states this is an inference, not a certainty.
- **Confirms the inferred category with the user in plain text before
  proceeding** — this is the specific, non-negotiable behavior the skill
  documents ("confirm the inference with the user in plain text rather
  than assuming it's right"). Silently proceeding on the inference alone
  is a failure.
- After confirmation (or once the scenario allows it), writes a baseline
  record and proceeds into a real audit against it.

## Should not show

- Proceeding straight to an audit against an inferred category without
  ever confirming it with the user.
- Treating the repo as if it needs inception-mode scaffolding despite
  already having real code.
- Fabricating a baseline record's contents without asking anything about
  the actual project (team size, compliance, LLM component, etc.).
