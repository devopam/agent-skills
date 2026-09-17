# Release notes — agent-skills v0.16.0

**Focus:** `regulatory-compliance-applicability-scan` — Stage I geographic close-out + force/thin-pack re-checks.

## Highlights

- **Global privacy pack inventory** near-exhaustive for practical use: runnable packs where a general PDP statute exists; explicit **Not covered** / **not in force** / **verify** / **limited** gates otherwise.
- Expansion waves H–I: additional Africa, Americas, Asia, Caribbean, Pacific, European microstates, Crown dependencies (JE/GG/IM), Bermuda, Cayman, Faroe, Greenland special, etc.
- **Force re-check (pre-release):** Mauritania APD operational signals; Bahamas Act 2025 vs 2003 transition; Brunei Parts 3–9 from 1 Jan 2026; Kiribati commencement-by-notice; Congo-Brazzaville limited to CNPD law; Suriname/Gambia not covered without gazette primary; Saint Lucia commencement Orders.
- **Evals** for new packs and critical gates (unenacted bills, phased force, Niger≠Nebraska, policy≠Act).
- **Portability** unchanged: skill-local `references/` and `assets/` only.

## Boundaries (unchanged)

- Suggest applicability; **do not certify** compliance.
- Primary instruments preferred; drafts and policies are not law.
- Unlisted or gated jurisdictions remain **Not covered** until primary is locked.

## Docs

- `references/packs/README.md` — inventory  
- `research/.../16-stage-i-remaining-inventory.md` — geographic close  
- `research/.../17-force-recheck-pre-016.md` — gate re-check log  
- `SKILL.md` — coverage + not-covered rule  

## Optional follow-ups (not blocking release)

- Monorepo `compliance-sources/registry.yaml` full URL mirror  
- Article-level depth on remaining thin EU overlays  
- Monthly refresh PR triage  
