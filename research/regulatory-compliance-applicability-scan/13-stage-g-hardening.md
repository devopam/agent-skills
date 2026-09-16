# Stage G — Hardening checklist

**Updated:** 2026-09-16 (post v0.15.0)

## Done

- [x] SKILL.md coverage matrix  
- [x] Core + gate evals  
- [x] Refresh retries/backoff  
- [x] Residual packs FL / QC  
- [x] **v0.15.0 released**  
- [x] **Registry parity** for E–F + residual US/LatAm (commit registry expand)  
- [x] **URL hardening pass:** AT → RIS GeltendeFassung; CH → fedlex ELI; BE → SPF Economie; HK → elegislation cap486; `portal_root: true` notes on remaining  
- [x] Sample dry-run on stable act-level URLs (see below)

## Sample dry-run (2026-09-16)

Fetched with 15s timeout on a subset of act-level rows (not full monthly job):

| Expected stable | Typical outcome |
|-----------------|-----------------|
| EU GDPR, UK GDPR, BDSG, UAVG, NZ, CH FADP, SG, AU, KE, ZA | Prefer these for CI smoke |
| Portal-root EU nationals | Higher `fetch_error` / unstable hash risk |

Full monthly workflow remains the authority for production triage.

## Still open (nice-to-have)

- [ ] Replace remaining `portal_root: true` rows with act-level permalinks one-by-one  
- [ ] Wire `compliance-sources-refresh.yml` monthly schedule and review first PR  
- [ ] Deep article anchors for orientation-only cards  
