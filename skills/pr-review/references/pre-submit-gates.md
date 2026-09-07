# Pre-submit & local quality gates

## Goal

Ensure the change has been (or can be) validated **locally** with the same
class of checks CI will run, so reviewers are not the first lint/test runner.

## Discover

In priority order:

1. **pre-commit** — `.pre-commit-config.yaml`. Note hooks (ruff, prettier,
   trailing-whitespace, custom). Preferred invocation: `pre-commit run --all-files`
   or `pre-commit run --files <changed>`.
2. **Task runners** — `make lint`, `make test`, `make check`, `just ci`, etc.
3. **Ecosystem scripts** — `npm test` / `npm run lint`, `uv run ruff`,
   `pytest`, `cargo test`, `go test`.
4. **CI mirror** — skim primary workflow for required jobs; flag if local
   gates are a strict subset (e.g. local ruff only, CI also mypy + integration).

## Findings patterns

| Observation | Typical severity |
|---|---|
| pre-commit configured; user has not run; obvious format/lint issues in diff | Important |
| Required test command fails on the change | Critical or Important |
| No local gates and CI is heavy | Important (Not Implemented local gate) |
| Local gates pass; CI has extra matrix not runnable locally | Minor (note residual risk) |

## Do / don't

- **Do** quote the exact command to run.
- **Do** distinguish "not run" from "run and failed."
- **Don't** require installing every CI-only tool when a documented subset is the project norm.
- **Don't** expand into redesigning the pipeline (`ci-cd-plumber`).
