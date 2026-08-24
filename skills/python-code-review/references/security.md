# Security

This is the security domain of the `python-code-review` skill's 11-domain
reference set. It identifies security vulnerabilities, unsafe patterns, and
missing protections in Python code, applying a VAPT (Vulnerability
Assessment & Penetration Testing) / WAPT (Web Application Penetration
Testing) mindset — review code the way an attacker would probe it, not the
way a linter would. It draws from OWASP Top 10:2025, OWASP API Security Top
10:2023, the OWASP GenAI Top 10 for LLM Applications 2026, Bandit's rule
set, and the OWASP Cheat Sheet Series for cryptographic and transport
parameters.

Two sibling domains own adjacent territory this file deliberately doesn't
duplicate: [Dependency & Supply Chain Security](../references/dependency-supply-chain-security.md)
owns full CI/CD pipeline security, SBOM generation, and CVE-database
scanning; [Performance](../references/performance.md) is where caching
*speed* concerns live, though one caching finding — unbounded-TTL caching of
sensitive data — is reviewed here instead, because whether a cache can leak
or be misused is this domain's lens, not that one's. Both boundaries are
called out again at the point they matter below.

## Table of Contents

- [Review Mindset (VAPT / WAPT)](#review-mindset-vapt--wapt)
- [Standards Cited and the OWASP Edition Transition](#standards-cited-and-the-owasp-edition-transition)
  - [OWASP Top 10: 2021 to 2025](#owasp-top-10-2021-to-2025)
  - [OWASP API Security Top 10: still 2023](#owasp-api-security-top-10-still-2023)
  - [OWASP GenAI LLM Top 10: 2023 v1.1 to 2026](#owasp-genai-llm-top-10-2023-v11-to-2026)
  - [Why SSRF's citation looks different depending on context](#why-ssrfs-citation-looks-different-depending-on-context)
- [Tier Applicability](#tier-applicability)
- [Critical Findings](#critical-findings)
  - [Dangerous Builtins and Unsafe Deserialization](#dangerous-builtins-and-unsafe-deserialization)
  - [Injection](#injection)
  - [Hardcoded Secrets](#hardcoded-secrets)
  - [Broken Authentication and Session Management](#broken-authentication-and-session-management)
- [Important Findings](#important-findings)
  - [Configuration and Secrets Management](#configuration-and-secrets-management)
  - [Input Validation](#input-validation)
  - [API and Mutation Abuse (OWASP API Security Top 10, 2023)](#api-and-mutation-abuse-owasp-api-security-top-10-2023)
  - [CSRF](#csrf)
  - [CORS Policy](#cors-policy)
  - [SSRF](#ssrf)
  - [PII and Sensitive Data Handling](#pii-and-sensitive-data-handling)
  - [Cryptography](#cryptography)
  - [TLS and Transport Security](#tls-and-transport-security)
  - [Exception Handling (Security Angle)](#exception-handling-security-angle)
  - [HTTP Security Headers](#http-security-headers)
  - [Rate Limiting and Brute-Force Defense](#rate-limiting-and-brute-force-defense)
- [Minor Findings](#minor-findings)
  - [Dependency Security (Residual, Security-Lens Only)](#dependency-security-residual-security-lens-only)
- [LLM-Specific Security](#llm-specific-security)
  - [LLM01 Prompt Injection](#llm01-prompt-injection)
  - [LLM02 Sensitive Information Disclosure](#llm02-sensitive-information-disclosure)
  - [LLM03 Excessive Agency](#llm03-excessive-agency)
  - [LLM04 Supply Chain (cross-reference only)](#llm04-supply-chain-cross-reference-only)
  - [LLM06 Unbounded Consumption](#llm06-unbounded-consumption)
  - [LLM08 Hidden Context Exposure](#llm08-hidden-context-exposure)
  - [LLM09 Vector and Embedding Weaknesses](#llm09-vector-and-embedding-weaknesses)
  - [LLM10 Improper Output Handling](#llm10-improper-output-handling)
  - [OWASP LLM Top 10: full 2023 to 2026 mapping](#owasp-llm-top-10-full-2023-to-2026-mapping)
- [Explicitly Out of Scope](#explicitly-out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Required Evidence in Findings](#required-evidence-in-findings)
- [Sources](#sources)

---

## Review Mindset (VAPT / WAPT)

For every external-facing boundary a piece of code exposes — an HTTP
endpoint, a file upload, a CLI argument, a webhook, a queue consumer, an LLM
prompt — ask the same seven questions an attacker would ask before
approving the code:

1. **Who can reach it?** — authentication and network exposure.
2. **What can they send?** — input validation and schema enforcement.
3. **What resources does it touch?** — authorization, both object-level and
   function-level.
4. **What does it reveal on error?** — information disclosure.
5. **Can its output be trusted downstream?** — injection propagation.
6. **Is it logged safely?** — PII and secret redaction.
7. **Can it be replayed or forged?** — idempotency, CSRF, signatures.

A finding that can't answer at least one of these with "yes, and here's the
control that makes it so" is a finding, not a formality.

---

## Standards Cited and the OWASP Edition Transition

### OWASP Top 10: 2021 to 2025

OWASP Top 10:2025 is the current released edition — 2021 is superseded, not
a parallel option. This is not a relabeling: the category set was
reshuffled, two categories were retired or absorbed, and two are new.
Every citation in this file uses the dual format **"A05:2025 Injection (was
A03:2021)"** during this transition period, because 2021-numbered
references remain common in the wild — other tooling, blog posts, older
checklists — and a bare 2025 number without that anchor reads as a
citation mismatch to anyone still calibrated to 2021.

| 2021 | 2025 | What changed |
|---|---|---|
| A01 Broken Access Control | A01 Broken Access Control | Same slot, now also absorbs SSRF (CWE-918) and CSRF (CWE-352) |
| A05 Security Misconfiguration | A02 Security Misconfiguration | Moved up |
| A02 Cryptographic Failures | A04 Cryptographic Failures | Moved down |
| A03 Injection | A05 Injection | Moved down |
| A04 Insecure Design | A06 Insecure Design | Moved down |
| A07 Identification and Authentication Failures | A07 Authentication Failures | Same slot, renamed |
| A08 Software and Data Integrity Failures | A08 Software or Data Integrity Failures | Same slot |
| A09 Security Logging and Monitoring Failures | A09 Security Logging and Alerting Failures | Same slot, renamed |
| A10 Server-Side Request Forgery | *(absorbed into A01)* | Retired as a standalone category, folded into Broken Access Control |
| *(new)* | A03 Software Supply Chain Failures | New, promoted straight to a top-3 category |
| *(new)* | A10 Mishandling of Exceptional Conditions | New |

Two category promotions matter beyond citation hygiene. **A03:2025
Software Supply Chain Failures** landing in the top three sharpens (it
doesn't remove) the boundary with the sibling
[Dependency & Supply Chain Security](../references/dependency-supply-chain-security.md)
domain — see [Dependency Security](#dependency-security-residual-security-lens-only)
below for exactly where that line sits. **A10:2025 Mishandling of
Exceptional Conditions** gives what used to be an unsourced "exception
handling, security angle" section in older versions of this checklist a
real top-10 backing — see
[Exception Handling](#exception-handling-security-angle).

### OWASP API Security Top 10: still 2023

No newer edition of the API Security Top 10 exists — 2023 remains current,
confirmed directly against `owasp.org/API-Security`. All ten of its
categories are in scope for this domain, not a partial subset — see
[API and Mutation Abuse](#api-and-mutation-abuse-owasp-api-security-top-10-2023)
for the full table. One mapping correction worth stating plainly:
**"mass assignment"** and **"excessive data exposure"** are 2019-edition
category names. In the 2023 edition they merged into a single category,
**API3:2023 Broken Object Property Level Authorization** — its own spec
page names both "previously named: Excessive Data Exposure" and
"previously named: Mass Assignment" as the two failure modes it now
covers. A finding citing "API6" for mass assignment or "API3" for excessive
data exposure using the 2019 numbering is citing the wrong edition; both
findings cite **API3:2023** now.

### OWASP GenAI LLM Top 10: 2023 v1.1 to 2026

The OWASP Top 10 for LLM Applications moved from v1.1 (2023) to a 2026
edition (published August 4, 2026), under the renamed **OWASP GenAI
Security Project** — 2023 v1.1 is explicitly archived on OWASP's own project
page. The canonical source is
`github.com/GenAI-Security-Project/GenAI-LLM-Top10`. This isn't a
renumbering either: two 2023 categories dropped off the list entirely
(Insecure Plugin Design, Model Theft) and two categories new to 2026 appear
(Hidden Context Exposure, Vector and Embedding Weaknesses). This domain's
[LLM-Specific Security](#llm-specific-security) section covers eight of
the ten 2026 categories with full checklists — see the
[full mapping table](#owasp-llm-top-10-full-2023-to-2026-mapping) at the
end of that section for exactly which, and why the remaining two aren't
treated as standalone review categories here.

### Why SSRF's citation looks different depending on context

SSRF has no standalone category in the general OWASP Top 10:2025 — it was
absorbed as CWE-918 into **A01:2025 Broken Access Control**, alongside
CWE-352 CSRF. But SSRF **remains its own standalone category in the API
Top 10** — API7:2023 Server Side Request Forgery, unchanged from prior
editions. So a general web-application SSRF finding cites A01:2025; an
API-surface SSRF finding cites API7:2023. That's not an inconsistency
between two findings that look otherwise identical — it's the two
taxonomies making different structural choices about the same
vulnerability class, and a reviewer who doesn't know this will misread the
citation mismatch as an error.

---

## Tier Applicability

| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Dangerous builtins & unsafe deserialization | Yes | Yes | Yes |
| Injection (SQL/NoSQL/Cypher/Cmd/Template/Log) | Yes | Yes | Yes |
| Hardcoded secrets | Yes | Yes | Yes |
| Configuration & secrets management | Yes | Yes | Yes |
| Broken authentication / session | No | Yes | Yes |
| Input validation | No | Yes | Yes |
| API / mutation abuse (full API Top 10:2023) | No | Yes | Yes |
| CSRF | No | Yes | Yes |
| CORS policy | No | Yes | Yes |
| SSRF | No | Yes | Yes |
| PII / sensitive data handling (incl. cache TTL) | Yes | Yes | Yes |
| Cryptography | No | Yes | Yes |
| TLS / transport | No | Yes | Yes |
| Exception handling (security angle) | Yes | Yes | Yes |
| HTTP security headers | No | Yes | Yes |
| Rate limiting & brute-force defense | No | Yes | Yes |
| mTLS / workload identity | No | No | Yes |
| Dependency security (residual, security-lens) | Yes | Yes | Yes |
| LLM01 Prompt injection *(if LLM used)* | Yes | Yes | Yes |
| LLM02 Sensitive information disclosure *(if LLM used)* | Yes | Yes | Yes |
| LLM03 Excessive agency *(if LLM used)* | Yes | Yes | Yes |
| LLM04 Supply chain *(if LLM used, cross-ref only)* | Yes | Yes | Yes |
| LLM06 Unbounded consumption *(if LLM used)* | Yes | Yes | Yes |
| LLM08 Hidden context exposure *(if LLM used)* | Yes | Yes | Yes |
| LLM09 Vector/embedding weaknesses *(if RAG/vector store used)* | No | Yes | Yes |
| LLM10 Improper output handling *(if LLM used)* | Yes | Yes | Yes |

---

## Critical Findings

### Dangerous Builtins and Unsafe Deserialization

- `eval()`, `exec()`, `compile()` with any externally influenced input.
- `pickle.loads()` / `pickle.load()` / `shelve` / `marshal` on untrusted
  data — these execute arbitrary code on deserialization by design, not by
  bug.
- `yaml.load()` without `Loader=SafeLoader` — use `yaml.safe_load()`
  directly.
- `jsonpickle` on untrusted input.
- `subprocess` with `shell=True` and variable input; `os.system()` with
  string concatenation or f-string interpolation.
- `xml.etree.ElementTree` / `lxml` without entity resolution disabled (XXE
  risk) — prefer `defusedxml` over hardening the stdlib parser by hand.

These are stable facts about Python stdlib and library behavior, not
date-sensitive claims — nothing here changes with an OWASP edition.

### Injection

Covers every query language a Python service is likely to touch, not just
SQL. Cite **A05:2025 Injection (was A03:2021)**.

- **SQL**: raw SQL built with f-strings, `.format()`, `%` interpolation, or
  string concatenation that includes user input.
- **NoSQL**: MongoDB `$where` with user input; unsanitized operators
  accepted directly into a query dict.
- **Cypher (Neo4j)**: f-string or concatenation of labels, relationship
  types, or property names into a Cypher query.
- **LDAP / XPath**: filter strings built from user input without escaping.
- **Server-side template injection (SSTI)**: Jinja2/Mako rendering a
  user-controlled *template string*, not just user-controlled template
  *variables* — the two are very different risk levels.
- **Command injection**: `os.system`, `subprocess.*` with `shell=True` plus
  a variable, `os.popen` with concatenation.
- **Log injection**: user input concatenated into a log message without
  stripping newlines/CR — log forging.
- Acceptable patterns: parameterized queries, an ORM with bound
  parameters, `psycopg2.sql.SQL()` + `sql.Identifier()`, Neo4j parameterized
  queries, explicit argument lists (never a shell string) for `subprocess`.

### Hardcoded Secrets

- API keys, passwords, tokens, connection strings in source — including
  "default" fallback values, which are a hardcoded secret with extra steps.
- High-entropy strings matching credential patterns.
- Private keys (`-----BEGIN`), certificates, `.pem`/`.p12`/`.pfx` files
  committed to the repository.
- `.env` files committed to version control.
- Secrets in Dockerfile `ENV` or `ARG` — image layers are cached and
  inspectable, this is not a private channel.
- Secrets embedded in test fixtures or sample data that ships with the
  package.

This section answers "is a secret hardcoded" — whether a secret that
*isn't* hardcoded is fetched, rotated, and delivered correctly is a
separate, deeper question; see
[Configuration and Secrets Management](#configuration-and-secrets-management).

### Broken Authentication and Session Management

- No authentication on mutating endpoints (POST/PUT/PATCH/DELETE) that
  change state.
- JWT `verify=False` / `algorithms=["none"]` / missing signature
  verification. Per the OWASP JWT Cheat Sheet, `alg: none` must be actively
  **rejected by the parser** — not merely checked after decoding, since a
  library that decodes an unverified token before your check runs has
  already done the damage.
- HMAC secrets for JWT signing with less than **160 bits of entropy**.
- **Algorithm/key-type confusion** — mixing MAC-based and public-key
  algorithms (e.g., an endpoint that accepts both `HS256` and `RS256` and
  verifies an `HS256` token using the RSA public key as the HMAC secret,
  since the public key is, by definition, public). This is a named attack
  class, not a hypothetical.
- Session tokens in URL query strings — they leak via Referer headers,
  server logs, and browser history.
- Password comparison with `==` rather than `hmac.compare_digest()`
  (timing attack).
- API-specific authentication issues fold in here rather than getting a
  separate subsection: token lifecycle scoped to API clients, credential
  reuse across service boundaries, and missing per-client rate limits on
  auth endpoints are **API2:2023 Broken Authentication** — cite it
  alongside the general authentication finding when the endpoint in
  question is API surface, not a browser-facing login flow.

---

## Important Findings

### Configuration and Secrets Management

Twelve-factor config discipline is a foundational principle, not
security-specific — see
[Zero Hardcoding / Config-Driven](../../project-incubation/references/architecture-principles.md#2-zero-hardcoding--config-driven-twelve-factor-config)
for the general case rather than duplicating it here. This section reviews
the security-specific layer on top of that: whether *code* fetches secrets
correctly at runtime, not whether a team picked the right secrets-manager
product — vault/KMS product selection and infra-level key management are
out of scope for a code-review skill (see
[Explicitly Out of Scope](#explicitly-out-of-scope)).

- **Rotation is a distinct check from "no hardcoded secrets."** A secret
  that's fetched from a vault at runtime but never rotated is still a
  long-lived credential risk. OWASP's Secrets Management Cheat Sheet states
  cadence is function- and risk-dependent — "from minutes... to years" —
  with no universal number. Flag the *absence* of any rotation mechanism,
  not a specific interval; inventing a required cadence would be a false
  precision this domain's own sourcing doesn't support.
- **Vault/KMS integration correctness** — the checkable pattern is whether
  secrets arrive via runtime fetch-from-vault, sidecar-container injection,
  or a mounted volume populated by the orchestrator, versus being baked
  into an image layer or committed alongside application config. The first
  three are correct patterns; the last two are the "hardcoded secret with
  extra steps" failure mode from a different angle.
- **CI/CD credentials specifically need short-lived, job-scoped rotation**
  — the cheat sheet is explicit that credentials used by CI/CD tooling
  should be "rotated frequently and expire after a job completes." A
  long-lived CI credential with broad scope is a standing liability even
  when it's correctly stored in a secrets manager.
- What this section does *not* review: which vault product to buy, how to
  configure an org's KMS key hierarchy, or infra-level access policies on
  the secret store itself. Those are deployment/infra decisions outside a
  code-review pass.

### Input Validation

- User input validated with a schema library (pydantic, marshmallow,
  attrs) at every system boundary — not just at the outermost HTTP layer.
- String inputs validated against a regex or allowlist where one applies —
  email, URL, identifier fields.
- File path inputs resolved and checked against an allowed base directory
  — no `../`, no absolute paths, no symlinks that escape the sandbox.
- Numeric inputs bounded (min/max); collection inputs bounded (max
  length/items/depth).
- Request body size limits configured (FastAPI `max_upload_size`, a
  Starlette middleware, nginx `client_max_body_size`).
- `Content-Type` strictly enforced — reject a mismatched payload rather
  than sniffing it.
- Pagination params (`limit`/`offset`/`page_size`) bounded with a hard max.

### API and Mutation Abuse (OWASP API Security Top 10, 2023)

All ten categories are in scope — the original version of this checklist
covered five; this one covers the full taxonomy, since a partial API Top 10
leaves real, common findings with nowhere to be filed.

| Category | What it covers | Code-review check |
|---|---|---|
| **API1:2023** Broken Object Level Authorization | An endpoint looks up an object by ID but never checks the authenticated caller owns or may access it | Every `get_item_by_id`-shaped lookup is paired with an authorization check — BOLA/IDOR |
| **API2:2023** Broken Authentication | API-specific auth failures — token lifecycle, credential reuse across services, missing per-client auth rate limits | See [Broken Authentication](#broken-authentication-and-session-management) — cite API2 alongside the general finding on API surface |
| **API3:2023** Broken Object Property Level Authorization | Merges the 2019 categories "Excessive Data Exposure" and "Mass Assignment" | **Mass assignment**: `User(**request.json())` lets a caller set `is_admin=True` — use an explicit allowlist schema (`UserCreateIn` distinct from `UserDB`). **Excessive data exposure**: response models return full DB rows including password hashes, internal flags, soft-delete markers — use explicit `*Out` response models |
| **API4:2023** Unrestricted Resource Consumption | No per-user/per-IP rate limit, no query-complexity limit (GraphQL), no timeout | Matches [Rate Limiting](#rate-limiting-and-brute-force-defense) applied to API surface specifically |
| **API5:2023** Broken Function Level Authorization | Admin endpoints distinguished only by URL prefix, not by a role check | e.g. `/admin/*` served by the same router without `Depends(require_admin)` — BFLA |
| **API6:2023** Unrestricted Access to Sensitive Business Flows | An endpoint has correct object- and function-level authz individually, but nothing stops scripted bulk abuse of the business flow itself | No check for scripted bulk-purchase, bulk-account-creation, or scalping-style abuse against a flow that is otherwise correctly authorized per-request |
| **API7:2023** Server Side Request Forgery | Standalone in the API taxonomy even though SSRF has no standalone slot in the general Top 10 anymore | See [SSRF](#ssrf) below |
| **API8:2023** Security Misconfiguration | Overlaps general **A02:2025 Security Misconfiguration (was A05:2021)** | Default configs, verbose errors, unnecessary HTTP methods enabled, missing security headers on API responses |
| **API9:2023** Improper Inventory Management | Shadow/zombie API versions still reachable; undocumented endpoints | An old `/v1/` router still mounted and reachable after `/v2/` shipped, with no deprecation/sunset enforcement |
| **API10:2023** Unsafe Consumption of APIs | Trusting a third-party API's response without the same validation rigor applied to first-party input | Response from an upstream API deserialized and used without schema validation, size limits, or error-path handling — the third-party boundary is still a trust boundary |

### CSRF

- Cookie-based session auth without a CSRF token on state-changing
  endpoints.
- `SameSite` cookie attribute not set — should be `Lax` or `Strict`.
- No double-submit token or synchronizer token pattern (Django/Flask).
- `Origin` / `Referer` header not validated on cookie-authenticated POST.
- Pure bearer-token APIs (Authorization header only) are not
  CSRF-exploitable *unless* the same endpoint also accepts cookie auth.
- Cite **A01:2025 Broken Access Control (was A10:2021 for SSRF, and CSRF
  was previously uncategorized as a standalone item)** — CWE-352 CSRF is
  one of the CWEs A01:2025 explicitly names.

### CORS Policy

- `allow_origins=["*"]` combined with `allow_credentials=True` — spec-
  violating, and many browsers still honor it, which makes it exploitable
  rather than merely non-conformant.
- Wildcard `*` origin in a production environment.
- Origin reflected from the request header without an allowlist
  (`Access-Control-Allow-Origin: <attacker.com>` echoed back verbatim).
- `allow_methods=["*"]` and `allow_headers=["*"]` on credentialed
  endpoints.
- No `max-age` / preflight caching strategy.

### SSRF

- Application fetches a URL supplied by user input (`httpx.get(user_url)`,
  webhooks, image proxies, URL previewers).
- No allowlist of permitted hosts/schemes. OWASP's SSRF Prevention Cheat
  Sheet states the governing principle plainly: **"deny-lists are
  bypass-prone, prefer allow-lists."** Blocking known-bad IPs is a floor,
  not the target state.
- Cloud-metadata IP not blocked — `169.254.169.254` on AWS/GCP/Azure is the
  canonical target, but it's the minimum deny-list entry, not sufficient on
  its own per the point above.
- RFC-1918 / link-local ranges not blocked.
- **DNS rebinding** not considered — re-resolve A/AAAA records and
  re-validate on each request; validating once and caching the resolution
  is not a defense.
- Redirects followed across hosts without re-validating the new target.
- Citation depends on context — see
  [Why SSRF's citation looks different depending on context](#why-ssrfs-citation-looks-different-depending-on-context)
  above: **A01:2025** for a general web-app finding, **API7:2023** for an
  API-surface finding.

### PII and Sensitive Data Handling

- PII (names, email, phone, SSN/national IDs, addresses, DOB, health/
  financial data) logged in plaintext, or present in error messages
  returned to clients.
- PII in URL query strings — logged by proxies, retained in browser
  history and Referer headers.
- Credentials, tokens, API keys, session IDs, Authorization headers, and
  cookies logged.
- Request/response bodies logged wholesale without redaction; PII surviving
  in exception tracebacks without scrubbing.
- Database errors (column names, values) or stack traces returned in an
  HTTP 500 response.
- Verbose server headers (`Server`, `X-Powered-By`) disclosing version —
  a fingerprinting aid for an attacker, not just noise.
- No data-retention/TTL policy on logs that contain PII.
- **Caching sensitive data without expiry** — handed off from the sibling
  [Performance](../references/performance.md) domain rather than reviewed
  twice. Caching user-specific or security-sensitive data — via
  `functools.cache`/`lru_cache` in-process, or an external store like Redis
  — with no TTL and no explicit invalidation path is a data-exposure risk
  here, not a speed problem: it produces stale authorization state, or a
  cache key that leaks one user's data to another. Performance owns
  whether the cache is *fast*; this domain owns whether it can *leak or be
  misused*.

### Cryptography

Numeric parameters below are precise, sourced directly from OWASP's
Cryptographic Storage and Password Storage Cheat Sheets, not
threshold-only guidance.

| Concern | Requirement |
|---|---|
| Password hashing, in OWASP's stated preference order | **Argon2id** (m=19456 KiB, t=2, p=1 minimum) first choice. **scrypt** (N=2^17, r=8, p=1) when Argon2id is unavailable. **PBKDF2-HMAC-SHA256 ≥600,000 iterations** only when FIPS-140 compliance is required. **bcrypt** (work factor ≥10, 72-byte password input limit) for legacy systems only — not a first choice for new code |
| Symmetric encryption | AES ≥128-bit, 256-bit preferred; authenticated modes only — **GCM** and **CCM** are first preference. AES in CBC-only mode without a separate HMAC is not acceptable |
| Asymmetric encryption | RSA ≥2048-bit is a floor when ECC isn't available. OWASP's actual current preference is ECC with **Curve25519**; **P-256 is an acceptable fallback floor** when Curve25519 isn't available — the same relationship PBKDF2 has to Argon2id above: a documented fallback, not a co-equal choice |
| Token/key generation | `secrets` module, never `random` or `random.SystemRandom` |
| Broken primitives (never acceptable) | MD4, MD5, SHA-1, RIPEMD-160 for password hashing or security-critical integrity (collision-broken); DES, 3DES, RC4, Blowfish (≤64-bit block); any cipher in ECB mode; static/hardcoded IVs, nonces, or salts; self-rolled crypto (custom XOR, custom hash combining, custom MAC) — use `hmac`, `cryptography`, or `nacl` instead |
| Key storage | Encryption keys never stored alongside the ciphertext they protect, and never in source |

### TLS and Transport Security

Reverified against the OWASP TLS Cheat Sheet, which frames 1.2 as a
compatibility fallback rather than a co-equal target with 1.3:

- **TLS 1.3 should be the default.**
- **TLS 1.2 is acceptable only for compatibility** with clients that can't
  yet negotiate 1.3 — not a target state to design for.
- **TLS 1.0 and 1.1 are formally deprecated by RFC 8996 (March 2021) and
  must be disabled.**
- **SSLv2 and SSLv3 are always disabled**, no exceptions.
- `verify=False` on `requests`, `httpx`, or `urllib3`; `ssl.CERT_NONE` or
  disabled hostname verification.
- Custom SSL context configured with weak cipher suites.
- HTTP (not HTTPS) endpoints used for auth or credential flows.
- `urllib.request.urlopen` without a scheme restriction.

### Exception Handling (Security Angle)

Backed by **A10:2025 Mishandling of Exceptional Conditions**, a new
top-10 category — this section was previously the weakest-sourced part of
this checklist and now has a real citation.

- Unfiltered database errors reaching the client.
- Exception paths that skip resource cleanup — connections, locks, or file
  handles left open, which is a resource-exhaustion path, not just an
  untidy one.
- Multi-step transactions left uncommitted or unrolled-back on error,
  leaving data in a corrupted or partial state.
- Bare `except:` clauses — these also swallow `SystemExit` and
  `KeyboardInterrupt`, masking security failures along with everything
  else.
- Raw exception text sent in an HTTP response (`detail=str(e)` exposes
  internals directly to the caller).
- `logger.exception` on an authentication failure that doesn't redact
  submitted credentials out of the captured locals.

### HTTP Security Headers

- **`Strict-Transport-Security` (HSTS)** — two real thresholds apply here,
  state both rather than picking one: **`max-age=63072000`** (2 years) is
  OWASP's current *recommended* value; **`max-age=31536000`** (1 year)
  remains accurate as the separate **hstspreload.org minimum eligibility
  floor** for submission to browser preload lists. A finding citing
  "should be ≥31536000" isn't wrong, it's citing the weaker of two real
  thresholds — prefer 63072000 as the target.
- Missing `Content-Security-Policy` (at minimum `default-src 'self'`).
- Missing `X-Frame-Options: DENY` or an equivalent CSP `frame-ancestors
  'none'`.
- Missing `X-Content-Type-Options: nosniff`.
- Missing `Referrer-Policy: strict-origin-when-cross-origin` or stricter.
- Missing `Permissions-Policy` disabling unused browser capabilities.
- `Server`, `X-Powered-By`, `X-AspNet-Version` headers leaking version
  information.
- No `Cache-Control: no-store` on auth or otherwise sensitive endpoints.

### Rate Limiting and Brute-Force Defense

- Auth endpoints (login, password reset, MFA, signup) without a per-IP
  **and** per-account rate limit.
- No exponential backoff or account lockout after repeated failures.
- No CAPTCHA or equivalent on abuse-prone endpoints.
- Password reset tokens with no expiry, that are reusable, predictable, or
  sent via a URL query parameter.
- **No universal lockout-attempt count exists in OWASP guidance, and this
  checklist doesn't invent one.** The correct finding is "no rate limit /
  no lockout exists" — not "lockout should trigger after N attempts" with
  a fabricated N. A reviewer who states a specific number here is citing a
  threshold that doesn't exist in the source material.

---

## Minor Findings

- `bandit` configured in CI/CD with a baseline and diff mode, so new
  findings are distinguished from pre-existing accepted risk.
- `# nosec` annotations always carry a justification comment — an
  unexplained suppression is itself a finding.
- Secret scanning (`gitleaks`, `trufflehog`) wired into pre-commit or CI.
- A pre-deployment DAST scan referenced in the CI pipeline.
- SBOM generation (CycloneDX/SPDX) for releases — ownership detail below.
- A threat-model document referenced from the README or docs — full
  STRIDE/PASTA walkthroughs are out of scope here (see
  [Explicitly Out of Scope](#explicitly-out-of-scope)), but a project
  should at least point at one if it exists.
- A security contact published (`SECURITY.md` or `security.txt`).

### Dependency Security (Residual, Security-Lens Only)

Full SBOM generation, CVE-database integration, lockfile discipline, and
CI/CD pipeline security belong to the sibling
[Dependency & Supply Chain Security](../references/dependency-supply-chain-security.md)
domain — sharpened, not created, by **A03:2025 Software Supply Chain
Failures** landing in the top three of the general Top 10. What stays in
*this* domain is narrower: whether an individual finding's exploit
mechanism is a supply-chain-sourced vulnerability that's actually reachable
through the code path under review — "this code calls a function in
dependency X, which has a known CVE relevant to this code path" is a
security-domain finding. Whether the project has an SBOM pipeline or a CVE
scanner wired into CI at all is the sibling domain's checklist, not this
one's.

One deliberate omission: don't cite a bare version-staleness claim (e.g.
"`requests` < 2.31 is old") as a finding unless a specific CVE backs it. A
version number alone isn't independently verifiable as a vulnerability —
name the CVE, or don't raise the finding here.

---

## LLM-Specific Security

Activate this section when the project imports an LLM SDK — `openai`,
`anthropic`, `google-generativeai`, `langchain`, `llama-index`, `cohere`,
`together`, `mistralai`, `boto3` (Bedrock), or `vertexai` are the common
signals. Eight of the ten OWASP GenAI LLM Top 10:2026 categories get a
full checklist below; the remaining two aren't treated as standalone
review categories by this skill — see the
[mapping table](#owasp-llm-top-10-full-2023-to-2026-mapping) for which and
why.

### LLM01 Prompt Injection

- System and user prompts kept separate; user content is never injected
  into the system role.
- User content wrapped in clearly delimited blocks (e.g.
  `<user_input>...</user_input>` with an accompanying warning) or passed as
  a distinct message role, not string-concatenated into the instruction
  text.
- Length caps enforced on user-supplied prompt text.
- Instruction-override strings ("ignore previous instructions" and its
  variants) detected or flagged where moderation matters.
- Retrieved documents (RAG) inserted into a prompt are labeled as untrusted
  data, not presented to the model indistinguishably from the system's own
  instructions — indirect prompt injection travels through this seam.

### LLM02 Sensitive Information Disclosure

Promoted from LLM06:2023 v1.1 — broader than a narrow "no API keys in tool
context" check. Covers PII/PHI/credentials/secrets leaking through any of:
the final answer, tool-call arguments, reasoning traces, retrieved RAG
chunks, logs of model I/O, and side channels like response timing or token
length.

- No secrets embedded in system prompts.
- Context sent to a model or provider is deliberately minimized, not
  defaulted to "send everything the request has access to."
- Logs of model input/output are access-restricted and scrubbed beyond
  regex-only redaction — regex redaction reliably misses PII in formats it
  wasn't written to expect.

### LLM03 Excessive Agency

Promoted from LLM08:2023 v1.1.

- Tools granted to the model are minimized in count; each tool's own
  functionality is minimized in scope.
- No open-ended tools — a generic shell-exec or unrestricted HTTP-fetch
  tool is an excessive-agency finding by itself, regardless of how it's
  used.
- Downstream permissions granted to a tool call are minimum-necessary.
- Tool calls execute in the **calling user's** authorization context, not
  a broadly-scoped service account — the model shouldn't be able to reach
  further than the human who invoked it could.
- Human-in-the-loop approval gates high-impact actions.
- **Complete mediation**: authorization is enforced by an independent
  policy layer outside the model, never by asking the model itself to
  judge whether an action is allowed. A system prompt instruction telling
  the model "don't delete production data" is not an authorization
  control.

### LLM04 Supply Chain (cross-reference only)

Renamed from LLM05:2023 v1.1 Supply Chain Vulnerabilities. Per this
skill's own domain boundary, the conditional model-artifact deserialization
subsection here is the sibling
[Dependency & Supply Chain Security](../references/dependency-supply-chain-security.md)
domain's territory — Bandit B614/B615-style checks on `torch.load`,
pickled model artifacts, and similar are covered there, not duplicated in
this file.

### LLM06 Unbounded Consumption

Renamed and broadened from LLM04:2023 v1.1 Model Denial of Service. This
category has a genuinely code-reviewable surface — token-budget and
spend-ceiling checks a reviewer can actually see in the diff — which is
why it stays in scope here even though "model DoS" as a phrase sounds like
an infrastructure concern.

- Pre-flight token-count estimation before the model call, not just after
  the response comes back.
- Both **tokens-per-minute and tokens-per-day** budgets enforced — a
  requests-per-second limit alone doesn't bound cost on a service with
  variable-length completions.
- `max_tokens` set explicitly on every call.
- Hard, non-overridable spend ceilings that **halt inference**, not ones
  that merely alert after the fact.
- Step/recursion-depth limits on agent loops, so a misbehaving agentic
  chain can't recurse into an unbounded spend.

### LLM08 Hidden Context Exposure

New in the 2026 edition. Assume all context available to the model —
system prompts, tool definitions, reasoning traces, retrieved documents —
is potentially exposable to the end user, whether through direct
extraction prompts, error messages, or side channels.

- No credentials, internal URLs, or business-sensitive logic embedded in a
  system prompt on the assumption it's hidden from the user — it isn't, in
  the threat-model sense that matters here.
- Reasoning-trace or scratchpad content that the application surfaces
  (for debugging, for a "show your work" UI feature) is treated with the
  same sensitivity review as the final output, not exempted because it
  wasn't the "real" answer.

### LLM09 Vector and Embedding Weaknesses

New in the 2026 edition. Applies to any project with a RAG pipeline or
vector store.

- Vector-store access is tenant-scoped — a multi-tenant RAG deployment
  enforces the same per-tenant isolation on vector search results that it
  would on a SQL query, not an implicit assumption that embeddings are
  "just numbers" and therefore safe to share across tenants.
- Embedding-inversion risk considered for sensitive source documents —
  embeddings can leak information about the text that produced them, so
  the same access controls that would apply to the source document should
  extend to its embedding.
- Retrieved-chunk provenance tracked, so a response can be traced back to
  which document supplied which claim — the same source-trust labeling
  discipline as LLM01, applied at the retrieval layer.

### LLM10 Improper Output Handling

Renamed and renumbered from LLM02:2023 v1.1 Insecure Output Handling —
demoted in rank but not in scope; treat **all** LLM output as untrusted
input to anything downstream of it.

- Model output never passed to `eval`, `exec`, a SQL execute call,
  `subprocess`, `os.system`, or `open(..., "w")` without validation first.
- Zero-trust validation before backend use — the model's output gets the
  same scrutiny a request body would.
- Context-aware encoding and parameterized queries for any
  model-authored query, exactly as if a human user had typed it.
- CSP applied against model-generated content rendered client-side.
- Control and non-printable characters sanitized before writing model
  output to a terminal or a log file.
- Auto-rendering of markdown images, link previews, and iframes disabled
  client-side for model-generated content.

### OWASP LLM Top 10: full 2023 to 2026 mapping

| 2023 v1.1 | 2026 | Change | In scope here? |
|---|---|---|---|
| LLM01 Prompt Injection | LLM01 Prompt Injection | Same slot | Yes |
| LLM06 Sensitive Information Disclosure | LLM02 Sensitive Information Disclosure | Promoted | Yes |
| LLM08 Excessive Agency | LLM03 Excessive Agency | Promoted | Yes |
| LLM05 Supply Chain Vulnerabilities | LLM04 Supply Chain | Renamed | Cross-reference only — see sibling domain |
| LLM03 Training Data Poisoning | LLM05 Data/Model Poisoning | Renamed, broadened | No — training-time concern, unreachable from a code-review pass |
| LLM04 Model Denial of Service | LLM06 Unbounded Consumption | Renamed, broadened | Yes |
| LLM09 Overreliance | LLM07 Misinformation | Renamed | No — a model-quality/UX concern rather than a code-level defect; the closest overlap is LLM03's human-in-the-loop requirement for high-impact actions |
| *(new)* | LLM08 Hidden Context Exposure | New | Yes |
| *(new)* | LLM09 Vector and Embedding Weaknesses | New | Yes, when RAG/vector store present |
| LLM02 Insecure Output Handling | LLM10 Improper Output Handling | Demoted in rank, renamed | Yes |
| LLM07 Insecure Plugin Design | *(dropped)* | No longer a standalone category | N/A |
| LLM10 Model Theft | *(dropped)* | No longer a standalone category | No — infra/access-control concern for model-hosting infrastructure, and now moot as a citation target since it isn't on the list at all |

---

## Explicitly Out of Scope

- **LLM05 Data/Model Poisoning and LLM training-data quality** —
  training-time concerns, not reachable from a code-review pass over
  application code.
- **Model theft** — an infrastructure/access-control concern for
  model-hosting infrastructure, not application code; also moot as a
  citation target now that it's off the 2026 top-10 list entirely.
- **Full CI/CD pipeline security** — pinned Actions/base images,
  poisoned-pipeline-execution vectors, artifact signing and attestation —
  owned by the sibling
  [Dependency & Supply Chain Security](../references/dependency-supply-chain-security.md)
  domain.
- **SBOM generation/consumption, CVE-database integration (OSV/GHSA),
  license-compatibility across the dependency tree, lockfile discipline** —
  same sibling-domain boundary.
- **Full STRIDE/PASTA threat-modeling walkthrough** — a deeper, separate
  exercise; see
  [Security-by-Design](../../project-incubation/references/architecture-principles.md#3-security-by-design)
  in the project-incubation domain, which scopes this out at the
  architecture-principles altitude for the same reason it's scoped out
  here at the code-review altitude.
- **Vault/KMS product selection, infra-level KMS key management** — this
  domain reviews whether code fetches secrets correctly at runtime, not
  which managed secrets product an organization should adopt.
- **A universal brute-force lockout threshold (a specific N)** — OWASP
  declines to name one; this checklist doesn't invent one either.
- **Framework-specific security rule sets** — Django security middleware
  specifics, FastAPI-specific dependency-injection auth patterns — belong
  to a future stack-specific overlay, not this domain's altitude.

---

## Scoring Guide

- **10** — Zero critical or important findings. Modern crypto parameters
  met (Argon2id/Curve25519 or their documented fallbacks). All HTTP
  security headers present. Secrets fetched correctly at runtime with a
  rotation path. LLM guardrails complete across every applicable category
  if the project is LLM-integrated. CORS/CSRF correct. PII redacted
  everywhere, including cache-TTL discipline on sensitive cached data.
- **8-9** — No critical findings; one or two minor important gaps (a
  single missing header, one unpinned dependency flagged with its CVE).
- **6-7** — No critical findings; several important gaps — missing input
  validation somewhere, a CORS policy that's only wrong in dev, one
  uncovered API Top 10 category on an API-heavy service.
- **4-5** — One critical finding, or many important gaps accumulated
  together (missing CSRF protection, PII in logs, weak crypto parameters).
- **1-3** — Multiple critical findings: `eval`/`exec` on user input,
  SQL/Cypher/prompt injection, hardcoded secrets, broken authentication,
  `allow_origins=["*"]` combined with credentials, secrets baked into a
  container image.

## Required Evidence in Findings

Each finding in this domain must include:

- **Severity** — Critical / Important / Minor.
- **Category** — one of: Injection / Auth / Authz / Config-Secrets / Crypto
  / PII / CORS / CSRF / SSRF / Deserialization / Secrets / Headers /
  Rate-Limit / Dependency / LLM / TLS / Input-Validation.
- **OWASP reference**, where applicable, in the dual-edition citation
  format established above — e.g. "A05:2025 Injection (was A03:2021)",
  "API3:2023 Broken Object Property Level Authorization", or "LLM03:2026
  Excessive Agency".
- **File and line number.**
- **Attack scenario** — one sentence describing how the finding is
  actually exploited, not just what rule it violates.
- **Fix** — a concrete, code-level remediation, not a restatement of the
  finding as advice.

---

## Sources

- https://owasp.org/www-project-top-ten/ — confirms OWASP Top 10 2025 is
  the current released version, superseding 2021. Retrieved 2026-08-24.
- https://owasp.org/Top10/2025/ — full 2025 category list (A01–A10).
  Retrieved 2026-08-24.
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/ — confirms
  SSRF (CWE-918) and CSRF (CWE-352) are covered CWEs under A01:2025, i.e.
  SSRF has no standalone 2025 category. Retrieved 2026-08-24.
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
  — new category description, example vulnerabilities, and prevention
  guidance. Retrieved 2026-08-24.
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/ —
  scope confirmation (SBOM, transitive dependencies) and promotion to a
  top-3 category. Retrieved 2026-08-24.
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/ — confirms
  API Security Top 10 2023 is still current; full API1–API10 list.
  Retrieved 2026-08-24.
- https://owasp.org/API-Security/editions/2023/en/0xa3-broken-object-property-level-authorization/
  — confirms API3:2023 merges 2019's "Excessive Data Exposure" and "Mass
  Assignment" into one category. Retrieved 2026-08-24.
- https://owasp.org/www-project-top-10-for-large-language-model-applications/
  — confirms 2023 v1.1 is archived and the 2026 edition (published August
  4, 2026) is current; links the canonical GitHub source. Retrieved
  2026-08-24.
- https://github.com/GenAI-Security-Project/GenAI-LLM-Top10/tree/main/2026/final
  and the individual category files for LLM02, LLM03, LLM06, LLM08, LLM09,
  and LLM10 within that tree — full 2026 category set, descriptions, and
  tiered mitigation guidance. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
  — rotation cadence guidance, dynamic vs. static secrets, vault/KMS
  integration patterns, CI/CD credential handling. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
  — TLS 1.3-default/TLS 1.2-compatibility-only guidance; RFC 8996 basis for
  disabling TLS 1.0/1.1. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_Cheat_Sheet.html
  — `alg:none` rejection requirement, HMAC secret entropy floor (≥160
  bits), algorithm/key-type confusion attack class. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html
  — current recommended HSTS `max-age` (63072000) and preload-list
  guidance. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html
  — AES-GCM/CCM authenticated-mode preference, RSA ≥2048-bit floor, ECC
  Curve25519 preference, `secrets` module guidance. Retrieved 2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
  — password-hashing preference order and exact parameters (Argon2id
  m=19456/t=2/p=1, scrypt N=2^17/r=8/p=1, PBKDF2-SHA256 ≥600,000
  iterations, bcrypt work factor ≥10 with a 72-byte input limit). Retrieved
  2026-08-24.
- https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
  — cloud-metadata IP deny-list guidance, the "prefer allow-lists over
  deny-lists" principle, DNS-rebinding re-resolution guidance. Retrieved
  2026-08-24.
- `skills/project-incubation/references/architecture-principles.md` (this
  repo) — cross-referenced for twelve-factor config (§2) and the
  Security-by-Design threat-modeling boundary (§3) rather than duplicated.
  Read 2026-08-24.
- `research/python-code-review-domain-scoping.md` (this repo) — source of
  the LLM-specific and configuration/secrets-management expansions
  required for this domain, and its boundary with the sibling Dependency &
  Supply Chain Security domain.
- `research/python-code-review/security.md` (this repo) — the approved
  research baseline this file was authored from; retained as the
  provenance record for the decisions above.
