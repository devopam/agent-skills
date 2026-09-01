# Release Documentation & Versioning

Changelogs, commit conventions, tags, and automation that turn git history
into human-readable release notes — and into trustworthy version numbers.

This is a first-class concern of `ci-cd-plumber`, not an afterthought. A
pipeline that ships artifacts without explaining what changed is only half
done.

## Table of Contents

- [Goals](#goals)
- [Conventional Commits](#conventional-commits)
- [Keep a Changelog](#keep-a-changelog)
- [Automation options](#automation-options)
- [What good looks like](#what-good-looks-like)
- [Audit checks](#audit-checks)
- [Generation guidance](#generation-guidance)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Goals

1. **Humans** can see what changed between versions without reading every
   diff.
2. **Machines** can infer SemVer bumps from structured commits when the
   team opts into that discipline.
3. **Releases** are repeatable: tag + notes + artifact refer to the same
   commit.

---

## Conventional Commits

Preferred commit prefix style:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

Common types:

| Type | Typical SemVer effect |
|---|---|
| `feat` | MINOR |
| `fix` | PATCH |
| `feat!` / `fix!` / `BREAKING CHANGE:` footer | MAJOR |
| `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore` | usually no bump / hidden from user notes |

Guidance:

- Prefer **squash merges** with a clean conventional PR title when using
  release-please / semantic-release — noisy WIP commits on the branch
  should not all land on main.
- Breaking changes must be explicit (`!` or `BREAKING CHANGE:`).
- Do not force Conventional Commits on a repo that refuses them; still
  offer a human-maintained Keep a Changelog.

---

## Keep a Changelog

Default file: `CHANGELOG.md` at repo root.

Expected shape:

- Newest version first.
- ISO dates (`YYYY-MM-DD`).
- An `[Unreleased]` section at the top.
- Categories such as **Added**, **Changed**, **Deprecated**, **Removed**,
  **Fixed**, **Security** (adapt if the project has a documented variant).
- Links to diffs/tags when hosting allows.

Write for humans: impact-oriented sentences, not raw commit dumps.

---

## Automation options

| Tool | Model | Good fit when |
|---|---|---|
| **release-please** | Opens a Release PR; merge publishes | GitHub; want human review before release; Conventional Commits |
| **semantic-release** | Fully automated on push to release branch | Team trusts commit discipline; wants hands-off publish |
| **git-cliff** / conventional-changelog | Generate notes from history | Flexible templates; can pair with custom workflows |
| **Changesets** | Explicit human bump files per change | JS monorepos; prefer curated notes over pure commit mining |
| **Manual** | Human edits CHANGELOG + tag | Small projects; irregular releases |

Default recommendations for this skill:

- **GitHub + Conventional Commits + reviewable releases** → release-please.
- **Fully automated library publish** → semantic-release (or ecosystem
  equivalent).
- **No Conventional Commits** → Keep a Changelog maintained in PRs +
  manual or semi-manual tag workflow.

---

## What good looks like

- `CHANGELOG.md` exists and is structured.
- Versions in changelog match git tags and any package manifest.
- Release automation (if any) is documented in CONTRIBUTING or docs.
- CI does not need production credentials to *draft* notes; publishing
  may need tighter permissions (see security domain).
- Library/package repos: tag drives the published version; no silent
  mismatch between `package.json` / `pyproject.toml` and the git tag.

---

## Audit checks

1. Is there a `CHANGELOG.md` (or equivalent published release notes)?
2. Does it follow a recognizable structure (Keep a Changelog or documented
   alternative)?
3. Are recent tags reflected in the changelog?
4. Is commit or PR discipline sufficient for the chosen automation?
5. Is release automation configured in CI, and is it still working (not a
   stale broken workflow)?
6. Do release jobs use least-privilege permissions?
7. For monorepos: per-package changelogs vs single root — is the choice
   consistent and documented?

---

## Generation guidance

When the user asks to generate or refresh release docs:

1. Inspect tags, recent commits, and existing changelog.
2. Prefer Conventional Commits grouping when prefixes are consistent.
3. If history is unstructured, produce a **draft** clearly marked for human
   edit — do not pretend noisy commits are polished product notes.
4. Never invent product intent that is not in the commits/PRs.
5. Offer to wire automation only after the team accepts the commit
   convention tradeoff.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Empty or missing changelog on a library consumed by others | Downstream cannot assess risk of upgrading |
| Changelog that only lists PR numbers with no description | Not human-readable |
| Version bump without notes | Audit and support nightmare |
| semantic-release on a repo with joke/wip commit messages on main | Nonsense versions and notes |
| Hand-edited versions in multiple files that drift from tags | Broken automation and confused consumers |

---

## Sources

- Keep a Changelog (keepachangelog.com) — structure and principles.
- Conventional Commits specification — types and breaking-change signaling.
- release-please and semantic-release documentation — automation models
  (PR-gated vs fully automatic).
- Practical comparisons of release-please / semantic-release / changesets
  (2025–2026 engineering blogs) — choose by review gate and monorepo needs.

Synthesized for this skill 2026-09-01.
