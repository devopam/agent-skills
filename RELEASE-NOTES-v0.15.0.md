# Release v0.15.0 — publish checklist

**Tag:** `v0.15.0`  
**Target:** `main` @ commit with plugin 0.15.0 + regulatory skill  
**Suggested title:** `0.15.0 — regulatory-compliance-applicability-scan`

## Body (copy into GitHub → Releases → Draft a new release)

```markdown
## Highlights

- **`regulatory-compliance-applicability-scan`** — global privacy/domain applicability scan
  - Stages A–F: EU-27+EEA, UK, US states, LatAm, Asia-Pacific, ME/Africa, CH/UA, DIFC/ADGM
  - Domain packs: fintech (PCI orientation), healthcare (HIPAA gate)
  - Hybrid `compliance-sources` registry + monthly refresh (retries/backoff)
  - Evals: not-covered, overlays, commencement/localization gates, no-certify
- Stage G baseline hardening (coverage matrix in SKILL.md)

## Plugin

Version **0.15.0** in `.claude-plugin/plugin.json`.

```bash
claude plugin validate .
# tag: v0.15.0
```

## Not legal advice

This skill suggests applicability against primary sources; it does not certify compliance.
```

## How to publish (one-time)

1. Open https://github.com/devopam/agent-skills/releases/new  
2. Tag: **v0.15.0** (create new tag on `main`)  
3. Paste title + body above  
4. Publish release  

*(Available GitHub connector tools can read releases but cannot create them.)*
