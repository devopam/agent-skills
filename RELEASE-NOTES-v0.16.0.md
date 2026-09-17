# Release notes — agent-skills v0.16.0

**Focus:** `regulatory-compliance-applicability-scan` geographic expansion close-out (Stage I) + documentation.

## Highlights

- **Global privacy pack inventory** expanded across Stages H–I: dozens of new runnable jurisdiction packs and explicit **Not covered** / **not in force** / **verify** gates where no general PDP statute exists.
- Regions covered in expansion waves include additional Africa, Americas, Asia, Caribbean, Pacific, European microstates, Crown dependencies (JE/GG/IM), Bermuda, Cayman, Faroe, and related territories.
- **Evals** added for representative new packs and critical gates (unenacted bills, phased force, jurisdiction disambiguation e.g. Niger vs Nebraska).
- **Portability** unchanged: skill-local `references/` and `assets/` only for IDE installs.
- Research trackers: `15-stage-h-more-countries.md`, `16-stage-i-remaining-inventory.md` (closed for residual geographic pass).

## Boundaries (unchanged)

- Suggest applicability; **do not certify** compliance.
- Primary legal instruments preferred; secondary sources are orientation only.
- Unlisted or gated jurisdictions remain **Not covered** until primary is locked.

## Upgrade notes

- Pull latest skill pack list from `references/packs/README.md`.
- Re-run intake for multi-jurisdiction products; newly covered codes may now yield packs instead of Not covered.

## Not in this release

- Monorepo registry full URL mirror (optional follow-up)
- Article-level depth for every thin overlay
