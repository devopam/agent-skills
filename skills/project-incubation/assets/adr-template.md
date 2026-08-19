<!--
Architecture Decision Record template. Copy this file to
docs/adr/000N-short-slug.md in the target repo (zero-padded, sequential
per repo — 0001, 0002, ...), fill in the blanks, delete the HTML
comments as you go, and delete this top comment last.

Format: Nygard's 2011 ADR shape (Title/Status/Context/Decision/
Consequences), the reference approach Fowler endorses. Two repo
examples of this exact shape in production use: MCPg's
docs/adr/0001-build-approach.md (scored Options-considered table) and
docs/adr/0002-technology-stack.md (flat Concern/Choice/Notes table).

Golden rule: an accepted ADR is immutable. If the decision changes
later, do not edit the Decision or Consequences sections of this file —
write a new ADR instead, and come back here only to update the Status
line (see below). The record of *why* the original call was made stays
intact for whoever reads it next.
-->

# ADR-000N: <short, specific decision title>

- **Status:** proposed
- **Date:** YYYY-MM-DD
- **Deciders:** <names or roles>

<!--
Status lifecycle: proposed -> accepted -> (optionally) superseded.

When a later ADR replaces this decision, do NOT rewrite Decision or
Consequences below. Instead:
  1. Change the Status line to:
     **Status:** superseded by [ADR-000N](000N-new-slug.md) (YYYY-MM-DD)
  2. Add a short block-quote note directly under it, e.g.:

> **Superseded.** <One sentence on what replaced this and why.> See
> [ADR-000N](000N-new-slug.md). The original rationale below is kept as
> the record of the original decision.

  Everything else in the file stays exactly as originally written.
-->

## Context

<!--
What forces are actually in play — technical constraints, team
constraints, prior decisions this builds on, business pressure, a
deadline, a security finding. Write it so someone with none of today's
context can follow the reasoning a year from now. If this decision only
makes sense given an earlier ADR, name it explicitly ("ADR-0003 commits
to X; this ADR picks the Y that's compatible with it").
-->

<!-- delete-me: 2-5 sentences is normal. If Context needs subsections, the
decision is probably too big for one ADR — consider splitting it. -->

## Options considered

<!--
Score the real options you actually evaluated against criteria that
matter for THIS decision — not a generic checklist copied between ADRs.
Keep the criteria identical across every option so the comparison is
honest, and make sure the option that wins is the one the Decision
section below actually picks.
-->

| Option | <criterion 1, e.g. "operational cost"> | <criterion 2> | <criterion 3> | Verdict |
|---|---|---|---|---|
| 1. <option name> | | | | |
| 2. <option name> | | | | |
| 3. <option name> | | | | |

<!--
delete-me: for a narrower stack/tooling choice (language, library,
storage engine) rather than an architectural fork, a flat decision
table often reads cleaner than scored options. Swap the table above for:

| Concern | Choice | Notes |
|---|---|---|
| <concern, e.g. "language"> | <choice> | <why, and what was rejected> |
| <concern> | <choice> | <why, and what was rejected> |

Either shape is fine — pick whichever makes THIS decision legible, and
delete the one you don't use.
-->

## Decision

<!--
State the choice in one sentence. Then say, in a sentence or two per
losing option, why each alternative lost — reference the Options-
considered table above by option number rather than re-explaining it.
If the decision has a non-obvious scope boundary (e.g. "we adopt X, but
only for subsystem Y, not the whole codebase"), state the boundary here
explicitly — that's usually the detail someone re-reads this ADR to
find.
-->

## Consequences

<!--
Be honest about cost, not just benefit — a Consequences section that's
all upside reads as unreviewed. "Follow-up" should link a tracked
issue/roadmap item where one exists, not just gesture at future work.
-->

- **Easier:** <what this decision unlocks or simplifies>
- **Harder:** <what this decision costs, defers, or complicates>
- **Follow-up:** <tracked work this creates, with a link if one exists>
