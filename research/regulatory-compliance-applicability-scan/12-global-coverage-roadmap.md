# Global coverage roadmap (stage by stage)

**Principle:** Each stage ends when packs are **runnable** (card + registry +
inventory row) with at least orientation themes; deepen later without blocking
the next stage. **Not covered** remains the rule for anything not listed.

**0.15.0** still deferred until stages feel coherent (depth + evals + refresh).

---

## Done

| Stage | Scope | Status |
|-------|--------|--------|
| **A** | GDPR + EU-27 + EEA (NO/IS/LI) overlays | **Complete** |
| **B** | United Kingdom (`privacy-uk`) | **Complete** (this commit) |
| **C0** | First-wave non-EU already shipped | IN, CN, KR, JP, SG, AE, SA, AU, RU, CA, BR; US CA/VA/CO/CT/UT/TX; domains |

---

## Remaining stages (follow in order)

### Stage C — Asia depth & neighbours

| Order | Pack target | Notes |
|------:|-------------|--------|
| C1 | Deepen `privacy-kr`, `privacy-jp`, `privacy-ru` | Already runnable; raise to deep |
| C2 | `privacy-tw` | Taiwan PDPA |
| C3 | `privacy-hk` | PDPO |
| C4 | `privacy-my` | Malaysia PDPA |
| C5 | `privacy-th` | PDPA Thailand |
| C6 | `privacy-id` | Indonesia PDP Law |
| C7 | `privacy-ph` | Philippines DPA |
| C8 | `privacy-vn` | Vietnam PDPD / decrees |
| C9 | `privacy-nz` | Privacy Act 2020 |

### Stage D — Americas expansion

| Order | Pack target | Notes |
|------:|-------------|--------|
| D1 | More US states (OR, MT, DE, IA, IN, TN, …) | Only states with comprehensive consumer privacy acts |
| D2 | `privacy-mx` | Mexico LFPDPPP / reforms |
| D3 | `privacy-ar` | Argentina PDPA |
| D4 | `privacy-cl` | Chile |
| D5 | `privacy-co-co` | Colombia (name TBD vs US-CO) |
| D6 | Canada provincial deep (QC Law 25, etc.) | Optional overlays on PIPEDA |

### Stage E — Middle East & Africa

| Order | Pack target | Notes |
|------:|-------------|--------|
| E1 | Deepen `privacy-ae`, `privacy-sa` | Free-zone packs separate if needed (DIFC/ADGM) |
| E2 | `privacy-il` | Israel Privacy Protection Law |
| E3 | `privacy-tr` | Turkey KVKK |
| E4 | `privacy-za` | South Africa POPIA |
| E5 | `privacy-ng` | Nigeria NDPR / Acts |
| E6 | `privacy-ke` | Kenya DPA |
| E7 | `privacy-eg` | Egypt PDPL |

### Stage F — Other Europe & special regimes

| Order | Pack target | Notes |
|------:|-------------|--------|
| F1 | `privacy-ch` | Switzerland FADP |
| F2 | `privacy-ua` | Ukraine |
| F3 | `privacy-rs` / Balkans as demand warrants | |
| F4 | DIFC / ADGM / other free zones | Explicitly not federal AE |

### Stage G — Hardening (parallel, any time)

1. Lock registry `primary_url` to act-level pages (reduce portal roots)  
2. Evals per major pack  
3. Monthly refresh dry-run + fetch_error remediation  
4. Cut **0.15.0** when Stages A–B + C1 + G baseline are solid  

---

## Stage exit criteria

- Pack file under `references/packs/`  
- Row in packs `README.md`  
- Registry source(s)  
- Not-covered rule still holds for unlisted places  
- No certification language in cards  

## Working agreement

We proceed **one stage (or one ordered row) at a time** unless you ask to batch.
Next recommended: **C1** (deepen KR/JP/RU) or **C2** (Taiwan) — your call after UK.
