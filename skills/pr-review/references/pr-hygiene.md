# PR hygiene

## Description

A good PR description states **why**, **what**, and **how to verify**.
Flag Important when the change is non-trivial and the description is empty
or only a commit subject dump.

## Changelog & user-facing docs

If the repo maintains `CHANGELOG.md` (Keep a Changelog) or versioned user
docs:

- User-visible behavior, APIs, CLI flags, or security fixes → expect an
  `[Unreleased]` (or version) entry unless the project explicitly skips
  chore-only changes.
- Operator docs (`docs/`, README install paths) → update when commands or
  config keys change.

Absence when clearly required → Important. Pure internal refactor → OK to skip
(note the judgment).

## Checklists

If `.github/PULL_REQUEST_TEMPLATE.md` exists, skim for required boxes
(roadmap row, test plan). Unchecked required items → Minor or Important
depending on project strictness.

## Linked issues / roadmap

When the project uses issue or roadmap linkage in the template, mention
missing links as Minor unless the template marks them required.
