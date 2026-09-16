# Stage G — Hardening checklist

**Status:** In progress / baseline complete for 0.15.0 cut  
**Date:** 2026-09-16

## Done in this wave

- [x] SKILL.md coverage matrix aligned to full A–F inventory  
- [x] Packs README as inclusion list  
- [x] Roadmap Stages A–F marked complete  
- [x] Core evals (disclaimer, not-covered, overlays, gates, domains)  
- [x] Refresh script with retries / backoff / timeouts  
- [x] Registry entries for major packs (61+ sources)

## Remaining (post-0.15.0 OK)

- [ ] Lock more EU overlay `primary_url` values from portal roots to act-level pages  
- [ ] Add registry rows for all Stage E–F packs not yet in YAML  
- [ ] Monthly Actions dry-run on full registry; triage fetch_error  
- [ ] Per-pack deep article anchors for orientation-only cards  
- [ ] Optional US residual states (FL, VT, …)

## Portal-root note

Many EU national registry rows still point at legislation **portals** (acceptable for orientation; refresh may hash unstable homepage HTML). Prefer act-level URLs when hardening URLs one-time.
