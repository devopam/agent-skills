# EU member-state variations

**Snapshot:** 2026-09-15  
**Decision:** `privacy-eu` covers **Regulation (EU) 2016/679** as the common
baseline. **Member-state-specific nuance is out of scope for the baseline
pack** and must be handled as **explicit national overlay packs** (or marked
**Not covered**).

## Why this split

GDPR is directly applicable but leaves **openings and related regimes** that
differ by country, for example:

- Article 9(4) and other openings for **national** rules on special categories
- Employment, research, journalism, and other **member-state** provisions
- **Age of consent** for information-society services (Art. 8 — national choice)
- **ePrivacy / national cookie and electronic-comms** rules (related, not the
  GDPR text itself)
- **DPA practice**, registration/DPO thresholds where national law still matters
- Sector laws (health, finance) at national level

Treating “EU” as a single homogeneous checklist **hides real obligations** and
encourages invented “typical German rules.”

## Model

```
privacy-eu          → GDPR union baseline (always first if EU/EEA in scope)
privacy-eu-de       → Germany overlay (BDSG + relevant national sources)
privacy-eu-fr       → France overlay (Loi Informatique et Libertés / CNIL-facing law)
privacy-eu-it       → Italy overlay (Codice privacy as amended / Garante context)
…                   → further member states as researched
```

### Runtime rules

1. If user selects Europe / EU / EEA → suggest **`privacy-eu`**.
2. If user (or repo) indicates a **specific member state** (establishment,
   hiring, .de/.fr domain, national DPA language):
   - If overlay pack exists → suggest **baseline + overlay**
   - If not → state **Not covered for [country] national variations**; still
     offer GDPR baseline only, and list which overlays exist
3. **Never** invent BDSG/CNIL-only duties from memory without a card + registry
   primary source.
4. Report section: **Union baseline findings** vs **National overlay findings**
   (separate tables).

## Priority overlays (after privacy-eu cards)

| Pack id | Country | Primary orientation (research targets) |
|---------|---------|----------------------------------------|
| `privacy-eu-de` | Germany | BDSG (Bundesdatenschutzgesetz) official text + GDPR |
| `privacy-eu-fr` | France | French data-protection statute as in force + GDPR |
| `privacy-eu-it` | Italy | Italian privacy code as amended + GDPR |

Further EEA states (NL, ES, SE, PL, …) follow the same pattern when primary
sources are locked in `compliance-sources/registry.yaml`.

## Related but separate

| Topic | Handling |
|-------|----------|
| UK | **`privacy-uk`** — not an EU member-state overlay |
| Switzerland | **Not covered** until researched (not EU GDPR pack) |
| ePrivacy Directive / national cookie laws | Optional future `privacy-eu-eprivacy-*` or country overlay sections — **not** silently folded into GDPR baseline |
| Binding Corporate Rules, adequacy decisions | Theme under GDPR transfers (Arts. 44–49); country nuance only if overlay documents it |

## Eval requirements

- Request “Germany-specific employment data rules” without `privacy-eu-de` →
  **Not covered** for that nuance; may still run `privacy-eu`
- Must not emit fake “BDSG §…” cites when overlay absent
