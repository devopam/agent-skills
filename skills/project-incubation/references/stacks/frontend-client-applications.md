# Frontend / Client Applications — Architecture & Stack

This category is a **pure client application with no owned backend of its
own** — a web SPA, a mobile app, or a desktop app whose only backend
interaction is calling a third-party or platform-hosted API (a SaaS API, an
auth provider, a payment processor, a BaaS like Firebase or Supabase) that a
*different* team or company owns and deploys. A mobile app whose only
backend interaction is Stripe's API and a third-party auth provider, with no
first-party backend at all, is this category. A desktop Electron/Tauri app
that syncs to a hosted service it doesn't operate is this category. A SPA
that is purely a client of someone else's API is this category.

**The operative test, stated precisely because getting it right is this
doc's single most important job**: does this project's own team own and
deploy a backend? If yes — even when the frontend half of that project looks
architecturally identical to a "pure" frontend project, same
React-plus-Vite-plus-TanStack-Query shape, same feature-folder component
structure — the project as a whole is [Business
Applications](business-applications.md)-shaped, and that doc's own [frontend
architecture](business-applications.md#frontend-architecture) section
already owns that frontend's guidance (SPA-vs-RSC/App-Router choice,
auth-behind-a-login framing, RBAC/ABAC-aware UI concerns); this doc does not
re-derive it. If no — the backend is someone else's system, called over the
network as a black-box dependency the client's own team cannot change,
redeploy, or add an endpoint to — the project is this category's, and this
doc's value only exists because of that missing backend: client-side storage
as the *primary*, not secondary-cache, data layer; offline/sync architecture
with real conflict resolution; app-store distribution mechanics; and no
server-side architecture-template question to answer at all. The line is
about **backend ownership**, not frontend tech-stack shape or architectural
sophistication — a React-plus-Vite-plus-TanStack-Query SPA calling `/api/*`
on a FastAPI backend the same team deploys is Business Applications, full
stop, even though nothing about its component tree or state-management code
looks different from a SPA calling a third-party API instead.

`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/` is real,
substantial, current frontend-engineering evidence — inspected directly this
pass: React 19.2, TypeScript, Vite 7, TanStack Query 5.90, Okta auth, a
Lexical rich-text stack, and a genuine feature-based `src/` structure. It is
also, confirmed by direct read, a PWA: `public/manifest.webmanifest`
declares `display: standalone` with real install icons. But its
`public/sw.js` is a deliberately minimal, non-offline service worker, and
its own top-of-file comment says so precisely: `/** Minimal service worker
— enables PWA install; no offline cache (enterprise app). */`. The `fetch`
handler does nothing but pass every request straight through to the
network — no cache-first or stale-while-revalidate strategy, no offline
fallback, no background sync. This is a genuinely useful, honest data point
for this doc's PWA framing below: a real production app adopted PWA
*installability* without adopting offline-first *data* architecture, and
the app's own code names the reason (an assumed-always-online enterprise
tool) rather than this doc inferring it. Applying this category's own
scoping test to the repo as a whole, though: `ubi-csr-tmf` is **not** an
instance of this category. The same repo's `aws/container/` directory holds
a sibling `backend/` — a FastAPI-shaped `app/`, Alembic `migrations/`, its
own `Dockerfile` — and the repo-root `charts/` directory ships an
`ubi-backend` Helm chart alongside `ubi-frontend`. This team owns and
deploys its own backend, so per the operative test above the project as a
whole is Business-Applications-shaped, not a worked example of this
category's own defining constraint. No other local repository was found
with a genuinely backend-less client shape — no local mobile app calling
only a third-party API, no standalone Electron/Tauri app with no
first-party backend. That absence is named honestly rather than papered
over, consistent with the precedent Business Applications' own baseline
already set for itself when a category-matching local repo didn't exist.

One convention carried through every section below, matching every other
doc in this skill: numeric claims are stated only where a primary source
backs the specific figure, and a claim sourced only from search-corroborated
secondary content is named as such rather than upgraded to settled fact.
Several of this category's highest-stakes facts — Apple's review-latency
figure, the CodePush shutdown, React Native's governance transfer — are
exactly the kind a model's training data goes stale on fastest.

## Table of contents

- [Local-first state management: local storage as the primary data layer](#local-first-state-management-local-storage-as-the-primary-data-layer)
- [Offline-first sync: last-write-wins, operational transformation, and CRDTs](#offline-first-sync-last-write-wins-operational-transformation-and-crdts)
- [App-store distribution mechanics](#app-store-distribution-mechanics)
- [Mobile: native vs. cross-platform](#mobile-native-vs-cross-platform)
- [Desktop: Electron vs. Tauri](#desktop-electron-vs-tauri)
- [Why this category has no server-side architecture-template question — and what replaces it](#why-this-category-has-no-server-side-architecture-template-question--and-what-replaces-it)
- [Testing a backend-less client](#testing-a-backend-less-client)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Local-first state management: local storage as the primary data layer

This is the category-defining reframe, and it's a genuinely different
framing from [Business Applications](business-applications.md)'s own
implicit model of client state, not just the same idea restated for a
smaller app. A full-stack app with an owned backend treats its client-side
cache — a TanStack Query cache, a Redux slice hydrated from an API response
— as a *derived, disposable* copy of data the team's own backend holds as
ground truth: if the cache is wrong or lost, the team can always re-query
their own API cheaply, because they control it and it's normally reachable.
A backend-less client has no such backend to fall back on. There is,
frequently, no single "ground truth" reachable on demand at all — only a
remote service someone else operates, which the client can't assume is
always up, always fast, or always the definitive record of what the user
just did. The architectural consequence is the **inverse** of the
owned-backend model: the local device copy has to be treated as primary, and
the remote service as a secondary sync target the app opportunistically
reconciles against, not the other way around.

This is a real, current, named engineering movement, not an assumed-to-exist
philosophy — anchored on the canonical "local-first software" essay
(Kleppmann, Wiggins, van Hardenberg, McGranaghan, Ink & Switch, Onward!
2019/SPLASH). The essay's own framing of the core distinction is worth
quoting directly, because it states the architectural consequence more
precisely than any paraphrase: "In cloud apps, the data on the server is
treated as the primary, authoritative copy; if a client has a copy, it is
merely a cache. In local-first applications we swap these roles: we treat
the copy of the data on your local device as the primary copy. Servers still
exist, but they hold secondary copies to assist with access from multiple
devices." The essay names seven ideals worth carrying forward precisely,
because they function as a concrete checklist against which to evaluate a
backend-less client's architecture, not just a mission statement: **(1) no
spinners** — operations respond near-instantaneously because the UI reads
local data, not a network round-trip; **(2)** a user's work is not trapped
on one device; **(3)** the network is optional — the app remains usable
offline, with sync happening later; **(4)** seamless real-time collaboration
with colleagues, without manual conflict resolution; **(5) the long now** —
data outlives the vendor or service, not locked behind one company's
continued existence; **(6)** security and privacy by default; **(7)** the
user retains ultimate ownership and control of their data.

A concrete design consequence of taking this seriously: a backend-less
client's data layer needs a real local persistence mechanism doing more work
than a disposable in-memory cache — an embedded database (IndexedDB/SQLite,
or a library built on top of one) that the app treats as its actual store of
record between sessions, capable of being written to while offline and read
from before any network round-trip completes. That category of
primary-local-store library is real, current, and actively maintained as of
this doc's research pass — not a niche or stale corner of the ecosystem.
Specific product selection (which local-first database, which sync add-on)
belongs to the companion [Preferred Libraries: Frontend / Client
Applications](../preferred-libraries/frontend-client-applications.md), which
also names the one honest counter-example this doc's own local precedent
supplies: the same `ubi-csr-tmf` PWA that ships install-ability ships no
local-first data layer at all, because an assumed-always-online enterprise
tool genuinely doesn't need one — local-first is a real architectural
commitment to make deliberately, not a default to reach for on every client
project regardless of whether intermittent connectivity or multi-device
continuity is an actual requirement.

## Offline-first sync: last-write-wins, operational transformation, and CRDTs

The concrete problem: a client needs to function with zero or intermittent
connectivity, and reconcile local changes against a remote source once
connectivity returns. Three genuinely distinct conflict-resolution
strategies exist, and picking among them is a real architectural decision,
not a detail to defer to a library's defaults.

**Last-write-wins (LWW)** is the simplest strategy: when two writes conflict
on the same field, the later one (by some ordering — server-arrival order,
a timestamp, a vector clock) wins outright and the other is silently
dropped. It is adequate whenever conflicts are rare or low-stakes at field
granularity, and it is the strategy two real production systems at
meaningful scale both converge on as their *default*, not their fallback.

**Operational Transformation (OT)** is still alive in centrally-coordinated
systems — historically the architecture behind Google Docs — but current
(2026) consensus across multiple sources is that new offline-first or
decentralized client designs are not choosing it: OT requires a central
server to mediate transform ordering, which is precisely the single point
this category's clients can't always reach by construction. OT is not the
right choice for a new backend-less or offline-capable client design today.

**CRDTs (Conflict-free Replicated Data Types)** guarantee convergence
without a central coordinator by construction, at the cost of real
implementation and memory overhead relative to a naive representation.
**Yjs** is the current adoption leader specifically for text and rich-content
collaborative editing. **Automerge** is a richer JSON-CRDT with an explicit
local-first design lineage — Kleppmann, the local-first essay's own lead
author, is a maintainer — and its own `Peritext` rich-text CRDT. **Loro** is
a newer, high-performance entrant in the same space. One genuinely important,
concrete current finding worth naming precisely rather than assuming from an
older prior: **Replicache is archived** — its own maintainers (Rocicorp)
have moved on to **Zero**, a sync-engine product rather than a
client-embedded CRDT library, and **ElectricSQL** has emerged as the leading
current "sync your existing Postgres to the client" primitive, a genuinely
different shape from an embedded CRDT library — it reached general
availability in March 2025. A tool that was a reasonable default reference
a few years ago being archived, with its own team's successor now aimed at a
different point in the design space, is exactly the kind of shift this
category's fast-moving sync-tooling landscape produces and a stale prior
would miss. Specific tool comparison and current recommendation belongs to
[Preferred Libraries: Frontend / Client
Applications](../preferred-libraries/frontend-client-applications.md); this
doc's own claim is narrower — that CRDT-based sync is a real, current,
actively-developed category, not a niche academic approach, and that the
specific tool landscape inside it has genuinely shifted in the last few
years.

Two real-world case studies make the decision concrete, because they show
the answer is not reflexively "always reach for CRDTs" the way the phrase
"real-time collaboration" might suggest. **Figma explicitly rejected both.**
Its own engineering account states plainly that OT was "unnecessarily
complex for our problem space," citing the same difficulty independent
CRDT/OT researchers Li and Li name — that formal correctness proofs for OT
transform functions are "very complicated and error-prone" even for
established OT algorithms — and that OT produces "a combinatorial explosion
of possible states which is very difficult to reason about." Figma also
rejected a *textbook* CRDT: its own account is explicit that "Figma isn't
using true CRDTs though. CRDTs are designed for decentralized systems...
Since Figma is centralized (our server is the central authority), we can
simplify our system." What Figma actually built is CRDT-*inspired* but
simplified for its own client-server shape: **per-property last-writer-wins
over a tree of objects**, where each property update is independently
resolved by "the most recent change we know about in last-to-the-server
order," and objects store parent links as atomic properties so that
unrelated properties on the same object never conflict with each other at
all. That design choice reflects Evan Wallace's own stated principle: build
a system with no more complexity than the problem actually requires, not the
most sophisticated technique available. **Linear**'s sync engine, per
secondary-source analysis of its architecture (Linear's own primary post is
a talk-landing page without substantive published text, worth flagging as
not independently confirmed in Linear's own words), reportedly uses
IndexedDB as the local store, a normalized in-memory object graph, and
**LWW as the default conflict strategy** because conflicts are genuinely
rare in an issue-tracking domain — with CRDTs adopted only narrowly, for
issue-description rich text specifically, not as a blanket application-wide
strategy.

**The decision rule this doc carries forward, synthesized from both cases**:
LWW is the correct default for most application state, where per-field
concurrent edits are rare and a small amount of silent-overwrite risk is
acceptable — Figma and Linear both confirm this holds at real production
scale, not just for a toy app with low stakes. Reach for a CRDT specifically
for the sub-domains where true concurrent collaborative editing on the
*same* structure is a named requirement — rich text is the dominant real
case, per both Yjs's and Automerge's own primary use case — rather than
adopting a CRDT wholesale for an entire application's state. Building the
whole application on a CRDT because one feature (a shared text editor) needs
one is over-engineering the other 95% of the app's state for a problem it
doesn't have.

## App-store distribution mechanics

This is a structurally distinct constraint no other project-incubation
stack category has: a web service or backend API deploys and rolls back in
minutes, on the team's own schedule; an app-store-distributed client cannot.
**Release cadence and rollback speed are fundamentally different
constraints for this category than for any server-side category in this
skill** — a mobile-app-store release has a review-latency floor measured in
hours to days even in the best case, and rolling back a *native* code
change requires a full new submission and review cycle, not a redeploy.

**Apple's own stated figure**: "on average, 90% of submissions are reviewed
in less than 24 hours," per Apple's own developer documentation. An
expedited-review path exists via a contact form for critical bug fixes or
event-tied launches, with Apple's own caveat that overusing expedited
requests gets deprioritized. Real-world commentary suggests complex or
policy-flagged apps can see multi-day review in practice — worth naming as
an anecdotal caveat on the vendor's own figure, not a vendor-confirmed
number in its own right. **Google Play publishes no comparable stated SLA**
— a real asymmetry worth keeping visible rather than manufacturing false
parity between the two platforms: community consensus converges on 1-3
business days for a standard update, longer for new developer accounts or
policy-sensitive apps, but that figure is search-corroborated only, not a
number Google states the way Apple does. Google Play's **staged rollout**
mechanic is a real, documented feature worth naming on its own mechanical
terms: the developer sets an arbitrary custom percentage of users who
receive an update first, and that percentage does **not** auto-increase — a
manual or scripted ramp is the developer's own responsibility, not something
the platform does automatically.

**The concrete architectural consequence is OTA (over-the-air) update
mechanisms that bypass full app-store review for JS/asset-bundle changes.**
Microsoft's App Center, including its CodePush service, shut down March 31,
2025. The current replacement for React Native and Expo teams is **EAS
Update**, Expo's own hosted OTA service, which ships only JS/asset-bundle
updates — no native code — as Expo's own current first-party
recommendation. This matters architecturally, not just as a tooling fact:
Apple's own App Store Review Guideline 3.3.1 permits interpreted-code (JS
bundle) updates but explicitly forbids using that mechanism to ship features
that would otherwise have required a new binary review, and the current
`runtimeVersion` fingerprint-policy mechanism exists specifically to keep an
OTA JS bundle matched to the native binary it was built against — a
compatibility contract, not a way to smuggle unreviewed native functionality
past app-store review. A team designing around OTA updates needs to draw
that line deliberately: pure JS/UI/logic changes can ship same-day through
an OTA channel; anything touching a native module, permission, or binary
capability still goes through the full review cycle above, with its
hours-to-days latency floor.

**Desktop is materially less store-gated than mobile.** Mac App Store
distribution requires sandboxing and review, the same review-latency
constraint mobile has. Direct distribution outside the Mac App Store
(Developer ID) instead requires **notarization** — Apple's automated
malware scan — plus Hardened Runtime, with no sandbox requirement and no
app-store review delay at all. That's a genuinely different distribution
model available to a desktop app that mobile simply doesn't have: a desktop
client can choose to skip store review entirely and still ship a
trust-verified binary. The practical takeaway for a new project: a mobile
release pipeline has to be designed around a review-latency floor it cannot
shrink to zero (only route around, for JS-only changes, via OTA), while a
desktop release pipeline can choose store distribution *or* a direct,
review-free distribution path depending on how much the team values
discoverability against release-speed control.

## Mobile: native vs. cross-platform

Cross-platform is the default framing this doc takes, consistent with this
skill's scope — fully native, per-platform Swift/SwiftUI or
Kotlin/Jetpack-Compose development is a real option, named here but not
deep-dived, since a team choosing it isn't making a cross-platform-framework
decision at all. Between the two dominant cross-platform frameworks, the
real, verifiable architectural discriminator is **how each one puts pixels
on screen**, not a popularity contest:

| Axis | React Native | Flutter |
|---|---|---|
| Rendering model | Maps to actual native platform widgets/components via its New Architecture's Fabric renderer | Renders its own UI via its own engine (historically Skia, now transitioning toward Impeller) rather than native widgets |
| Consequence | Closer native look-and-feel, easier native-module interop; some cross-platform visual inconsistency since each platform's native widgets differ | Pixel-perfect UI consistency across iOS/Android/desktop/web from one codebase, at the cost of not automatically picking up native platform look-and-feel changes |
| Language | JavaScript/TypeScript — the same language as most existing web frontend codebases | Dart only |
| Governance (2026) | **React Foundation**, a Linux Foundation project formed in February 2026 — Meta transferred React, React Native, and JSX into it; the governing board spans Amazon, Callstack, Expo, Meta, Microsoft, Software Mansion, and Vercel, with Meta committing $3M+ over five years and retaining an initial majority board stake | Remains squarely Google-owned and Google-funded; no comparable foundation transfer has occurred |

**A genuinely current, high-impact architectural shift worth naming
precisely**: React Native's **New Architecture** — the Fabric render
pipeline, TurboModules, and the JSI bridge replacement — is now the
*mandatory default*, not an opt-in. The old-architecture opt-out was removed
in RN 0.82, and the legacy bridge is being deleted entirely in 0.83; Expo
SDK 55+ runs entirely on the New Architecture. This is not a cosmetic
version bump: the JSI bridge replaces React Native's historical
asynchronous-JSON-bridge communication model between JS and native code with
direct, synchronous JS-to-native calls, which is the mechanism underlying
the "closer native look-and-feel" row above rather than a separate,
unrelated improvement.

**React Native's governance transfer is a genuine, current shift worth
stating without the old "single-vendor Meta ownership" framing**, which is
now materially outdated. Moving from one company's internal project to a
multi-stakeholder foundation with a named, funded board is a real
governance-risk reduction, comparable in kind to how OpenJS Foundation
membership functions for Electron below — though it landed only months
before this doc's own research pass, and is worth re-checking at any future
audit of a project already committed to React Native, since a fresh
foundation's practical governance behavior is not yet as proven as an
established one's. Flutter carries the mirror-image trade-off: no equivalent
foundation transfer has occurred, so its long-term continuity still rests on
one company's continued willingness to fund it, not a multi-stakeholder
structure — a real, if less formalized, governance-risk asymmetry against
React Native's new position.

**Decision rule**: default to React Native when the team is JS/TS-first,
wants to share code and patterns with an existing React web codebase, or
values the newly multi-stakeholder governance model as a lower
single-vendor-risk bet. Default to Flutter when pixel-perfect cross-platform
UI consistency matters more than JS-ecosystem code sharing, or the team is
starting fresh with no existing React investment. Neither is a wrong default
today — this is a genuine team-fit decision, not a settled technical winner,
and specific adoption-momentum and star/issue-count comparisons belong to
[Preferred Libraries: Frontend / Client
Applications](../preferred-libraries/frontend-client-applications.md) rather
than this doc's own architectural framing.

## Desktop: Electron vs. Tauri

The real, verifiable architectural discriminator here mirrors the mobile
one above in shape, though it cuts along a different axis: **how the
runtime the app depends on gets delivered.** Electron bundles a fixed
version of Chromium plus a Node.js runtime with every app it ships. Tauri
instead uses the operating system's own native WebView — WebView2 on
Windows, WKWebView on macOS, webkitgtk on Linux — plus a Rust backend, and
ships neither a browser engine nor a JS runtime inside the app binary
itself.

That single structural difference cuts both ways, and both sides are worth
naming precisely rather than treating one as strictly better. Because Tauri
doesn't ship its own browser engine, there is a real, structural reason to
expect a smaller installer and lower baseline memory footprint — Tauri's
own official documentation states only that "a minimal Tauri app can be less
than 600KB," with **no official numeric Electron comparison** on that page.
The specific bundle-size and RAM figures that circulate in blog
comparisons — commonly cited as roughly 3-10MB vs. 120-200MB installer size,
30-40MB vs. 200-300MB RAM — are third-party and vendor-adjacent claims only,
not independently benchmarked and not traceable to a neutral primary source.
They're named here explicitly as **unverified** rather than presented as
settled fact, the same discipline this repo's other stack docs apply to any
unsourced statistic; the qualitative architectural reason (no bundled
browser engine) is the load-bearing claim, the specific MB numbers are
illustrative only. The cost of Tauri's approach is the mirror image of its
benefit: **rendering behavior varies by the end user's installed OS WebView
version**, a genuine cross-platform rendering-consistency risk Electron does
not have, since Electron ships one pinned Chromium build identically on
every platform regardless of what's installed on the user's machine.

Both frameworks are large, current, actively maintained projects as of this
doc's research pass — this is a genuine two-way choice between mature
options, not a mature-vs-experimental split the way this comparison might
have read a few years ago. Tauri 2.0 shipped stable on 2024-10-02, well
established by now rather than a bleeding-edge, pre-1.0 concern. Governance
differs in a way worth noting alongside the technical trade-off: Electron is
an OpenJS Foundation Impact Project, the same vendor-neutral foundation home
as Node.js and Jest, not single-vendor-owned. On the native-API-access
trade-off: Electron's much larger, longer-established plugin and
native-module ecosystem is a real current advantage for apps needing broad
native-API surface coverage; Tauri's Rust-backend model is newer but
growing, and trades a memory-safe systems language for native-side code
against a smaller (though real and actively growing) plugin ecosystem to
draw on versus reimplementing a native integration from scratch.

**Decision rule**: Tauri is the right default when installer size and
baseline resource usage are named constraints and the team can tolerate, or
explicitly test against, OS-WebView rendering variance. Electron remains the
right default when broad native-module/plugin-ecosystem coverage or
guaranteed identical rendering across every user's machine matters more than
footprint. Packaging-tool selection and specific adoption/maintenance
comparison belong to [Preferred Libraries: Frontend / Client
Applications](../preferred-libraries/frontend-client-applications.md).

## Why this category has no server-side architecture-template question — and what replaces it

[architecture-templates.md](../architecture-templates.md)'s whole pattern
catalog — layered, hexagonal/ports-and-adapters, microservices, modular
monolith, event-driven, CQRS, serverless — is explicitly a
**deployment-topology** decision: which of several ways to structure and
deploy a *server-side* system. A project in this category has, by
construction, no server component of its own, and therefore no deployment
topology to choose in that sense at all. There is nothing analogous to
"should this be a modular monolith or microservices," because there is no
backend being built here to apply that question to — that question belongs
entirely to whichever team owns the backend this client happens to call.

**But hexagonal/ports-and-adapters does have a genuine, currently-documented
client-side analogue**, confirmed via two authoritative, currently-live
official sources rather than assumed to exist by analogy. **Flutter's own
official app-architecture guide** defines an explicit layered shape where
**"Services"** wrap raw network or platform API endpoints, and
**"Repositories"** consume one or more services and transform their raw data
into the app's own domain models — with the explicit rule that
"Repositories should never be aware of each other," and that ViewModel/UI
code depends only on repositories, never on services directly. **Android's
own official architecture guidance** defines the identical shape in its own
terms: a data layer made of repositories, each wrapping zero-to-many data
sources — network, local database, files — explicitly framed as
"abstracting sources of data from the rest of the app." Both are real,
current, first-party platform guidance, not a community-invented analogy
forced onto client code after the fact.

A parallel, real-but-less-standardized convention exists in the React/web
ecosystem: ports (interfaces defining an API contract) and adapters
(HTTP-client implementations satisfying that contract), wired into
components via dependency injection through context — decoupling business
logic and UI from the specific REST/GraphQL/SDK shape of whichever backend
the client happens to call. This is a real pattern, with concrete current
implementations findable in the open, but it is a **community
convention** — often called "repository pattern," "API-client abstraction
layer," or "hexagonal-inspired architecture" — not an official,
standardized platform pattern the way Flutter's and Android's own guidance
is. That confidence-level distinction is worth preserving rather than
flattening: cite Flutter's and Android's guidance as settled first-party
fact, and the React-ecosystem convention as a real but less authoritative
practice a team can adopt, not a documented platform standard it's
following.

**The concrete payoff is the same reasoning
[architecture-templates.md](../architecture-templates.md) already gives for
server-side hexagonal architecture, now applied to a client's own outbound
dependency on a backend it doesn't own rather than to a server's outbound
dependency on a database or message broker**: abstracting the specific
backend API a client talks to behind an interface means swapping API
providers, or mocking the API entirely for tests, doesn't ripple through the
UI or business-logic layer. That payoff matters more, not less, in this
category than in a full-stack app, precisely because this category's client
has no control at all over the backend it depends on — a third-party API can
change its contract, get replaced by the team's own choice, or simply become
unreachable in a way an owned backend rarely does, and a client built
without this seam pays for that lack of insulation directly in its own UI
code.

## Testing a backend-less client

Three layers here are genuinely distinct from how [Business
Applications](business-applications.md) or [Backend & API
Services](backend-api-services.md) would test an owned system, and each
follows from the same structural fact: this category's project doesn't own
the backend it calls, so it cannot spin one up for a real integration test
the way a full-stack project can.

**Component testing** verifies a UI component's behavior in isolation from
both the rest of the app and any network call — interaction tests that
simulate user events (clicks, typing) against a rendered component and
assert on the resulting DOM state, runnable in CI without a browser or a
backend at all.

**Visual-regression testing** catches the failure mode component-behavior
tests structurally cannot: a component that behaves correctly but renders
wrong — a broken layout, a regressed color token, an unintended style
change. The current tooling in this space works specifically at the
*component* level rather than needing a full running app plus backend,
which is exactly why it fits this category's own structural gap: golden-file
screenshot comparison with a configurable pixel-difference tolerance is the
current standard mechanism, with a documented caveat worth naming
precisely — OS, hardware, and rendering variance affects screenshot
consistency across machines, a real CI-reproducibility concern best handled
by running visual-comparison CI jobs in one pinned container image rather
than across heterogeneous runners.

**End-to-end testing against a mocked or stubbed backend, rather than a
real one, is the structurally distinct need this category has that a
full-stack project doesn't.** A full-stack project can spin up its own real
backend for integration tests; this category's project, by definition,
cannot, because it doesn't own that backend. The current, mature, standard
mechanism for this is **network-level request interception** — true
Service Worker-based interception in the browser, and an equivalent
class-extension mechanism in Node-based test and server environments — that
gives a single source of truth for network behavior reusable across local
development, integration tests, end-to-end tests, and component-story
tooling alike. This is a materially different approach from stubbing at the
code level (mocking a fetch wrapper function): intercepting at the network
layer means the same mock definitions work whether the request originates
from application code, a test runner's own driven browser, or a
component-development tool, because none of them can tell the difference
between a real network response and an intercepted one. Test-runner-level
network mocking (route interception built into a browser-automation E2E
tool) is the E2E-runner-level equivalent of the same idea, scoped to
whichever test framework is already in use rather than a separate
dependency.

**Mobile E2E testing is a further specialization of this same problem**,
with two structurally different current approaches. One does gray-box,
in-process test synchronization directly with the running app; the other
does black-box, accessibility-layer-driven testing via a declarative
flow definition with no native build configuration required at all — a
meaningfully lower setup cost for a team that doesn't want E2E test
infrastructure coupled to native build tooling. Current first-party Expo
documentation recommends the black-box, no-native-build-config approach and
makes no mention of the in-process alternative at all — a real current
signal of where first-party framework backing is heading, worth naming
distinctly from flakiness or CI-runtime claims circulating between the two,
which are vendor/blog claims not independently verified in this doc's own
research pass. Flutter has its own official integration-test package,
distinct from its unit/widget-test tooling, running the full app on a real
device, emulator, or cloud device farm — the natural Flutter-native pairing
with the fake or mocked-repository testing approach Flutter's own
architecture guide (above) already recommends for isolating tests from a
real backend. Specific tool names, license terms, and adoption-signal
comparison across every tool named in this section belong entirely to
[Preferred Libraries: Frontend / Client
Applications](../preferred-libraries/frontend-client-applications.md).

## Where this doc stops

**Anything owning both a backend and a UI** is [Business
Applications](business-applications.md)'s territory, already shipped — this
doc does not re-derive its frontend-architecture section (SPA-vs-RSC/
App-Router choice, auth-behind-a-login framing, RBAC/ABAC-aware UI
concerns), which already covers general frontend engineering for a project
that owns its own backend. This doc names only what's genuinely *different*
when there's no owned backend to lean on: local-first state management,
sync/conflict resolution, app-store distribution, and mobile/desktop as
first-class client targets rather than a web-only assumption.

**Backend-side concerns of any kind** — API design, database selection,
server-side auth issuance, billing/entitlement backend logic — belong to
whichever category owns the backend this category's client happens to call,
most commonly [Backend & API Services](backend-api-services.md) or Business
Applications from *that* project's own perspective, never this one. This
category's project, by definition, does not own that backend.

**Deep native-mobile-platform API guidance** — Swift/SwiftUI-specific or
Kotlin/Jetpack-Compose-specific idiomatic detail for fully-native,
non-cross-platform apps — stays at the decision-axis level named above
(native vs. cross-platform), not a platform-specific deep dive. Fully-native
development is a real, legitimate option, named but not exhaustively
covered, consistent with this skill's cross-platform-leaning scope.

**Specific tool/library names, version pins, license comparisons, and
adoption-signal tables** — which local-first database, which CRDT library,
React Native vs. Flutter adoption-momentum figures, Electron vs. Tauri
governance and packaging-tool detail, which visual-regression or mobile-E2E
product — belong entirely to the companion [Preferred Libraries: Frontend /
Client Applications](../preferred-libraries/frontend-client-applications.md).
This doc names a tool only where its own documented behavior *is* the
architectural fact being described — Flutter's official Services/
Repositories guide, Figma's documented per-property LWW choice, the
network-interception mechanism underlying this category's E2E mocking
approach — not as a comparative recommendation between competing products.

**Cost modeling and app-store fee structures** — Apple's commission tiers,
Google Play's fee schedule — stay out of scope, the same no-cost-modeling
convention every other doc in this skill applies.

**Push notification infrastructure, deep-linking, and analytics/crash-
reporting SDK selection** are real client-app concerns, but not
distinctively *architectural* the way state management, sync, and
distribution mechanics are — a named gap for a possible future addition to
this doc, not silently folded in as if already covered.

## Sources

- Local precedent (read directly, not a web source): full read of
  `ubi-csr-tmf/aws/container/frontend/package.json`, `src/` structure,
  `src/services/`, `public/manifest.webmanifest`, and `public/sw.js`;
  directory listings of `aws/container/` and repo-root `charts/`
  confirming a co-owned backend — read 2026-08-31
- `research/architecture-templates.md`,
  `research/stacks/business-applications/stack.md`,
  `skills/project-incubation/references/stacks/business-applications.md`,
  `skills/project-incubation/SKILL.md`, `research/taxonomy-roadmap.md`,
  and this category's own approved baselines
  (`research/stacks/frontend-client-applications/{stack.md,libraries.md}`)
  — read directly to confirm scope boundaries and author from — read
  2026-08-31
- https://www.inkandswitch.com/essay/local-first/ — direct fetch (this
  pass): the canonical local-first-software essay (Kleppmann, Wiggins,
  van Hardenberg, McGranaghan, Onward! 2019), its seven ideals, and its
  local-primary/server-secondary framing, all quoted directly — retrieved
  2026-08-31
- GitHub REST API, direct queries against `api.github.com/repos/...` for
  `pubkey/rxdb`, `dexie/Dexie.js`, `pouchdb/pouchdb`, `Nozbe/WatermelonDB`,
  `yjs/yjs`, `automerge/automerge`, `loro-dev/loro`,
  `rocicorp/replicache` (confirmed `archived: true`), `rocicorp/mono`
  (Zero), `electric-sql/electric`, `tauri-apps/tauri`,
  `electron/electron`, `facebook/react-native` (redirects to
  `react/react-native`), `flutter/flutter`, `mswjs/msw`,
  `storybookjs/storybook`, `microsoft/playwright`, `wix/Detox`,
  `mobile-dev-inc/maestro`, `chromaui/chromatic-cli` — stars, license,
  `pushed_at`, `archived` — retrieved 2026-08-31
- https://www.figma.com/blog/how-figmas-multiplayer-technology-works/ —
  direct fetch (this pass): Figma's account of rejecting textbook OT
  ("unnecessarily complex for our problem space," a "combinatorial
  explosion of possible states") and textbook CRDTs ("Figma isn't using
  true CRDTs though... since Figma is centralized... we can simplify our
  system"), the per-property LWW-over-a-tree design, and Evan Wallace's
  "no more complex than necessary" principle — retrieved 2026-08-31
- Linear's sync-engine architecture (IndexedDB, LWW default, narrow CRDT
  use for rich text) — search-corroborated secondary analysis only;
  Linear's own primary source is a talk-landing page with no substantive
  text — flagged as not confirmed in Linear's own words — retrieved
  2026-08-31
- ElectricSQL's March 2025 1.0 GA — search-corroborated only, not
  independently fetched or benchmarked — retrieved 2026-08-31
- https://developer.apple.com/distribute/app-review/ — direct fetch:
  "on average, 90% of submissions are reviewed in less than 24 hours,"
  and the expedited-review path's overuse-deprioritization caveat —
  retrieved 2026-08-31
- Google Play's standard review turnaround (1-3 business days typical) —
  search-corroborated only; two direct-fetch attempts at Google-owned
  pages found no stated SLA number, unlike Apple's — retrieved 2026-08-31
- https://support.google.com/googleplay/android-developer/answer/6346149
  — direct fetch: Google Play's staged-rollout mechanic (custom
  percentage, no auto-increase) — retrieved 2026-08-31
- Microsoft App Center/CodePush shutdown (March 31, 2025) and EAS Update
  as the current OTA replacement — search-corroborated across multiple
  sources; introduction mechanics direct-fetch confirmed at
  https://docs.expo.dev/eas-update/introduction/ — retrieved 2026-08-31
- Apple App Store Review Guideline 3.3.1 and the `runtimeVersion`
  fingerprint-policy compatibility mechanism — search-corroborated, not
  independently fetched against Apple's own guideline text — retrieved
  2026-08-31
- Mac App Store sandboxing vs. Developer-ID notarization/Hardened-Runtime
  — search-corroborated across several developer writeups, not one
  single official Apple page — retrieved 2026-08-31
- React Native's New Architecture as the now-mandatory default (opt-out
  removed RN 0.82, legacy bridge deleted RN 0.83; Expo SDK 55+
  New-Architecture-only) — search-corroborated across multiple current
  2026 sources — retrieved 2026-08-31
- React Foundation formation (Linux Foundation, announced 2026-02-24/25;
  Meta's transfer of React/React Native/JSX, deal closing early 2026;
  board spanning Amazon, Callstack, Expo, Meta, Microsoft, Software
  Mansion, Vercel; Meta's $3M+/five-year commitment) — corroborated via
  `research/stacks/frontend-client-applications/libraries.md`'s own
  direct fetch of Meta's engineering.fb.com announcement plus
  linuxfoundation.org, thenewstack.io, theregister.com — retrieved
  2026-08-31
- https://v2.tauri.app/blog/tauri-20/ — direct fetch: Tauri 2.0 stable
  release date, 2024-10-02 — retrieved 2026-08-31
- https://tauri.app/start/ — direct fetch: Tauri's own claim ("a minimal
  Tauri app can be less than 600KB"), no official Electron-comparison
  figure on this page — retrieved 2026-08-31
- Tauri-vs-Electron bundle-size/RAM figures ("3-10MB vs. 120-200MB"
  installer; "30-40MB vs. 200-300MB" RAM) — flagged unverified: only
  third-party/vendor-adjacent blog sources, not independently
  benchmarked — retrieved 2026-08-31
- Electron's OpenJS Foundation Impact Project status — corroborated via
  `research/stacks/frontend-client-applications/libraries.md` — retrieved
  2026-08-31
- https://docs.flutter.dev/app-architecture/guide — direct fetch:
  Flutter's official Services/Repositories layered architecture and the
  "Repositories should never be aware of each other" rule — retrieved
  2026-08-31
- https://developer.android.com/topic/architecture — direct fetch:
  Android's official data-layer/repository architecture, "abstracting
  sources of data from the rest of the app" — retrieved 2026-08-31
- React/web "hexagonal-inspired" client architecture (ports/adapters via
  React Context DI) — search-corroborated community convention, not an
  official standard; a commonly-cited primary writeup 403'd on direct
  fetch and is cited by title/search-snippet only — retrieved 2026-08-31
- https://storybook.js.org/docs/writing-tests/interaction-testing —
  direct fetch: Storybook's interaction-testing feature and CI
  integration — retrieved 2026-08-31
- https://playwright.dev/docs/test-snapshots — direct fetch: Playwright's
  visual-comparison mechanism and its OS/hardware rendering-variance
  caveat — retrieved 2026-08-31
- https://mswjs.io/docs/ — direct fetch: Mock Service Worker's
  network-level interception mechanism and its "single source of truth
  for network behavior" framing — retrieved 2026-08-31
- https://docs.expo.dev/develop/unit-testing/ — direct fetch: Expo's
  current testing guidance, recommending the black-box, no-native-build
  mobile E2E approach with no mention of the in-process alternative —
  retrieved 2026-08-31
- Mobile E2E flakiness/CI-runtime comparison figures between the two
  current approaches — search-corroborated only, vendor-influenced,
  not independently verified — retrieved 2026-08-31
- https://docs.flutter.dev/testing/integration-tests — direct fetch:
  Flutter's official `integration_test` package, distinct from
  `flutter_test`, running on a real device/emulator/device farm —
  retrieved 2026-08-31
