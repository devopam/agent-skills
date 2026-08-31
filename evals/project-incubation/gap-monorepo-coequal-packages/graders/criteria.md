# Grading criteria: gap — monorepo with coequal packages

Tests the skill's monorepo-specific flow (Phase 1's structural fork +
"Monorepos: category selection per package") for a repo with genuinely
coequal, independently-deployable packages — the case the skill's
maintainer flagged as common in practice, distinct from a single project
with one embedded subsystem (already covered by the
`gap-straddles-two-categories` case).

## Must show

- Recognizes this repo as a **monorepo** per the skill's own bar
  (independent deploy schedules, different package owners — both stated
  explicitly in the prompt), not a single project with an internal
  `packages/` split.
- Does **not** force one of the three packages to be a single repo-wide
  "primary category" with the others demoted to secondary/minor — treats
  `apps/web`, `apps/api`, and `infra/` as coequal, each getting its own
  category assignment (or explicitly states one is genuinely the
  dominant package if it reasons its way there, but doesn't do this by
  default just because the flow used to require a primary).
- Correctly categorizes **`apps/api`** as **Backend & API Services** — a
  REST backend owning the database but not a UI, an unambiguous fit.
- Correctly categorizes **`infra/`** as **Infrastructure & Platform
  Engineering** — Terraform/IaC provisioning, the canonical case for this
  category.
- For **`apps/web`**, accepts either **Business Applications** or
  **Frontend / Client Applications** as a defensible pick, as long as the
  reasoning actually engages with the ownership question (does `apps/web`
  "own" `apps/api` as its backend just because they're same-team/same-repo,
  or does calling a separately-deployed sibling package's API make it a
  backend-less client in the sense this skill's own categories mean) —
  this is a genuinely debatable edge case in the skill's own current
  reference docs, not one this eval should force a single "correct"
  answer on. What matters is that the question is engaged with, not
  glossed over silently.
- Indicates the baseline record will use the **package category map**
  structure (a table: package path → category → architecture pattern →
  library snapshot), not the single primary/secondary-category fields
  meant for a single-project repo.
- Indicates each package gets its own architecture-template decision
  (Phase 3) — doesn't force one shared topology across all three, given
  `infra/` has no request/response topology to speak of at all.

## Should not show

- Treating this as a single project and forcing one primary category for
  the whole repo.
- Silently picking a category for `apps/web` with no acknowledgment that
  the ownership question is genuinely ambiguous here.
- Fabricating an 11th category or a "monorepo" pseudo-category that
  doesn't exist in this skill's taxonomy — each package still maps to
  one of the 10 real categories.
- Skipping `infra/` as "not really a project" — it's a real,
  independently-deployable package per the prompt's own framing and gets
  its own category treatment like the others.
