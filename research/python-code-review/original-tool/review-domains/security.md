# Security Review Domain

## Scope
Identifies security vulnerabilities, unsafe patterns, and missing protections.
Applies a VAPT (Vulnerability Assessment & Penetration Testing) and WAPT (Web
Application Penetration Testing) mindset: review code as an attacker would
probe it. Draws from OWASP Top 10 (2021), OWASP API Security Top 10 (2023),
OWASP LLM Top 10, Bandit rules, and cryptographic best practices.

## Review Mindset (VAPT / WAPT)
For every external-facing boundary (HTTP endpoint, file upload, CLI arg,
webhook, queue consumer, LLM prompt), ask:
1. **Who can reach it?** — authentication and network exposure
2. **What can they send?** — input validation and schema enforcement
3. **What resources does it touch?** — authorization (object-level + function-level)
4. **What does it reveal on error?** — information disclosure
5. **Can its output be trusted downstream?** — injection propagation
6. **Is it logged safely?** — PII and secret redaction
7. **Can it be replayed or forged?** — idempotency, CSRF, signatures

## Tier Applicability
| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Dangerous builtins | Yes | Yes | Yes |
| Hardcoded secrets | Yes | Yes | Yes |
| Injection (SQL/NoSQL/Cypher/Cmd/Template) | Yes | Yes | Yes |
| Prompt injection (if LLM used) | Yes | Yes | Yes |
| Input validation | No | Yes | Yes |
| POST/mutation API abuse (IDOR, BOLA, BFLA, mass assignment) | No | Yes | Yes |
| CSRF protection | No | Yes | Yes |
| CORS policy | No | Yes | Yes |
| SSRF prevention | No | Yes | Yes |
| XXE / deserialization | Yes | Yes | Yes |
| PII in logs | Yes | Yes | Yes |
| Dependency pinning & CVE scan | Yes | Yes | Yes |
| Crypto review | No | Yes | Yes |
| TLS / weak ciphers | No | Yes | Yes |
| HTTP security headers | No | Yes | Yes |
| mTLS / workload identity | No | No | Yes |
| Rate limiting / brute-force defense | No | Yes | Yes |

---

## Review Criteria

### Critical

**Dangerous Builtins & Deserialization**
- `eval()`, `exec()`, `compile()` with any external/user input
- `pickle.loads()` / `pickle.load()` / `shelve` / `marshal` on untrusted data
- `yaml.load()` without `Loader=SafeLoader` (use `yaml.safe_load`)
- `jsonpickle` on untrusted input
- `subprocess` with `shell=True` and variable input
- `os.system()` with string concatenation or f-string interpolation
- `xml.etree.ElementTree` / `lxml` without `resolve_entities=False` (XXE risk) — prefer `defusedxml`

**Injection (all query languages)**
- **SQL:** raw SQL with f-strings, `.format()`, `%` interpolation, or string concatenation including user input
- **NoSQL:** MongoDB `$where` with user input, unsanitized operators in query dicts
- **Cypher (Neo4j):** f-string / concat of labels, relationship types, property names into Cypher
- **LDAP / XPath:** filter strings built from user input without escaping
- **Template injection (SSTI):** Jinja2/Mako rendering user-controlled template strings (not just template *variables*)
- **Command injection:** `os.system`, `subprocess.*` with `shell=True` + variable, `os.popen` with concat
- **Log injection:** user input concatenated into log messages without newline/CR stripping (log-forging)
- Acceptable: parameterized queries, ORM with bound params, `psycopg2.sql.SQL() + sql.Identifier()`, Neo4j parameterized queries, explicit argument lists for subprocess

**Prompt Injection (LLM / AI integration)**
Flag when the project uses any LLM SDK (openai, anthropic, google-generativeai, langchain, llama-index, etc.):
- User-controlled content concatenated directly into system/user prompts without delimiting or labeling as untrusted
- LLM output passed to `eval`, `exec`, `subprocess`, SQL execution, or file writes without validation
- No content guardrails on LLM inputs (length limits, allowlist of tools, PII scrub)
- Tool/function-calling schemas that let the model execute arbitrary shell/SQL/HTTP
- Retrieved documents (RAG) inserted into prompts without source-trust labeling — indirect prompt injection risk
- Chained agents where one agent's output becomes another's instructions without filtering
- API keys or DB credentials accessible in the model's tool context

**Hardcoded Secrets**
- API keys, passwords, tokens, connection strings in source code (including "default" fallbacks)
- High-entropy strings matching credential patterns
- Private keys (`-----BEGIN`), certificates, `.pem`/`.p12`/`.pfx` in the repository
- `.env` files committed to version control
- Secrets in Dockerfile `ENV` or `ARG` (layers are cached and visible)
- Secrets in test fixtures or sample data that ship with the package

**Broken Authentication / Session (Critical when present)**
- No authentication on mutating endpoints (POST/PUT/PATCH/DELETE) that modify state
- JWT `verify=False` / `algorithms=["none"]` / missing signature verification
- Session tokens in URL query strings (leak via Referer, logs, history)
- Password comparison with `==` rather than `hmac.compare_digest()` (timing attack)

### Important

**Input Validation (OWASP API4 — Unrestricted Resource Consumption / OWASP API5 — BFLA)**
- User input validated with schema library (pydantic, marshmallow, attrs) at every system boundary
- String inputs validated against regex/allowlist where applicable — email, URL, identifiers
- File path inputs resolved and checked against an allowed base dir (no `../`, no absolute paths, no symlinks to outside)
- Integer/numeric inputs bounded (min/max); collection inputs bounded (max length/items/depth)
- Request body size limits configured (FastAPI `max_upload_size`, Starlette middleware, nginx `client_max_body_size`)
- Content-Type strictly enforced (reject mismatched payloads)
- Pagination params `limit`/`offset`/`page_size` bounded with hard max

**POST / Mutation API Exploitation (OWASP API Top 10)**
- **Mass assignment (API6):** Pydantic/ORM models accept arbitrary fields from request body and persist them — e.g., `User(**request.json())` lets an attacker set `is_admin=True`. Use explicit allowlist schemas (separate `UserCreateIn` without privileged fields from `UserDB`).
- **BOLA / IDOR (API1):** endpoint looks up object by ID from path/query but never checks that the authenticated user owns or may access that object. Every `get_item_by_id` must be paired with an authorization check.
- **BFLA (API5):** admin endpoints distinguished only by URL prefix, not by role check — e.g., `/admin/*` served by same router without `Depends(require_admin)`.
- **Excessive data exposure (API3):** response models return full DB rows including password hashes, internal flags, soft-delete markers. Use explicit `*Out` response models.
- **Lack of resources & rate limiting (API4):** no per-user/per-IP rate limit, no query complexity limit (for GraphQL), no timeout
- **Insecure direct method invocation:** `getattr(obj, request_param)` or dispatch dicts keyed by user input — remote code / method execution
- **Unsafe redirects / open redirect:** `return RedirectResponse(request.query_params["next"])` without allowlist
- **File upload:** no MIME sniffing, no extension allowlist, no virus scan hook, no content-length cap, stored under web root, original filename preserved (path traversal)
- **Verb tampering:** same handler registered for GET and POST with different side-effect expectations

**CSRF (Cross-Site Request Forgery)**
- Cookie-based session auth without CSRF token on state-changing endpoints
- SameSite cookie attribute not set (should be `Lax` or `Strict`)
- No double-submit token or synchronizer token pattern (for Django/Flask)
- `Origin` / `Referer` header not validated on cookie-authenticated POST
- Note: pure bearer-token APIs (Authorization header) are not CSRF-exploitable unless also accepting cookie auth

**CORS Policy**
- `allow_origins=["*"]` combined with `allow_credentials=True` (spec-violating, many browsers still honor it — exploitable)
- Wildcard `*` in production environments
- Origin reflected from request header without allowlist (`Access-Control-Allow-Origin: <attacker.com>`)
- `allow_methods=["*"]` and `allow_headers=["*"]` on credentialed endpoints
- No `max-age` / preflight caching strategy

**SSRF (Server-Side Request Forgery)**
- Application fetches URLs provided by user input (`httpx.get(user_url)`, webhooks, image proxies, URL previewers)
- No allowlist of permitted hosts/schemes
- No blocking of RFC-1918 / link-local / metadata IPs (169.254.169.254 — cloud metadata)
- DNS rebinding not considered (re-resolve after validation)
- Redirects followed across hosts without re-validating

**PII / Sensitive Data Handling**
- PII (names, email, phone, SSN, national IDs, addresses, DOB, health/financial data) logged in plaintext
- PII in error messages returned to clients
- PII in URL query strings (logged by proxies, stored in browser history/Referer)
- Credentials, tokens, API keys, session IDs, Authorization headers, cookies logged
- Request/response bodies logged wholesale without redaction
- PII in exception tracebacks without scrubbing
- No data-retention/TTL policy on logs containing PII
- Database errors (with column names, values) returned to client
- Stack traces exposed in HTTP 500 responses
- Verbose server headers (Server, X-Powered-By) disclose version — fingerprinting aid
- `.env.example` leaking real credential format hints

**Cryptography**
- MD4, MD5, SHA-1, RIPEMD-160 used for password hashing or security-critical integrity (collision-broken)
- Password hashing uses plaintext, MD5, SHA-1, SHA-256(no salt), or unsalted hashes — must be Argon2id (argon2-cffi) or bcrypt or scrypt
- DES, 3DES, RC4, Blowfish (≤64-bit block), or any cipher in ECB mode
- AES without authenticated mode (CBC-only without HMAC) — prefer AES-GCM, AES-CCM, ChaCha20-Poly1305
- Static / hardcoded IVs, nonces, or salts
- RSA key size < 2048 bits; ECC curve < P-256
- `random` / `random.SystemRandom` for tokens — must be `secrets`
- Self-rolled crypto (custom XOR, custom hash combining, custom MAC) — use `hmac`, `cryptography`, `nacl`
- Weak PBKDF2 iteration counts (< 600,000 for SHA-256 as of 2024 OWASP)
- JWT `HS256` signed with a short/low-entropy secret; JWT without `exp`/`nbf`; JWT `alg: none`
- Encryption keys stored alongside ciphertext or in code

**TLS / Transport**
- `verify=False` on `requests`, `httpx`, `urllib3`
- `ssl.CERT_NONE`, disabled hostname verification
- Acceptance of TLS 1.0 / 1.1 or SSLv3 — require TLS 1.2+ (prefer 1.3)
- Custom SSL context with weak cipher suites
- HTTP (not HTTPS) endpoints for auth/credential flows
- `urllib.request.urlopen` without scheme restriction

**Exception Handling (security angle)**
- Bare `except:` clauses (swallows `SystemExit`/`KeyboardInterrupt` and masks security failures)
- Raw exception text sent in HTTP responses (`detail=str(e)` exposes internals)
- `logger.exception` on auth failures that don't redact submitted credentials from locals
- Security-sensitive operations (auth, crypto, authz) that silently swallow errors

**HTTP Security Headers (web/enterprise)**
- Missing: `Strict-Transport-Security` (HSTS) with `max-age ≥ 31536000; includeSubDomains; preload`
- Missing: `Content-Security-Policy` (at minimum `default-src 'self'`)
- Missing: `X-Frame-Options: DENY` or CSP `frame-ancestors 'none'`
- Missing: `X-Content-Type-Options: nosniff`
- Missing: `Referrer-Policy: strict-origin-when-cross-origin` or stricter
- Missing: `Permissions-Policy` (formerly Feature-Policy) disabling unused capabilities
- `Server`, `X-Powered-By`, `X-AspNet-Version` headers leaking version
- No `Cache-Control: no-store` on auth / sensitive endpoints

**Rate Limiting & Brute-Force Defense**
- Auth endpoints (login, password reset, MFA, signup) without per-IP + per-account rate limit
- No exponential backoff / account lockout after N failed attempts
- No CAPTCHA or equivalent on abuse-prone endpoints
- Password reset tokens: no expiry, reusable, predictable, sent via URL query param

**Dependency Security (supply chain)**
- Dependencies version-pinned in `pyproject.toml` or lock file (`poetry.lock`, `uv.lock`, `requirements.txt` with hashes)
- `pip-audit` / `safety` / `osv-scanner` wired in CI
- No unpinned transitive deps in requirements
- Integrity hashes present for reproducible builds
- No deprecated/unmaintained packages (e.g., `paramiko` old versions, `requests` < 2.31)
- Python runtime version pinned and current (no EOL interpreters)

### Minor
- `bandit` configured in CI/CD pipeline with baseline + diff mode
- `# nosec` annotations always carry a justification comment
- Security-focused code comments explaining non-obvious decisions
- Secret scanning (gitleaks, trufflehog) in pre-commit / CI
- Pre-deployment DAST scan reference in CI
- SBOM generation (CycloneDX / SPDX) for releases
- Threat model document referenced in README or docs
- Security contact (`SECURITY.md`, `security.txt`) published

---

## LLM-Specific Checks (activate when openai / anthropic / google-generativeai / langchain / llama-index / cohere / together / mistralai / boto3 bedrock / vertexai imports are detected)

**Prompt Construction**
- System and user prompts separated; user content never injected into system role
- User content wrapped in clearly delimited blocks (e.g., `<user_input>...</user_input>` with warning) or passed as distinct message roles
- Length caps on user-supplied prompt text
- Instruction-override strings (e.g., "ignore previous instructions") detected and stripped or flagged when moderation matters

**Tool / Function Calling**
- Tool definitions restrict model capability (no generic `run_shell`, `run_sql`, `http_get(url)` without host allowlist)
- Tool outputs validated before re-injecting into model context
- Model-invoked DB queries use parameterized helpers, not raw SQL strings the model authored
- File system tools sandboxed to a specific directory

**RAG (Retrieval-Augmented Generation)**
- Retrieved documents clearly labeled as untrusted data in the prompt
- Document ingestion pipeline sanitizes zero-width / invisible / homoglyph characters
- Source provenance tracked; responses cite sources

**Output Handling**
- Model output never passed to `eval`, `exec`, SQL execute, `subprocess`, `os.system`, or `open(..., "w")` without validation
- Model-generated URLs/paths checked against allowlists before fetch/open
- Streaming responses still subject to content filtering at boundaries

**Cost / DoS**
- Per-user token and request quotas
- Max tokens / max output length set on every call
- Context window size checked before API call (reject over-budget requests early)

---

## Scoring Guide
- 10: Zero critical/important findings; modern crypto; all headers; LLM guardrails if applicable; CORS/CSRF correct; PII redacted everywhere
- 8-9: No critical findings; 1-2 minor important gaps (e.g., one missing header, one unpinned dep)
- 6-7: No critical findings; several important gaps (missing validation, unpinned deps, weak CORS in dev)
- 4-5: 1 critical finding OR many important gaps (missing CSRF, PII in logs, weak crypto)
- 1-3: Multiple critical findings (eval, SQL/Cypher/prompt injection, hardcoded secrets, broken auth, `allow_origins=["*"]` with credentials)

## Required Evidence in Findings
Each finding must include:
- **Severity** (Critical / Important / Minor)
- **Category** (one of: Injection / Auth / Authz / Crypto / PII / CORS / CSRF / SSRF / Deserialization / Secrets / Headers / Rate-Limit / Dependency / LLM / TLS / Input-Validation)
- **OWASP reference** where applicable (Top 10 2021, API Top 10 2023, LLM Top 10)
- **File and line number**
- **Attack scenario** — one sentence describing how it is exploited
- **Fix** — concrete code-level remediation
