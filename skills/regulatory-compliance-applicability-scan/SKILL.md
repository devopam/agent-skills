---
name: regulatory-compliance-applicability-scan
description: Maps researched privacy and domain packs (EU/EEA/UK, Americas, Asia-Pacific, ME/Africa, CH/UA/free zones; fintech/healthcare) to repo evidence. Declines missing packs. Suggests applicability gaps only—not legal advice or certification.
---

# Regulatory compliance applicability scan

**Inventory (authoritative):** [references/packs/README.md](references/packs/README.md)  
**Sources registry:** [compliance-sources/registry.yaml](../../../compliance-sources/registry.yaml)  
**Roadmap:** [research/.../12-global-coverage-roadmap.md](../../../research/regulatory-compliance-applicability-scan/12-global-coverage-roadmap.md)

## Coverage matrix (summary)

| Region | Runnable |
|--------|----------|
| EU + EEA | `privacy-eu` + all `privacy-eu-{cc}` overlays |
| UK | `privacy-uk` (standalone; not an EU overlay) |
| CH / UA | `privacy-ch`, `privacy-ua` |
| US | `privacy-us` (CA) + listed state packs |
| Americas other | `privacy-ca|br|mx|ar|cl|co` |
| Asia-Pacific | `privacy-in|cn|kr|jp|tw|hk|my|th|id|ph|vn|sg|nz|au|ru` |
| ME / Africa | `privacy-ae|sa|il|tr|eg|za|ng|ke` |
| Free zones | `privacy-difc`, `privacy-adgm` (≠ federal UAE) |
| Domains | `domain-fintech`, `domain-healthcare-pharma` |

**Anything not listed → Not covered.** State that clearly; do not invent a pack.

## Intake (one question at a time)

1. Jurisdictions / markets (or infer from repo; confirm)  
2. Roles (controller / processor / both)  
3. Data types (personal, sensitive/SPI, payment, health)  
4. For EU: member state(s) for overlays  
5. Domains: payments card data? PHI/health?

## Phases

0 **Intake** → 1 **Evidence** (repo signals only) → 2 **Obligation map** (pack themes → primary cites → gaps/unknowns) → 3 **Report** (table + severity-ordered observations; disclaimer) → 4 **Optional baseline** file for drift.

## Report rules

- Always: *Not legal advice; suggest applicability, do not certify compliance.*  
- Cite primary instruments from the pack/registry; authentic language prevails.  
- Prefer **unknown / verify live** over invented article numbers or fine schedules.  
- Honour pack **gates** (commencement, localization verify, s.33 not in force, free zone ≠ federal).  
- EU + UK → run both regimes when both markets apply.  
- Colombia → `privacy-co`, never Colorado for Bogotá users.

## Boundaries

No compliant/certified/PCI-DSS-validated claims. No how-to for evasion. Historical or secondary commentary is interpretation aid only.
