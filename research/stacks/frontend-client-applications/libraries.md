# Baseline: Frontend / Client Applications — Preferred Libraries
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This is category #5 from `research/taxonomy-roadmap.md` — the **last
category still pending** on the current roadmap. Scope, per the roadmap
entry: "web SPAs, mobile apps, desktop apps. Currently implicitly folded
into Business Applications, but a pure client app with no owned backend
has different structural needs (state management, offline/sync,
app-store distribution, no server-side architecture-template question to
answer)." A parallel `stack.md` in this same directory covers
architecture/decision-criteria; this file names specific tools/products
with license and maintenance-signal detail only, matching this repo's
`libraries.md` convention.

**Scoping discipline applied throughout**: this category is specifically
the **backend-less client** — a SPA/mobile/desktop app with no owned
server of its own, consuming either a third-party API directly or a BaaS
(Firebase/Supabase-style) layer. Where Business Applications (already
shipped) already names a library relevant to a full-stack app that
happens to also have a frontend (React itself, Next.js, general UI
patterns), this file does not re-litigate that — it only re-examines a
topic when the backend-less constraint genuinely changes the decision
(state management with no co-located API to cache against; offline/sync
because there's no server of record to always assume reachable;
app-store/binary distribution because there's no web deploy target
alone). One real risk this framing raises and answers directly: a
React web SPA that happens to call a third-party API isn't
automatically "this category" just because it lacks *its own* backend —
Business Applications already covers React/Next.js as a UI layer
generically. What's genuinely new here is (a) mobile/desktop as
first-class targets, not just web, and (b) the client-only state/sync/
distribution concerns that only bite once there's no owned backend to
lean on.

## Local precedent — real, but not an instance of this category itself

`ubi-csr-tmf/aws/container/frontend/package.json` (read in full) is a
genuine, substantial production frontend: **React 19.2 + TypeScript
5.9 + Vite 7.1 + Ant Design v5.27 (with the
`@ant-design/v5-patch-for-react-19` compatibility shim) + TanStack Query
5.90 + React Router 7.9 (data-mode, not SSR) + Okta auth
(`@okta/okta-auth-js` + `@okta/okta-react`) + a Lexical 0.45 rich-text
editor + Tailwind 3.4 + a real (if minimal) PWA setup.**

**Applying this category's own scoping nuance precisely, as instructed**:
this repo also owns its own backend (`ubi-csr-tmf/aws/container/backend`,
a FastAPI/Flask document-processing service, confirmed by direct read of
its `requirements.txt` during the parallel MLOps research pass) — so the
*project* is Business-Applications-shaped, not an instance of this
category's own defining constraint (a client with no owned backend at
all). It is named here honestly as real, current frontend-tooling
evidence from an **adjacent-category project**, not a worked example of
Frontend/Client Applications specifically. `find /Users/devopammittra/
GitHub/agent-skills -iname "*react-native*" -o -iname "*flutter*" -o
-iname "*electron*" -o -iname "*tauri*" -o -iname "*expo*"` — zero
results, confirming no local precedent for the category's actually
distinguishing surfaces (mobile/desktop) exists anywhere checked.

**One genuinely relevant negative finding from the local read**: the
PWA setup is real but deliberately minimal and hand-rolled, not built on
the tooling named below. `frontend/vite.config.ts` has **no
`vite-plugin-pwa` entry** — `public/sw.js` is a hand-written 11-line
service worker (`"Minimal service worker — enables PWA install; no
offline cache (enterprise app)"` per its own header comment) that only
implements install/activate/fetch passthrough, with no Workbox
precaching or offline strategy at all. `public/manifest.webmanifest`
exists for installability. This is a real, honest data point: even a
sophisticated production frontend in this exact tooling ecosystem chose
to *not* adopt the PWA build tooling named in this baseline's own PWA
section, because an internal enterprise tool with guaranteed
connectivity had no offline requirement to justify it — worth carrying
into the authored doc as a concrete "PWA tooling is opt-in, driven by an
actual offline requirement, not a default for every SPA" framing.

## Ecosystem choice

Genuinely split three ways in a manner none of this repo's other eight
categories are — the defining shape of this category, not incidental:
**web** (JS/TS, npm-distributed), **mobile** (React Native/JS-TS or
Flutter/Dart, app-store-distributed binaries), and **desktop**
(Electron/JS-TS or Tauri/Rust+JS-TS, OS-installer-distributed binaries).
Tables below are grouped by this three-way split rather than forced into
one cross-platform table, since license/governance/distribution-model
differ by target, not just by library.

## In scope

### Cross-platform mobile frameworks — impact: high — depth: table + decision rule

**Adoption data verified fresh, not assumed from stale priors — this has
genuinely shifted and the two frameworks are closer than older
"React Native wins" priors suggest.** A 2025 Statista survey of 500
enterprise mobile teams found 42% using React Native vs. 38% using
Flutter — a near-even enterprise split. Broader developer-population
surveys (Stack Overflow Developer Survey 2024) found Flutter slightly
ahead among all developers (9.4% vs. 8.4%) and further ahead among
*learners* specifically (11.1% vs. 6.7%) — Flutter is winning new
adopters at a faster clip even where React Native retains an installed-
base edge. **Job-market reality cuts the other way**: React Native
carries roughly 6x more US job postings than Flutter, reflecting its
longer market presence and deeper enterprise entrenchment, not current
developer-mindshare direction. Read together: Flutter has real
mindshare/growth momentum; React Native has real incumbency/hiring
depth. Neither framework is fading — this is a genuine two-horse race,
not a decided one.

**React Native's governance changed materially and very recently — a
fresh, load-bearing finding, not background color.** The Linux
Foundation announced formation of the **React Foundation on
2026-02-24/25**, with Meta transferring **React, React Native, and
JSX** into it (announced by Meta's own engineering blog 2025-10-07, deal
closing early 2026). The governing board spans **Amazon, Callstack,
Expo, Meta, Microsoft, Software Mansion, and Vercel** — Meta retains a
majority board stake for an initial period and commits **$3M+ over a
five-year partnership** plus a continuing dedicated engineering team, but
technical governance (releases, features, direction) is now explicitly
separated from the business/foundation layer and driven by maintainers,
not Meta unilaterally. This is a genuine governance shift from
single-vendor-owned to multi-stakeholder-foundation-owned, landing
inside this exact snapshot window (last confirmed activity February–May
2026) — the "Meta ownership" framing this baseline was asked to verify
is now materially outdated as of this pass and should not be stated as a
simple fact without this correction.

**Flutter/Dart remains squarely Google-owned, unchanged.** No
comparable foundation transfer has occurred; Google continues to fund
and direct Flutter/Dart development directly. Despite periodic "is
Google abandoning Flutter" rumor cycles (most recently resurfacing
around Google's broader 2024 cost-cutting), current search corroboration
shows continued investment: over 1M active developers, ~30% of new free
iOS apps now built with Flutter (up from ~10% in 2021), and eight stable
releases shipped in 2025 on a quarterly cadence — described in Google's
own framing as Flutter's "Production Era." Worth stating plainly: this
is a real, if less formalized, governance-risk asymmetry against React
Native's new foundation model — Flutter's continuity still rests on one
company's continued willingness to fund it, not a multi-stakeholder
structure.

| Framework | License | Governance | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|
| **React Native** (`facebook/react-native`) | MIT | **React Foundation** (Linux Foundation), as of 2026-02; Meta remains the largest single contributor/funder under a 5-year committed partnership, board includes Amazon/Callstack/Expo/Meta/Microsoft/Software Mansion/Vercel | 2026-08-31 | Direct GitHub fetch: 126,463 stars, 25,234 forks, 1,170 open issues, pushed 2026-08-31 (very active) |
| **Flutter** (`flutter/flutter`) | BSD-3-Clause | Google-owned and Google-funded, no foundation transfer | 2026-08-31 | Direct GitHub fetch: 178,730 stars, 31,033 forks, 13,210 open issues (notably higher open-issue count than React Native — a volume/triage signal worth a light flag, not necessarily neglect given commit cadence), pushed 2026-08-31 (very active) |

**Decision rule**: default to **React Native** when the team is
JS/TS-first, wants to share code/patterns with an existing React web
codebase, or values the newly multi-stakeholder governance model as a
lower single-vendor-risk bet; default to **Flutter** when pixel-perfect
cross-platform UI consistency matters more than JS-ecosystem code
sharing, the team is starting fresh with no existing React investment,
or the higher current learner/mindshare growth rate is itself a signal
worth weighing for long-term hiring. Neither is a wrong default in 2026
— this is a genuine team-fit decision, not a clear technical winner,
and the honest current data (near-even enterprise split, opposite
signals on incumbency vs. growth) should be stated to the user rather
than collapsed into one recommendation.

### Cross-platform desktop frameworks — impact: high — depth: table + decision rule

**Electron's governance, reconfirmed precisely**: Electron is an
**OpenJS Foundation Impact Project** (graduated from incubation), under
the OpenJS Foundation's Cross-Project Council technical-governance
model — the same vendor-neutral foundation home as Node.js, Express,
and Jest. Not single-vendor-owned.

**Tauri's maturity, verified current rather than assumed**: Tauri is
past its early-maturity phase — latest stable is **v2.11.5, published
2026-07-01** (Tauri 2.0 itself shipped GA in October 2024), and its
GitHub star count (110,704) has grown to within range of Electron's own
(122,819) in this snapshot, a genuinely fresh convergence worth stating
precisely rather than assuming Tauri is still "the smaller upstart."
Apache-2.0, no single-vendor governance concentration comparable to a
foundation but no BSL/SSPL-style commercial gate either.

**Concrete, current, direct-fetch-corroborated discriminators** (search-
corroborated benchmark figures, consistent across multiple independent
2026 comparison sources, not independently re-benchmarked in this pass):
a Tauri "Hello World" build ships around **3–10 MB** vs. Electron's
**120–200 MB** (Electron bundles a full Chromium + Node.js runtime;
Tauri uses Rust for the backend and the OS's native WebView, so the
runtime isn't shipped in the binary at all) — roughly a 20–50x bundle-
size difference. Idle memory footprint is reported around **42 MB**
(Tauri) vs. **168 MB** (Electron), a 50–75% reduction. Native-API access
model differs structurally, not just in overhead: Electron ships Node.js
directly in the renderer/main process, giving full Node API access
out of the box; Tauri instead exposes a Rust-side command-invocation
bridge (`#[tauri::command]`) that the JS frontend calls into
explicitly, and native OS integration requires either a first-party
Tauri plugin or writing Rust — a materially different (more explicit,
more secure-by-default, steeper-if-unfamiliar) native-access model than
Electron's implicit Node access.

| Framework | License | Governance | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|
| **Electron** (`electron/electron`) | MIT | **OpenJS Foundation** Impact Project (vendor-neutral, Node.js/Express/Jest's own foundation home) | 2026-08-31 | Direct GitHub fetch: 122,819 stars, 17,453 forks, 751 open issues, pushed 2026-08-31 (very active) |
| **Tauri** (`tauri-apps/tauri`) | Apache-2.0 | Tauri Programme within the Commons Conservancy (nonprofit steward, not a single-vendor-owned project); no BSL/SSPL commercial gate | 2026-08-31 | Direct GitHub fetch: 110,704 stars, 3,910 forks, 1,458 open issues, pushed 2026-08-31 (very active); latest release `tauri-v2.11.5`, published 2026-07-01 |
| **electron-builder** (`electron-userland/electron-builder`) | MIT | Community-maintained, the standard Electron packaging/installer tool (not first-party OpenJS) | 2026-08-31 | Direct GitHub fetch: 14,659 stars, 1,869 forks, pushed 2026-08-30 (active) |
| **Electron Forge** (`electron/forge`) | MIT | First-party, under the `electron` GitHub org itself | 2026-08-31 | Direct GitHub fetch: 7,135 stars, 640 forks, pushed 2026-08-28 (active); latest release `v7.11.2`, published 2026-05-20 |

**Decision rule**: default to **Tauri** for a genuinely new desktop
project where bundle size, memory footprint, and a more locked-down
native-access model matter, and the team is willing to have some Rust
in the stack (even if only at the plugin boundary) — the bundle-size/
memory gap is large enough to be a real user-facing differentiator
(install time, disk footprint on constrained machines), not a rounding
error. Default to **Electron** when the team wants zero Rust exposure,
needs the broadest existing plugin/native-integration ecosystem (still
larger than Tauri's, by tenure), or is porting/sharing significant code
with an existing Node.js backend that assumes direct Node API access.
For packaging: **electron-builder** is the more feature-complete,
higher-adoption choice for Electron; **Electron Forge** is the
first-party option with tighter Electron-team integration, worth
preferring when staying entirely within first-party tooling is valued
over electron-builder's broader feature set. Tauri's bundler is built
into the Tauri CLI itself — no separate packaging-tool decision exists
for it.

### State management for backend-less/client-heavy apps — impact: high — depth: table + decision rule

**Scope boundary, stated explicitly**: Business Applications already
names React/Next.js as UI-layer choices but does not deep-dive
client-state-management library choices, since a full-stack app
typically leans on server-side state (RSC, API routes, session state)
more than a pure client does. This section is this category's own
contribution: what to reach for when there is no co-located backend to
own canonical state, so *all* meaningful state — including "remote"
data — has to be modeled and cached entirely client-side.

**Current relative adoption, verified rather than listing everything
that exists**: **Zustand** has clearly separated from the pack as the
default lightweight client-state library — 58,628 stars, still gaining
(pushed 2026-08-28) and roughly **5x Redux Toolkit's** star count
(11,225) despite Redux Toolkit being the "official," longer-established
choice. This is a genuine, current adoption inversion worth stating
plainly rather than defaulting to Redux Toolkit out of institutional
habit. **Jotai** (21,251 stars, atomic/bottom-up model, good fit when
state genuinely decomposes into many small independent atoms rather
than one global store) sits as the clear #2 lightweight option. **Redux
Toolkit** remains relevant specifically for teams with an existing large
Redux codebase or those wanting Redux DevTools' mature time-travel
debugging and a very large existing middleware ecosystem — not the
default for a new backend-less client app in 2026.

**TanStack Query's role in this category specifically**: even with no
owned backend, a backend-less client still very often talks to *someone
else's* API (a third-party REST/GraphQL API, or a BaaS like Firebase/
Supabase) — TanStack Query's cache/refetch/stale-time model applies
identically to that case as it does to an owned backend, which is why
the local-precedent frontend already uses it (TanStack Query 5.90)
against its own owned API. Genuinely worth naming here on its own
strength (50,238 stars, pushed 2026-08-31, the single most-starred
library in this table) as "the" answer for *remote*-shaped client state
specifically, paired with Zustand/Jotai for *local*-only UI/app state —
not a replacement for either, a different axis of the same app's state.

**Legend State, checked for genuine currency rather than assumed**: a
real, current, local-first-oriented library — **v3 is in beta as of
this pass** (not yet the recommended stable default; the project's own
docs recommend starting new projects on the v3 beta over v2 given how
much has improved), built around fine-grained observables with
built-in local-persistence and sync plugins (Keel, Supabase, TanStack
Query, plain fetch). Smaller adoption than the above (4,193 stars) but
a genuinely distinct value proposition — optimistic local-first writes
with automatic retry-until-synced — worth naming specifically for a
backend-less app that wants offline-tolerant writes without adopting a
full CRDT database (see next section).

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Zustand** (`pmndrs/zustand`) — **default for local/UI state** | Lightweight global client state, minimal boilerplate | MIT | The current default — has overtaken Redux Toolkit in adoption momentum by a wide and still-growing margin | 2026-08-31 | 58,628 stars, 2,188 forks, pushed 2026-08-28 |
| **Jotai** (`pmndrs/jotai`) | Atomic/bottom-up state composition | MIT | Best fit when state naturally decomposes into many small independent pieces rather than one store | 2026-08-31 | 21,251 stars, 724 forks, pushed 2026-08-24 |
| **Redux Toolkit** (`reduxjs/redux-toolkit`) | Global state with mature DevTools/middleware ecosystem | MIT | Named for an existing Redux codebase or teams wanting time-travel debugging depth; not the default for a new backend-less client in 2026 given the adoption gap to Zustand | 2026-08-31 | 11,225 stars, 1,292 forks, pushed 2026-08-24 |
| **TanStack Query** (`TanStack/query`) — **default for remote/cached-API state** | Fetching, caching, and sync of any remote data source (third-party API, BaaS, or an owned backend alike) | MIT | The most-adopted, most-current option in this table; equally applicable whether or not the client owns a backend, since it caches against whatever API is called | 2026-08-31 | 50,238 stars, 4,226 forks, pushed 2026-08-31 (most active repo in this table) |
| **Legend State** (`LegendApp/legend-state`) | Fine-grained observable state with built-in local-first persistence/sync plugins | MIT | The genuinely current local-first-oriented option — named specifically for a backend-less app wanting offline-tolerant optimistic writes without adopting a full sync database; v3 (recommended for new projects per the project's own docs) is still beta, worth flagging before treating as a stable default | 2026-08-31 | 4,193 stars, 145 forks, pushed 2026-08-11 |

**Decision rule**: pair **Zustand** (local/UI state) with **TanStack
Query** (remote/cached-API state) as the default combination for a new
backend-less client — this is the same shape the local-precedent
project already uses for its remote-state half, extended here with
Zustand for the local half. Reach for **Jotai** instead of Zustand when
state is naturally atomic/fine-grained rather than store-shaped. Reach
for **Redux Toolkit** only when inheriting an existing Redux codebase or
specifically wanting its DevTools depth. Reach for **Legend State**
specifically when the app needs offline-tolerant optimistic local
writes with automatic background sync and doesn't want to hand-roll
that retry logic on top of Zustand/TanStack Query — treat it as
beta-stage on v3, stable-but-superseded on v2.

### Offline-first / local-first / sync libraries — impact: high — depth: table + decision rule

**Scope note**: this is the section with no Business Applications
analog at all — a full-stack app with its own backend rarely needs a
client-side sync database, since the owned backend *is* the source of
truth reachable directly. A backend-less client that still needs
multi-device consistency or offline tolerance has to solve this
client-side, which is what makes this section genuinely category-
defining.

**PouchDB, a real and precise nuance found via direct API verification,
not assumed from a stale prior**: PouchDB is simultaneously the
**longest-established** option here and shows a striking split
signal — the repo's `pushed_at` is **2026-08-25 (very actively
committed to)**, but its **latest tagged GitHub release is `9.0.0`,
published 2024-06-21** — over two years without a new tagged release
despite ongoing commit activity. (One search source claimed an "8.0.0
release in June 2026," which a direct `gh api repos/pouchdb/pouchdb/
releases` fetch during this pass did not corroborate — the actual
release history tops out at `9.0.0`/2024-06-21, confirming the
search-summarized claim was wrong and the direct fetch is the fact of
record.) Community signals (CouchDB's own project digest posts)
describe bi-weekly PouchDB triage sessions working through a backlog —
consistent with "actively maintained by a smaller volunteer team,
slower on cutting tagged releases" rather than abandoned. Worth this
precise framing rather than either "thriving" or "dead."

**WatermelonDB, checked for the specific churn this repo's instructions
flagged**: `Nozbe/WatermelonDB` is maintained by Nozbe (a task-
management company that runs it in their own production app — a real
maintenance-motivation signal, not just goodwill) but shows **pushed_at
2025-08-11, roughly 12.5 months stale relative to this snapshot** — a
real, worth-flagging staleness gap, though not abandoned (no archive
flag, active alternative-comparison coverage in current 2026 sources).

**RxDB's license, verified precisely rather than assumed permissive
end-to-end**: the core `pubkey/rxdb` repo is genuinely **Apache-2.0**
(confirmed via direct GitHub API license-metadata fetch, not just
README framing) — but this is an **open-core product**, not a fully
free one: RxDB Premium (Pro/Pro Plus/Enterprise tiers, annual-only
licensing, no monthly option) gates better performance, smaller build
size, additional storage-engine backends, and encryption — and the free
core tier itself caps out at **13 open collections in parallel**, a
concrete, load-bearing free-tier limit worth stating precisely (not
every open-core product in this repo's other baselines has a numeric
usage cap this specific). A notable non-commercial carve-out: a single
developer using RxDB in a side project can get 2 years of free Premium
access by completing a maintainer-listed task.

**CRDT-based sync libraries, checked for genuine current adoption
rather than named on reputation alone**: **Yjs** is the clear
production-adoption leader — search-corroborated at roughly 920K weekly
downloads with the largest ecosystem of framework bindings/providers,
and is the default choice for collaborative text/rich-editor use cases
specifically (a genuinely adjacent fit to the local precedent's own
Lexical rich-text editor, though the local precedent does not currently
use Yjs for that). **Automerge** is smaller in raw adoption (~85K
downloads) but has closed a real historical performance gap: Automerge
3.0 (July 2025) re-architected around columnar compression for a
reported 10x+ memory-usage reduction, and its JSON-document-with-
Git-like-history model is the better fit than Yjs's text/shared-types
model for backend-less apps modeling structured records (not
prose/rich-text) that want full change-history for free. Both are
genuinely current, actively developed, and not competing for the exact
same use case — worth naming both rather than picking one winner.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **RxDB** (`pubkey/rxdb`) — **default for a full local-first database** | NoSQL local-first database (IndexedDB/OPFS/SQLite storage adapters) with built-in replication to an existing backend | Apache-2.0 core (open-core; Premium tiers gate performance/storage-engine/encryption features — see callout, including a hard 13-collection free-tier cap) | The most actively developed, broadest-storage-adapter option in this table; the free-tier collection cap is real and should be sized against the app's actual schema before committing | 2026-08-31 | 23,371 stars, 1,175 forks, pushed 2026-08-31 (very active, most active repo in this section) |
| **WatermelonDB** (`Nozbe/WatermelonDB`) | React Native-first local-first database, built for large-dataset lazy-loading performance | MIT | Best fit specifically for React Native apps wanting a mature, SQLite-backed local database with a proven large-scale production user (Nozbe's own app); the ~12.5-month staleness gap is a real, worth-flagging maintenance-velocity concern before adopting as a primary dependency today | 2026-08-31 | 11,778 stars, 656 forks, **pushed 2025-08-11 — ~12.5 months stale relative to this pass**, a real flag |
| **PouchDB** (`pouchdb/pouchdb`) | Offline-first local database purpose-built to sync/replicate with CouchDB (or CouchDB-compatible) servers | Apache-2.0 | The right choice specifically when the backend (or a BaaS) already speaks CouchDB's replication protocol; not a general-purpose pick outside that pairing | 2026-08-31 | 17,603 stars, 1,507 forks, 185 open issues, pushed 2026-08-25 (active commits) but **latest tagged release `9.0.0` published 2024-06-21 — over 2 years without a new tag**, a real, precise nuance worth stating rather than either "thriving" or "abandoned" |
| **Yjs** (`yjs/yjs`) | CRDT sync engine for real-time collaborative editing (text/rich-content-shaped data) | License field returns `NOASSERTION` on GitHub's own detector — not independently re-verified by reading the LICENSE file directly this pass, a real gap to flag rather than assume permissive | The production-adoption leader for collaborative-editing CRDT sync specifically (largest ecosystem of bindings/providers); best fit for prose/rich-text collaborative state | 2026-08-31 | 22,728 stars, 799 forks, pushed 2026-08-06; ~920K weekly downloads per current search corroboration (not independently direct-fetched from npm this pass) |
| **Automerge** (`automerge/automerge`) | CRDT sync engine for structured JSON-document data with full built-in change history | MIT | Best fit for backend-less apps syncing structured records (not prose) that want Git-like history for free; Automerge 3.0's columnar-compression rewrite (July 2025) closed most of the historical memory-overhead gap to Yjs | 2026-08-31 | 6,545 stars, 266 forks, pushed 2026-08-28; ~85K downloads per current search corroboration (not independently direct-fetched from npm this pass) |

**Decision rule**: for a backend-less app that needs a full local
database with replication to *some* backend, default to **RxDB** given
its broadest storage-adapter support and active development, sizing the
free tier's 13-collection cap against the app's schema first; choose
**WatermelonDB** specifically for a React Native app already accepting
some staleness risk in exchange for large-dataset read performance;
choose **PouchDB** only when the backend already speaks CouchDB's
replication protocol. For real-time multi-user collaborative state
specifically (not just single-user offline tolerance), reach for **Yjs**
when the shape is prose/rich-text (a natural pairing with the local
precedent's own Lexical editor, notable even though not currently wired
together there) and **Automerge** when the shape is structured JSON
records wanting built-in version history.

### PWA tooling — impact: med — depth: paragraph + table, framed by the local precedent's own minimal setup

**Workbox's governance, verified rather than assumed**: `GoogleChrome/
workbox` remains a **Google Chrome-team-maintained** project (not spun
out to a neutral foundation) — MIT-licensed, 12,995 stars, pushed
2026-08-04 (roughly 3.5 weeks stale relative to this snapshot, not a
concerning gap for a mature, feature-complete library). Still the
de facto service-worker toolkit underneath the broader PWA-build-tooling
ecosystem, including the plugin named below.

**vite-plugin-pwa**, the natural fit given the local precedent's own
Vite-based build, wraps Workbox rather than replacing it: maintained by
the community `vite-pwa` GitHub org (not Google, not a foundation),
MIT-licensed, 4,258 stars, pushed 2026-05-05 (roughly 4 months stale
relative to this snapshot — worth a light freshness check at authoring
time, though the plugin is feature-stable enough that a quiet period is
not automatically a red flag the way it would be for a fast-moving
framework). It lazy-loads `workbox-build` internally and exposes both
Workbox's `generateSW` (zero-config precaching) and `injectManifest`
(hand-written service worker with Workbox's precache-manifest injected
in) strategies.

**The local precedent's own choice is the load-bearing finding for this
section, not a footnote**: `ubi-csr-tmf/aws/container/frontend` uses
**neither** `vite-plugin-pwa` nor Workbox — its `sw.js` is 11 lines of
hand-written install/activate/fetch-passthrough with **no offline
caching whatsoever**, explicitly commented as sufficient because the
app is an internal enterprise tool with assumed connectivity and only
wanted install-ability (the PWA "Add to Home Screen" affordance), not
offline support. This is a real, current example of PWA tooling being
correctly *skipped* rather than under-used — worth carrying into the
authored doc as the honest framing: reach for `vite-plugin-pwa`/Workbox
specifically when there's a genuine offline requirement, not by default
for every SPA that wants installability.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| **Workbox** (`GoogleChrome/workbox`) | Service-worker precaching/routing/runtime-caching strategies | MIT | The underlying toolkit almost every current PWA build plugin wraps rather than reimplementing | 2026-08-31 | 12,995 stars, 880 forks, pushed 2026-08-04 |
| **vite-plugin-pwa** (`vite-pwa/vite-plugin-pwa`) | Zero-config-to-configurable PWA/service-worker generation for Vite builds | MIT | The natural default for any Vite-based frontend (the local precedent's own build tool) wanting a real offline strategy, not the hand-rolled passthrough it currently ships with | 2026-08-31 | 4,258 stars, 256 forks, pushed 2026-05-05 |

### App-store distribution / build tooling — impact: high — depth: table + decision rule

**Expo's positioning, verified as genuinely evolved rather than assumed
from an older "managed vs. bare workflow" framing**: as of this pass,
current sources converge on **Expo (managed workflow + EAS Build) being
the right default for nearly every new React Native project**, not just
a training-wheels option for apps without custom native code. Expo SDK
53/54-era config plugins and first-class Expo Modules now cover
virtually every native API surface without ejecting; the old rule of
"go bare once you need a native module" has been replaced by "stay on
Expo unless contributing to React Native core itself or hitting one
specific unwrappable native dependency." EAS Build/Update/Submit handle
cloud compilation, OTA updates, and store submission as one managed
pipeline — a genuinely different (and higher-leverage) default than
the historical framing.

**Fastlane's governance, checked precisely rather than assumed
Google-maintained in the active sense**: Google acquired Fastlane in
January 2017 and technically still holds it, but search corroboration
is consistent and specific — **Google has not sponsored the project
since November 2021**, and ongoing maintenance/new-maintainer approval
has been noted as difficult as a result. The actual current development
activity lives in the community `fastlane-community` GitHub
organization. Practical read: Fastlane is not abandoned (still the
de facto CLI for automating iOS/Android builds, code signing, and
store-metadata submission, with real recent commit activity) but is a
**nominally corporate-owned, practically community-sustained** project
worth naming as a governance nuance the same way this repo's other
baselines flag "was popular, now stale" or BSL-style commercial-capture
patterns — this is a different but comparably worth-stating pattern:
corporate ownership with corporate disengagement.

**Desktop-equivalent packaging tooling**: covered above (Cross-platform
desktop frameworks section) — `electron-builder`/`Electron Forge` for
Electron, Tauri's own built-in bundler for Tauri — not re-listed here to
avoid duplication.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Expo** (`expo/expo`, EAS Build/Update/Submit) — **default for React Native** | Cloud build pipeline, OTA updates, and app-store submission for React Native apps, now covering nearly all native-API needs via config plugins/Expo Modules without ejecting | MIT (the open-source SDK/CLI; EAS itself is a managed cloud service, usage-metered, not separately licensed as OSS) | The current default for nearly every new React Native project per this pass's search corroboration — a genuinely evolved position from the older "managed workflow only for simple apps" framing; Expo also holds a board seat on the new React Foundation (see mobile-frameworks section), a further signal of its centrality to the React Native ecosystem specifically | 2026-08-31 | 51,927 stars, 13,708 forks, pushed 2026-08-31 (very active) |
| **Fastlane** (`fastlane/fastlane`) | CLI automation for iOS/Android build, code-signing, and app-store-metadata submission — the underlying tool EAS Submit itself is often layered on or compared against | MIT | Still the de facto store-submission automation tool with real ongoing (community-driven) activity; the corporate-disengagement nuance above is worth surfacing to a team evaluating long-term dependency risk, not a reason to avoid it today | 2026-08-31 | 42,044 stars, 6,025 forks, pushed 2026-08-28 (active); nominal owner Google, but no Google sponsorship since November 2021 per search corroboration — active development now lives in the community `fastlane-community` org |

**Decision rule**: default to **Expo + EAS** for a new React Native
project's entire build/OTA-update/store-submission pipeline; reach for
**Fastlane** directly only when the team is on bare React Native (or
native iOS/Android) and needs CLI-level control over signing/submission
that EAS doesn't already provide, or is integrating store automation
into a CI pipeline EAS doesn't cover. For Flutter, the ecosystem's own
first-party `flutter build`/Codemagic-or-similar CI tooling covers the
equivalent need — not independently deep-researched this pass, a real
gap worth flagging (see Explicitly out of scope).

### Testing tooling specific to this category — impact: med — depth: table + scope boundary vs. E2E

**Scope boundary, checked per this baseline's own instruction**: neither
`business-applications.md` nor any other shipped `preferred-libraries/
*.md` file names Playwright or Cypress anywhere (confirmed via a repo-
wide grep across all nine shipped files) — so there is no sibling
category to defer E2E testing to. Rather than leaving a silent gap or
deep-researching a topic outside this pass's core ask, E2E is named here
at a light, "these exist and are current" level only, consistent with
this repo's convention for named-but-not-deep-researched items (matching
how MLOps/Platform Engineering names cloud-native registries).

**Component-testing tools**: **React Testing Library** (`testing-library/
react-testing-library`) remains the standard for behavior-driven
component tests (query by role/text, not implementation detail) —
19,645 stars, MIT, pushed 2026-08-27. **Storybook's own test-runner and
interaction-testing features have matured into a genuine component-
testing platform, not just a docs/preview tool**, verified via current
Storybook docs: interaction tests (Vitest-integrated, step-through
debugging in the Interactions panel), accessibility tests, visual tests,
and coverage reports are now run together in CI directly from stories,
without spinning up the full app — Storybook itself: 90,973 stars, MIT,
pushed 2026-08-31 (the most active repo in this entire document).

**Visual-regression tools, with the licensing/commercial-tier structure
this baseline was asked to check precisely**: neither **Chromatic**
(Storybook's own commercial visual-testing SaaS) nor **Percy** (owned by
BrowserStack) is open-source — both are proprietary hosted services with
metered free tiers. Verified current pricing shape: Chromatic's free
tier covers 5,000 snapshots/month on Chrome only, with paid tiers ($179/
mo Starter for 35K snapshots, adding Safari/Firefox/Edge; $399/mo Pro
for 85K) and per-overage-snapshot billing ($0.008/snapshot). Percy's
free tier is also 5,000 snapshots/month, but its paid tier starts
materially higher (~$599/mo per current search corroboration) — Percy
is consistently priced well above Chromatic and other current
alternatives (e.g. Argos CI, named in current comparison sources but not
independently deep-researched this pass) at comparable snapshot volumes.
**The real licensing-trap-shaped finding here**: both tools gate
*volume*, not core functionality, the opposite shape from an open-core
license trap (no self-hosting alternative exists for either — this is a
pure managed-SaaS decision, not a license-text-reading exercise the way
Sidekiq/Avo/Lago were in Business Applications) — the trap, if any, is
snapshot-volume cost creep at scale, worth sizing against the app's
actual story/variant count before committing to a plan.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **React Testing Library** (`testing-library/react-testing-library`) | Behavior-driven component unit tests | MIT | The standard, query-by-role/text approach that discourages testing implementation detail | 2026-08-31 | 19,645 stars, 1,168 forks, pushed 2026-08-27 |
| **Storybook** test-runner / interaction tests (`storybookjs/storybook`) | Story-driven component tests: interaction, accessibility, and visual checks run together in CI without the full app | MIT | Matured from a docs/preview tool into a genuine component-testing platform; a natural fit for any project already writing stories for UI development | 2026-08-31 | 90,973 stars, 10,430 forks, pushed 2026-08-31 (most active repo named in this document) |
| **Chromatic** (Storybook's own commercial visual-testing product) | Cross-browser visual-regression snapshots, tied directly into Storybook stories | Proprietary hosted SaaS | The natural pairing for a project already on Storybook; free tier (5K snapshots/mo, Chrome-only) is real but volume-limited — priced below Percy at comparable paid-tier volume | 2026-08-31 | Not independently direct-fetched (commercial SaaS, no public repo); pricing search-corroborated: free tier 5K/mo; Starter $179/mo (35K, adds Safari/Firefox/Edge); Pro $399/mo (85K); $0.008/extra snapshot |
| **Percy** (BrowserStack) | Cross-browser visual-regression snapshots, integrates with Cypress/Playwright/Storybook alike | Proprietary hosted SaaS | Broader test-runner integration than Chromatic (not Storybook-exclusive) but priced materially higher at comparable volume — reach for this specifically when the team is already on BrowserStack for cross-browser testing generally | 2026-08-31 | Not independently direct-fetched; pricing search-corroborated: free tier 5K/mo, paid tier starting ~$599/mo |
| Playwright (`microsoft/playwright`) — named at existence level only | End-to-end browser testing | Apache-2.0 | No sibling category names this; named here lightly since this category is the natural home, but not deep-researched this pass (see Explicitly out of scope) | 2026-08-31 | 95,415 stars, 6,368 forks, pushed 2026-08-31 |
| Cypress (`cypress-io/cypress`) — named at existence level only | End-to-end browser testing | MIT | Same as Playwright — named for completeness, not deep-researched | 2026-08-31 | 51,020 stars, 3,661 forks, pushed 2026-08-31 |

**Decision rule**: pair **React Testing Library** for component-level
unit tests with **Storybook's interaction/a11y/visual test-runner** when
the project already authors stories for UI development — the marginal
cost of adding tests on top of existing stories is low. Reach for a
dedicated visual-regression SaaS (**Chromatic** by default given its
lower cost at comparable volume and tight Storybook integration; **Percy**
specifically when already standardized on BrowserStack) only once visual
drift has caused a real incident or the design system is stable enough
that pixel-diffs carry signal rather than noise. E2E tool choice
(Playwright vs. Cypress) is named but explicitly flagged as not deep-
researched in this pass — a real gap for a follow-up, not a considered
recommendation either way.

## Explicitly out of scope

- **Frontend UI component libraries** (MUI, shadcn/ui, Ant Design, and
  similar) — Business Applications' own baseline already excluded these
  as "a general frontend concern... belongs in a cross-cutting frontend
  baseline rather than duplicated here," which arguably makes this
  category their natural home. Not covered in this pass regardless,
  since it wasn't in this baseline's explicit research brief — a real,
  named gap for a follow-up pass, not an oversight to paper over.
- **React/Next.js/React Router themselves as web frameworks** — already
  named and license/adoption-verified in Business Applications; this
  file only re-examines state-management/sync/distribution topics that
  differ specifically because of the backend-less constraint, not the
  base framework choice itself.
- **Flutter-side build/CI/distribution tooling** (Codemagic or
  equivalent) — named only implicitly via the mobile-frameworks section;
  not independently deep-researched the way Expo/EAS and Fastlane were
  for the React Native side. A real gap given Flutter's near-even
  adoption with React Native in this same pass's own findings.
- **E2E testing tool depth (Playwright vs. Cypress decision criteria)** —
  named at an existence level only per the Testing section above; no
  sibling category claims this topic, but it also wasn't deep-researched
  here, which is itself worth flagging rather than silently deferring.
- **BaaS platforms as a category** (Firebase, Supabase, Appwrite) —
  these are whole-product/vendor-selection decisions analogous to how
  Business Applications excluded no-code platforms (Retool/Appsmith/
  Budibase) as "whole-product procurement decisions, not libraries to
  add to a codebase." A backend-less client very often talks to one of
  these, and the *state-management/sync* libraries in this file (e.g.
  Legend State's Supabase sync plugin) name specific integration points,
  but BaaS vendor selection itself is not researched here.
- **Native (non-cross-platform) mobile development** (Swift/SwiftUI,
  Kotlin/Jetpack Compose) — this category's roadmap framing is
  specifically cross-platform client tooling; a team choosing fully
  native per-platform development isn't reaching for a
  cross-platform-framework decision at all, and native-platform-specific
  library curation is a different, much larger research surface not
  implied by this category's own roadmap scope.
- **Desktop-equivalent app-store distribution depth** (Mac App Store /
  Microsoft Store submission specifics, notarization workflows) — named
  only at the packaging-tool level (electron-builder/Electron Forge/
  Tauri's bundler); the deeper platform-specific submission/notarization
  process itself was not independently researched this pass.

## Sources

- Local `find`/direct-read passes, 2026-08-31: full read of
  `/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/
  package.json`, `vite.config.ts`, `public/sw.js`, and a listing of
  `public/` confirming `manifest.webmanifest` presence and no
  `vite-plugin-pwa`/Workbox dependency; `find agent-skills -iname
  "*react-native*" -o -iname "*flutter*" -o -iname "*electron*" -o
  -iname "*tauri*" -o -iname "*expo*"` — zero results.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license,
  stars, forks, open issues, `pushed_at`, `archived`) for:
  facebook/react-native, flutter/flutter, electron/electron,
  tauri-apps/tauri, electron-userland/electron-builder, electron/forge,
  pmndrs/zustand, pmndrs/jotai, reduxjs/redux-toolkit, TanStack/query,
  LegendApp/legend-state, pouchdb/pouchdb, Nozbe/WatermelonDB,
  pubkey/rxdb, yjs/yjs, automerge/automerge, GoogleChrome/workbox,
  vite-pwa/vite-plugin-pwa, expo/expo, fastlane/fastlane,
  testing-library/react-testing-library, storybookjs/storybook,
  microsoft/playwright, cypress-io/cypress — retrieved 2026-08-31.
- `gh api repos/tauri-apps/tauri/releases/latest`,
  `gh api repos/electron/forge/releases/latest`,
  `gh api repos/pouchdb/pouchdb/releases` (full recent-release list,
  not just `/latest`, specifically to resolve a search-summarized claim
  of an "8.0.0 release in June 2026" that this direct fetch did not
  corroborate — actual latest tag is `9.0.0`, published 2024-06-21) —
  retrieved 2026-08-31.
- `curl`/`gh api` direct license-file/metadata checks: `pubkey/rxdb`
  license metadata confirmed Apache-2.0 for the core repo (RxDB
  Premium's separate commercial terms corroborated via search of
  `rxdb.info/premium/`, not independently fetched as a license
  document) — retrieved 2026-08-31.
- WebSearch corroboration (not independently direct-fetched primary
  source, flagged inline where used): React Native vs. Flutter 2025/2026
  adoption data (Statista enterprise survey, Stack Overflow Developer
  Survey 2024, job-posting-volume comparisons, via
  quashbugs.com/tech-insider.org/discretelogix.com aggregations);
  React Foundation formation and governance structure (Meta's own
  engineering.fb.com announcement, directly fetched via WebFetch;
  linuxfoundation.org press release; thenewstack.io; theregister.com);
  Flutter's continued Google investment and adoption figures
  (blackkitetechnologies.com, devnewsletter.com "State of Flutter 2026");
  Tauri vs. Electron bundle-size/memory-footprint benchmarks
  (rustify.rs, tech-insider.org, pkgpulse.com — consistent across
  multiple independent sources, not independently re-benchmarked this
  pass); Expo/EAS current managed-workflow-as-default positioning
  (silpho.com, pawelkarniej.com); Fastlane's Google-ownership-but-no-
  sponsorship-since-2021 finding (analyticsindiamag.com,
  connortumbleson.com, the `fastlane-community` GitHub org's own
  existence); Legend State v3 beta status and local-first sync-plugin
  list (legendapp.com's own docs/blog); Storybook's current
  interaction/a11y/visual test-runner feature set (storybook.js.org's
  own docs); Chromatic and Percy current pricing/free-tier shape
  (argos-ci.com comparison posts, vendr.com, browserstack.com's own
  Percy page); Yjs/Automerge current relative download/adoption figures
  and Automerge 3.0's July 2025 columnar-compression rewrite
  (taskade.com CRDT history post, pkgpulse.com, stack.convex.dev) —
  all retrieved 2026-08-31.
- `research/stacks/mlops-platform-engineering/libraries.md` and
  `skills/project-incubation/references/preferred-libraries/
  business-applications.md` — read directly to confirm this baseline's
  own scope boundaries, the local-precedent project's owned-backend
  status (cross-checked against the MLOps baseline's own read of
  `ubi-csr-tmf/aws/container/backend/app/requirements.txt`), and to
  confirm via repo-wide grep that no shipped `preferred-libraries/*.md`
  file names Playwright or Cypress — read 2026-08-31.

## Open questions — resolved this pass (2026-08-31), no user round-trip

Per an explicit "continue uninterrupted, use your own judgment" instruction
standing for this whole taxonomy-roadmap sweep, resolved directly:

1. **Flutter-side build/CI/distribution tooling stays a named, flagged
   gap, not deep-researched now** — Expo/Fastlane depth is the right
   priority given this repo's own JS/TS-ecosystem lean elsewhere
   (Developer Tooling & Libraries, Backend & API Services both treat
   TypeScript as a first-class second ecosystem; Dart has no equivalent
   footprint anywhere else in this skill). A real, honestly-flagged gap
   for a future pass, not silently dropped.
2. **UI component libraries stay unassigned, flagged as a real
   cross-category gap for a future pass** — this pass's own research
   brief didn't include them, and forcing a section in now without the
   same research rigor the rest of this doc holds itself to would be
   worse than an honest, named gap. Worth a dedicated future pass adding
   a UI-component-library section to this category specifically (its
   most natural home, since Business Applications already declined the
   territory), not resolved here.
3. **E2E test tooling (Playwright vs. Cypress) stays at existence-level
   naming, not deep-dived** — same reasoning as #2: a real, useful future
   addition, but out of this pass's actual research scope, named
   honestly rather than forced.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/frontend-client-applications.md
  — est. 430–500 lines (six category sections — cross-platform mobile
  frameworks with the fresh React Foundation governance-transfer finding
  and current adoption-data correction, cross-platform desktop
  frameworks with concrete Tauri-vs-Electron discriminators, state
  management reframed for the backend-less constraint specifically,
  offline-first/local-first/sync libraries as the section with no
  Business Applications analog at all, PWA tooling anchored by the
  local precedent's own honest "PWA tooling correctly skipped" finding,
  app-store distribution tooling with the Expo-repositioning and
  Fastlane-governance nuances, and testing tooling with the
  Chromatic-vs-Percy pricing/licensing-shape comparison — plus the
  Local-precedent section's "adjacent-category evidence, not a worked
  example" framing carried forward, matching the rigor and rough length
  of MLOps/Platform Engineering and Business Applications' own
  structure).
