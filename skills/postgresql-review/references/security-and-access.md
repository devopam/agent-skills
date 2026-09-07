# Security & access

## Intent

Least privilege, RLS posture, sensitive columns, connection encryption signals.
Not full host CIS or network design.

## MCPg tools

`list_roles`, `list_grants`, `list_policies`, `test_rls_for_role`,
`find_sensitive_columns`, `verify_connection_encryption`.

## What to look for

- Over-broad grants (PUBLIC, superuser-like app roles)
- Multi-tenant / sensitive tables without RLS, or RLS without FORCE where owners bypass
- Policies missing WITH CHECK on writes (when policies exist)
- Sensitive column names/heuristics without compensating controls noted
- App roles with BYPASSRLS
- Test as the real app role via `test_rls_for_role` when investigating RLS

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Tight grants; RLS coherent where required |
| 7–8 | Minor grant hygiene issues |
| 5–6 | Missing RLS on tenant data or noisy sensitive columns |
| 1–4 | Open grants on sensitive data or RLS bypass footguns on app roles |

## Sources

RLS footgun writeups; MCPg security tools — research 2026-09-07.
