# Baseline: Architecture Template Selection
Status: user-approved      Date: 2026-08-19

## In scope

- Named architecture pattern catalog: layered/n-tier, hexagonal (ports &
  adapters), microservices, modular monolith, event-driven, CQRS/event
  sourcing, serverless — impact: high — depth: table (per pattern: fit
  signals — team size/scale/deployment/domain complexity — plus honest
  trade-offs). Note: serverless (runtime/deployment axis) and event-
  driven (communication-style axis) overlap rather than compete — the
  authored doc should say these compose (e.g. "event-driven microservices
  on serverless compute") rather than treat them as mutually exclusive.

- Selection heuristic / decision framework connecting project answers
  (team size, expected scale, latency/consistency needs, compliance,
  domain complexity, deployment constraints) to a recommended pattern —
  impact: high — depth: table + short flowchart-style decision logic.
  Anchor: Azure Architecture Center's style×dependency-management×domain
  table (reusable shape) plus Fowler's monolith-first/microservice-
  premium heuristic (complexity, not size, is the trigger).

- Architecture Decision Records (ADR) as the recording mechanism —
  impact: high — depth: section + reusable template, per Nygard's 2011
  format (Title/Status/Context/Decision/Consequences), endorsed by
  Fowler. Local precedent, read directly, confirmed reusable in shape
  (not content):
  - `C:\Users\devop\GitHub\MCPg\docs\adr\0001-build-approach.md` — an
    "Options considered" section scored against named criteria, then a
    Decision stating the choice and why alternatives lost.
  - `C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` — a
    flat Concern | Choice | Notes decision table, plus a "Deviations
    from the inherited base" section.
  Both use a **Status** field supporting supersession (MCPg's ADR-0001 is
  marked "superseded by ADR-0007") — carries forward since
  project-incubation re-audits repos over their lifecycle and template
  choices will get revisited.

- Cross-cutting: database selection heuristic (SQL vs NoSQL vs NewSQL,
  when polyglot persistence is justified vs. overkill) — impact: high —
  depth: table. Governance overhead, not the tech itself, is the real
  cost of polyglot persistence.

- Cross-cutting: API design/versioning approach — impact: med — depth:
  checklist (versioning-strategy trade-offs, resource-oriented design per
  Google's AIP-based guide, backward compatibility as the primary goal
  with versioning as fallback).

- Cross-cutting: UX/frontend architecture concerns, when applicable —
  impact: low — depth: paragraph. Deliberately shallow: monolith frontend
  vs. micro-frontends vs. BFF is largely orthogonal to the backend
  pattern and overlaps the later Business Applications stack doc.

- Cross-cutting: network topology basics — API gateway vs. service mesh,
  when each is needed vs. premature — impact: med — depth: section.
  Consistent theme: gateway (north-south) is justified past 1 externally-
  facing service; mesh (east-west: mTLS, retries, tracing) only past a
  service-count/maturity threshold most early projects don't cross —
  premature mesh adoption is a named anti-pattern.

- Cross-cutting: security-by-design touchpoints — auth pattern selection
  (OAuth2/OIDC vs. API keys vs. mTLS, and when to combine them) and
  secrets management — impact: high — depth: checklist/table. OWASP
  Secrets Management Cheat Sheet is the durable canonical source for the
  secrets half; auth pattern selection is more heuristic (user-facing →
  OAuth2/OIDC; service-to-service → mTLS or client-credentials; simple
  partner integration → API keys, never as the sole factor for anything
  sensitive).

- Cross-cutting: storage tier selection — object vs. block vs. file,
  hot/cold tiering — impact: med — depth: table. Default posture worth
  stating plainly: object storage unless low-latency random I/O is
  required (→ block) or genuine concurrent multi-writer file semantics
  are required (→ file); tiering complexity is frequently premature
  (cited stat: most "cold" data isn't actually cold — see sources).

## Explicitly out of scope

- Stack-specific architecture guidance for the 5 categories (Data &
  Analytics Platforms, Business Applications, Integration & Event-Driven
  Systems, Backend & API Services, Agentic & MCP Platforms) — these get
  their own research baselines under `research/stacks/*`; this doc stays
  at the cross-cutting decision-framework layer only.
- Specific library/framework/vendor recommendations (e.g. "use Kong vs.
  Envoy," "use Auth0 vs. Keycloak") — belongs in the `preferred-libraries`
  reference docs per stack category, not here. This doc names the pattern
  and the selection criteria, not the product.
- Container-orchestration platform selection (Kubernetes vs. ECS vs.
  Nomad specifics) — deployment-target detail that's downstream of the
  pattern choice and more naturally belongs with Backend & API Services
  or a future deployment-focused doc.
- Deep compliance/regulatory guidance (HIPAA, PCI-DSS, SOC2 control
  specifics) — treated only as a *signal* that feeds the decision
  framework ("compliance regime present → bias toward stronger
  consistency / auditability / event sourcing for the affected
  subdomain"), not as a compliance reference itself.
- Cost modeling / cloud pricing comparisons — trade-offs are described
  qualitatively (e.g. "microservices premium," "provisioned concurrency
  costs whether used or not") but no numeric pricing, since that churns
  fast and isn't this doc's job.
- Detailed CAP-theorem / distributed-systems theory exposition — referenced
  only insofar as it explains *why* SQL vs. NoSQL trade-offs exist, not
  taught from scratch.

## Sources

- https://www.martinfowler.com/bliki/MonolithFirst.html — durable
  qualitative heuristic for monolith-vs-microservices timing (start
  monolith, split only once boundaries are known and complexity demands
  it) — retrieved 2026-08-19
- https://martinfowler.com/bliki/MicroservicePremium.html — names the
  "microservice premium" concept directly; complexity (not size) is the
  trigger for microservices — retrieved 2026-08-19
- https://martinfowler.com/bliki/CQRS.html — Fowler's own cautions on
  CQRS: appropriate only for complex domains or read/write-disparate
  high-performance systems; "majority of cases... have not been good" —
  retrieved 2026-08-19
- https://martinfowler.com/bliki/ArchitectureDecisionRecord.html — Fowler
  endorsing Nygard's ADR format as the reference approach — retrieved
  2026-08-19
- https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/
  — Azure Architecture Center "Architecture Styles" overview; reusable
  comparison-table shape (style × dependency-management × domain-type),
  covers N-tier, Web-Queue-Worker, Microservices, Event-driven, Big
  Data, Big Compute with fit/trade-off framing; page dated 2025-09-25,
  content updated 2026-08-18 — retrieved 2026-08-19
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html
  — AWS Prescriptive Guidance on hexagonal/ports-and-adapters: intent,
  applicability, and explicit "issues and considerations" (complexity,
  maintenance overhead, latency) — retrieved 2026-08-19
- https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
  — Azure Architecture Center Event Sourcing pattern: exhaustive "when to
  use" / "when not to use" lists, problems/considerations (eventual
  consistency, versioning events, idempotency, GDPR/right-to-be-forgotten
  tension), explicitly pairs with CQRS; updated 2026-03-27, page refreshed
  2026-08-15 — retrieved 2026-08-19
- Shopify Engineering, "Deconstructing the Monolith" —
  https://shopify.engineering/deconstructing-monolith-designing-software-maximizes-developer-productivity
  — primary real-world case for modular monolith as a deliberate choice
  over microservices at meaningful scale; confirmed direct quote: "We
  wanted a solution that increased modularity without increasing the
  number of deployment units, allowing us to get the advantages of both
  monoliths and microservices without so many of the downsides" —
  retrieved 2026-08-19
- https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/tradeoffs.html
  (AWS Well-Architected Serverless Applications Lens, "Tradeoffs" page) —
  confirmed by direct fetch: this specific page covers only the
  provisioned-concurrency cost trade-off and points to the general
  Well-Architected Framework whitepaper for the rest; cold-start and
  "long-running → containers/EC2" framing came from secondary sources
  (AWS Compute Blog posts, practitioner write-ups) surfaced in the same
  search pass, not this page — annotation corrected to avoid
  over-attributing — retrieved 2026-08-19
- https://docs.cloud.google.com/apis/design — Google Cloud API Design
  Guide (AIP-based); resource-oriented design, standard methods
  (Get/List/Create/Update/Delete), versioning via AIP-185/AIP-180 —
  retrieved 2026-08-19
- https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
  — confirmed by direct fetch: full lifecycle guidance (secure
  generation, centralized/least-privilege storage & access, rotation,
  revocation/expiration, mandatory audit logging) — canonical durable
  source for the secrets-management touchpoint — retrieved 2026-08-19
- https://konghq.com/blog/enterprise/the-difference-between-api-gateways-and-service-mesh
  — vendor-authored (Kong sells both categories of product) but its
  north-south (gateway) vs. east-west (mesh) framing was independently
  corroborated by Gravitee, Medium/Kasun Indrasiri, and DigitalAPI
  write-ups surfaced in the same search pass — flagged as vendor content;
  worth swapping for a neutral source (e.g. an Azure Architecture Center
  microservices-communication article) during authoring if a cleaner
  citation is wanted — retrieved 2026-08-19
- Richards, Mark & Ford, Neal. *Fundamentals of Software Architecture: An
  Engineering Approach* (O'Reilly, 2020) —
  https://www.oreilly.com/library/view/fundamentals-of-software/9781492043447/
  (URL appeared directly in search results) — establishes "architecture
  characteristics" and explicit trade-off analysis as the framing device
  for pattern selection — retrieved 2026-08-19
- Ford, Neal; Richards, Mark; Sadalage, Pramod; Dehghani, Zhamak.
  *Software Architecture: The Hard Parts* (O'Reilly, 2021), ISBN
  978-1-492-08689-5 — cited by ISBN, not URL: the O'Reilly catalog URL
  used in an earlier draft of this doc was reconstructed, not confirmed
  in search results, and has been removed; the confirmed listing is
  https://www.amazon.com/Software-Architecture-Trade-Off-Distributed-Architectures/dp/1492086894
  — companion book extending trade-off analysis to distributed-
  architecture specifics (service granularity, data ownership) —
  retrieved 2026-08-19
- https://martinfowler.com/bliki/ArchitectureDecisionRecord.html —
  confirmed by direct fetch: Fowler's own framing of ADRs (short,
  markdown, sequentially numbered, immutable/superseded-not-edited) and
  his attribution of the format to Michael Nygard's 2011 essay, itself
  building on Philippe Kruchten's earlier decision-log work — retrieved
  2026-08-19
- Nygard, Michael. "Documenting Architecture Decisions" (2011), reference
  copy at https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md
  — search-result snippet only, not independently opened this pass;
  origin of the ADR format (Title/Status/Context/Decision/Consequences)
  that MCPg's ADRs already follow — retrieved 2026-08-19
- Local precedent (not web sources, read directly):
  `C:\Users\devop\GitHub\MCPg\docs\adr\0001-build-approach.md` and
  `C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` — real
  in-repo examples of the ADR shape this skill should recommend
  (Options-considered scoring, flat decision table, "Deviations from
  inherited base" / supersession via Status field) — read 2026-08-19

## Open questions for the user

- Should the authored decision framework output a single recommended
  pattern, or a ranked shortlist with confidence/caveats (e.g. "modular
  monolith, with event-driven overlay for the ingestion subdomain")?
  Real systems often combine axes (pattern × runtime × communication
  style) rather than picking one pure pattern — worth deciding how
  prescriptive vs. compositional the output should be.
- Should project-incubation ship a literal ADR template file (an
  `assets/adr-template.md`, mirroring MCPg's `docs/adr/000N-*.md` shape)
  that gets copied into new repos, or just document the format in prose
  and let each project author its own first ADR from scratch?
- How much should this doc pre-hint at typical pattern-per-category
  pairings for the 5 stack categories researched later (e.g. "Agentic &
  MCP Platforms commonly pairs with hexagonal + event-driven"), versus
  staying strictly pattern-agnostic and leaving that call entirely to the
  stack-specific docs? Pre-hinting risks staleness/duplication once those
  docs land; staying silent risks the two layers feeling disconnected.
- Compliance was named in the prompt's decision-table axes but this
  research treats it only as a shallow *signal* (see out-of-scope). Is
  that the right depth, or does the user want a small compliance-signal
  table (e.g. PCI → isolate cardholder-data subdomain; HIPAA → audit
  trail bias toward event sourcing) even though full regulatory detail
  stays out of scope?
- The UX/frontend-architecture item landed at "low impact / paragraph"
  since it's largely downstream of the Business Applications stack doc.
  Confirm that's acceptable rather than promoting it to its own
  subsection now.
- This research pass did not turn up a strong primary source specifically
  on-prem/air-gapped/regulated-network deployment constraints, even
  though "deployment constraints" was named as a per-pattern signal in
  the prompt. That constraint is exactly what most cleanly rules out
  serverless and biases toward layered/modular-monolith. Worth a
  follow-up search during authoring, or explicit sign-off that
  qualitative treatment (no dedicated source) is fine for that one
  signal.

## Applicability note (added post-Checkpoint-A, see skill-flow-decisions.md #3)

A software/non-software top-level fork was added to SKILL.md's routing
logic after this baseline was approved. This entire document is
**software-path-only** — the non-software path (documentation, research,
knowledge-base, dataset projects) skips architecture-template selection
entirely; there's no pattern to select when there's no code architecture.

## Resolutions (Checkpoint A review, 2026-08-19)

- **Output shape**: compositional, with a primary pick — recommend one
  named pattern but explicitly surface common overlays/combinations (e.g.
  "modular monolith, with event-driven overlay for ingestion") rather than
  forcing a single pure-pattern answer. Carries into SKILL.md's Q&A logic
  and the baseline record's "chosen template + reasoning" field (may record
  more than one composed element).
- **ADR template asset**: ship a literal `assets/adr-template.md`, mirroring
  MCPg's ADR shape (Title/Status/Context/Decision/Consequences, an
  Options-considered scoring section, Status supporting supersession) —
  cheap, reusable, and matches the "one opinionated default" authoring
  convention.
- **Pattern-per-category pre-hinting**: light touch only — a one-line
  "commonly pairs with" hint per stack category in this doc's pattern
  table, not full duplication of the stack docs' own content. Avoids
  staleness while keeping the two layers connected.
- **Compliance-signal depth**: add a small compliance-signal table (e.g.
  PCI-relevant → isolate cardholder-data subdomain; HIPAA-relevant → bias
  toward event sourcing / audit trail) — still explicitly not full
  regulatory guidance, just a bias signal feeding the decision framework.
- **UX/frontend depth**: confirmed as low-impact/paragraph-depth, deferred
  to the future Business Applications stack doc for real coverage.
- **On-prem/air-gapped deployment constraint**: keep as a qualitative
  decision-framework signal (no dedicated source found) — it's real and
  important (cleanly rules out serverless, biases toward layered/modular
  monolith) even without a citation to back a specific claim about it.

## Target file(s) + estimated length

- skills/project-incubation/references/architecture-templates.md —
  est. 480–560 lines (7-pattern comparison table + decision-framework
  section/table + ADR section with embedded template + ~5 cross-cutting
  subsections, several as tables/checklists per the depth notes above).
