---
type: llm
weight: 1
---

# Grading criteria: gap — monorepo with coequal packages

Pass if the response:

1. Recognizes the repo as a monorepo (independent deploy schedules and different owners) rather than a single project.
2. Treats `apps/web`, `apps/api` and `infra/` as coequal, each with its own category, not one repo-wide primary category.
3. Categorizes `apps/api` as Backend & API Services and `infra/` as Infrastructure & Platform Engineering.
4. Categorizes `apps/web` as Business Applications or Frontend / Client Applications and engages with the ownership question.
5. Says the baseline record will use a per-package category map (package, category, architecture pattern, libraries).

Fail if it forces a single primary category or miscategorizes `apps/api` or `infra/`.
