# Security (React)

## Critical
- `dangerouslySetInnerHTML` / `innerHTML` with unsanitized user HTML (XSS).
- Open redirects from user-controlled URLs.
- Storing tokens in `localStorage` when XSS would yield them — prefer httpOnly cookies where architecture allows.
- Sensitive data in client bundles (private API keys).

## Important
- Missing CSRF strategy when cookie-based session + browser mutations.
- Over-exposing internal IDs/PII in client state or URLs.
- Dependency XSS in markdown/HTML renderers without sanitization.

## Minor
- Verbose client error overlays left enabled in production builds.
