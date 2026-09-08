Pre-submit review. The repo's own `CONTRIBUTING.md` documents that
contributors should run `pre-commit run --all-files` before opening a
PR, but there is no `.pre-commit-config.yaml` in the repo at all — the
tooling was never actually wired up. The diff itself is small, passes
whatever ad-hoc lint the CI workflow runs, and needs no tests (a docs
typo fix). User asks for a PR readiness check.
