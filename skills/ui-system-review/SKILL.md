---
name: ui-system-review
description: Audits an existing project for UI system consistency — design tokens, shared components, themes, icon/media libraries, and form-factor adaptation (responsive web; Apple/Android packs when available) — with a scored report and severity-ordered remediation suggestions. Use when reviewing frontend UI consistency, design-system adherence, token drift, mixed component libraries, or responsive/tablet layout discipline.
---

# UI system review

Audit **existing** UI code for system consistency. This is not a subjective
visual critique and not a full WCAG certification.

Ask questions one at a time in plain text. Host-agnostic: no required
browser automation in v0.

## Phase 0 — Scope and stack

1. Confirm target path (repo root or app package in a monorepo).
2. Detect UI stack from manifests and imports (see
   [references/stack-detection.md](references/stack-detection.md)).
3. Confirm with the user which **pack(s)** and **form factors** to score:
   - **Web (v0):** always available when web UI exists — includes responsive
     desktop/tablet/mobile checks.
   - **Apple / SwiftUI:** when signals present — full pack guidance lands in
     v1; until then score only what is evidence-backed and mark deep checks
     Not Implemented if references are not yet loaded.
   - **Android / Compose:** same as Apple until v1.1 pack ships.
4. Ask whether to write/update `docs/ui-system-baseline.md` after the audit.

If the tree has no UI layer, stop and say so.

## Phase 1 — Evidence pass

Gather only repo evidence:

- Package/manifest dependencies and theme entrypoints
- Token definitions (CSS variables, theme objects, asset catalogs)
- Component library import patterns and duplicate primitives
- Icon/image packages and asset layout
- Breakpoint / size-class usage
- Preview/Storybook and lint config if present

**Evidence rule:** every finding needs a path and observable pattern. If you
cannot point to evidence, do not invent drift.

## Phase 2 — Score domains

Score each applicable domain 0–10 using
[references/domains.md](references/domains.md). Apply pack detail:

- Web + responsive → [references/web.md](references/web.md)
- Apple (when pack available) → [references/apple-swiftui.md](references/apple-swiftui.md)
- Android (when pack available) → [references/android-compose.md](references/android-compose.md)

Until Apple/Android reference files are fully authored, still note clear
hardcoding or dual-theme issues on those stacks as Important with evidence,
and mark pack-specific depth as **Not Implemented** rather than guessing.

## Phase 3 — Report

Emit a report following [assets/report-template.md](assets/report-template.md):

1. Context (packs, form factors)
2. Domain scorecard + composite average
3. Findings ordered **Critical → Important → Minor → Not Implemented**
4. **Remediation suggestions** (required): for each Critical/Important item,
   What / Why / Suggested direction / Evidence — concise in v0; no drive-by
   refactors applied by the agent unless the user explicitly asks

## Phase 4 — Baseline (optional)

If requested, write or update `docs/ui-system-baseline.md` from
[assets/baseline-template.md](assets/baseline-template.md): stack, scores,
open items, drift log.

## Boundaries

- Suggest remediations; do not bulk-rewrite the design system unless asked.
- Do not fail the skill if Storybook or token lint is missing — score
  Governance accordingly.
- Defer live browser pixel checks unless the user provides tooling and asks.
- Hand off repo scaffolding and non-UI architecture to `project-incubation`;
  CI gates to `ci-cd-plumber`; PR-sized diffs to `pr-review`.
