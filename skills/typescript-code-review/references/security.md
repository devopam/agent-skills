# Security (TypeScript)

Mindset: OWASP Top 10 / API Top 10. Runtime-specific HTTP hardening may be deeper in `nodejs-code-review`; XSS/DOM in `react-code-review`.

## Critical
- `eval`, `new Function`, dynamic `child_process` with user input.
- Hardcoded secrets (API keys, private keys) in source.
- SQL/NoSQL/command string concatenation with untrusted input.
- `dangerouslySetInnerHTML`-style sinks without sanitization (if TSX present).

## Important
- Prototype pollution risks (`Object.assign` on untrusted objects, unsafe merge).
- JWT/session handling flaws; insecure cookie flags (when applicable).
- Path traversal in filesystem APIs.
- SSRF via user-controlled URLs in server code.
- Missing authorization checks on sensitive operations.

## Minor
- Verbose error messages leaking internals to clients.
