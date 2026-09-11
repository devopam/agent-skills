# Remediation feature and roadmap

## Remediation suggestions (phased)

Every audit ends with **Remediation** ordered by severity (same order as findings).

### v0 (ship with web pack)

For each Important/Critical finding:

- **What** — one-line problem
- **Why it matters** — consistency / a11y / maintenance
- **Suggested direction** — concrete but non-prescriptive (e.g. “Route buttons through `components/ui/button`; deprecate local `PrimaryButton` copies”)
- **Evidence pointer** — files already cited

Do **not** auto-apply large refactors.

### v1+ (after packs stabilize)

- Optional **improvement themes**: token migration, icon consolidation, breakpoint cleanup
- Short **playbooks** per pack (e.g. “Introduce CSS variable scale”, “Unify on MaterialTheme M3”)
- Link to baseline fields so re-audit measures progress

User request: add deeper suggestions **after** key aspects are covered — matches this phase split.

## Full roadmap

| Phase | Deliverable |
|-------|-------------|
| **R0** | Research baselines (this folder) |
| **v0** | Skill router + web pack + responsive domain + scorecard + v0 remediation + baseline template + evals (web fixtures) |
| **v0.1** | Harden web pack from first real audits; expand evals |
| **v1** | **Apple / SwiftUI** pack (+ iPad form factors) |
| **v1.1** | **Android / Compose** pack (+ tablet / WindowSizeClass) |
| **v2** | Deeper remediation playbooks; optional Flutter/RN packs if demand |
| **v2+** | Optional browser-assisted checks (if tools available); Figma export optional input |

## Versioning note

Repo semver: new skill = minor; new platform pack = minor; remediation playbook depth = minor; breaking scorecard meaning = major.
