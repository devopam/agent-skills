# Project Structure

Root-level files, directory layout, monorepo vs. polyrepo, repo governance,
and Git LFS — the cross-cutting shape decisions every repo needs, regardless
of what it builds.

**Applicability.** `project-incubation` forks at inception into a software
path and a non-software path (documentation, research, knowledge-base, or
dataset repos). Most of this doc applies to both — root-level files and
governance don't care whether the repo produces code. `src/`, `scripts/`
(as executables), and `tests/` are software-specific and are marked as such
below; where a non-software repo has a real equivalent (e.g. `validation/`
in place of `tests/`), that's called out inline rather than left implied.

## Table of contents

- [Root-level files](#root-level-files)
  - [README.md](#readmemd)
  - [LICENSE](#license)
  - [CONTRIBUTING.md](#contributingmd)
  - [CHANGELOG.md](#changelogmd)
  - [CODEOWNERS](#codeowners)
  - [SECURITY.md](#securitymd)
  - [CODE_OF_CONDUCT.md](#code_of_conductmd)
  - [.gitignore](#gitignore)
  - [.gitattributes](#gitattributes)
  - [.editorconfig](#editorconfig)
- [Standard directory structure](#standard-directory-structure)
  - [docs/](#docs)
  - [src/ (software projects)](#src-software-projects)
  - [scripts/ vs. src/ vs. CI-only tooling](#scripts-vs-src-vs-ci-only-tooling)
  - [tests/ (software projects) — and validation/ elsewhere](#tests-software-projects--and-validation-elsewhere)
- [Monorepo vs. polyrepo](#monorepo-vs-polyrepo)
- [Repo settings & governance](#repo-settings--governance)
  - [Branching model](#branching-model)
  - [Branch protection: rulesets vs. classic](#branch-protection-rulesets-vs-classic)
  - [PR review requirements](#pr-review-requirements)
  - [Merge strategy](#merge-strategy)
  - [CI/CD gates: block vs. warn](#cicd-gates-block-vs-warn)
- [Git LFS](#git-lfs)
- [Sources](#sources)

## Root-level files

**Applies to:** both paths.

Not every file below is load-bearing for every repo. The table states the
default; the per-file subsections explain when to skip one.

| File | Load-bearing? | Why |
|---|---|---|
| `README.md` | Yes, always | First thing a human or agent reads; no README means no onboarding |
| `LICENSE` | Yes, unless deliberately proprietary/unlicensed | Without it, default copyright applies and nobody outside the org has clear rights to use the code |
| `CONTRIBUTING.md` | Yes, if the repo accepts outside contributions | Skip only for a genuinely solo/internal repo with no PR process to document |
| `CHANGELOG.md` | Strongly recommended, not strictly load-bearing | Cheap to maintain incrementally, expensive to reconstruct after the fact |
| `CODEOWNERS` | Yes, once more than ~one person touches the repo | Enables automatic review assignment and required-reviewer enforcement |
| `SECURITY.md` | Yes, for anything public or handling user data | Without it, GitHub has no reporting channel to surface and vulnerabilities get filed as public issues |
| `CODE_OF_CONDUCT.md` | Nice-to-have | Matters most for repos expecting outside community contributors |
| `.gitignore` | Yes, always | Prevents build output, secrets, and OS cruft from ever entering history |
| `.gitattributes` | Yes, if the repo crosses OS line-ending conventions or tracks binary/large files | Otherwise low-priority |
| `.editorconfig` | Nice-to-have | Cheap, prevents whitespace/line-ending churn in diffs |

### README.md

Follow the shape of the [standard-readme spec](https://github.com/RichardLitt/standard-readme/blob/main/spec.md):
required sections are **Background**, **Install**, **Usage**, **API**,
**Contributing**, and **License**; **Security** and **Maintainers** are
optional add-ons. For a library or service, `API` documents the actual
public interface; for a non-software repo (docs/research/dataset), drop
`API` and `Install` in their literal sense and replace them with whatever
the equivalent on-ramp is — "How this repo is organized" and "How to use
these docs/this dataset." The point of the spec isn't the exact section
names, it's that a reader can predict where to look.

### LICENSE

**Scope note:** this doc covers placement and format only. License
*selection* is a legal decision, not a structural one — for a chooser walk
through `skills/project-incubation/assets/license-guide.md`, or point a
human at [choosealicense.com](https://choosealicense.com/) directly.

- File goes at the repo root, named `LICENSE` (no extension) or
  `LICENSE.md` — GitHub recognizes both and renders a license badge either
  way.
- For repos combining multiple licenses (e.g. code under MIT, docs under
  CC-BY), use per-file
  [SPDX license identifiers](https://spdx.dev/) in a header comment
  (`SPDX-License-Identifier: MIT`) rather than trying to make one root
  `LICENSE` file cover everything.
- Don't hand-write license text. Copy the canonical text from
  choosealicense.com or GitHub's own "Add a license" flow.

### CONTRIBUTING.md

Minimum viable structure:

1. **Dev environment setup** — the exact commands to get from clone to
   running tests, not prose about "make sure your environment is set up."
2. **How to propose a change** — branch naming if you enforce one, PR
   process, what the PR description should contain.
3. **Style/lint requirements** — point at the actual linter config, don't
   restate its rules in prose.
4. **Test requirements** — what must pass before review, how to run just
   the affected tests locally.
5. **Commit message conventions**, if enforced (e.g. Conventional Commits) —
   state it explicitly if your CI lints commit messages, since that's a gate
   contributors will hit blind otherwise.
6. **Review/merge process** — who approves, what merge strategy lands the
   PR (see [Merge strategy](#merge-strategy)).

This repo's own [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) is a live
example of this shape applied to a skills repo specifically.

### CHANGELOG.md

Use the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
Its guiding principles, condensed:

- Written for humans, not generated from raw commit logs.
- One entry per version, newest first.
- Group changes by type within a version, not one flat bullet list.
- Every version gets a date in ISO 8601 (`YYYY-MM-DD`) — no "recently."
- Keep an **`[Unreleased]`** section at the top for changes not yet cut
  into a release; move its contents under the new version heading at
  release time rather than writing the changelog retroactively.
- If the repo follows SemVer, say so explicitly at the top of the file.

The six standard categories, in this order, only including the ones that
actually have entries for a given version:

`Added` · `Changed` · `Deprecated` · `Removed` · `Fixed` · `Security`

This repo's own versioning policy (Patch/Minor/Major mapped to what kind of
skill change triggers each) is documented in
[`CONTRIBUTING.md`](../../../CONTRIBUTING.md#versioning) — a concrete
worked example of pairing a changelog with a SemVer policy.

### CODEOWNERS

GitHub-native, not a generic convention — this section is GitHub-specific.

- **Placement precedence**: GitHub checks `.github/CODEOWNERS`, then the
  repo root, then `docs/CODEOWNERS`, in that order, and uses **only the
  first one it finds** — you cannot split ownership rules across multiple
  locations expecting them to merge. Pick one location per repo.
- **Syntax** is gitignore-style path patterns, one pattern per line,
  followed by one or more owners (`@user` or `@org/team`).
- **Last matching pattern wins**, not first — order specific overrides
  *after* broad defaults, the same rule GitHub applies to `.gitignore`.
  A common gotcha: putting a broad `* @org/core-team` rule *below* a
  narrower path rule accidentally overrides the narrow rule instead of
  falling back to it.
- **3 MB file size cap.** A CODEOWNERS file over that limit is silently
  ignored by GitHub, not rejected with an error — if reviewer assignment
  stops working on a large repo, check the file size before anything else.
- **Case-sensitive** path matching, unlike some filesystems — a pattern
  that doesn't match due to casing fails silently (no owner assigned, no
  error surfaced).
- Any `@org/team` listed must have write access to the repo and be a
  *visible* (not secret) team, or GitHub won't assign it as a reviewer.

### SECURITY.md

Placement: root, `docs/`, or `.github/` — GitHub auto-surfaces it in the
repo's **Security** tab and offers it as a template when someone opens a
new issue. Minimum contents: a supported-versions table (which release
lines still get security patches) and how to report a vulnerability —
prefer directing reporters to GitHub's private vulnerability reporting
flow over a public issue tracker or a plain email address, so a live
exploit doesn't get disclosed in the open before a fix ships.

### CODE_OF_CONDUCT.md

Adopt [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)
verbatim rather than drafting one — it's the current canonical version and
includes an explicit four-tier enforcement ladder (Correction → Warning →
Temporary Ban → Permanent Ban) that most hand-rolled codes of conduct lack.
Link to the canonical text or copy it unmodified; don't paraphrase it.

### .gitignore

Don't hand-roll one. Start from
[github/gitignore](https://github.com/github/gitignore)'s per-language
templates, combined via a generator (gitignore.io or the GitHub
"Add .gitignore" flow at repo creation) if the repo spans multiple
ecosystems. Hand-rolled `.gitignore` files reliably miss OS-specific cruft
(`.DS_Store`, `Thumbs.db`) and IDE directories that the maintained
templates already cover.

### .gitattributes

Two independent jobs live in this file: line-ending normalization and
(if used) [LFS tracking](#git-lfs) — LFS patterns are covered separately
below. For line endings:

```gitattributes
# Baseline: normalize everything to LF in the repo, checkout in the
# platform's native ending.
* text=auto

# Force LF regardless of platform for scripts that must run in a
# Unix-style shell (CRLF breaks the shebang line).
*.sh text eol=lf

# Force CRLF for files that only ever get edited/run on Windows.
*.bat text eol=crlf
*.cmd text eol=crlf

# Mark generated/vendored files so they're excluded from GitHub's
# language stats and, more usefully, from PR diffs by default.
dist/** linguist-generated
vendor/** linguist-vendored
docs/legal/** linguist-documentation
```

The `linguist-*` attributes matter beyond cosmetics: `linguist-generated`
and `linguist-vendored` files are collapsed in PR diffs by default, which
keeps a vendored dependency bump or a compiled-output commit from burying
the actual code change in a review.

### .editorconfig

One file at the repo root, respected natively by most editors (or via a
near-universal plugin for the rest):

```ini
root = true

[*]
indent_style = space
indent_size = 2
charset = utf-8
end_of_line = lf
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false  # trailing double-space = markdown line break
```

Cheap to add, and it prevents the specific class of PR noise where a
contributor's editor silently re-indents or re-terminates a file their
diff didn't otherwise need to touch.

## Standard directory structure

### docs/

**Applies to:** both paths.

`docs/` holds anything that isn't the README (too long for the front door)
and isn't a reference doc consumed programmatically. For a software
project: architecture decision records, runbooks, design docs. For a
non-software (docs/research/dataset) project, `docs/` may *be* the bulk of
the repo's content — in that case, keep this same instinct: `README.md`
is the on-ramp, `docs/` is the depth, don't collapse both into one huge
README.

### src/ (software projects)

**Applies to:** software projects only.

Layout conventions diverge sharply by ecosystem — don't apply one
language's convention to another.

**Python — src-layout vs. flat-layout.**
[PyPA's own guidance](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)
recommends **src-layout as the default**:

```
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       └── module.py
├── tests/
├── pyproject.toml
└── README.md
```

over flat-layout:

```
project/
├── mypackage/
│   ├── __init__.py
│   └── module.py
├── tests/
├── pyproject.toml
└── README.md
```

The reason is concrete, not stylistic: with flat-layout, running tests
from the repo root can silently import the *uninstalled working copy*
(because Python puts the current directory on `sys.path`) instead of the
actually-installed package — masking packaging bugs that only surface
after `pip install`. src-layout forces tests to run against the installed
package, which is what your users actually get. Flat-layout is still fine
for a quick script or a repo that's never distributed as a package.

**Node/TypeScript.**

```
project/
├── src/       # source, TypeScript or ESM/CJS source
├── dist/      # compiled output — gitignored, never committed
├── bin/       # CLI entry shims referenced by package.json's "bin" field
└── scripts/   # dev/release tooling, not shipped in the published package
```

`bin/` and `scripts/` both hold executables, but the distinction is
whether it ships: `bin/` entries are part of the published package's
public surface (referenced by `package.json`'s `bin` map); `scripts/`
entries are for maintainers only (release cutting, codegen, local setup)
and are excluded via `.npmignore`/`files` in `package.json`.

**Go — `cmd/`, `internal/`, `pkg/`.**
The [golang-standards/project-layout](https://github.com/golang-standards/project-layout)
repo is the most-cited Go layout convention, but treat it as a
community pattern, not a standard — Russ Cox (Go's tech lead) has
explicitly disclaimed it as official guidance. Used well:

```
project/
├── cmd/
│   └── myapp/
│       └── main.go     # one subdir per binary, minimal logic
├── internal/            # private packages — compiler-enforced, cannot
│                         # be imported by any module outside this one
└── pkg/                 # library code meant for external import
```

`internal/` is the one piece worth adopting broadly — it's not just
convention, the Go compiler enforces the import restriction. `pkg/` is
more contested (Go's own standard library doesn't use it, and some
maintainers argue everything not in `internal/` is implicitly `pkg/`
already). The counter-guidance carries real weight: **start with a flat
`main.go` at the repo root and only grow into `cmd/`/`internal/`/`pkg/`
once there's an actual second binary or a real need to block external
imports.** Imposing the full structure on a single-binary project adds
navigation overhead for no present benefit.

### scripts/ vs. src/ vs. CI-only tooling

**Applies to:** software projects primarily; the disambiguation (as
opposed to the executable-specific framing) is a useful instinct for
non-software repos too.

Three different things get called "scripts" and mixing them up creates
navigation debt:

| Lives in | Contains | Ships to users? |
|---|---|---|
| `src/` | The product | Yes |
| `scripts/` | Dev/ops tooling run by humans or CI — migrations, release cutting, local setup | No |
| `.github/workflows/` or `.github/scripts/` | Glue specific to one CI workflow | No, and not even meant to run outside CI |

The third category is the one that gets misplaced most often: a script
that only makes sense inside a specific GitHub Actions job (assumes CI
env vars, writes to `$GITHUB_OUTPUT`) belongs under `.github/`, not
top-level `scripts/`, so it reads as visibly CI-scoped rather than looking
like a general-purpose dev tool that happens to fail when run locally.

### tests/ (software projects) — and validation/ elsewhere

**Applies to:** software projects use `tests/`. A non-software repo that
needs an equivalent (schema validation for a dataset, fact-checking or
link-checking for a docs/research repo) should name it for what it does —
`validation/` is a reasonable default — rather than forcing `tests/` onto
content that isn't code, or silently having no place for it at all. Either
way, a repo audited later should show up as "no automated checks, by
design" rather than getting flagged as if it forgot to write tests it was
always going to have.

## Monorepo vs. polyrepo

**Applies to:** both paths (a documentation/research org can face the same
split decision across multiple knowledge bases).

Default to a monorepo until it hurts — this is deliberately the
conventional, low-drama starting point, not a bias to defend forever.
There's no single authoritative numeric threshold ("split at N services"
or "N engineers") worth committing to here; the signal is qualitative and
you'll recognize it when several of these are true at once, not any one in
isolation:

- **CI time is creeping up** and no one change or team is the obvious
  cause — every PR is paying the tax of every team's build/test suite,
  not just its own.
- **Every PR triggers a full-repo build** because change-detection or a
  build-graph tool (affected-package detection) isn't in place, so cost
  scales with repo size instead of with the size of the actual change.
- **CODEOWNERS entries are blurring** — multiple teams claim overlapping
  paths, or nobody can say with confidence who owns a given top-level
  directory anymore.
- **Reviews routinely cross team boundaries** — a change scoped to one
  team's area keeps dragging in unrelated approvers because the tooling
  can't scope review requirements to a subtree.
- **Release cadences are in real conflict** — one team ships multiple
  times a day, another ships quarterly, and the monorepo's single
  versioning/release process is actively fighting both.

Google's monorepo (~2 billion lines of code, 25,000+ engineers, tens of
thousands of commits/day) is the existence-proof extreme: it works, but
only because of purpose-built infrastructure (Piper, Bazel) that almost no
organization has or needs. It's evidence that monorepos scale, not
evidence that any given org should keep pushing past its actual pain
signals to chase that scale.

**Splitting a monorepo, when the signs above are real:**

1. Extract along the ownership boundary that's *already* blurring, not an
   idealized target architecture — the split should relieve the actual
   pain, not create a new one.
2. Preserve history with `git filter-repo` (not the deprecated
   `git filter-branch`) rather than starting the new repo from a fresh,
   historyless commit.
3. Stand up the new repo's CI/CD, branch protection, and CODEOWNERS
   *before* cutting consumers over — not as a follow-up PR after the split
   already shipped.
4. Update cross-repo dependency references atomically with the split
   (pinned versions, package registry entries), so nothing is left
   pointing at code that no longer lives where it says it does.
5. Migrate one team or directory at a time and verify that team's
   build/deploy actually works from the new location before continuing —
   don't big-bang the whole split in one pass.

## Repo settings & governance

**Applies to:** both paths. Governance guidance here is written against
GitHub specifically (matches this skill's actual usage) — the concepts
(branch protection, required review, CI gates) transfer to GitLab,
Bitbucket, or self-hosted Gitea, but the exact syntax and feature names
below are GitHub's.

### Branching model

Name the branching model before writing branch protection rules —
protection rules only make sense in reference to the model they're
enforcing.

| Model | Shape | Best fit |
|---|---|---|
| **Trunk-based** | Short-lived branches, frequent merges to `main`, incomplete work hidden behind feature flags | Continuously-deployed services — default choice for most software-path repos |
| **GitHub Flow** | `main` + feature branches + PR + deploy on merge, no long-lived release branches | Same continuous-deployment shape as trunk-based, slightly more branch-per-feature ceremony; the practical default for repos without feature-flag infrastructure |
| **GitFlow** | `main` + `develop` + `release/*` + `hotfix/*` branches | Software that ships discrete, versioned releases (installed apps, libraries with support windows) — heavier process, wrong fit for a continuously-deployed service |

Default recommendation: trunk-based or GitHub Flow for anything
continuously deployed; reach for GitFlow only when the project genuinely
maintains multiple supported release lines at once.

### Branch protection: rulesets vs. classic

GitHub **rulesets** are the current, actively-developed mechanism and
should be taught as the primary one — they support fnmatch target
patterns across multiple branches/tags at once, org-level enforcement
applied across repos, and layering multiple independent rule sets rather
than one rule per branch. Classic branch protection rules still work and
remain the only option on older GitHub Enterprise Server versions, but are
narrower in scope.

| Capability | Rulesets | Classic branch protection |
|---|---|---|
| Target selection | fnmatch patterns, multiple branches/tags at once | One branch name pattern |
| Org-level enforcement across repos | Yes | No |
| Multiple independent rule layers per branch | Yes | No — one protection config per branch |
| Path-scoped required-reviewer rule (layers on top of CODEOWNERS) | Yes — generally available as of February 2026 | No |
| Bypass list (specific actors/teams exempted) | Yes, granular | Admin-override toggle only |
| Works on older GitHub Enterprise Server | No | Yes |

The path-scoped required-reviewer ruleset rule is worth calling out
specifically: it layers *on top of* CODEOWNERS rather than replacing it —
CODEOWNERS still owns ownership and default review requests, while the
ruleset rule adds enforceable policy (e.g. "this path needs 2 approvals
from `@org/security` regardless of who CODEOWNERS assigns"). Use both
together, not one instead of the other.

### PR review requirements

- **Minimum approvals**: 1 for low-stakes repos, 2 for anything with
  production blast radius or compliance requirements.
- **Require review from Code Owners** for any file matching a CODEOWNERS
  pattern — this is what actually makes CODEOWNERS enforce anything;
  without this setting on, CODEOWNERS only affects auto-assignment, not
  whether the PR can merge without that reviewer's approval.
- **Dismiss stale reviews on new pushes**: turn this on for anything above
  trivial-stakes — an approval on commit A shouldn't silently cover commit
  D pushed after review.
- GitHub automatically excludes the PR author's own most recent push from
  satisfying required-reviewer count — don't build a redundant check for
  this.

### Merge strategy

| Strategy | History shape | Use when | Gotcha |
|---|---|---|---|
| **Merge commit** | Full branch history preserved, plus a merge node | You want per-feature grouping visible directly in `main`'s history | Gets noisy fast on high-velocity repos with many small PRs |
| **Squash and merge** | One commit per PR on `main` | The common default — keeps `main` linear and easy to bisect | Individual in-PR commit granularity is lost; the squash commit message is the *permanent* record, so write it deliberately, not auto-accept GitHub's concatenation of commit titles |
| **Rebase and merge** | Commits replayed individually onto `main`, no merge commit | You want linear history *and* to keep individual commit granularity | GitHub's "rebase and merge" is not the same operation as a local `git rebase` — it rewrites committer metadata and drops empty commits, so don't assume a rebase-merged PR round-trips identically to what a contributor ran locally |

Pick one strategy per repo and enforce it in the repo's merge settings
(GitHub lets you disable the other two) — mixed strategies make `git log`
inconsistent across the repo's own history.

### CI/CD gates: block vs. warn

Pipeline *construction* (YAML, runners, specific CI provider) is
stack-specific and lives in each stack category's own reference doc, not
here. What belongs here is policy: which checks should be allowed to
block a merge versus surface as a warning.

| Check | Recommended gate |
|---|---|
| Unit tests | Block |
| Linting / formatting | Block (pair with an auto-fix bot where available so most violations never reach review) |
| Type checking | Block |
| Security/dependency scanning (e.g. CodeQL, Dependabot alerts) | Block on critical/high severity; warn on medium/low |
| License compliance scanning | Block |
| Code coverage delta | Warn by default; only promote to block once a team's coverage is stable enough that regressions are rare, real signal — an immature block here just trains people to write low-value tests to satisfy the number |
| Performance / bundle-size regression | Warn by default; escalate to block if warnings are repeatedly ignored in practice |

The general principle: block on checks that are cheap to satisfy honestly
and expensive to skip (tests, types, high-severity security); warn on
checks that are more judgment-dependent or newer to the team, and only
promote a warn to a block once you've observed it's actually acted on.

## Git LFS

**Applies to:** both paths — a research repo tracking source PDFs or a
dataset repo tracking sample files hits these same thresholds as a
software repo tracking design assets.

**Thresholds** (GitHub-specific, verified current as of this writing):
pushing a file over **50 MiB** produces a warning but still succeeds;
pushing a file over **100 MiB** is hard-rejected — the push fails outright
without LFS. Files added through GitHub's web upload UI face a stricter
25 MiB cap regardless.

Git LFS itself is a pointer-file mechanism: the repo tracks a small
pointer, the actual content lives in a separate LFS content store fetched
on checkout. Its practical ceiling is a **few hundred MB per file** —
beyond that, or once total tracked-binary volume gets large, a
purpose-built external store (S3, GCS) or a data-versioning tool (DVC) is
a better fit than pushing LFS further than it's meant to go.

**What belongs where:**

| Content | Where |
|---|---|
| Binary assets that are small in count and change alongside the code (design files, icons, small sample datasets, small model checkpoints) | Git LFS |
| Build artifacts that regenerate from source (`dist/`, compiled binaries, coverage reports) | `.gitignore` — they don't need version history at all |
| Large datasets, model weights beyond LFS's practical few-hundred-MB ceiling, or anything needing its own lineage/versioning | External object storage (S3/GCS) or DVC, referenced by path/manifest — not committed |
| Credentials, private keys, any secret | Never committed, LFS or not |

**`.gitattributes` patterns**, generated via `git lfs track` rather than
hand-written (the command manages the `filter=lfs diff=lfs merge=lfs -text`
quartet for you and avoids typo'd attribute lines that silently fail to
trigger LFS):

```gitattributes
*.psd filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
assets/models/** filter=lfs diff=lfs merge=lfs -text
```

**Track vs. migrate.** `git lfs track` only affects *new* commits going
forward. Files that are already committed as regular blobs need
`git lfs migrate import`, which **rewrites history** — treat this as a
one-time, coordinated operation (ideally before a repo goes public or is
widely cloned), not something to run casually on a shared branch.

## Sources

- [GitHub Docs — About CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) — location precedence, gitignore-style syntax, last-match-wins, 3 MB cap, case sensitivity. Retrieved 2026-08-19.
- [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/) — guiding principles, six standard categories, Unreleased convention, ISO 8601 dates. Retrieved 2026-08-19.
- [GitHub Docs — About pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges) — merge/squash/rebase trade-offs, and that GitHub's rebase-and-merge rewrites committer info and drops empty commits (differs from a local `git rebase`). Retrieved 2026-08-19.
- [PyPA — src layout vs. flat layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/) — src-layout as PyPA's recommended default, and why (prevents importing the uninstalled working copy). Retrieved 2026-08-19.
- [golang-standards/project-layout](https://github.com/golang-standards/project-layout) — widely-cited `cmd/`/`internal/`/`pkg/` convention, explicitly not an official Go standard (disclaimed by Russ Cox); counter-guidance to start flat. Retrieved 2026-08-19.
- [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) — current canonical version, four-tier enforcement ladder. Retrieved 2026-08-19.
- [GitHub Docs — Adding a security policy to your repository](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository) — SECURITY.md placement options and auto-surfacing behavior. Retrieved 2026-08-19.
- [Git LFS FAQ](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-faq.adoc) and [git-lfs.com](https://git-lfs.com/) — pointer-file mechanism, practical few-hundred-MB-per-file ceiling, `git lfs track` vs. `git lfs migrate import`. Retrieved 2026-08-19.
- [GitHub Docs — About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github) — 50 MiB soft-warning / 100 MiB hard-block push thresholds, 25 MiB web-upload cap. Directly re-verified during authoring (2026-08-19) to confirm current values.
- [rehansaeed.com — .gitattributes Best Practices](https://rehansaeed.com/gitattributes-best-practices/) — `* text=auto` baseline, per-filetype `eol` overrides, `linguist-*` attributes. Retrieved 2026-08-19.
- [standard-readme spec](https://github.com/RichardLitt/standard-readme/blob/main/spec.md) — required/optional README sections. Retrieved 2026-08-19.
- Monorepo warning-sign framing synthesized from multiple 2025–2026 practitioner sources (no single authoritative spec exists for this) — dev.to/elpddev, "Six Reasons Your Monorepo CI Got Slower This Quarter," and havenwulf.com, "Monorepos at Scale" — plus Google's publicly stated monorepo scale (~2B LOC, 25k+ engineers, 40k commits/day) as the existence-proof extreme. Retrieved 2026-08-19. Kept deliberately qualitative in this doc — no numeric team/service threshold is asserted, per explicit review resolution.
- [GitHub Changelog — Required review by specific teams now available in rulesets](https://github.blog/changelog/2025-11-03-required-review-by-specific-teams-now-available-in-rulesets/) (2025-11-03) and [GitHub Changelog — Required reviewer rule is now generally available](https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/) (2026-02-17) — path-scoped required-reviewer ruleset rule, layered on top of (not replacing) CODEOWNERS. Directly re-verified during authoring (2026-08-19) to confirm GA status and the CODEOWNERS relationship.
