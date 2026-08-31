# Baseline: Frontend / Client Applications — Architecture & Stack
Status: draft      Date: 2026-08-31

## Category definition (working boundary)

A **pure client application with no owned backend of its own** — a web SPA,
mobile app, or desktop app whose only backend interaction is calling a
third-party or platform-hosted API (a SaaS API, an auth provider, a payment
processor, a public/partner API) that a different team or company owns and
deploys. Examples: a mobile app that only calls Stripe and a third-party
auth provider directly, with no first-party backend at all; a desktop
Electron/Tauri app that syncs to a hosted service it doesn't operate; a SPA
that is purely a client of someone else's API. This is the last of the 10
project-incubation stack categories (see `research/taxonomy-roadmap.md`).

## Local precedent

`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/` — inspected
directly this pass (`package.json` read in full, `src/` structure
enumerated, `src/services/` read, `public/manifest.webmanifest` and
`public/sw.js` read in full). This is real, substantial frontend-engineering
evidence: React 19.2 + TypeScript + Vite 7 + Ant Design v5 (`antd` 5.27) +
TanStack Query v5.90 + Okta auth (`@okta/okta-auth-js` v8, `@okta/okta-react`
v6), a Lexical rich-text editor stack (`lexical` + `@lexical/*` v0.45, plus
a separate Jodit HTML editor), Tailwind v3, `docx`/`docx-preview`/`mammoth`/
`exceljs`/`jspdf` document-processing libraries, and a real feature-based
`src/` structure (`features/`, `pages/`, `services/`, `router/`, `auth/`,
`context/`, `hooks/`, `components/`). `src/services/` holds `api.ts`,
`endpoints.ts` (111KB — a large endpoint map), and `queryClient.ts` (58KB) —
a sizable API-client-plus-TanStack-Query integration layer.

It is also, confirmed by direct read, a PWA: `public/manifest.webmanifest`
declares `display: standalone` with real install icons. But `public/sw.js`
is a **minimal, explicitly non-offline service worker** — its own top-of-file
comment states this precisely: `/** Minimal service worker — enables PWA
install; no offline cache (enterprise app). */`. The worker's `fetch`
handler does nothing but pass every request straight through to the network
(`event.respondWith(fetch(event.request))`) — no cache-first/
stale-while-revalidate strategy, no offline fallback, no background sync.
This is a genuinely useful, honest local data point: a real enterprise React
app adopted PWA *installability* mechanics without adopting offline-first
*data* architecture — the two are independently adoptable, not a package
deal — and the repo's own code comment names the reason (an assumed-always-
online "enterprise app") rather than this doc inferring it.

**Applying this category's own scoping nuance precisely: `ubi-csr-tmf` is
not an instance of Frontend / Client Applications.** The same repo,
independently confirmed this pass — `aws/container/` contains sibling
`agents/`, `backend/`, `frontend/` directories, and the repo-root `charts/`
directory holds `agents`, `ubi-backend`, `ubi-frontend` Helm charts — owns a
real backend (`aws/container/backend/`: a FastAPI-shaped `app/`, Alembic
`migrations/`, its own `Dockerfile`) alongside this frontend. Per this
category's own defining boundary (a pure client with **no owned backend**),
`ubi-csr-tmf` as a whole project is Business-Applications-shaped — it owns
both a backend and a UI end-users interact with directly, exactly matching
that category's own SKILL.md description ("anything owning both a backend
and a UI end-users interact with directly"). This frontend directory is
real, current, useful frontend-engineering evidence (confirms React 19,
TanStack Query v5, Vite 7 as genuinely current choices) but it is evidence
from a project whose overall shape is Business Applications, **not a worked
example of this category's own defining constraint** (a backend-less
client). Stated this way deliberately rather than forced into being
something it isn't.

`/Users/devopammittra/GitHub/agent-skills` (this repo) — checked for
completeness: a `find` for `*.tsx`/`*.jsx` across the tree and a directory
listing turn up nothing. This is a prompt-only Claude Code plugin repo
(`skills/`, `research/`, `evals/`, markdown/JSON only) — no frontend code of
any kind. Expected, noted briefly rather than skipped.

No other local repo was found with a genuinely backend-less client shape
(a mobile app calling only a third-party API, a standalone Electron/Tauri
app with no first-party backend, a SPA with no owned API). Flagged as an
open question below, consistent with the Business Applications baseline's
own precedent of surfacing "no local repo matched this category" rather
than silently leaning on external sources without saying so.

## Explicitly out of scope

- **Anything owning both a backend and a UI — Business Applications'
  territory (already shipped)**, precisely per that category's own
  SKILL.md description ("SaaS/enterprise CRUD apps, admin/back-office
  tools, anything owning both a backend and a UI end-users interact with
  directly") and its own baseline's category definition ("a persistent
  database, a UI that end-users and business operators directly interact
  with, and typically both a backend AND a frontend under one product").
  **The operative test to carry into the authored doc**: does this
  project's own repo/team own and deploy a backend? If yes — even when the
  frontend half of that project looks architecturally identical to a "pure"
  frontend project (same React+Vite+TanStack Query shape, same
  component/feature-folder structure) — the project as a whole is
  Business-Applications-shaped, and that category's own frontend-
  architecture section (SPA-vs-RSC/App-Router choice, RBAC/ABAC,
  multi-tenancy-aware frontend concerns) already owns that frontend's
  guidance; this doc does not re-derive it. If no — the backend is someone
  else's system, called over the network as a black-box dependency — the
  project is this category's, and this doc's value-add is precisely the
  set of concerns that exist *only because* there's no co-located backend
  to lean on: client-side storage as the *primary* (not secondary-cache)
  data layer, offline/sync architecture with real conflict resolution,
  app-store distribution mechanics, and no server-side architecture-
  template question to answer at all. A worked example worth carrying
  forward (this doc's own local-precedent finding): a React+Vite+TanStack
  Query SPA calling `/api/*` on a FastAPI backend the same team owns and
  deploys is Business Applications, full stop, even though nothing about
  its component tree or state-management code looks different from a SPA
  calling a third-party API. A React Native app whose only backend
  interaction is calling Stripe's API and a third-party auth provider
  directly, with no first-party backend of its own, is this category. The
  line is about **backend ownership**, not frontend tech-stack shape or
  architectural sophistication.
- **Generic frontend state-management and component-architecture guidance
  already covered by Business Applications** (server-state-caching-over-an-
  owned-API framing, SPA-vs-RSC/Next.js-App-Router choice, general
  component patterns) — this doc names only what's genuinely *different*
  when there's no owned backend to cache against (see In-scope below), not
  a restatement of general frontend engineering practice that applies
  either way.
- **Backend-side concerns of any kind** — API design, database selection,
  server-side auth issuance, billing/entitlement backend logic — all
  belong to whichever category owns the backend the client happens to call
  (most commonly Backend & API Services or Business Applications, from the
  perspective of *that* project, not this one). This category's project,
  by definition, does not own that backend.
- **Deep native-mobile-platform API guidance** (Swift/SwiftUI-specific or
  Kotlin/Jetpack-Compose-specific idiomatic detail for fully-native, non-
  cross-platform apps) — this doc's mobile section stays at the native-vs-
  cross-platform decision-axis level, not a platform-specific deep dive;
  fully-native development is named as a real option but not exhaustively
  covered.
- **Specific tool/library version pins, license comparisons, and adoption-
  signal tables beyond what's needed to establish a claim's currency** —
  belongs to the companion `libraries.md` baseline being produced in
  parallel. This doc names a tool only where its own documented behavior
  *is* the architectural fact being described (e.g. Flutter's official
  repository-pattern guide, MSW's network-interception mechanism, Figma's
  documented LWW choice) — illustrative anchors for a pattern, not this
  doc encroaching on `libraries.md`'s comparative job.
- **Cost modeling / app-store fee structures** (Apple's 15%/30% commission
  tiers, Google Play's fee schedule) — same no-cost-modeling convention as
  every other baseline in this repo.
- **Push notification infrastructure, deep-linking, and analytics/crash-
  reporting SDK selection** — real client-app concerns, but not
  distinctively *architectural* in the way state management, sync, and
  distribution mechanics are; flagged as a possible future gap rather than
  silently covered (see Open questions).

## In scope

- **State management for a backend-less client: local storage as the
  primary data layer, not a secondary cache** — impact: high — depth:
  section. The category-defining reframe, distinct from Business
  Applications' own server-state-caching-over-an-owned-API framing (React
  Query/TanStack Query treating the client cache as a *derived,
  disposable* copy of a backend the team controls and can always re-query
  cheaply). Here there is no such backend to treat as ground truth on
  demand — the local store frequently **is** the primary place the
  application's data lives, synced opportunistically to a remote service
  the app doesn't own. **"Local-first software" is a real, current, named
  movement**, not an assumed-to-exist philosophy — anchored on direct
  fetch of the canonical Ink & Switch essay (Kleppmann, Wiggins, van
  Hardenberg, McGranaghan, "Local-first software: You own your data, in
  spite of the cloud," Onward! 2019/SPLASH). Its seven ideals, worth
  carrying forward precisely: **(1) no spinners** — the UI responds
  instantly because it reads local data, not a network round-trip; **(2)**
  work is not trapped on one device; **(3)** the network is optional, not
  load-bearing for basic operation; **(4)** seamless real-time
  collaboration when online; **(5)** "the long now" — data outlives the
  vendor/service; **(6)** security and privacy by default; **(7)** the
  user retains ultimate ownership and control of their data. The
  architectural consequence for this doc: the local device copy is
  primary and the server is a secondary/sync target — the **inverse** of
  the owned-backend model Business Applications already covers.
  **Current client-side database landscape**, GitHub-API-verified
  (`api.github.com/repos/...`, retrieved 2026-08-31, all figures current
  as of that date): **RxDB** — 23,371 stars, Apache-2.0, pushed same-day
  (actively maintained), positioned (search-corroborated) as the most
  comprehensive option — multi-backend sync, CRDT support, encryption;
  **Dexie.js** — 14,551 stars, Apache-2.0, pushed 2026-08-28, a thin
  IndexedDB wrapper, lightest to adopt, with an optional Dexie Cloud sync
  add-on; **PouchDB** — 17,603 stars (now governed under `apache/pouchdb`,
  Apache Software Foundation), Apache-2.0, pushed 2026-08-25, the oldest
  of the group, CouchDB-replication-native; **WatermelonDB** — 11,778
  stars, MIT, pushed 2025-08-11 — worth flagging honestly that this is
  roughly a year stale relative to the other three as of this doc's
  retrieval date, a real maintenance-cadence signal, not a reason to
  exclude it outright (it remains a real, mobile/React-Native-specialist
  option built on native SQLite for at-scale performance). Specific
  head-to-head tool comparison and current recommendation belongs to
  `libraries.md`; this doc's own claim is narrower — that this whole
  *category of primary-local-store libraries* is real, current, and
  actively maintained, not a niche or stale approach.

- **Offline-first / sync architecture: the concrete problem and current
  conflict-resolution landscape** — impact: high — depth: section. The
  concrete problem this doc's task framing named: a client needs to
  function with zero or intermittent connectivity, and reconcile local
  changes against a remote source once connectivity returns. Three
  real conflict-resolution strategies, with current maturity verified
  rather than assumed from stale knowledge: **(1) Last-write-wins (LWW)**
  — the simplest strategy, adequate when conflicts are rare or low-stakes
  at field granularity, but it silently drops one side of a concurrent
  write to the same field with no reconciliation. **(2) Operational
  Transformation (OT)** — still live in centrally-coordinated systems
  (Google Docs' historical architecture) but the current (2026) consensus
  across multiple sources is that new offline-first/decentralized designs
  are not choosing OT: it requires a central server to mediate transform
  ordering, which is precisely the single point this category's clients
  can't always reach. **(3) CRDTs (Conflict-free Replicated Data Types)**
  — GitHub-API-verified current activity (retrieved 2026-08-31): **Yjs**
  — 22,728 stars, pushed 2026-08-06, dominant for text/rich-text
  collaborative editing; **Automerge** — 6,545 stars, MIT, pushed
  2026-08-28, a richer JSON-CRDT with a `Peritext` rich-text CRDT and an
  explicit local-first design lineage (Kleppmann, the local-first essay's
  own lead author, is a maintainer); **Loro** — 6,102 stars, MIT, pushed
  2026-08-29, a newer, high-performance entrant. **A genuinely important,
  concrete current finding worth naming precisely: Replicache is
  archived** — GitHub-API-confirmed `archived: true`, 1,173 stars, last
  push 2022-05-07 — its own team (Rocicorp) has moved on to **Zero**
  (`rocicorp/mono`, 3,375 stars, Apache-2.0, pushed same-day as this
  doc's retrieval), a sync engine rather than a client-embedded CRDT
  library. **ElectricSQL** — 10,346 stars, Apache-2.0, pushed 2026-08-27
  — is the leading current "sync your existing Postgres to the client"
  primitive rather than a CRDT library per se; reached 1.0 GA in March
  2025 (search-corroborated) with a v1.1 release in August 2025 adding a
  custom storage engine claimed 102x faster on writes (search-
  corroborated, not independently benchmarked this pass). **Two concrete,
  directly-fetched real-world case studies worth naming as the doc's
  worked examples**, because they show the decision is not "always reach
  for CRDTs": **Figma** (direct fetch of
  figma.com/blog/how-figmas-multiplayer-technology-works/) explicitly
  *rejected* both textbook OT (too complex/combinatorial for their case)
  and textbook CRDTs (unneeded decentralization overhead, since Figma's
  own server is already a central authority) — they landed on **per-
  property last-writer-wins over a tree-of-objects document model**,
  quoting Evan Wallace's own design principle of using "no more complex
  [a strategy] than necessary." **Linear**'s sync engine (secondary-source
  analysis only — Linear's own primary post is a talk-landing page with no
  substantive text, flagged honestly as not independently verified from
  Linear's own words) reportedly uses IndexedDB as the local store, a
  normalized in-memory object graph, and **LWW as the default** conflict
  strategy because conflicts are rare in their issue-tracking domain —
  with CRDTs adopted only narrowly, for issue-description rich text
  specifically, not as a blanket strategy. **Decision rule to carry into
  the authored doc, synthesized from the above rather than a single
  source**: LWW is the correct default for most app state where per-field
  concurrent edits are rare and a small amount of silent overwrite risk is
  acceptable (Figma and Linear both confirm this at real production
  scale); reach for a CRDT specifically for the sub-domains where true
  concurrent collaborative editing on the *same* structure is a named
  requirement (rich text being the most common case, per Yjs's and
  Automerge's own dominant use case) rather than adopting a CRDT
  wholesale for an entire application's state; OT is not the right choice
  for a new backend-less/offline-capable client design in 2026.

- **App-store distribution mechanics — a genuinely distinct constraint no
  other project-incubation category has** — impact: high — depth: section.
  A web service or backend API can deploy instantly; an app-store-
  distributed client cannot, and this doc names the mechanics precisely.
  **Apple App Store**: direct fetch of developer.apple.com/distribute/
  app-review/ states "on average, 90% of submissions are reviewed in less
  than 24 hours"; an expedited-review path exists (via a contact form) for
  critical bug fixes or event-tied launches, with Apple's own stated
  caveat that overusing expedited requests gets deprioritized. Search-
  corroborated real-world commentary suggests complex or policy-flagged
  apps can see multi-day review in practice — flagged as anecdotal, not
  vendor-confirmed, worth naming as a real-world caveat on the vendor's
  own 90%-in-24-hours figure. **Google Play**: could not direct-fetch a
  Google-owned page stating a specific SLA number this pass (the
  play.google.com/console policy URL attempted returned a 404); search-
  corroborated community consensus is 1-3 business days for standard
  updates, longer (a week or more) for new developer accounts or policy-
  sensitive apps — flagged honestly as search-corroborated only, not a
  vendor-stated figure the way Apple's is. Google Play's **staged
  rollout** mechanic is direct-fetch confirmed (support.google.com/
  googleplay/android-developer/answer/6346149): the developer sets an
  arbitrary custom percentage of users who receive an update first; the
  percentage does not auto-increase, a manual/scripted ramp is the
  developer's own responsibility. **The concrete architectural
  consequence — OTA update mechanisms that bypass full app-store review**:
  Microsoft's App Center, including its CodePush service, **shut down
  March 31, 2025** (search-corroborated across multiple current sources);
  the current (2026) replacement for React Native / Expo teams is
  **EAS Update**, Expo's own hosted OTA service, which ships only
  JS/asset-bundle updates (no native code) — direct-fetch of
  docs.expo.dev/eas-update/introduction confirms this is Expo's current
  first-party recommendation. Apple's own App Store Review Guideline
  3.3.1 permits interpreted-code (JS bundle) updates but explicitly
  forbids using that mechanism to ship features that would otherwise have
  required a new binary review — the `runtimeVersion` fingerprint-policy
  mechanism (search-corroborated as the 2026-recommended binary/JS
  compatibility contract) exists specifically to keep an OTA JS bundle
  matched to the native binary it was built against, not to smuggle
  unreviewed native functionality past app-store review. **Desktop is
  materially less store-gated than mobile**: Mac App Store distribution
  requires sandboxing and review; **direct distribution (Developer ID)
  requires notarization** (Apple's automated malware scan) plus Hardened
  Runtime instead, with no sandbox requirement and no app-store review
  delay at all — search-corroborated across several current developer
  writeups, not confirmed against one single official Apple page covering
  the full framing this pass, flagged honestly as such. This is the real
  structural fact worth carrying forward precisely: **release cadence and
  rollback speed are fundamentally different constraints for this
  category** than for any server-side category in this skill — a backend
  service deploys and rolls back in minutes; a mobile-app-store release
  has a review-latency floor measured in hours-to-days even in the best
  case, and any rollback of a *native* code change requires a full new
  submission and review cycle, not a redeploy.

- **Mobile: native vs. cross-platform as a genuine decision axis** —
  impact: high — depth: table. GitHub-API-verified current momentum
  (retrieved 2026-08-31; note React Native's canonical repo has moved to
  the `react` GitHub org, i.e. `react/react-native`, reflecting the
  broader 2026 reorganization of React-family repos under a dedicated
  `react` org — a real, verifiable, current fact worth naming): **React
  Native** — 126,463 stars, 25,234 forks, 1,170 open issues, MIT, pushed
  same-day; **Flutter** — 178,730 stars, 31,033 forks, 13,210 open
  issues, BSD-3-Clause, pushed same-day. Flutter leads on raw stars;
  React Native shows notably fewer open issues (not conclusive on its
  own — could reflect different triage practices rather than lower defect
  volume). **A genuinely current, high-impact architectural shift worth
  naming precisely**: React Native's **New Architecture** (Fabric render
  pipeline, TurboModules, the JSI bridge replacement) is now the
  *mandatory default*, not an opt-in — search-corroborated across
  multiple 2026 sources: the old-architecture opt-out was removed in RN
  0.82, and the legacy bridge is being deleted entirely in 0.83; Expo SDK
  55+ runs entirely on the New Architecture; adoption signals cited
  (~83% of SDK 54 EAS-built projects and ~85% of popular npm RN packages
  New-Architecture-compatible as of January 2026) are search-corroborated,
  not independently direct-fetched this pass. **Real discriminators,
  not "it depends"**: Flutter renders its own UI via its own engine
  (historically Skia, now transitioning toward Impeller) rather than
  mapping to native platform widgets — this buys pixel-perfect UI
  consistency across iOS/Android/desktop/web from one codebase, at the
  cost of not automatically picking up native platform look-and-feel
  changes. React Native, via the New Architecture's Fabric renderer,
  maps to actual native platform widgets/components — closer native
  look-and-feel and easier native-module interop, at the cost of some
  cross-platform visual inconsistency. Language: Flutter is Dart-only;
  React Native is JS/TypeScript, the same language as most existing web
  frontend codebases, a real onboarding-cost discriminator for a team
  that already has a JS/TS web frontend. Survey-based adoption figures
  (Stack Overflow 2025-style comparisons circulating in 2025/2026 blog
  posts) were **not independently verified** against Stack Overflow's own
  primary results page this pass and are excluded from this baseline
  rather than cited as verified current data — a real gap flagged
  honestly, not silently papered over with a plausible-sounding number.

- **Desktop: Electron vs. Tauri as a genuine decision axis** — impact:
  high — depth: table. GitHub-API-verified (retrieved 2026-08-31):
  **Electron** — 122,819 stars, 17,453 forks, 751 open issues, MIT,
  pushed same-day; **Tauri** — 110,704 stars, 3,910 forks, 1,458 open
  issues, Apache-2.0, pushed same-day — both large, current, actively
  maintained projects, not a mature-vs-experimental split the way this
  comparison might have read a few years ago. **Tauri 2.0's stability is
  direct-fetch confirmed**: the stable 2.0 release shipped 2024-10-02
  (v2.tauri.app/blog/tauri-20/), well-established as of this doc's 2026
  retrieval date, not a bleeding-edge/pre-1.0 concern any more. **The
  real, verifiable architectural discriminator**: Tauri uses the
  operating system's own native WebView (WebView2 on Windows, WKWebView
  on macOS, webkitgtk on Linux) plus a Rust backend, instead of Electron's
  approach of bundling a fixed version of Chromium plus a Node.js runtime
  with every app. This cuts both ways and both sides are worth naming
  precisely: Tauri's approach means the app doesn't ship its own browser
  engine (a real, structural reason to expect a smaller installer and
  lower baseline memory footprint), but it also means **rendering
  behavior varies by the end user's installed OS WebView version** — a
  genuine cross-platform rendering-consistency risk Electron does not
  have, since Electron ships one pinned Chromium build identically on
  every platform. **Bundle-size and memory numbers require an honesty
  flag**: official Tauri docs (direct fetch of tauri.app/start/) state
  only that "a minimal Tauri app can be less than 600KB" and make **no
  official numeric Electron comparison**; the widely-repeated figures
  circulating in blog posts (roughly "3-10MB Tauri vs. 120-200MB Electron"
  installer size, "30-40MB vs. 200-300MB" RAM) are third-party/vendor-
  adjacent claims only, not independently benchmarked by this pass or
  traceable to a neutral primary source — named here explicitly as
  **unverified** rather than presented as settled fact, the same
  discipline this repo's other baselines apply to unsourced statistics.
  **Native-API-access tradeoff, stated honestly**: Electron's much larger,
  longer-established plugin/native-module ecosystem is a real current
  advantage for apps needing broad native-API surface coverage; Tauri's
  Rust-backend model is newer but growing and offers a memory-safe
  systems language for native-side code, at the cost of a smaller
  (though real and current, per the star counts above) plugin ecosystem
  to draw on versus reimplementing a native integration from scratch.
  **Decision rule to carry into the authored doc**: Tauri is the right
  default when installer size and baseline resource usage are named
  constraints and the team can tolerate (or explicitly test against) OS-
  WebView rendering variance; Electron remains the right default when
  broad native-module/plugin-ecosystem coverage or guaranteed identical
  rendering across every user's machine matters more than footprint.

- **Why this category has no server-side architecture-template question
  to answer at all, and what client-side pattern replaces it** — impact:
  high — depth: section. `research/architecture-templates.md`'s whole
  pattern catalog (layered, hexagonal/ports-and-adapters, microservices,
  modular monolith, event-driven, CQRS, serverless) is explicitly a
  **deployment-topology** decision — which of several ways to structure
  and deploy a *server-side* system. A pure client app in this category
  has, by construction, no server component of its own and therefore no
  deployment topology to choose in that sense at all — there is nothing
  analogous to "should this be a modular monolith or microservices"
  because there is no backend being built here to apply that question to.
  **But hexagonal/ports-and-adapters does have a genuine, currently-
  documented client-side analogue, verified via two authoritative,
  currently-live official sources rather than assumed to exist**:
  **Flutter's own official app-architecture guide** (direct fetch,
  docs.flutter.dev/app-architecture/guide) defines an explicit layered
  shape where **"Services"** wrap raw network/platform API endpoints and
  **"Repositories"** consume one or more services and transform their raw
  data into the app's own domain models, with the explicit rule that
  "Repositories should never be aware of each other" and that
  ViewModels/UI code depend only on repositories, never on services
  directly. **Android's own official architecture guidance** (direct
  fetch, developer.android.com/topic/architecture) defines the same
  shape in its own terms: a data layer made of repositories, each
  wrapping zero-to-many data sources (network, local DB, files),
  explicitly framed as "abstracting sources of data from the rest of the
  app." Both are real, current, first-party platform guidance — not a
  community-invented analogy forced onto client code. **A parallel,
  real-but-less-standardized convention exists in the React/web
  ecosystem**: ports (interfaces) defining an API contract, adapters
  (HTTP-client implementations) satisfying that contract, wired into
  components via dependency injection through context — decoupling
  business logic and UI from the specific REST/GraphQL/SDK shape of
  whichever backend the client happens to call. Concrete current
  implementations exist (search-corroborated: `juanm4/hexagonal-
  architecture-frontend`, `Maua-Dev/hexagonal_arch_react_template`, and
  a commonly-cited "Hexagonal-Inspired Architecture in React" writeup
  whose direct fetch was blocked by a 403 this pass, flagged as search-
  snippet-only) but this is a **community convention** (often called
  "repository pattern," "API-client abstraction layer," or "hexagonal-
  inspired"), not an official, standardized pattern the way Flutter's and
  Android's own guidance is — an honest confidence-level distinction
  worth preserving in the authored doc. **The concrete payoff, stated
  precisely, is exactly what the task framing asked to verify**:
  abstracting the specific backend API a client talks to behind an
  interface means swapping API providers, or mocking the API entirely for
  tests, doesn't ripple through the UI/business-logic layer — the same
  reasoning the cross-cutting architecture-templates.md doc already gives
  for server-side hexagonal architecture, now confirmed as a real,
  officially-documented pattern applied to a client's own outbound
  dependency on a backend it doesn't own, rather than to a server's
  outbound dependency on a database or message broker.

- **Testing approaches distinct to this category — a UI-only client with
  no backend to spin up for integration tests** — impact: high — depth:
  section. Three genuinely distinct layers, each anchored on current,
  mostly directly-fetched sources. **Component testing**: Storybook's
  interaction-testing feature (play functions plus Testing Library's
  `userEvent`, with Vitest/`@testing-library/jest-dom` assertion
  integration) is current, actively documented first-class practice as
  of Storybook 10.5 (direct fetch, storybook.js.org/docs/writing-tests/
  interaction-testing), with documented CI-integration guidance —
  GitHub-API-verified Storybook itself remains large and active (90,973
  stars, pushed same-day as this doc's retrieval). **Visual regression
  testing**: Chromatic (Storybook's own first-party visual-testing
  product, auto-capturing and pixel-diffing screenshots per commit across
  browsers/viewports/themes) is the natural current fit specifically
  because it works at the *component* level rather than needing a full
  running app-plus-backend (search-corroborated, not independently direct
  -fetched this pass); Percy (BrowserStack) is a live current alternative,
  with a late-2025 AI-assisted visual-review-agent addition claimed to
  reduce false positives (search-corroborated); Playwright's own built-in
  `toHaveScreenshot()` visual comparison is direct-fetch confirmed
  current (playwright.dev/docs/test-snapshots) — golden-file generation,
  a configurable `maxDiffPixels` tolerance, and an explicit documented
  caveat that OS/hardware/rendering variance affects screenshot
  consistency across machines, a real CI-reproducibility concern worth
  naming (e.g. running visual-comparison CI jobs in one pinned container
  image rather than on heterogeneous runners). **End-to-end testing
  against a mocked/stubbed backend rather than a real one** — the
  structurally distinct testing need this category has that a
  full-stack project doesn't (a full-stack project can spin up its own
  real backend for integration tests; this category's project, by
  definition, doesn't own the backend it calls, so it cannot). **Mock
  Service Worker (MSW)** is direct-fetch confirmed (mswjs.io/docs) and
  GitHub-API-verified as the current, mature, actively-maintained
  standard for this: 18,173 stars, MIT, not archived, pushed 2026-07-24,
  only 41 open issues — a healthy current project. MSW does true
  network-level request interception (a real Service Worker in the
  browser; a Node-level class-extension mechanism in test/server
  environments), explicitly marketed by its own docs as providing "a
  single source of truth for network behavior" reusable across local
  dev, integration tests, E2E tests, and Storybook — directly matching
  this category's own structural gap (no owned backend to run in CI).
  Playwright's and Cypress's own built-in network-interception/route-
  mocking is the E2E-runner-level equivalent of the same idea.
  **Mobile-specific**: Detox and Maestro are the two live current React
  Native E2E options (GitHub-API-verified, retrieved 2026-08-31: Detox —
  12,019 stars, MIT, pushed 2026-08-24; Maestro — 15,461 stars,
  Apache-2.0, pushed same-day). Detox does gray-box, in-process test
  synchronization with the app; Maestro does black-box, accessibility-
  layer-driven testing via YAML-defined flows with no native/build
  configuration required — Expo's own official docs (direct fetch,
  docs.expo.dev/develop/unit-testing) currently recommend Maestro-based
  E2E testing and make no mention of Detox at all, a real current signal
  of first-party Expo backing shifting toward Maestro; specific
  flakiness-percentage and CI-runtime comparisons circulating between the
  two are search-corroborated vendor/blog claims only, not independently
  verified this pass. Flutter's own official `integration_test` package
  (direct fetch, docs.flutter.dev/testing/integration-tests) is confirmed
  current, distinct from `flutter_test` widget/unit tests, running the
  full app on a real device/emulator/Firebase Test Lab — the natural
  Flutter-native pairing with the fake/mocked-repository testing approach
  Flutter's own architecture guide (see the hexagonal-analogue section
  above) explicitly recommends for isolating tests from a real backend.

## Sources

- Local precedent: direct read of
  `/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/
  package.json`, `src/` directory structure, `src/services/{api.ts,
  endpoints.ts,queryClient.ts}`, `public/manifest.webmanifest`, and
  `public/sw.js`; directory listings of `aws/container/` and repo-root
  `charts/` confirming a co-owned backend (`aws/container/backend/`,
  `charts/ubi-backend`) — read 2026-08-31
- `research/architecture-templates.md`,
  `research/stacks/business-applications/stack.md`,
  `skills/project-incubation/references/stacks/business-applications.md`,
  `skills/project-incubation/SKILL.md`, `research/taxonomy-roadmap.md` —
  read directly this pass (not web sources) to confirm this category's
  scope boundary against Business Applications precisely and to avoid
  re-deriving cross-cutting content those docs already cover — read
  2026-08-31
- https://www.inkandswitch.com/essay/local-first/ — direct fetch: the
  canonical "local-first software" essay (Kleppmann, Wiggins, van
  Hardenberg, McGranaghan, Onward! 2019), its seven ideals, and the
  local-device-primary/server-secondary framing — retrieved 2026-08-31
- GitHub REST API, direct queries against `api.github.com/repos/...` for
  `pubkey/rxdb`, `dexie/Dexie.js`, `pouchdb/pouchdb` (redirects to
  `apache/pouchdb`), `Nozbe/WatermelonDB`, `yjs/yjs`, `automerge/automerge`,
  `loro-dev/loro`, `rocicorp/replicache` (confirmed `archived: true`),
  `rocicorp/mono` (Zero), `electric-sql/electric`, `tauri-apps/tauri`,
  `electron/electron`, `facebook/react-native` (redirects to
  `react/react-native`), `flutter/flutter`, `mswjs/msw`,
  `storybookjs/storybook`, `microsoft/playwright`, `wix/Detox`,
  `mobile-dev-inc/maestro`, `chromaui/chromatic-cli` — stars, license,
  `pushed_at`, and `archived` status for each pulled directly — retrieved
  2026-08-31
- https://www.figma.com/blog/how-figmas-multiplayer-technology-works/ —
  direct fetch: Figma's own account of rejecting textbook OT and textbook
  CRDTs in favor of per-property last-writer-wins over a tree-of-objects
  document model, including the Evan Wallace "no more complex than
  necessary" framing — retrieved 2026-08-31
- Linear sync-engine architecture (IndexedDB local store, LWW default,
  narrow CRDT use for rich text) — **search-corroborated secondary
  analysis only** (fujimon.com/blog/linear-sync-engine); Linear's own
  primary source (linear.app/now/scaling-the-linear-sync-engine) is a
  talk-landing page with no substantive text and did not yield verifiable
  primary content on direct fetch — flagged explicitly as not confirmed
  in Linear's own words — retrieved 2026-08-31
- ElectricSQL 1.0 GA (March 2025) and v1.1 (August 2025, custom storage
  engine, claimed 102x write-throughput improvement) — search-corroborated
  only, not independently direct-fetched or benchmarked this pass —
  retrieved 2026-08-31
- Martin Kleppmann, "CRDTs: The Hard Parts" (2020) — named as the standard
  primary reference for CRDT tradeoffs (naive CRDT implementations can use
  orders of magnitude more memory than the underlying data) but not
  directly fetched this pass (talk/slide format) — search-corroborated
  only — retrieved 2026-08-31
- https://developer.apple.com/distribute/app-review/ — direct fetch:
  "on average, 90% of submissions are reviewed in less than 24 hours,"
  and the expedited-review request mechanism with Apple's own
  overuse-deprioritization caveat — retrieved 2026-08-31
- Google Play standard review turnaround (1-3 business days typical,
  longer for new/policy-flagged accounts) — **search-corroborated only**;
  two direct-fetch attempts at Google-owned pages found no stated SLA
  number (the play.google.com/console policy URL returned a 404;
  `support.google.com/googleplay/android-developer/answer/9859348`,
  fetched in a follow-up pass, discusses review generally but states no
  turnaround-time figure at all) — Google appears not to publish one the
  way Apple does, not merely a fetch that missed it — retrieved
  2026-08-31, follow-up 2026-08-31
- https://support.google.com/googleplay/android-developer/answer/6346149
  — direct fetch: Google Play staged-rollout mechanic (developer sets an
  arbitrary custom percentage; it does not auto-increase) — retrieved
  2026-08-31
- Microsoft App Center / CodePush shutdown (March 31, 2025) and EAS
  Update as the current React Native/Expo OTA replacement — search-
  corroborated across multiple current sources (expo.dev/blog/
  how-to-replace-app-center-and-codepush); the OTA introduction mechanics
  themselves direct-fetch confirmed at
  https://docs.expo.dev/eas-update/introduction/ — retrieved 2026-08-31
- Apple App Store Review Guideline 3.3.1 (interpreted-code/OTA updates
  permitted, but not to ship features that would have required binary
  review) and the `runtimeVersion`/fingerprint-policy compatibility
  mechanism — search-corroborated, not independently direct-fetched
  against Apple's own guideline text this pass — retrieved 2026-08-31
- Mac App Store sandboxing vs. Developer-ID direct-distribution
  notarization/Hardened-Runtime path — search-corroborated across
  several current developer writeups, not confirmed against one single
  official Apple page covering the full framing this pass — retrieved
  2026-08-31
- React Native New Architecture (Fabric/TurboModules/JSI) as the now-
  mandatory default (opt-out removed RN 0.82, legacy bridge deleted RN
  0.83; Expo SDK 55+ New-Architecture-only) and adoption-signal figures
  (~83% of SDK 54 EAS-built projects, ~85% of popular npm packages
  New-Architecture-compatible as of January 2026) — search-corroborated
  across multiple current 2026 sources, not one single official RN blog
  post — retrieved 2026-08-31
- Stack Overflow / State-of-Mobile-style survey figures comparing React
  Native vs. Flutter adoption — **excluded from this baseline**: cited
  figures found in search results trace to 2024-survey commentary reused
  in later blog posts, and this pass could not independently direct-fetch
  Stack Overflow's own primary results page to confirm current numbers —
  flagged honestly rather than asserted — retrieved 2026-08-31
- https://v2.tauri.app/blog/tauri-20/ — direct fetch: Tauri 2.0 stable
  release date, 2024-10-02 — retrieved 2026-08-31
- https://tauri.app/start/ — direct fetch: Tauri's own official claim
  ("a minimal Tauri app can be less than 600KB"), with no official
  numeric Electron-comparison figure on this page — retrieved 2026-08-31
- Tauri-vs-Electron bundle-size/RAM comparison figures ("3-10MB vs.
  120-200MB" installer size; "30-40MB vs. 200-300MB" RAM) — **flagged as
  unverified**: found only in third-party/vendor-adjacent blog sources
  (tech-insider.org, pkgpulse.com, gethopp.app), not independently
  benchmarked this pass and not traceable to a neutral primary source —
  retrieved 2026-08-31
- https://docs.flutter.dev/app-architecture/guide — direct fetch:
  Flutter's official Services/Repositories layered architecture, the
  "Repositories should never be aware of each other" rule, and
  ViewModel-depends-only-on-repositories framing — retrieved 2026-08-31
- https://developer.android.com/topic/architecture — direct fetch:
  Android's official UI/domain/data-layer architecture, repositories
  abstracting zero-to-many data sources, explicitly framed as
  "abstracting sources of data from the rest of the app" — retrieved
  2026-08-31
- React/web "hexagonal-inspired" client architecture (ports/adapters via
  React Context DI) — search-corroborated community convention, not an
  official standard: `juanm4/hexagonal-architecture-frontend`,
  `Maua-Dev/hexagonal_arch_react_template` repos found via search but not
  individually fetched; a commonly-cited Alex Kondov writeup
  (alexkondov.com/hexagonal-inspired-architecture-in-react/) returned a
  403 on direct-fetch attempt this pass and is cited by title/search-
  snippet only — retrieved 2026-08-31
- https://storybook.js.org/docs/writing-tests/interaction-testing —
  direct fetch: Storybook 10.5's play-function/Testing-Library
  interaction-testing feature and CI-integration guidance — retrieved
  2026-08-31
- Chromatic and Percy as current visual-regression-testing products —
  search-corroborated (chromatic.com/storybook, browserstack.com/percy,
  percy.io/blog/visual-regression-testing-tools), not individually
  direct-fetched this pass; Percy's late-2025 AI Visual Review Agent
  addition is a search-corroborated claim only — retrieved 2026-08-31
- https://playwright.dev/docs/test-snapshots — direct fetch: Playwright's
  built-in `toHaveScreenshot()` visual comparison, `maxDiffPixels`
  tolerance, and the documented OS/hardware rendering-variance caveat —
  retrieved 2026-08-31
- https://mswjs.io/docs/ — direct fetch: Mock Service Worker's network-
  level interception mechanism (Service Worker in-browser, class-
  extension in Node) and its own "single source of truth for network
  behavior" framing across dev/integration/E2E/Storybook use — retrieved
  2026-08-31
- https://docs.expo.dev/develop/unit-testing/ — direct fetch: Expo's
  current official testing guidance, recommending Maestro-based E2E
  testing with no mention of Detox — retrieved 2026-08-31
- Detox-vs-Maestro flakiness-percentage and CI-runtime comparison figures
  — search-corroborated only (maestro.dev/insights/detox-vs-maestro-
  reducing-flakiness-react-native and similar), vendor-influenced source,
  not independently verified this pass — retrieved 2026-08-31
- https://docs.flutter.dev/testing/integration-tests — direct fetch:
  Flutter's official `integration_test` package, distinct from
  `flutter_test` widget/unit tests, running the full app on a real
  device/emulator/Firebase Test Lab — retrieved 2026-08-31

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
standing for this whole taxonomy-roadmap sweep, resolved directly:

1. **No local repo matching this category's defining shape stays an
   accepted gap** — fine to lean entirely on external sources, matching
   the precedent the Business Applications baseline already set for
   itself in the same situation.
2. **Push notifications/deep-linking/analytics SDK selection stay
   out of scope** — real concerns, but not distinctively architectural
   the way state management, sync, and distribution mechanics are; the
   existing Explicitly-out-of-scope entry already names this honestly as
   a flagged gap rather than silently covered.
3. **Google Play's review-SLA figure stays search-corroborated, not
   vendor-confirmed** — a second follow-up direct-fetch attempt this pass
   (`support.google.com/googleplay/android-developer/answer/9859348`)
   also did not surface a stated number; Google genuinely appears not to
   publish one the way Apple does. The authored doc should keep the
   asymmetric confidence levels visible (Apple's 90%-in-24-hours is
   vendor-stated; Google's 1-3-business-days is community consensus) —
   accurate and honest is better than manufacturing false parity.
4. **Tauri-vs-Electron bundle-size/RAM numbers stay explicitly labeled
   unverified third-party claims**, not presented as settled fact — the
   qualitative architectural reason (native WebView vs. bundled Chromium)
   is the load-bearing claim; the specific MB figures are illustrative
   only.
5. **Fully-native mobile development stays named but not deep-dived** —
   consistent with this skill's cross-platform-leaning scope and the
   roadmap category's own framing.

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/frontend-client-applications.md
  — est. 520–600 lines (7 in-scope subsections at section/table depth,
  most carrying real current-verification nuance — GitHub-API-sourced
  currency checks, explicit vendor-claim-vs-verified-fact flags, and two
  directly-fetched real-world case studies — plus the scope-boundary
  section against Business Applications needing full precision per this
  task's own framing of it as the single most important thing to get
  right; likely comparable in length to the Infrastructure & Platform
  Engineering and ML/AI Model Development authored files given how many
  genuinely distinct sub-topics this category covers).
