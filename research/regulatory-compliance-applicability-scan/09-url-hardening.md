# URL hardening (one-time process)

**Date:** 2026-09-15  
**Goal:** Make `compliance-sources/registry.yaml` resilient to portal flakiness
and prefer official entry points.

## Process (repeat when adding packs)

1. Prefer **official** publisher (legislature, EUR-Lex, law.go.kr, SSO, etc.)
2. Add `watch_urls` for consolidations / English aids (never sole authority)
3. Note language authority in `notes`
4. Run `scripts/compliance-sources/refresh.py` (3 retries, 20s timeout)
5. On persistent `fetch_error`: try alternate official path; document in notes
6. Do not delete a source solely because of transient fetch failure

## Known flaky classes

| Class | Mitigation |
|-------|------------|
| Legifrance / some EU national portals | Alternate consolidé IDs; retries |
| MeitY landing pages | Prefer India Code / Gazette PDF when locked |
| pravo.gov.ru | watch consolidator; prefer state publication when stable |
| NPC China | Chinese URL primary; EN watch only |
| PCI SSC | Library may require interaction — hash portal page |

## Script supports

Retries 3×, backoff 2/5/10s, 20s timeout, 2MB body sample, `attempts` in meta.
