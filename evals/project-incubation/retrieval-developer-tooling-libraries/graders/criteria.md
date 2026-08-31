# Grading criteria: retrieval — Developer Tooling & Libraries

Tests whether `project-incubation` picks the right category for a
publishable CLI-tool project (not Backend & API Services or Business
Applications) and applies this category's two named decision rules
correctly for a **single-package, non-monorepo** project specifically —
this scenario is designed to trigger the "Release Please" branch of the
release-automation rule and the "uv + Typer" branch of the
build-tooling/CLI-framework defaults, not the monorepo or legacy
branches.

## Must show

- Selects **Developer Tooling & Libraries** as the category, not Backend
  & API Services (there's no request/response API surface here) or
  Business Applications (no owned UI).
- Names **uv** as the default Python build/packaging tool for a new
  project (or reasons through why, e.g. build+publish+dependency
  management in one tool) — not defaulting to Poetry or setuptools
  without comment.
- Names **Typer** (or reasons through Click vs. Typer vs. argparse) as
  the default CLI framework for a new Python CLI.
- Applies the release-automation decision rule and lands on the correct
  branch for THIS scenario: a **single-package** repo → **Release
  Please**, not Changesets (which is the monorepo-specific
  recommendation) and not semantic-release as the starting default (that
  requires established Conventional-Commits trust, not a fresh project).
- Surfaces at least one concrete CLI-UX convention from `clig.dev`'s
  guidelines (e.g. help-text-leads-with-examples, `stdout`/`stderr`
  stream discipline, human-first output with an explicit `--json`/
  `--plain` opt-in, or tiered destructive-action confirmation) rather
  than only discussing packaging mechanics.

## Should not show

- Recommending Changesets as the default for a single-package repo —
  that's the wrong branch of the release-automation rule.
- Treating this as Backend & API Services or Agentic & MCP Platforms.
- Naming `py.typed`/API-stability-marking machinery as blocking day-one
  setup for what is, per the prompt, a CLI tool rather than an SDK/typed
  library — relevant context, not a hard requirement to lead with.
