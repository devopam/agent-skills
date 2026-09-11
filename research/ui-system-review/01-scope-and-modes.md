# Scope and modes

## Name

**`ui-system-review`** — codebase UI *system* consistency (not open-ended UX research).

## In scope

- Design-system / component-library presence and actual **usage**
- Design **tokens** vs hardcoded colors, spacing, type, radius
- **Theme** / light-dark / brand configuration
- **Duplicate or parallel** primitives (two Button systems, mixed icon packs)
- Icon and image library conventions
- **Form factors:** responsive web; phone vs tablet patterns on Apple/Android when those packs apply
- Code-visible **accessibility** footguns (labels, semantics, min touch targets where inferable)
- Governance: Storybook/previews, lint for tokens, baseline doc
- **Ordered remediation suggestions** (v0: concise; later: deeper playbooks)

## Out of scope

- Subjective aesthetics (“is this beautiful?”)
- Full Figma file audits (optional attachment later, not required)
- Live visual regression as a hard dependency (optional if browser tools exist)
- Implementing redesigns (suggest only; same boundary as other skills)
- Backend / API design

## Modes

| Mode | Trigger |
|------|---------|
| **Audit** (default) | Existing app with UI code |
| **Baseline close-out** | Optional write/update `docs/ui-system-baseline.md` after audit |
| **Inception (light)** | Near-empty UI — recommend system choices only; hand off deep scaffolding to project norms |

Detect stack → confirm with user → load pack references → score domains → findings by severity → remediation section → optional baseline.

## Report shape (aligned with ci-cd-plumber / python-code-review)

1. Context (stack pack(s), form factors in scope)
2. Domain scorecard 0–10 + composite
3. Findings ordered Critical / Important / Minor / Not Implemented
4. **Remediation suggestions** (priority-ordered; v0 short; later expandable)
5. Baseline close-out if requested

## Evidence rule

Every finding needs **file-level evidence** (path, pattern, import, or count). No evidence → do not invent inconsistency.
