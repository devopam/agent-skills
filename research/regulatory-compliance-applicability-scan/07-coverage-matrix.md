# Coverage matrix (authoritative for the skill)

**Last updated:** 2026-09-15  
**Rule:** If the user asks for a **region, country nuance, or domain not listed
as available**, state **Not covered**, do **not** invent obligations, and only
offer packs that are runnable (card + registry).

## Product domains

| Domain id | Status |
|-----------|--------|
| `domain-healthcare-pharma` | Planned (priority) |
| `domain-fintech` | Planned (priority) |
| Other verticals | **Not covered** |

## Data privacy — regions

| Region | Status | Pack direction |
|--------|--------|----------------|
| Europe (union) | In progress | `privacy-eu` (GDPR only) |
| Europe (member-state nuance) | Planned overlays | `privacy-eu-de`, `privacy-eu-fr`, `privacy-eu-it`, then others — see [08-eu-member-state-variations.md](08-eu-member-state-variations.md) |
| India | Planned | `privacy-in` |
| Americas | Planned | `privacy-us`, `privacy-ca`, `privacy-br` (country packs) |
| Middle East | Planned | `privacy-ae`, `privacy-sa` |
| Japan, etc. | **Not covered** | — |

## Agent behaviour when out of coverage

> **Not covered:** No researched pack for **[X]**. I will not invent requirements.
> Available packs: **[list]**. Proceed with those, or stop?

Examples:

- Japan → not covered  
- “German employee monitoring rules” without `privacy-eu-de` → national nuance
  not covered; optional GDPR baseline only  
- “EU cookie law” without ePrivacy/national overlay → not covered as a full
  assessment (baseline may note Art. 8/consent themes only at GDPR level)
