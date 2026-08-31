# Grading criteria: retrieval — Frontend / Client Applications

Tests whether `project-incubation` picks the right category using this
category's own defining test — **backend ownership, not tech-stack
shape** — for a mobile app with genuinely no owned backend (only
third-party APIs), and correctly identifies the offline requirement as
this category's own local-first/state-management territory, not a
Business Applications concern.

## Must show

- Selects **Frontend / Client Applications** as the category — the
  prompt explicitly states no owned backend exists or is planned, calling
  only Plaid and a third-party auth provider. This should NOT be treated
  as Business Applications just because it's a real, substantial app.
- Applies the category's own operative test explicitly or implicitly:
  backend ownership (not owned here) is what determines the category,
  not the sophistication or shape of the client code.
- Surfaces **local-first state management** (local storage as the
  primary data layer, not a disposable cache) given the explicit offline
  requirement ("keep working when someone's on a flight with no
  signal... syncing up once they land").
- Names a conflict-resolution strategy for the sync-on-reconnect
  scenario — at minimum, mentions that last-write-wins is the sensible
  default for most app state, reserving CRDTs for genuinely concurrent
  collaborative editing (not relevant here, since this is a single-user
  expense tracker).
- If mobile framework choice comes up, presents React Native vs. Flutter
  as a genuine team-fit decision (not declaring one a clear winner) and,
  if governance comes up, correctly notes React Native's move to the
  new multi-stakeholder React Foundation rather than describing it as
  simply "Meta-owned."

## Should not show

- Treating this as Business Applications and reaching for that category's
  frontend-architecture section (SPA-vs-RSC/App-Router, RBAC/ABAC
  framing) — there is no owned backend here for that framing to apply to.
- Recommending a CRDT-based sync solution as the default for this
  single-user scenario, when LWW is the better-fit default per this
  skill's own decision rule (Figma and Linear both default to LWW at
  production scale).
- Presenting operational transformation (OT) as a live current option for
  a new offline-capable client design.
- Describing React Native as simply "Meta-owned" without the 2026
  governance-transfer correction, if governance comes up at all.
