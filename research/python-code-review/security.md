# Baseline: Security
Status: user-approved      Date: 2026-08-24

Starting point: `research/python-code-review/original-tool/review-domains/security.md`
(255 lines, substantial, not re-derived from zero). This baseline verifies its
load-bearing claims by direct fetch, corrects two OWASP edition/mapping
errors found during verification, and implements the two expansions required
by `research/python-code-review-domain-scoping.md`: (a) LLM-specific coverage
beyond prompt injection, and (b) a dedicated configuration & secrets
management subsection.

## Headline verification findings (read before the rest)

1. **OWASP Top 10 moved from 2021 to 2025.** The original cites "OWASP Top
   10 (2021)" throughout. `owasp.org/www-project-top-ten/` states plainly
   "the most current released version is the OWASP Top Ten 2025." Category
   numbers and names changed substantially — this is not a relabeling, it's
   a reshuffle (see table below). Every `OWASP reference` field the original
   asks reviewers to cite needs updating.
2. **OWASP Top 10 for LLM Applications moved from v1.1 (2023) to a 2026
   edition**, published under the renamed OWASP GenAI Security Project.
   `owasp.org/www-project-top-10-for-large-language-model-applications/`
   explicitly labels 2023 v1.1 "archived" and names "OWASP GenAI LLM Top 10
   2026 (published August 4, 2026)" as current, canonical source
   `github.com/GenAI-Security-Project/GenAI-LLM-Top10`. Category IDs, names,
   and — more importantly — the actual category *set* changed: two 2023
   categories dropped off the top-10 list (Insecure Plugin Design, Model
   Theft) and two new ones appeared (Hidden Context Exposure, Vector and
   Embedding Weaknesses) that the scoping doc could not have considered
   because it predates this edition. See "Open questions" below — this is
   a scope decision for the user, not one this baseline makes unilaterally.
3. **OWASP API Security Top 10 (2023) is still current** — confirmed
   directly, no newer edition exists. But the original mis-maps two findings
   to it: "Mass assignment (API6)" and "Excessive data exposure (API3)" are
   **2019-edition** category numbers. In the 2023 edition both merged into a
   single category, **API3:2023 Broken Object Property Level Authorization**
   — confirmed by direct fetch of that category's page, which names both
   "previously named: Excessive Data Exposure" and "previously named: Mass
   Assignment" as the two failure modes it now covers. API6:2023 is a
   different, unrelated category (Unrestricted Access to Sensitive Business
   Flows) that the original doesn't mention at all.
4. **SSRF has no standalone category in OWASP Top 10:2025** — it was
   absorbed as CWE-918 into **A01:2025 Broken Access Control** (confirmed:
   A01's page lists CWE-918 SSRF and CWE-352 CSRF alongside access-control
   CWEs). The original's SSRF subsection is still fully justified — **SSRF
   remains its own standalone category in the API Top 10 (API7:2023 Server
   Side Request Forgery)**, confirmed unchanged — but the `OWASP reference`
   field for a web-app (non-API) SSRF finding now cites A01:2025, not a
   dedicated SSRF category, and reviewers should know why before they see a
   citation that looks like a category mismatch.
5. **A10:2025 Mishandling of Exceptional Conditions is a new top-10
   category** that upgrades the original's weakest-sourced subsection
   ("Exception Handling (security angle)," previously backed by no external
   citation at all) into one now backed by a top-10 category. Confirmed via
   direct fetch: covers unfiltered database errors reaching clients,
   resource exhaustion from exceptions that skip cleanup, and multi-step
   transactions left in a corrupted/partial state on error — all of which
   the original already flags, now with a real citation.
6. **A03:2025 Software Supply Chain Failures is now a top-3 category**,
   which sharpens (doesn't eliminate) the existing boundary with the
   sibling Dependency & Supply Chain Security domain from the scoping doc.
   The original's "Dependency Security (supply chain)" subsection is mostly
   that sibling domain's territory now; this baseline keeps only the
   security-relevant residue here (see "Explicitly out of scope").

### OWASP Top 10 2021 → 2025 category mapping (for citation correctness)

| 2021 | 2025 | Change |
|---|---|---|
| A01 Broken Access Control | A01 Broken Access Control | Same slot, now also absorbs SSRF (CWE-918) and CSRF (CWE-352) |
| A05 Security Misconfiguration | A02 Security Misconfiguration | Moved up |
| A02 Cryptographic Failures | A04 Cryptographic Failures | Moved down |
| A03 Injection | A05 Injection | Moved down |
| A04 Insecure Design | A06 Insecure Design | Moved down |
| A07 Identification and Authentication Failures | A07 Authentication Failures | Same slot, renamed |
| A08 Software and Data Integrity Failures | A08 Software or Data Integrity Failures | Same slot |
| A09 Security Logging and Monitoring Failures | A09 Security Logging and Alerting Failures | Same slot, renamed |
| A10 Server-Side Request Forgery | *(absorbed into A01)* | Category retired, folded into Broken Access Control |
| *(new)* | A03 Software Supply Chain Failures | New, promoted to top-3 |
| *(new)* | A10 Mishandling of Exceptional Conditions | New |

No exact publication date was found on the pages fetched; the project index
page's own wording ("the most current **released** version") indicates a
final release, not a release candidate, but this baseline flags the absence
of an explicit date rather than assuming.

### OWASP LLM Top 10 2023 v1.1 → 2026 mapping

| 2023 v1.1 | 2026 | Change |
|---|---|---|
| LLM01 Prompt Injection | LLM01 Prompt Injection | Same slot |
| LLM06 Sensitive Information Disclosure | LLM02 Sensitive Information Disclosure | Promoted |
| LLM08 Excessive Agency | LLM03 Excessive Agency | Promoted |
| LLM05 Supply Chain Vulnerabilities | LLM04 Supply Chain | Same rank-ish, renamed |
| LLM03 Training Data Poisoning | LLM05 Data/Model Poisoning | Renamed, broadened |
| LLM04 Model Denial of Service | LLM06 Unbounded Consumption | Renamed, broadened — see note below |
| LLM09 Overreliance | LLM07 Misinformation | Renamed |
| *(new)* | LLM08 Hidden Context Exposure | New |
| *(new)* | LLM09 Vector and Embedding Weaknesses | New |
| LLM02 Insecure Output Handling | LLM10 Improper Output Handling | Demoted in rank, renamed |
| LLM07 Insecure Plugin Design | *(dropped)* | No longer a standalone top-10 category |
| LLM10 Model Theft | *(dropped)* | No longer a standalone top-10 category |

**Correction to the scoping doc, surfaced not silently applied:** the
scoping doc (predating this edition) told this domain to reject "model-DoS"
as an infra/training concern out of scope for code review. The 2026
successor category, **LLM06 Unbounded Consumption**, is broader than the
old "Model DoS" framing and has a genuinely code-reviewable surface the
original tool's own "Cost / DoS" subsection already checks (per-user token
quotas, `max_tokens` set on every call, context-budget check before the
API call, hard non-overridable spending ceilings, step/recursion limits on
agent loops). This baseline keeps that subsection in scope and reclassifies
it under LLM06 rather than inheriting a blanket rejection that the source
material no longer supports. **Model Theft** is correctly still out of
scope (infra/training concern), and is now moot as a citation target since
it dropped off the list entirely — same conclusion as the scoping doc, for
a firmer reason.

**Not decided by this baseline, flagged for the user:** LLM08 Hidden
Context Exposure (system-prompt/reasoning-trace extraction) and LLM09
Vector and Embedding Weaknesses (RAG/vector-store multi-tenant isolation,
embedding inversion) are new 2026 categories with real code-reviewable
surfaces the original tool's RAG subsection already brushes against
(source-trust labeling, provenance) but doesn't name. See "Open questions."

---

## In scope

- **Dangerous builtins & unsafe deserialization** (`eval`/`exec`, `pickle`,
  `yaml.load` without `SafeLoader`, XXE) — impact: high — depth: checklist.
  No changes from original; these are stable, non-date-sensitive facts about
  Python stdlib/library behavior, not re-verified individually.
- **Injection** (SQL/NoSQL/Cypher/LDAP/XPath/SSTI/command/log injection) —
  impact: high — depth: checklist. OWASP reference updates to A05:2025
  Injection (was A03:2021).
- **Hardcoded secrets** (keys, tokens, `.env` in VCS, secrets in Dockerfile
  `ENV`/`ARG`) — impact: high — depth: checklist.
- **Configuration & secrets management** *(new subsection, required
  expansion)* — impact: med-high — depth: section. 12-factor config
  discipline (cross-reference `skills/project-incubation/references/
  architecture-principles.md` §2 rather than duplicate — that doc already
  treats this as a foundational principle for every project); secret
  *rotation* as a distinct check from "no hardcoded secrets" (rotation
  cadence is function/risk-dependent per OWASP's Secrets Management Cheat
  Sheet, "from minutes... to years" — no universal number, explicitly a
  judgment call); vault/KMS integration correctness — checkable patterns are
  runtime fetch-from-vault, sidecar-container secret injection, or mounted
  volumes populated by the orchestrator, versus secrets baked into an image
  or committed config; CI/CD credentials specifically flagged as needing
  short-lived, job-scoped rotation (cheat sheet: "credentials used by the
  CI/CD tooling... rotated frequently and expire after a job completes").
  Boundary note: full secrets-manager *product* selection and infra-level
  KMS setup is out of a code-review skill's remit — this subsection reviews
  whether the *code* fetches secrets correctly at runtime, not which vault
  product a team should buy.
- **Broken authentication / session** (unverified JWT, timing-unsafe
  comparison, tokens in URLs) — impact: high — depth: checklist. JWT
  guidance reverified: `alg:none` must be rejected by the parser (OWASP JWT
  Cheat Sheet, explicit), HMAC secrets need ≥160 bits of entropy, algorithm/
  key-type confusion (mixing MAC and public-key algorithms) is a named
  attack class the original doesn't currently mention — worth adding.
- **Input validation** — impact: med-high — depth: checklist.
- **API / mutation abuse**, remapped to the actual API Top 10:2023 category
  set — impact: high — depth: checklist:
  - BOLA/IDOR → API1:2023 Broken Object Level Authorization (unchanged)
  - Broken authentication → API2:2023 (the original doesn't currently list
    this API-specific angle separately from its general auth section — minor
    gap, not a required expansion, noted for the author)
  - Mass assignment + excessive data exposure → **API3:2023 Broken Object
    Property Level Authorization** (corrected mapping, see finding #3 above)
  - Unrestricted resource consumption → API4:2023 (unchanged, matches
    original's "Lack of resources & rate limiting")
  - BFLA → API5:2023 (unchanged)
  - Unrestricted access to sensitive business flows → API6:2023 (new to
    this baseline; original doesn't cover this category at all — e.g. no
    check for scripted bulk-purchase/bulk-account-creation abuse against a
    business-logic endpoint that individually has correct authz)
  - SSRF → API7:2023 (unchanged, standalone in the API taxonomy even though
    retired from the general Top 10 — see finding #4)
  - Security misconfiguration → API8:2023 (overlaps general Top 10 A02:2025)
  - Improper inventory management → API9:2023 (new to this baseline —
    shadow/zombie API versions still reachable, undocumented endpoints)
  - Unsafe consumption of third-party APIs → API10:2023 (new to this
    baseline — trusting a third-party API's response without the same
    validation rigor applied to first-party input)
- **CSRF** — impact: med — depth: checklist. Now cross-cited to A01:2025
  (CWE-352) per finding #4.
- **CORS policy** — impact: med — depth: checklist.
- **SSRF** — impact: high — depth: checklist. Cloud-metadata-IP blocking
  (`169.254.169.254` for AWS/GCP/Azure) reconfirmed via OWASP's SSRF
  Prevention Cheat Sheet, which also states the stronger principle the
  original doesn't currently state: **"deny-lists are bypass-prone, prefer
  allow-lists"** — deny-listing metadata IPs is the minimum floor, not the
  target state. DNS-rebinding guidance reconfirmed (re-resolve A+AAAA
  records and re-validate, don't validate once and cache).
- **PII / sensitive data handling** — impact: high — depth: checklist.
- **Cryptography** — impact: high — depth: table (numeric parameters below
  are now precise rather than threshold-only, per direct OWASP Cryptographic
  Storage / Password Storage Cheat Sheet fetch):
  - Password hashing, in OWASP's stated preference order: **Argon2id**
    (m=19456 KiB / t=2 / p=1 minimum), **scrypt** (N=2^17, r=8, p=1) when
    Argon2id unavailable, **PBKDF2-HMAC-SHA256 ≥600,000 iterations** when
    FIPS-140 compliance is required (verified in a prior pass this session,
    not re-verified here), **bcrypt** (work factor ≥10, 72-byte password
    input limit) for legacy systems only — the original lists these four
    without the preference order or exact parameters; this is a precision
    upgrade, not a correction.
  - Symmetric encryption: AES ≥128 bit (256 preferred), authenticated modes
    only — GCM and CCM named as first preference, confirming the original.
  - Asymmetric: RSA ≥2048 bit confirmed as a floor when ECC isn't available;
    **but** OWASP's actual current preference is ECC with **Curve25519**,
    not P-256. The original's "ECC curve < P-256" threshold is this
    baseline's inference of a reasonable floor, not OWASP's stated
    preference — flagged as a judgment call, not a verified threshold.
  - `secrets` module (not `random`) for tokens/keys — reconfirmed.
- **TLS / Transport** — impact: high — depth: checklist. Reverified against
  the OWASP TLS Cheat Sheet: **TLS 1.3 should be the default; TLS 1.2 is
  acceptable only for compatibility; TLS 1.0/1.1 are formally deprecated by
  RFC 8996 (March 2021) and must be disabled; SSLv2/SSLv3 always disabled.**
  This sharpens the original's "require TLS 1.2+ (prefer 1.3)" — the current
  cheat sheet frames 1.2 as a compatibility fallback, not a co-equal target.
- **Exception handling (security angle)** — impact: med, upgraded from the
  original's unsourced treatment — depth: checklist. Now backed by
  A10:2025 Mishandling of Exceptional Conditions (see finding #5): unfiltered
  DB errors reaching clients, exception paths that skip resource cleanup,
  multi-step transactions left uncommitted/unrolled-back on error.
- **HTTP security headers** — impact: med — depth: checklist. HSTS
  reverified: the OWASP HSTS Cheat Sheet's current *recommended* value is
  **`max-age=63072000`** (2 years), not the original's `≥31536000` (1 year)
  — but 31536000 remains accurate as the **hstspreload.org minimum
  eligibility floor**, a different and also-real threshold. State both,
  labeled: 31536000 = preload-list minimum, 63072000 = OWASP's current
  recommended value.
- **Rate limiting & brute-force defense** — impact: med — depth: checklist.
  No universal lockout-attempt-count exists in OWASP guidance — the
  original doesn't state one, and this baseline confirms none should be
  invented; keep it as "no rate limit / no lockout" as the finding, not
  "lockout after N attempts" with an invented N.
- **Dependency security (residual, security-lens only)** — impact: low
  here / high in the sibling domain — depth: paragraph. Full SBOM
  generation, CVE-database integration, lockfile discipline, and CI/CD
  pipeline security now belong to the Dependency & Supply Chain Security
  domain per the scoping doc, sharpened further by A03:2025's promotion to
  a top-3 general category (finding #6). What stays here: whether an
  individual finding's *exploit mechanism* is a supply-chain-sourced
  vulnerability reachable through this code path — i.e., this domain still
  flags "this code calls a function in a dependency with a known CVE
  relevant to this code path," but SBOM/scanning-pipeline existence is the
  sibling domain's checklist, not this one's. Drop the original's version-
  specific example ("`requests` < 2.31") unless a specific CVE is cited —
  a bare version-number staleness claim isn't independently verifiable
  without naming the CVE it refers to.
- **LLM-specific security**, expanded per the scoping doc's required item
  (a) — impact: high for LLM-integrated projects, else n/a — depth: section:
  - **LLM01 Prompt Injection** (original's existing coverage, unchanged rank)
  - **LLM10 Improper Output Handling** (renamed/renumbered from "Insecure
    Output Handling" LLM02:2023 — treat all LLM output as untrusted input
    to anything downstream: zero-trust validation before backend use,
    context-aware encoding, parameterized queries for any model-authored
    query, CSP against model-generated content, sanitizing control/
    non-printable characters before writing to terminals or logs, disabling
    auto-rendering of markdown images/link-previews/iframes client-side)
  - **LLM03 Excessive Agency** (promoted from LLM08:2023 — minimize tools
    granted, minimize each tool's functionality, avoid open-ended tools
    like a generic shell-exec, minimum-necessary downstream permissions,
    execute in the calling user's authorization context not a service
    account, human-in-the-loop approval for high-impact actions, and
    "complete mediation" — authorization enforced by an independent policy
    layer, never by asking the model to judge whether an action is allowed)
  - **LLM02 Sensitive Information Disclosure** (promoted from LLM06:2023 —
    broader than the original's narrow "API keys in tool context" line:
    covers PII/PHI/credentials/secrets leaking not just through the final
    answer but through tool-call arguments, reasoning traces, retrieved
    RAG chunks, logs, and even side channels like response timing or token
    length; concrete review checks — no secrets in system prompts, context
    sent to a model/provider is minimized rather than defaulted to "send
    everything," logs of model I/O are restricted and scrubbed beyond
    regex-only redaction)
  - **LLM06 Unbounded Consumption** (the original's existing "Cost / DoS"
    subsection, reclassified — see the correction above. Add: pre-flight
    token-count estimation before the model call, tokens-per-minute AND
    tokens-per-day budgets (not just requests-per-second), hard non-
    overridable spend ceilings that halt inference rather than merely
    alert, step/recursion-depth limits on agent loops)
  - **LLM04 Supply Chain** (cross-reference only, per the scoping doc's
    explicit instruction — the conditional model-artifact deserialization
    subsection is the sibling Dependency & Supply Chain domain's territory;
    don't duplicate Bandit B614/B615-style checks here)

## Explicitly out of scope

- **LLM05 Data/Model Poisoning, LLM training-data quality** — training-time
  concern, not reachable from a code-review pass over application code;
  consistent with the scoping doc's rejection and this repo's existing
  ML/AI-out-of-scope precedent (`research/taxonomy-roadmap.md`).
- **Model theft** — infra/access-control concern for model-hosting
  infrastructure, not application code; also now moot as a citation target
  since it dropped off the 2026 top-10 list entirely (see finding #2).
- **Full CI/CD pipeline security** (pinned Actions/base images, poisoned-
  pipeline-execution vectors, artifact signing/attestation) — owned by the
  sibling Dependency & Supply Chain Security domain; A03:2025's promotion
  to a top-3 category sharpens rather than removes this boundary (finding
  #6).
- **SBOM generation/consumption, CVE-database integration (OSV/GHSA),
  license-compatibility across the dependency tree, lockfile discipline** —
  same sibling-domain boundary.
- **Full STRIDE/PASTA threat-modeling walkthrough** — cross-reference
  `skills/project-incubation/references/architecture-principles.md` §3
  (Security-by-Design), which already scopes this out as "a deeper, separate
  exercise" at the architecture-principles altitude; same call applies here
  at the code-review altitude.
- **Vault/KMS product selection, infra-level KMS key management** — this
  domain reviews whether *code* fetches secrets correctly at runtime, not
  which managed secrets product an org should adopt.
- **A universal brute-force lockout threshold (a specific N)** — OWASP
  declines to name one; don't invent one for this skill either.
- **Framework-specific security rule sets** (Django security middleware
  specifics, FastAPI-specific dependency-injection auth patterns) — belongs
  to a future stack-specific overlay per the scoping doc's own rejection of
  framework-specific domains at this altitude.

## Open questions for the user

1. **LLM08 Hidden Context Exposure and LLM09 Vector and Embedding
   Weaknesses are new 2026 top-10 categories the scoping doc predates and
   didn't rule on.** Both have real code-reviewable surfaces close to what
   the original's RAG subsection already touches (source-trust labeling →
   LLM09's tenant-scoped vector-store ACLs and embedding-inversion handling;
   system-prompt secrecy → LLM08's "never embed credentials in hidden
   context, assume all context is potentially exposable"). Include as a
   third LLM expansion beyond the two the scoping doc named, or hold for a
   future scoping-doc refresh pass? This baseline lists them under
   "in scope" candidates above but does not treat the decision as made.
2. **Unbounded Consumption (LLM06) reclassification** — this baseline keeps
   the original's "Cost / DoS" subsection in scope under the new category
   name rather than following the scoping doc's blanket "model-DoS is out
   of scope" instruction, because the actual 2026 category text names a
   genuinely code-reviewable surface (token-budget checks, spend ceilings)
   that the scoping doc's authors likely didn't have in view when writing
   the rejection. Confirm this reclassification is correct rather than
   scope creep.
3. **OWASP Top 10:2025 citation format** — the field is still transitioning;
   2021-numbered references remain common in the wild (tooling, blog posts,
   other checklists) even though 2025 is now the current edition. Should
   findings cite 2025 only, or both editions during a transition period
   (e.g. "A05:2025 Injection (was A03:2021)")? This baseline used the dual
   format above for clarity during research; the author should decide the
   skill's actual citation convention.
4. **API1–API10:2023 full-category adoption** — the original only used 5 of
   the 10 API Top 10 categories. This baseline adds API2, API6, API9, API10
   as newly in-scope. Confirm this is desired breadth versus deliberately
   narrower original scoping.
5. **Curve25519 vs P-256 as the ECC floor** — flagged above as a judgment
   call. Confirm whether the skill should state a hard floor (and which) or
   leave ECC curve strength as a qualitative check.

## Sources

- https://owasp.org/www-project-top-ten/ — confirms OWASP Top 10 2025 is
  the current released version, superseding 2021 — retrieved 2026-08-24
- https://owasp.org/Top10/2025/ — full 2025 category list (A01–A10 names)
  — retrieved 2026-08-24
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/ — confirms
  SSRF (CWE-918) and CSRF (CWE-352) are covered CWEs under A01:2025, i.e.
  SSRF has no standalone 2025 category — retrieved 2026-08-24
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
  — new category; description, example vulnerabilities (resource
  exhaustion, DB-error information disclosure, state corruption on
  interrupted transactions), and prevention guidance — retrieved 2026-08-24
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/ —
  scope confirmation (SBOM, transitive dependencies, OWASP Dependency-Track/
  Dependency-Check) and promotion to a top-3 category — retrieved 2026-08-24
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/ — confirms API
  Security Top 10 2023 is still current; full API1–API10 category list —
  retrieved 2026-08-24
- https://owasp.org/API-Security/editions/2023/en/0xa3-broken-object-property-level-authorization/
  — confirms API3:2023 merges 2019's separate "Excessive Data Exposure" and
  "Mass Assignment" categories, correcting the original's API6/API3
  mismapping — retrieved 2026-08-24
- https://owasp.org/www-project-top-10-for-large-language-model-applications/
  — confirms 2023 v1.1 is archived, 2026 edition is current (published
  August 4, 2026), and links the canonical GitHub source — retrieved
  2026-08-24
- https://github.com/GenAI-Security-Project/GenAI-LLM-Top10/tree/main/2026/final
  — full 2026 LLM Top 10 file listing / category set (LLM01–LLM10) —
  retrieved 2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM02_SensitiveInformationDisclosure.md
  — description and tiered mitigation guidance for LLM02:2026 — retrieved
  2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM03_ExcessiveAgency.md
  — description and mitigation guidance for LLM03:2026 — retrieved
  2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM06_UnboundedConsumption.md
  — description and mitigation guidance for LLM06:2026, basis for the
  Cost/DoS reclassification — retrieved 2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM08_HiddenContextExposure.md
  — new category description and guidance — retrieved 2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM09_VectorAndEmbeddingWeaknesses.md
  — new category description and guidance (multi-tenant isolation,
  embedding inversion) — retrieved 2026-08-24
- https://raw.githubusercontent.com/GenAI-Security-Project/GenAI-LLM-Top10/main/2026/final/LLM10_ImproperOutputHandling.md
  — description and mitigation guidance for LLM10:2026 (renamed/renumbered
  from LLM02:2023 Insecure Output Handling) — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
  — primary source for the new configuration & secrets management
  subsection: rotation cadence guidance, dynamic vs static secrets, vault/
  KMS integration patterns, runtime secret delivery mechanisms — retrieved
  2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
  — TLS 1.3-default/TLS 1.2-compatibility-only guidance, RFC 8996 basis for
  disabling TLS 1.0/1.1 — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_Cheat_Sheet.html
  — `alg:none` rejection requirement, HMAC secret entropy (≥160 bits),
  algorithm/key-type confusion attack class — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html
  — current recommended HSTS max-age (63072000), includeSubDomains/preload
  guidance — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html
  — AES-GCM/CCM authenticated-mode preference, RSA ≥2048-bit floor, ECC
  Curve25519 preference, `secrets` module guidance — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
  — password-hashing preference order and exact parameters (Argon2id
  m=19456/t=2/p=1, scrypt N=2^17/r=8/p=1, PBKDF2-SHA256 ≥600,000 iterations,
  bcrypt work factor ≥10 + 72-byte limit) — retrieved 2026-08-24
- https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
  — cloud-metadata-IP deny-list confirmation, "prefer allow-lists over
  deny-lists" principle, DNS-rebinding re-resolution guidance — retrieved
  2026-08-24
- `skills/project-incubation/references/architecture-principles.md` (this
  repo) — cross-referenced rather than duplicated for 12-factor config (§2)
  and the Security-by-Design threat-modeling scope boundary (§3) — read
  2026-08-24
- `research/python-code-review-domain-scoping.md` (this repo) — source of
  the two required expansions and the domain's boundary with the sibling
  Dependency & Supply Chain Security domain — read 2026-08-24
- PBKDF2 600,000-iteration threshold — verified in a prior pass this
  session via OWASP's own Password Storage Cheat Sheet; not re-fetched here,
  reconfirmed indirectly by the same page returning the same figure during
  this session's Password Storage Cheat Sheet fetch above.

## Resolutions (Checkpoint A review, 2026-08-24)

- **LLM08 Hidden Context Exposure + LLM09 Vector and Embedding Weaknesses**:
  include as a third LLM expansion. Both are real, current (Aug 2026) OWASP
  categories with genuine code-reviewable surface the original tool's RAG
  subsection already brushes against — matches the explicit
  comprehensive-coverage directive for this whole project.
- **Unbounded Consumption (LLM06) reclassification**: confirmed correct —
  keep in scope under the new category name, superseding the scoping doc's
  now-stale blanket rejection.
- **OWASP citation format**: keep the dual format ("A05:2025 Injection
  (was A03:2021)") as a transitional aid — matches what this baseline
  already used in its own findings, useful while 2021-numbered references
  remain common in the wild.
- **API1–API10:2023 full adoption**: confirmed — adopt full breadth (all
  10 categories, not the original's 5), matches the comprehensive-coverage
  directive.
- **Curve25519 vs. P-256 ECC floor**: state Curve25519 as the actual
  verified OWASP preference; keep P-256 as an acceptable floor when
  Curve25519 isn't available — mirrors how the same section already treats
  PBKDF2 as a FIPS-compliance fallback behind Argon2id.

## Target file(s) + estimated length

- `skills/python-code-review/references/security.md` — est. 480-560 lines.
  Grows from the original's 255 lines primarily from: the corrected/expanded
  API Top 10 mapping (10 categories instead of 5), the new configuration &
  secrets management subsection, the LLM-specific section expanding from one
  item (prompt injection) to six-to-eight (pending the open question on
  LLM08/LLM09), and precise cryptographic parameters replacing threshold-only
  language. The Tier Applicability matrix, Scoring Guide, and Required
  Evidence structure from the original carry forward largely unchanged —
  update only the OWASP-edition citations inside them.
