# Security (Node.js)

## Critical
- Injection (SQL, NoSQL, command, LDAP) via string concat.
- Hardcoded secrets; private keys in repo.
- `eval` / `vm.runInNewContext` with user input.
- Path traversal (`fs` + user paths without containment).
- Authentication bypass; missing authz on mutations.
- Insecure deserialization.

## Important
- Helmet/security headers missing on public HTTP servers (web+).
- Cookie `Secure`/`HttpOnly`/`SameSite` misconfiguration.
- CSRF on cookie-session browser APIs.
- SSRF on user-supplied URLs.
- Overly permissive CORS (`*`) with credentials.
- Prototype pollution via merge of JSON bodies.
- Rate limiting absent on auth and expensive endpoints (enterprise).

## Minor
- Stack traces returned to clients in production.
