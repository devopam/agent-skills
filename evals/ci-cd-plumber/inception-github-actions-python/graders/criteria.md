# Grading criteria: inception-github-actions-python

Pass if the response:

1. Detects Inception mode (no baseline, no real CI).
2. Does not re-ask items already given (GitHub Actions, Python+uv, single
   deployable container, standard maturity, Conventional Commits, SBOM
   desire).
3. Recommends layered pipeline: PR validation + main build of immutable
   artifact + release path.
4. Defaults to least-privilege permissions, SHA pinning of actions, and
   lockfile-based installs.
5. Mentions SBOM generation and build-once-promote-always for the image.
6. Proposes release automation consistent with Conventional Commits
   (e.g. release-please) and Keep a Changelog.
7. Plans writing `docs/ci-cd-baseline.md` from the template before or with
   the workflow scaffold.
8. Stays within CI/CD + release-docs scope (no application architecture
   redesign).

Fail if it invents compliance requirements not stated, uses floating
action tags as the recommended pin style, or bulk-overwrites without a
plan/confirmation step.
