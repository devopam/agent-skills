# Baseline: Project Structure
Status: user-approved      Date: 2026-08-19

## In scope

- Root-level file inventory (which are load-bearing vs. nice-to-have) — impact: high — depth: table
- README.md template/sections — impact: high — depth: section
- LICENSE selection guidance (not full license text) — impact: high — depth: paragraph
- CONTRIBUTING.md template — impact: med — depth: section
- CHANGELOG.md — Keep a Changelog format — impact: med — depth: section
- CODEOWNERS — GitHub-native syntax, placement, gotchas — impact: high — depth: section
- SECURITY.md — impact: med — depth: paragraph
- CODE_OF_CONDUCT.md (Contributor Covenant) — impact: low — depth: paragraph
- .gitignore — impact: high — depth: paragraph (mostly "use github/gitignore templates, don't hand-roll")
- .gitattributes — line-ending normalization + LFS tracking — impact: high — depth: section
- .editorconfig — impact: med — depth: paragraph
- Standard directory structure (docs/, src/, scripts/, tests/) with ecosystem examples — impact: high — depth: table + per-ecosystem subsections
  - Python: src-layout vs flat-layout — impact: high — depth: section
  - Node/TypeScript: src/, dist/, bin/ vs scripts/ — impact: high — depth: section
  - Go: golang-standards/project-layout (cmd/, internal/, pkg/) and the "grow into it" counter-guidance — impact: high — depth: section
- scripts/ vs src/ vs CI-only tooling — disambiguation — impact: med — depth: paragraph
- Monorepo vs. polyrepo decision — impact: high — depth: section
  - Concrete warning signs (CI time creep, cross-cutting reviews, ownership blur) — impact: high — depth: checklist
  - Split strategy when breaking up a monorepo — impact: med — depth: checklist
- Repo settings & governance — impact: high — depth: section
  - Branch protection rules — impact: high — depth: table
  - PR review requirements (min reviewers, CODEOWNERS integration, stale-review dismissal) — impact: high — depth: section
  - Merge strategy trade-offs (merge commit / squash / rebase) — impact: high — depth: table
  - CI/CD gates: block vs. warn — impact: high — depth: table
- Git LFS — impact: med — depth: section
  - Concrete thresholds (GitHub's 50MB warn / 100MB hard block) — impact: high — depth: paragraph
  - What belongs in LFS vs. external artifact store (S3/GCS/DVC) vs. .gitignore — impact: med — depth: checklist
  - .gitattributes patterns for LFS — impact: med — depth: paragraph

## Explicitly out of scope

- Full license text / legal advice on license selection — defer to choosealicense.com link only, not our content to author
- CI/CD pipeline *implementation* (YAML syntax, specific runners) — that's stack-specific, belongs in downstream stack-category docs, not this cross-cutting doc
- Language-specific build tooling configuration (package.json contents, pyproject.toml contents, go.mod contents) beyond where they physically live — downstream docs' job
- Full Contributor Covenant text — link to canonical source, don't reproduce
- Detailed monorepo build-tool comparison (Nx vs. Turborepo vs. Bazel feature matrix) — that's a tooling choice for a "build systems" doc, not project structure; we only need the warning-signs/threshold framing here
- Git workflow strategies (GitFlow vs. trunk-based vs. GitHub Flow) — adjacent but distinct topic; likely another cross-cutting baseline candidate, flag for the human
- Secrets management / vault integration — security topic, not structure
- Dependency-update automation (Dependabot/Renovate config) — governance-adjacent but tooling-specific, defer

## Sources

- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners — CODEOWNERS file location precedence (.github/ > root > docs/), gitignore-style pattern syntax, "last matching pattern wins," 3MB file size cap, case-sensitivity — retrieved 2026-08-19
- https://keepachangelog.com/en/1.1.0/ — Keep a Changelog spec: 7 guiding principles, 6 standard categories (Added/Changed/Deprecated/Removed/Fixed/Security), Unreleased section convention, ISO 8601 dates — retrieved 2026-08-19
- https://docs.github.com/en/pull-requests/reference/pull-request-merges — GitHub's own framing of merge commit vs. squash vs. rebase, including when each is recommended and the caveat that GitHub's "rebase and merge" differs from a local git rebase (rewrites committer, drops empty commits) — retrieved 2026-08-19
- https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/ — PyPA's authoritative src-layout vs. flat-layout discussion; src-layout is the PyPA-recommended default because it prevents accidental import of the uninstalled working copy — retrieved 2026-08-19
- https://github.com/golang-standards/project-layout — widely-cited but explicitly *not* an official Go standard (Russ Cox has disclaimed it); cmd/, internal/, pkg/ convention; counter-guidance to start flat and grow into structure — retrieved 2026-08-19
- https://www.contributor-covenant.org/version/2/1/code_of_conduct/ — Contributor Covenant v2.1, current canonical version, adds explicit 4-tier enforcement ladder (Correction/Warning/Temporary Ban/Permanent Ban) — retrieved 2026-08-19
- https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository — SECURITY.md placement (root, docs/, or .github/), auto-surfaces in the repo's Security tab and on new-issue creation — retrieved 2026-08-19
- https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-faq.adoc and https://git-lfs.com/ — Git LFS purpose (pointer files + remote content store), practical ceiling of a "few hundred MB" per file before other tools (DVC, external object storage) are more appropriate, `.gitattributes`-driven tracking via `git lfs track`, migrate-vs-track distinction — retrieved 2026-08-19
- GitHub large-file limits (50 MiB soft warning on push, 100 MiB hard rejection without LFS) — corroborated by https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github and community discussion threads — retrieved 2026-08-19
- https://rehansaeed.com/gitattributes-best-practices/ — concrete `.gitattributes` patterns: `* text=auto`, explicit `eol=lf`/`eol=crlf` overrides per file type, `linguist-` attributes — retrieved 2026-08-19
- https://github.com/RichardLitt/standard-readme/blob/main/spec.md — standard-readme spec: required sections (Background/Install/Usage/API/Contributing/License), optional Security/Maintainers sections — retrieved 2026-08-19
- Monorepo warning-sign / scale sourcing (synthesized from multiple 2025-2026 practitioner sources, no single authoritative doc): CI time creeping without an attributable culprit; full-repo builds on every PR; ownership/CODEOWNERS blur once teams exceed ~single-digit count; Google's monorepo (~2B LOC, 25k+ engineers, 40k commits/day) as the existence-proof extreme that requires purpose-built infra (Piper/Bazel) most orgs don't have — retrieved 2026-08-19, via dev.to/elpddev "Six Reasons Your Monorepo CI Got Slower This Quarter" and havenwulf.com "Monorepos at Scale"
- https://github.blog/changelog/2025-11-03-required-review-by-specific-teams-now-available-in-rulesets/ and https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/ — recent (late 2025/early 2026) GitHub ruleset features layering path-scoped required-reviewer rules on top of CODEOWNERS — retrieved 2026-08-19

## Open questions for the user

- **Git workflow strategy (branching model: trunk-based vs. GitFlow vs. GitHub Flow)** surfaced repeatedly while researching merge strategy and branch protection — it's adjacent to "repo settings & governance" but arguably its own cross-cutting topic. Should it be folded into this doc's governance section, or is it one of the other two cross-cutting areas already planned? Flagging because branch protection rules are hard to write correctly without first fixing the branching model they protect.
- **Rulesets vs. classic branch protection rules**: GitHub has been actively pushing "repository rulesets" as the successor to classic branch protection (target-branch patterns, org-level enforcement, bypass lists) with notable features shipping as recently as Nov 2025 and Feb 2026. Should the skill teach rulesets as the primary mechanism (more current, GitHub's stated direction) or branch protection rules (more universally recognized/documented, works identically on older GitHub Enterprise Server versions the user's audience might run)? This materially changes the "table" content for that section.
- **How prescriptive should the monorepo-vs-polyrepo threshold be?** Research did not surface one authoritative numeric threshold (e.g., "N services" or "N engineers") — only qualitative warning signs and case studies at extremes (Google's 25k engineers on one repo vs. typical startup guidance to default to monorepo until it hurts). Do you want the skill to commit to a specific rule-of-thumb number anyway (opinionated, more actionable) or stay qualitative (more defensible, less useful as a checklist)?
- **Scope boundary with "CI/CD gates"**: this doc lists which checks should block vs. warn as a governance topic, but the actual CI/CD pipeline construction is explicitly out of scope here and presumably belongs to a stack-category doc. Confirm that split is what's intended before the human authors — otherwise "block vs. warn" guidance floats without a home for the mechanics.
- **License selection**: should this doc even name specific licenses (MIT/Apache-2.0/etc.) as defaults, or strictly defer to choosealicense.com and treat license *choice* as out of scope, only covering *placement/format* (LICENSE file at root, SPDX identifier)? Current draft treats choice as out of scope — confirm that's correct for a structure-focused doc rather than a legal/licensing doc.
- Non-GitHub platforms (GitLab, Bitbucket, self-hosted Gitea) were not researched — all governance/CODEOWNERS findings above are GitHub-specific. If the skill needs to be platform-agnostic, this section needs a second research pass; if agentskills.io skills are implicitly GitHub-centric, no action needed. Please confirm assumption.

## Applicability note (added post-Checkpoint-A, see skill-flow-decisions.md #3)

A software/non-software top-level fork was added to SKILL.md's routing
logic after this baseline was approved. Root-level files, docs/, and
governance sections apply to both paths. `src/`, `scripts/` (executables),
and `tests/` sections are software-path-specific — Phase 2 authoring must
tag each accordingly (e.g. a non-software project might use `validation/`
in place of `tests/`) rather than silently applying software framing to a
documentation/research repo.

## Resolutions (Checkpoint A review, 2026-08-19)

- **Branching model**: fold into this doc's governance section as a short
  subsection (not a 4th cross-cutting research area) — branch protection
  doesn't make sense without first naming the model it protects.
- **Rulesets vs. classic branch protection**: teach GitHub rulesets as the
  primary/current mechanism; note classic branch protection briefly as the
  older equivalent (still relevant for older GitHub Enterprise Server).
- **Monorepo threshold**: stay qualitative — warning signs only, no
  fabricated numeric threshold.
- **CI/CD gates vs. pipeline mechanics split**: confirmed as scoped —
  block-vs-warn policy stays here, pipeline construction stays in
  stack-category docs.
- **License selection**: this doc covers placement/format only (LICENSE at
  root, SPDX identifier) and links out to
  `skills/project-incubation/assets/license-guide.md` (the chooser table)
  for selection help — reconciles "no legal advice here" with still giving
  the user somewhere to go.
- **Platform scope**: primarily GitHub-centric (matches actual usage);
  concepts (branch protection, required reviews, CI gates) transfer to
  GitLab/Bitbucket but exact syntax/features described are GitHub's.

## Target file(s) + estimated length
- skills/project-incubation/references/project-structure.md — est. 450-600 lines (dense reference doc: several comparison tables, per-ecosystem code-block trees, and templates for README/CHANGELOG/CODEOWNERS/.gitattributes push this longer than prose-only guidance; tables and checklists compress better than paragraphs but the ecosystem-specific examples for Python/Node/Go each need their own directory-tree block)
