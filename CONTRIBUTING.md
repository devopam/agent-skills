# Contributing

## Adding a new skill

Each skill lives at `skills/<skill-name>/`, following the
[Agent Skills spec](https://agentskills.io/specification):

```
skills/<skill-name>/
├── SKILL.md          # required: name + description frontmatter, instructions
├── references/       # optional: reference docs, loaded on demand
├── scripts/           # optional: executable code
└── assets/            # optional: templates, resources
```

Conventions this repo follows for every `SKILL.md` (based on
`superpowers:writing-skills` and Anthropic's Agent Skills best practices):

- **Frontmatter stays spec-minimal**: `name` (letters/numbers/hyphens, ≤64
  chars) and `description` only. No host-specific fields (no `triggers`,
  `allowed-tools`, etc.) — skills here must work on any compliant client, not
  just Claude Code.
- **`description` states what it does, then when to use it** — one clause of
  capability, one clause of "Use when [triggers]." Never narrate the skill's
  internal workflow/steps in the description; doing so causes agents to
  short-circuit past the actual instructions instead of reading them.
- **SKILL.md is a router, not an encyclopedia.** Keep it under ~500 lines.
  Anything that's genuine reference depth belongs in `references/`, linked
  inline at the exact point in SKILL.md where that reference becomes
  relevant — not dumped in a "see also" list at the end.
- **`references/` stays one level deep.** No nesting references inside
  references. Files over ~100 lines get a table of contents at the top.
  Name files by their content, not `doc1.md`/`notes.md`.
- **Use plain-text interaction, not host-specific tools**, unless a skill
  explicitly documents itself as host-specific. Assume the agent can only
  read instructions and ask the user questions one at a time in prose.

## Research-before-authoring

Skills whose reference content requires curating external, time-sensitive
knowledge (established patterns, recommended libraries, etc.) go through a
research phase before any `references/*.md` file is written:

1. Research each topic area using live sources (WebSearch/WebFetch) —
   never from model memory alone, since libraries and best practices move
   faster than any model's training cutoff.
2. Write a structured **coverage baseline** per area (scope, explicit
   non-scope, sources with retrieval dates, target file + estimated length)
   under a temporary `research/` directory at the repo root, mirroring the
   target `references/` tree. This baseline stays at scope-level — what's
   in/out and why, not yet the fully fleshed-out recommendation.
3. Get the baseline reviewed and approved (expand/modify as needed) before
   authoring the corresponding `references/*.md` file.
4. **Authoring is itself a second, deeper research pass — not a rewrite of
   the baseline's notes into prose.** Every recommendation that makes it
   into a `references/*.md` file gets its own concrete, specific backing:
   named tools/patterns/thresholds rather than generic advice, real
   worked examples where one exists, and honest trade-offs — the goal is a
   skill that gives an agent (and the humans it's guiding) an actionable
   mandate, not a survey. A generic reference doc that could apply to any
   project is a sign the authoring pass didn't go deep enough. Where a
   recommendation genuinely differs by project shape (e.g. a
   documentation/research-only project vs. a software project, or by
   project scale), say so explicitly rather than defaulting to one
   generic answer.
5. Once content is authored and committed, delete the promoted baseline from
   `research/` — but carry its key citations forward into the authored file's
   own **Sources** section, so provenance survives the cleanup.

## Versioning

This repo follows [Semantic Versioning](https://semver.org/) at the
repo/plugin level (`.claude-plugin/plugin.json`'s `version` field):

- **Patch** (`0.1.x`): wording fixes, added sources/citations, corrected
  library entries that don't change recommended structure or flow.
  - **Minor** (`0.x.0`): new reference file, new stack category, new
    meaningfully-scoped section within an existing skill.
  - **Major** (`x.0.0`): breaking changes to a skill's flow (e.g. the
    inception/audit Q&A structure changes in a way that invalidates existing
    baseline records written by a prior version).

Record every change in [CHANGELOG.md](CHANGELOG.md) under `[Unreleased]`
until it's tagged.

## Validation

Before considering a skill change done:

```bash
claude plugin validate . --strict
```

For skills with an `evals/` suite:

```bash
claude plugin eval <path> --no-publish --runs 1
```

Never publish eval reports (`--no-publish` is the default expectation here)
without explicit sign-off — publishing sends results to claude.ai.
