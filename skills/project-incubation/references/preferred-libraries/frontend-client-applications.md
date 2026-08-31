# Frontend / Client Applications — Preferred Libraries

Companion to [stacks/frontend-client-applications.md](../stacks/frontend-client-applications.md),
which covers architecture and selection criteria; this doc names the actual
tools, their licenses, and honest maintenance/adoption signal for the
**backend-less client** specifically — a web SPA, mobile app, or desktop app
with no owned server of its own, calling either a third-party API directly or
a BaaS (Firebase/Supabase-style) layer. Where
[Business Applications](business-applications.md) (already shipped) names a
library relevant to a full-stack app that happens to also have a frontend
(React itself, Next.js, React Router as UI-layer choices), this file does not
re-litigate that — it only re-examines a topic when the backend-less
constraint genuinely changes the decision: state management with no
co-located API to lean on, offline/sync because there's no server of record
to assume reachable, and app-store/binary distribution because a web deploy
target alone isn't the whole story once mobile and desktop are first-class
targets.

No local precedent for this category's own defining shape exists: a `find`
across this repo and `/Users/devopammittra/GitHub/ubi-csr-tmf` for
react-native/flutter/electron/tauri/expo-shaped files or dependencies turned
up zero hits. `ubi-csr-tmf/aws/container/frontend` (React 19.2 + TypeScript
5.9 + Vite 7.1 + Ant Design v5.27 + TanStack Query 5.90 + React Router 7.9 +
Okta auth + a Lexical rich-text editor + a deliberately minimal, hand-rolled
PWA setup) is genuine, current production frontend-tooling evidence, but it
is honestly named here as evidence from an **adjacent-category project**, not
a worked example of this category: that same repo owns a FastAPI/Flask
backend of its own (confirmed by direct read of its `requirements.txt` during
the parallel MLOps research pass), so the project is Business-Applications-
shaped, not a client with no owned backend at all. One finding from that read
is genuinely load-bearing for this doc's own PWA section below: the app's
`public/sw.js` is an 11-line hand-written passthrough with **no offline
caching whatsoever** and no `vite-plugin-pwa` dependency, its own header
comment stating this is sufficient because the app is "an internal enterprise
tool... no offline cache" — a real, current example of PWA build tooling
being correctly *skipped*, not under-used, worth carrying forward as a
framing rather than a footnote.

This authoring pass re-verified rather than transcribed the baseline in one
materially important place. The baseline named **Yjs**'s license as
`NOASSERTION` per GitHub's own license detector and explicitly flagged that
as "not independently re-verified by reading the LICENSE file directly this
pass" — a real gap. A direct fetch of
`raw.githubusercontent.com/yjs/yjs/main/LICENSE` this pass resolves it: the
file is the standard **MIT License** text, copyright Kevin Jahns and RWTH
Aachen University's Chair of Computer Science 5, dated 2023. GitHub's
detector returning `NOASSERTION` here is a false negative, not a genuine
licensing ambiguity — the same detector-vs-file-content gap this repo's
Business Applications and MLOps baselines have both independently run into
elsewhere, worth correcting plainly rather than passing the hedge forward
into a shipped doc. A second, smaller strengthening: the baseline's
Tauri-vs-Electron bundle-size figures were search-corroborated only, across
multiple independent secondary comparison sites, not confirmed against a
primary source. A direct fetch of Tauri's own `v2.tauri.app/start/` docs this
pass adds a first-party data point — Tauri's own docs state "a minimal Tauri
app can be less than 600KB in size" — consistent in direction with, and
slightly more extreme than, the secondary-sourced 3–10 MB "Hello World"
figure (600KB is a bare-minimum build; 3–10 MB is a more typical starter
app), giving this claim a primary-source anchor it didn't have before. A
spot-check re-fetch of the highest-traffic repos in this doc (React Native,
Flutter, Electron, Tauri, RxDB, Zustand, PouchDB, WatermelonDB, Legend State,
Expo, Fastlane) found every figure unchanged or within single-digit drift
from the baseline (Flutter's open-issue count moved from 13,210 to 13,209) —
small enough to confirm these are live, reproducible numbers, not
stale copy-paste.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [Cross-platform mobile frameworks](#cross-platform-mobile-frameworks)
- [Cross-platform desktop frameworks](#cross-platform-desktop-frameworks)
- [State management for backend-less apps](#state-management-for-backend-less-apps)
- [Offline-first / local-first / sync libraries](#offline-first--local-first--sync-libraries)
- [PWA tooling](#pwa-tooling)
- [App-store distribution / build tooling](#app-store-distribution--build-tooling)
- [Testing tooling](#testing-tooling)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

This category splits **three ways** in a manner none of this skill's other
nine categories do — the defining shape of the category, not incidental
detail: **web** (JS/TS, npm-distributed, no installer at all), **mobile**
(React Native/JS-TS or Flutter/Dart, app-store-distributed binaries with
review/signing gates neither of the other two targets have), and **desktop**
(Electron/JS-TS or Tauri/Rust+JS-TS, OS-installer-distributed binaries).
License, governance, and distribution model differ by *target*, not just by
library choice within a target, which is why the sections below are grouped
by platform rather than forced into one cross-platform table. A team building
for more than one target should expect to make an independent framework
decision per target below, not assume one choice covers all three — the only
concern in this doc that genuinely crosses all three targets uniformly is
state management (TanStack Query and Zustand/Jotai work identically whether
the shipped artifact is a web bundle, a mobile binary, or a desktop
installer).

## Cross-platform mobile frameworks

**React Native's governance changed materially and very recently — load-
bearing, not background color.** The Linux Foundation announced formation of
the **React Foundation** on 2026-02-24/25, with Meta transferring React,
React Native, and JSX into it (announced on Meta's own engineering blog
2025-10-07, deal closing early 2026). The governing board spans Amazon,
Callstack, Expo, Meta, Microsoft, Software Mansion, and Vercel — Meta retains
a majority board stake for an initial period and commits $3M+ over a
five-year partnership plus a continuing dedicated engineering team, but
technical governance (releases, features, direction) is now explicitly
separated from the foundation/business layer and driven by maintainers, not
Meta unilaterally. Any framing of React Native as simply "Meta-owned" is now
materially outdated as of this pass.

**Flutter remains squarely Google-owned**, with no comparable foundation
transfer. Current search corroboration (against periodic "is Google
abandoning Flutter" rumor cycles) shows continued direct investment: over 1M
active developers, roughly 30% of new free iOS apps now built with Flutter
(up from ~10% in 2021), and eight stable releases shipped in 2025 on a
quarterly cadence. This is a real, if less formalized, governance-risk
asymmetry against React Native's new foundation model — Flutter's continuity
still rests on one company's continued willingness to fund it.

**Adoption is a genuine near-even split, not a decided race.** A 2025
Statista survey of 500 enterprise mobile teams found 42% using React Native
vs. 38% Flutter. Broader developer-population surveys (Stack Overflow
Developer Survey 2024) found Flutter slightly ahead among all developers
(9.4% vs. 8.4%) and further ahead among *learners* specifically (11.1% vs.
6.7%) — Flutter is winning new adopters faster even where React Native holds
an installed-base edge. Job-market reality cuts the other way: React Native
carries roughly 6x more US job postings, reflecting longer market presence
and deeper enterprise entrenchment rather than current mindshare direction.

| Library | For | License | Why recommended |
|---|---|---|---|
| **React Native** (`facebook/react-native`) | Cross-platform mobile (iOS/Android) from a JS/TS/React codebase | MIT | Default when the team is JS/TS-first, wants code/pattern sharing with an existing React web codebase, or values the newly multi-stakeholder React Foundation governance as a lower single-vendor-risk bet than a year ago. Direct GitHub fetch (re-confirmed this pass): 126,463 stars, 25,234 forks, 1,170 open issues, pushed 2026-08-31 (very active) |
| **Flutter** (`flutter/flutter`) | Cross-platform mobile (and desktop/web) from a single Dart codebase, own rendering engine | BSD-3-Clause | Default when pixel-perfect cross-platform UI consistency matters more than JS-ecosystem code sharing, or the team is starting fresh with no existing React investment and wants to weigh Flutter's faster current learner/mindshare growth as a hiring signal. Direct GitHub fetch (re-confirmed this pass): 178,730 stars, 31,033 forks, 13,209 open issues (a notably higher open-issue volume than React Native — a triage-volume signal worth a light flag, not necessarily neglect given commit cadence), pushed 2026-08-31 (very active) |

**Decision rule**: neither framework is a clear technical winner in 2026 —
state the real trade-off (React Native's new multi-stakeholder governance and
JS-ecosystem code sharing vs. Flutter's faster growth curve and rendering
consistency) rather than defaulting to one out of habit. Reach for React
Native by default when the team already has React web investment to share
code/patterns with; reach for Flutter when starting greenfield with no such
investment or when UI-consistency-across-platforms is the harder constraint.

## Cross-platform desktop frameworks

**Electron's governance**: an **OpenJS Foundation Impact Project** (graduated
from incubation), the same vendor-neutral foundation home as Node.js,
Express, and Jest — not single-vendor-owned.

**Tauri has moved past "smaller upstart" status.** Latest stable is
`tauri-v2.11.5`, published 2026-07-01 (Tauri 2.0 itself shipped GA in October
2024), and its star count has grown to within range of Electron's own in
this snapshot (110,704 vs. 122,819) — a genuinely fresh convergence worth
stating precisely. Governed by the **Tauri Programme within the Commons
Conservancy** (a nonprofit steward, not a single vendor) under Apache-2.0,
with no BSL/SSPL-style commercial gate.

**Bundle-size and memory discriminators, now backed by a primary source, not
just secondary-blog corroboration.** A Tauri "Hello World" build ships
around 3–10 MB vs. Electron's 120–200 MB — Electron bundles a full Chromium +
Node.js runtime; Tauri uses Rust for the backend and the OS's own native
WebView, so no browser runtime ships in the binary at all. Idle memory
footprint runs around 42 MB (Tauri) vs. 168 MB (Electron). Tauri's own docs
(`v2.tauri.app/start/`, fetched directly this pass) independently corroborate
the direction and scale: "a minimal Tauri app can be less than 600KB in
size" — a first-party figure this doc didn't have before, consistent with
(and more extreme than) the 3–10 MB "typical starter app" figure from
secondary sources. Native-API access differs structurally, not just in
overhead: Electron ships Node.js directly in the renderer/main process,
giving full Node API access out of the box; Tauri exposes a Rust-side
command-invocation bridge (`#[tauri::command]`) the JS frontend calls into
explicitly, and native OS integration requires either a first-party Tauri
plugin or writing Rust — more explicit and secure-by-default, steeper if the
team has no Rust familiarity.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Electron** (`electron/electron`) | Cross-platform desktop apps via Chromium + Node.js, full Node API access in-process | MIT | Default when the team wants zero Rust exposure, needs the broadest existing plugin/native-integration ecosystem (still larger than Tauri's by tenure), or is porting/sharing code with an existing Node.js backend assuming direct Node API access. Direct GitHub fetch (re-confirmed this pass): 122,819 stars, 17,453 forks, 751 open issues, pushed 2026-08-31; **OpenJS Foundation** Impact Project |
| **Tauri** (`tauri-apps/tauri`) | Cross-platform desktop apps via Rust backend + OS-native WebView, no bundled browser runtime | Apache-2.0 | Default for a genuinely new desktop project where bundle size, memory footprint, and a more locked-down native-access model are real user-facing differentiators (install time, disk footprint on constrained machines) and the team accepts some Rust in the stack, even if only at the plugin boundary. Direct GitHub fetch (re-confirmed this pass): 110,704 stars, 3,910 forks, 1,458 open issues, pushed 2026-08-31; latest release `v2.11.5` (2026-07-01); governed by the **Tauri Programme / Commons Conservancy**, no commercial license gate |
| **electron-builder** (`electron-userland/electron-builder`) | Packaging/installer generation for Electron apps | MIT | The more feature-complete, higher-adoption Electron packager; community-maintained (not first-party OpenJS). Direct GitHub fetch: 14,659 stars, 1,869 forks, pushed 2026-08-30 |
| **Electron Forge** (`electron/forge`) | Packaging/installer generation for Electron apps | MIT | First-party option (under the `electron` GitHub org itself), preferable when staying entirely within first-party tooling is valued over electron-builder's broader feature set. Direct GitHub fetch: 7,135 stars, 640 forks, pushed 2026-08-28; latest release `v7.11.2` (2026-05-20) |

**Decision rule**: **Tauri** for a new desktop project where bundle
size/memory/native-access lockdown matter and Rust exposure is acceptable;
**Electron** for zero-Rust-exposure teams, the broadest plugin ecosystem, or
heavy Node-backend code sharing. For packaging: **electron-builder** for
feature completeness, **Electron Forge** for first-party integration; Tauri's
own CLI bundles its own packaging so no separate tool decision applies there.

## State management for backend-less apps

**Scope boundary**: Business Applications names React/Next.js as UI-layer
choices but does not deep-dive client-state-management libraries, since a
full-stack app typically leans on server-side state (RSC, API routes,
session state) more than a pure client can. This section is this category's
own contribution: what to reach for when there's no co-located backend to
own canonical state, so *all* meaningful state — including "remote" data —
has to be modeled and cached entirely client-side.

**Zustand has clearly separated from the pack.** 58,628 stars, still gaining
(pushed 2026-08-28), roughly **5x Redux Toolkit's** star count (11,225)
despite Redux Toolkit being the older, "official" choice — a genuine, current
adoption inversion worth stating plainly rather than defaulting to Redux
Toolkit out of institutional habit. **Jotai** (21,251 stars) is the clear #2
lightweight option, better suited when state naturally decomposes into many
small independent atoms rather than one global store. **Redux Toolkit**
remains relevant specifically for an existing large Redux codebase or teams
wanting Redux DevTools' mature time-travel debugging — not the default for a
new backend-less client in 2026.

**TanStack Query applies identically whether or not the client owns a
backend.** Even a backend-less client very often talks to *someone else's*
API (a third-party REST/GraphQL API, or a BaaS like Firebase/Supabase) —
TanStack Query's cache/refetch/stale-time model works the same against that
as against an owned backend, which is exactly why the adjacent-category local
precedent already uses it (TanStack Query 5.90) against its own owned API.
The single most-starred library in this table (50,238 stars, pushed
2026-08-31) — named here for *remote*-shaped client state specifically,
paired with Zustand/Jotai for *local*-only UI/app state, not a replacement
for either.

**Legend State is a genuinely distinct, smaller option worth naming on its
own strength.** v3 is in beta as of this pass — the project's own docs
recommend starting new projects on the v3 beta over v2 given how much has
improved, but that means it is not yet a stable default. Built around
fine-grained observables with built-in local-persistence and sync plugins
(Keel, Supabase, TanStack Query, plain fetch) — optimistic local-first writes
with automatic retry-until-synced, worth naming specifically for a
backend-less app wanting offline-tolerant writes without adopting a full CRDT
database (see next section).

| Library | For | License | Why recommended |
|---|---|---|---|
| **Zustand** (`pmndrs/zustand`) — default for local/UI state | Lightweight global client state, minimal boilerplate | MIT | Has overtaken Redux Toolkit in adoption momentum by a wide and still-growing margin. Direct GitHub fetch (re-confirmed this pass): 58,628 stars, 2,188 forks, pushed 2026-08-28 |
| **Jotai** (`pmndrs/jotai`) | Atomic/bottom-up state composition | MIT | Best fit when state naturally decomposes into many small independent pieces rather than one store. Direct GitHub fetch: 21,251 stars, 724 forks, pushed 2026-08-24 |
| **Redux Toolkit** (`reduxjs/redux-toolkit`) | Global state with mature DevTools/middleware ecosystem | MIT | Named for an existing Redux codebase or teams wanting time-travel debugging depth; not the default for a new backend-less client given the adoption gap to Zustand. Direct GitHub fetch: 11,225 stars, 1,292 forks, pushed 2026-08-24 |
| **TanStack Query** (`TanStack/query`) — default for remote/cached-API state | Fetching, caching, and sync of any remote data source (third-party API, BaaS, or an owned backend alike) | MIT | The most-adopted, most-current option here; equally applicable whether or not the client owns a backend, since it caches against whatever API is called. Direct GitHub fetch: 50,238 stars, 4,226 forks, pushed 2026-08-31 (most active repo in this table) |
| **Legend State** (`LegendApp/legend-state`) | Fine-grained observable state with built-in local-first persistence/sync plugins | MIT | The genuinely current local-first-oriented option, for a backend-less app wanting offline-tolerant optimistic writes without adopting a full sync database; v3 (recommended for new projects per the project's own docs) is still beta. Direct GitHub fetch (re-confirmed this pass): 4,193 stars, 145 forks, pushed 2026-08-11 |

**Decision rule**: pair **Zustand** (local/UI state) with **TanStack Query**
(remote/cached-API state) as the default combination for a new backend-less
client. Reach for **Jotai** instead of Zustand when state is naturally
atomic. Reach for **Redux Toolkit** only when inheriting an existing Redux
codebase or specifically wanting its DevTools depth. Reach for **Legend
State** when the app needs offline-tolerant optimistic local writes with
automatic background sync and doesn't want to hand-roll that retry logic —
treat it as beta-stage on v3, stable-but-superseded on v2.

## Offline-first / local-first / sync libraries

**Scope note**: this is the section with no Business Applications analog at
all — a full-stack app with its own backend rarely needs a client-side sync
database, since the owned backend *is* the source of truth reachable
directly. A backend-less client that still needs multi-device consistency or
offline tolerance has to solve this client-side, which is what makes this
section genuinely category-defining.

**PouchDB shows a real, precise split signal, confirmed by direct API check
rather than a stale prior.** The repo's `pushed_at` is 2026-08-25 (actively
committed to), but its latest *tagged* GitHub release is `9.0.0`, published
2024-06-21 — over two years without a new tag despite ongoing commit
activity, re-confirmed this pass via a fresh `gh api repos/pouchdb/pouchdb/
releases/latest` fetch returning the identical tag/date. One search source
had claimed an "8.0.0 release in June 2026" that a direct fetch of the full
release history did not corroborate — the actual release history tops out at
`9.0.0`/2024-06-21. Community signals (CouchDB's own project-digest posts)
describe bi-weekly PouchDB triage sessions working a backlog — consistent
with "actively maintained by a smaller volunteer team, slower on cutting
tagged releases," not abandoned.

**WatermelonDB, checked for real staleness, not assumed thriving.**
Maintained by Nozbe (a task-management company running it in their own
production app — a real maintenance-motivation signal), but `pushed_at`
2025-08-11 — roughly 12.5 months stale relative to this pass, re-confirmed
via fresh fetch this pass, a real flag though not abandonment (no archive
flag, active alternative-comparison coverage in current 2026 sources).

**RxDB's license, precise rather than assumed permissive end-to-end.** The
core `pubkey/rxdb` repo is genuinely Apache-2.0 (direct GitHub API
license-metadata fetch, re-confirmed this pass), but this is an **open-core
product**: RxDB Premium (Pro/Pro Plus/Enterprise tiers, annual-only, no
monthly option) gates better performance, smaller build size, additional
storage-engine backends, and encryption — and the free core tier caps out at
**13 open collections in parallel**, a concrete, load-bearing free-tier limit
worth sizing against an app's actual schema before committing. A notable
carve-out: a single developer using RxDB in a side project can get 2 years of
free Premium access by completing a maintainer-listed task.

**CRDT sync libraries — the license correction is the headline finding this
pass.** The baseline flagged Yjs's license as GitHub-detector `NOASSERTION`,
not independently verified. A direct fetch of Yjs's actual `LICENSE` file
this pass resolves it cleanly: **MIT**, copyright Kevin Jahns and RWTH Aachen
University's Chair of Computer Science 5 (2023) — the detector's
`NOASSERTION` was a false negative, and the corrected fact belongs in this
doc's table without a hedge. Adoption-wise, **Yjs** remains the clear
production-adoption leader — search-corroborated at roughly 920K weekly
downloads with the largest ecosystem of framework bindings/providers, the
default choice for collaborative text/rich-editor use cases specifically (a
genuinely adjacent fit to the local precedent's own Lexical rich-text editor,
though not currently wired together there). **Automerge** is smaller in raw
adoption (~85K downloads) but closed a real historical performance gap:
Automerge 3.0 (July 2025) re-architected around columnar compression for a
reported 10x+ memory-usage reduction, and its JSON-document-with-Git-like-
history model fits backend-less apps modeling structured records (not prose)
that want full change history for free — not competing for the same use case
as Yjs, worth naming both.

| Library | For | License | Why recommended |
|---|---|---|---|
| **RxDB** (`pubkey/rxdb`) — default for a full local-first database | NoSQL local-first database (IndexedDB/OPFS/SQLite adapters) with built-in replication to an existing backend | Apache-2.0 core (open-core; Premium gates performance/storage-engine/encryption — see the hard 13-collection free-tier cap above) | The most actively developed, broadest-storage-adapter option here; size the free-tier collection cap against the app's actual schema first. Direct GitHub fetch (re-confirmed this pass): 23,371 stars, 1,175 forks, pushed 2026-08-31 (most active repo in this section) |
| **WatermelonDB** (`Nozbe/WatermelonDB`) | React Native-first local-first database built for large-dataset lazy-loading performance | MIT | Best fit for React Native apps wanting a mature, SQLite-backed local database with a proven large-scale production user (Nozbe's own app); the ~12.5-month staleness gap is a real, worth-flagging maintenance-velocity concern before adopting as a primary dependency today. Direct GitHub fetch (re-confirmed this pass): 11,778 stars, 656 forks, **pushed 2025-08-11 — ~12.5 months stale**, a real flag |
| **PouchDB** (`pouchdb/pouchdb`) | Offline-first local database purpose-built to sync/replicate with CouchDB (or CouchDB-compatible) servers | Apache-2.0 | The right choice specifically when the backend (or a BaaS) already speaks CouchDB's replication protocol; not a general-purpose pick outside that pairing. Direct GitHub fetch (re-confirmed this pass): 17,603 stars, 1,507 forks, 185 open issues, pushed 2026-08-25 (active commits) but **latest tagged release `9.0.0` published 2024-06-21 — over 2 years without a new tag**, re-confirmed via a fresh releases-list fetch this pass |
| **Yjs** (`yjs/yjs`) | CRDT sync engine for real-time collaborative editing (text/rich-content-shaped data) | **MIT** — corrected this pass via direct fetch of the repo's own LICENSE file; GitHub's detector reports `NOASSERTION`, a false negative, not a genuine licensing gap | The production-adoption leader for collaborative-editing CRDT sync specifically (largest ecosystem of bindings/providers); best fit for prose/rich-text collaborative state. Direct GitHub fetch (re-confirmed this pass): 22,728 stars, 799 forks, pushed 2026-08-06; ~920K weekly downloads per search corroboration (not independently direct-fetched from npm) |
| **Automerge** (`automerge/automerge`) | CRDT sync engine for structured JSON-document data with full built-in change history | MIT | Best fit for backend-less apps syncing structured records (not prose) wanting Git-like history for free; the 3.0 columnar-compression rewrite (July 2025) closed most of the historical memory-overhead gap to Yjs. Direct GitHub fetch: 6,545 stars, 266 forks, pushed 2026-08-28; ~85K downloads per search corroboration |

**Decision rule**: default to **RxDB** for a full local database with
replication to some backend, sizing the 13-collection free-tier cap against
the app's schema first; choose **WatermelonDB** for a React Native app
already accepting some staleness risk for large-dataset read performance;
choose **PouchDB** only when the backend already speaks CouchDB's
replication protocol. For real-time multi-user collaborative state
specifically (not just single-user offline tolerance), reach for **Yjs** for
prose/rich-text (a natural pairing with the local precedent's own Lexical
editor) and **Automerge** for structured JSON records wanting built-in
version history.

## PWA tooling

**Workbox remains Google Chrome-team-maintained**, not spun out to a neutral
foundation — MIT-licensed, 12,995 stars, pushed 2026-08-04. Still the de
facto service-worker toolkit underneath the broader PWA-build-tooling
ecosystem, including the plugin below.

**vite-plugin-pwa** wraps Workbox rather than replacing it: community
`vite-pwa` GitHub org (not Google, not a foundation), MIT, 4,258 stars,
pushed 2026-05-05. It lazy-loads `workbox-build` internally and exposes both
Workbox's `generateSW` (zero-config precaching) and `injectManifest`
(hand-written service worker with Workbox's precache manifest injected in)
strategies.

**The honest, load-bearing finding for this section is that PWA tooling is
opt-in, not default.** The adjacent-category local precedent — a real,
current, Vite-based production frontend — uses **neither** `vite-plugin-pwa`
nor Workbox. Its `sw.js` is 11 lines of hand-written install/activate/fetch
passthrough with no offline caching whatsoever, its own header comment
stating this is sufficient because the app is an internal enterprise tool
with assumed connectivity that only wanted install-ability (the "Add to Home
Screen" affordance), not offline support. Reach for the tooling below
specifically when there's a genuine offline requirement — not by default for
every SPA that merely wants installability.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Workbox** (`GoogleChrome/workbox`) | Service-worker precaching/routing/runtime-caching strategies | MIT | The underlying toolkit almost every current PWA build plugin wraps rather than reimplementing. Direct GitHub fetch: 12,995 stars, 880 forks, pushed 2026-08-04 |
| **vite-plugin-pwa** (`vite-pwa/vite-plugin-pwa`) | Zero-config-to-configurable PWA/service-worker generation for Vite builds | MIT | The natural default for any Vite-based frontend wanting a real offline strategy, rather than a hand-rolled passthrough — reach for it once an actual offline requirement exists, not automatically. Direct GitHub fetch: 4,258 stars, 256 forks, pushed 2026-05-05 |

## App-store distribution / build tooling

**Expo is now the right default for nearly every new React Native project**,
not just a training-wheels option for apps without custom native code —
verified against an older "managed vs. bare workflow" framing that current
sources no longer support. Expo SDK 53/54-era config plugins and first-class
Expo Modules cover virtually every native API surface without ejecting; the
old rule of "go bare once you need a native module" has been replaced by
"stay on Expo unless contributing to React Native core itself or hitting one
specific unwrappable native dependency." EAS Build/Update/Submit handle cloud
compilation, OTA updates, and store submission as one managed pipeline.

**Fastlane's governance is nominal-ownership-with-real-disengagement, a
distinct pattern worth naming precisely.** Google acquired Fastlane in
January 2017 and technically still holds it, but search corroboration is
consistent and specific: **Google has not sponsored the project since
November 2021**, and ongoing maintenance/new-maintainer approval has been
noted as difficult as a result. Actual current development activity lives in
the community `fastlane-community` GitHub organization. Not abandoned — still
the de facto CLI for automating iOS/Android builds, code signing, and
store-metadata submission, with real recent commit activity, re-confirmed
this pass (pushed 2026-08-28) — but a **nominally corporate-owned,
practically community-sustained** project, a different but comparably
worth-flagging pattern from this repo's usual "was popular, now stale" or
BSL-style commercial-capture flags.

**Desktop-equivalent packaging tooling** is covered in the Cross-platform
desktop frameworks section above (`electron-builder`/`Electron Forge` for
Electron, Tauri's own built-in bundler for Tauri) — not re-listed here to
avoid duplication.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Expo** (`expo/expo`, EAS Build/Update/Submit) — default for React Native | Cloud build pipeline, OTA updates, and app-store submission for React Native apps, now covering nearly all native-API needs via config plugins/Expo Modules without ejecting | MIT (the open-source SDK/CLI; EAS itself is a managed, usage-metered cloud service, not separately licensed as OSS) | The current default for nearly every new React Native project; Expo also holds a board seat on the new React Foundation (see mobile-frameworks section), a further signal of its centrality to the React Native ecosystem specifically. Direct GitHub fetch (re-confirmed this pass): 51,927 stars, 13,708 forks, pushed 2026-08-31 (very active) |
| **Fastlane** (`fastlane/fastlane`) | CLI automation for iOS/Android build, code-signing, and app-store-metadata submission — the underlying tool EAS Submit is itself often layered on or compared against | MIT | Still the de facto store-submission automation tool with real ongoing (community-driven) activity; the corporate-disengagement nuance above is worth surfacing to a team evaluating long-term dependency risk, not a reason to avoid it today. Direct GitHub fetch (re-confirmed this pass): 42,044 stars, 6,025 forks, pushed 2026-08-28; nominal owner Google, no Google sponsorship since November 2021, active development in the community `fastlane-community` org |

**Decision rule**: default to **Expo + EAS** for a new React Native
project's entire build/OTA-update/store-submission pipeline; reach for
**Fastlane** directly only when on bare React Native (or native iOS/Android)
and needing CLI-level control over signing/submission that EAS doesn't
already provide, or integrating store automation into a CI pipeline EAS
doesn't cover. Flutter's own first-party `flutter build`/Codemagic-or-
equivalent CI tooling covers the equivalent need — not independently
deep-researched this pass (see Where this doc stops).

## Testing tooling

**Scope check**: a repo-wide grep confirms no other shipped
`preferred-libraries/*.md` file names Playwright or Cypress anywhere — so
there is no sibling category to defer E2E testing to. E2E is named here at a
light, "these exist and are current" level only, consistent with this
repo's own convention for named-but-not-deep-researched items (matching how
the MLOps doc names cloud-native registries).

**Component-testing tools**: **React Testing Library** remains the standard
for behavior-driven component tests (query by role/text, not implementation
detail) — 19,645 stars, MIT, pushed 2026-08-27. **Storybook's own
test-runner and interaction-testing features have matured into a genuine
component-testing platform, not just a docs/preview tool** — per Storybook's
own current docs, interaction tests (Vitest-integrated, step-through
debugging in the Interactions panel), accessibility tests, visual tests, and
coverage reports now run together in CI directly from stories, without
spinning up the full app. 90,973 stars, MIT, pushed 2026-08-31 (the most
active repo named in this document).

**Visual-regression tooling, with the licensing/commercial-tier structure
checked precisely.** Neither **Chromatic** (Storybook's own commercial
visual-testing SaaS) nor **Percy** (owned by BrowserStack) is open-source —
both are proprietary hosted services with metered free tiers. Chromatic's
free tier covers 5,000 snapshots/month on Chrome only, with paid tiers ($179/
mo Starter for 35K snapshots, adding Safari/Firefox/Edge; $399/mo Pro for
85K) and per-overage-snapshot billing ($0.008/snapshot). Percy's free tier is
also 5,000 snapshots/month, but its paid tier starts materially higher
(~$599/mo per search corroboration) — priced consistently above Chromatic at
comparable snapshot volumes. **The real licensing-shape finding here**: both
tools gate *volume*, not core functionality — the opposite shape from an
open-core license trap (no self-hosting alternative exists for either — this
is a pure managed-SaaS decision, not a license-text-reading exercise the way
Sidekiq/Avo/Lago are in Business Applications). The trap, if any, is
snapshot-volume cost creep at scale, worth sizing against the app's actual
story/variant count before committing to a plan.

| Library | For | License | Why recommended |
|---|---|---|---|
| **React Testing Library** (`testing-library/react-testing-library`) | Behavior-driven component unit tests | MIT | The standard, query-by-role/text approach that discourages testing implementation detail. Direct GitHub fetch: 19,645 stars, 1,168 forks, pushed 2026-08-27 |
| **Storybook** test-runner / interaction tests (`storybookjs/storybook`) | Story-driven component tests: interaction, accessibility, and visual checks run together in CI without the full app | MIT | Matured from a docs/preview tool into a genuine component-testing platform; a natural fit for any project already writing stories for UI development. Direct GitHub fetch: 90,973 stars, 10,430 forks, pushed 2026-08-31 (most active repo named in this document) |
| **Chromatic** (Storybook's own commercial visual-testing product) | Cross-browser visual-regression snapshots, tied directly into Storybook stories | Proprietary hosted SaaS | The natural pairing for a project already on Storybook; free tier (5K snapshots/mo, Chrome-only) is real but volume-limited — priced below Percy at comparable paid-tier volume. Not independently fetched (commercial SaaS, no public repo); pricing search-corroborated: free 5K/mo, Starter $179/mo (35K, adds Safari/Firefox/Edge), Pro $399/mo (85K), $0.008/extra snapshot |
| **Percy** (BrowserStack) | Cross-browser visual-regression snapshots, integrates with Cypress/Playwright/Storybook alike | Proprietary hosted SaaS | Broader test-runner integration than Chromatic (not Storybook-exclusive) but priced materially higher at comparable volume — reach for it specifically when already on BrowserStack for cross-browser testing generally. Pricing search-corroborated: free 5K/mo, paid tier starting ~$599/mo |
| Playwright (`microsoft/playwright`) — named at existence level only | End-to-end browser testing | Apache-2.0 | No sibling category names this; named here lightly since this category is the natural home, but not deep-researched this pass. Direct GitHub fetch: 95,415 stars, 6,368 forks, pushed 2026-08-31 |
| Cypress (`cypress-io/cypress`) — named at existence level only | End-to-end browser testing | MIT | Same as Playwright — named for completeness, not deep-researched. Direct GitHub fetch: 51,020 stars, 3,661 forks, pushed 2026-08-31 |

**Decision rule**: pair **React Testing Library** for component-level unit
tests with **Storybook's interaction/a11y/visual test-runner** when the
project already authors stories for UI development — the marginal cost of
adding tests on top of existing stories is low. Reach for a dedicated
visual-regression SaaS (**Chromatic** by default given its lower cost at
comparable volume and tight Storybook integration; **Percy** specifically
when already standardized on BrowserStack) only once visual drift has caused
a real incident or the design system is stable enough that pixel-diffs carry
signal rather than noise. E2E tool choice (Playwright vs. Cypress) is named
but explicitly not deep-researched — a real gap for a follow-up, not a
considered recommendation either way.

## Where this doc stops

**Frontend UI component libraries** (MUI, shadcn/ui, Ant Design, and
similar) are not covered here. Business Applications' own baseline already
excluded these as "a general frontend concern... belongs in a cross-cutting
frontend baseline rather than duplicated here" — which arguably makes this
category their natural home, but it wasn't in this pass's research brief. A
real, named gap for a follow-up pass, not an oversight papered over.
**React/Next.js/React Router themselves as web frameworks** are already
named and license/adoption-verified in Business Applications; this doc only
re-examines state-management/sync/distribution topics that differ because of
the backend-less constraint, not the base framework choice. **Flutter-side
build/CI/distribution tooling** (Codemagic or equivalent) is named only
implicitly via the mobile-frameworks section, not independently
deep-researched the way Expo/EAS and Fastlane were for React Native — a real
gap given Flutter's near-even adoption with React Native found in this same
pass. **E2E testing tool depth** (Playwright vs. Cypress decision criteria)
is named at existence level only, per the Testing section above — no sibling
category claims this topic, but it also wasn't deep-researched here.
**BaaS platforms as a category** (Firebase, Supabase, Appwrite) are
whole-product/vendor-selection decisions, the same shape Business
Applications excluded no-code platforms (Retool/Appsmith/Budibase) under as
"whole-product procurement decisions, not libraries to add to a codebase" —
a backend-less client very often talks to one of these, and the
state-management/sync libraries above name specific integration points
(Legend State's Supabase sync plugin), but BaaS vendor selection itself
isn't researched here. **Native (non-cross-platform) mobile development**
(Swift/SwiftUI, Kotlin/Jetpack Compose) is out of scope — this category's own
roadmap framing is specifically cross-platform client tooling, and native
per-platform library curation is a different, much larger research surface.
**Desktop-equivalent app-store distribution depth** (Mac App Store/Microsoft
Store submission specifics, notarization workflows) is named only at the
packaging-tool level (electron-builder/Electron Forge/Tauri's bundler); the
deeper platform-specific submission/notarization process itself wasn't
independently researched.

## Sources

- Local `find`/direct-read passes, 2026-08-31: full read of
  `/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/
  package.json`, `vite.config.ts`, `public/sw.js`, and a listing of
  `public/` confirming `manifest.webmanifest` presence and no
  `vite-plugin-pwa`/Workbox dependency; `find agent-skills -iname
  "*react-native*" -o -iname "*flutter*" -o -iname "*electron*" -o -iname
  "*tauri*" -o -iname "*expo*"` — zero results.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`) for: facebook/react-native,
  flutter/flutter, electron/electron, tauri-apps/tauri,
  electron-userland/electron-builder, electron/forge, pmndrs/zustand,
  pmndrs/jotai, reduxjs/redux-toolkit, TanStack/query, LegendApp/legend-state,
  pouchdb/pouchdb, Nozbe/WatermelonDB, pubkey/rxdb, yjs/yjs,
  automerge/automerge, GoogleChrome/workbox, vite-pwa/vite-plugin-pwa,
  expo/expo, fastlane/fastlane, testing-library/react-testing-library,
  storybookjs/storybook, microsoft/playwright, cypress-io/cypress — retrieved
  2026-08-31.
- **Re-verification during this authoring pass (2026-08-31)**: fresh `gh
  api` re-fetch of facebook/react-native, flutter/flutter, electron/electron,
  tauri-apps/tauri, pubkey/rxdb, pmndrs/zustand, pouchdb/pouchdb (plus
  `releases/latest`), Nozbe/WatermelonDB, LegendApp/legend-state, expo/expo,
  and fastlane/fastlane — every figure matched the baseline within normal
  single-day drift (Flutter's open-issue count moved from 13,210 to 13,209),
  confirming these are live, reproducible numbers, not stale copy-paste.
- **New this authoring pass**:
  `https://raw.githubusercontent.com/yjs/yjs/main/LICENSE` — direct fetch
  resolving the baseline's flagged `NOASSERTION` gap; the file is the
  standard MIT License text (copyright Kevin Jahns / RWTH Aachen University
  Chair of Computer Science 5, 2023) — GitHub's license detector returning
  `NOASSERTION` for this repo is a false negative, corrected in the CRDT
  table above.
- **New this authoring pass**: `https://v2.tauri.app/start/` — direct fetch
  of Tauri's own documentation, adding a first-party bundle-size data point
  ("a minimal Tauri app can be less than 600KB in size") alongside the
  baseline's secondary-sourced 3–10 MB "Hello World" figure.
- WebSearch corroboration (not independently direct-fetched primary source,
  flagged inline where used): React Native vs. Flutter 2025/2026 adoption
  data (Statista enterprise survey, Stack Overflow Developer Survey 2024,
  job-posting-volume comparisons); React Foundation formation and governance
  structure (Meta's own engineering.fb.com announcement, linuxfoundation.org
  press release); Flutter's continued Google investment and adoption
  figures; Tauri vs. Electron bundle-size/memory-footprint benchmarks
  (rustify.rs, tech-insider.org, pkgpulse.com, digitalapplied.com,
  buildmvpfast.com — consistent across multiple independent sources, now
  corroborated by Tauri's own docs above); Expo/EAS current
  managed-workflow-as-default positioning; Fastlane's
  Google-ownership-but-no-sponsorship-since-2021 finding (the
  `fastlane-community` GitHub org's own existence); Legend State v3 beta
  status and local-first sync-plugin list (legendapp.com's own docs/blog);
  Storybook's current interaction/a11y/visual test-runner feature set
  (storybook.js.org's own docs); Chromatic and Percy current
  pricing/free-tier shape (argos-ci.com comparison posts, vendr.com,
  browserstack.com's own Percy page); Yjs/Automerge current relative
  download/adoption figures and Automerge 3.0's July 2025
  columnar-compression rewrite — all retrieved 2026-08-31.
- `research/stacks/mlops-platform-engineering/libraries.md` — read to
  confirm the local precedent's owned-backend status (cross-checked against
  that baseline's own read of `ubi-csr-tmf/aws/container/backend/app/
  requirements.txt`).
- `skills/project-incubation/references/preferred-libraries/
  business-applications.md` and
  `skills/project-incubation/references/preferred-libraries/
  mlops-platform-engineering.md` — read directly as this doc's own scope
  boundaries and structural/rigor template respectively.
- `research/stacks/frontend-client-applications/libraries.md` — read in full
  as this doc's approved research baseline; the Yjs MIT-license correction
  and the Tauri primary-source bundle-size figure above are new to this
  authoring pass and were not present in the baseline.
