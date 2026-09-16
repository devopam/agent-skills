# Pack: privacy-uk (United Kingdom)

**Not** an EU/EEA overlay — standalone UK regime post-Brexit.  
**Primaries:**

| Instrument | Official |
|------------|----------|
| **UK GDPR** | Retained/assimilated Regulation (EU) 2016/679 as amended in UK law — https://www.legislation.gov.uk/eur/2016/679 |
| **Data Protection Act 2018** | https://www.legislation.gov.uk/ukpga/2018/12 |

**Registry:** `uk-gdpr`, `uk-dpa-2018`  
**Runnable:** yes  
**ICO guidance:** interpretation aid only (not primary law)

## When to suggest

UK establishment; UK residents as data subjects; “UK GDPR” / DPA 2018 / ICO;
.uk product; transfers involving UK.

Do **not** pair with `privacy-eu` as if the UK were still an EU member state.
If the project also serves the EU/EEA, run **both** `privacy-eu` (± member
overlay) **and** `privacy-uk` as separate packs.

## Obligation themes

Verify article/section numbers on **current** legislation.gov.uk revised texts.
UK statute and UK GDPR diverge from EU GDPR over time — never assume identity.

### T1 — Scope and application

| | |
|--|--|
| **Primary** | UK GDPR Arts. 2–3 area; DPA 2018 Part 1 overview |
| **Signals** | UK entity, UK users, UK hosting |
| **Gaps** | UK user base with only “EU GDPR” policy and no UK narrative |

### T2 — Lawfulness of processing

| | |
|--|--|
| **Primary** | UK GDPR Art. 6 (and Art. 9 where special category) |
| **Signals** | Lawful-basis statements in privacy notice |
| **Gaps** | No lawful basis documented |

### T3 — Transparency / privacy notices

| | |
|--|--|
| **Primary** | UK GDPR Arts. 12–14 |
| **Signals** | Privacy policy; controller identity; purposes |
| **Gaps** | Collection without accessible notice |

### T4 — Data subject rights

| | |
|--|--|
| **Primary** | UK GDPR Chapter III (access, rectification, erasure, restriction, portability, objection) |
| **Signals** | SAR / rights request channels |
| **Gaps** | Consumer accounts with no request path |

### T5 — Controller / processor duties

| | |
|--|--|
| **Primary** | UK GDPR Arts. 24–28, 32 |
| **Signals** | Security docs; processor contracts |
| **Gaps** | Processors with no Art. 28-style terms story |

### T6 — International transfers

| | |
|--|--|
| **Primary** | UK GDPR Chapter V (as amended in UK) |
| **Signals** | Overseas hosting; transfer tools named in policy |
| **Gaps** | UK personal data sent abroad with no transfer mechanism story |
| **Note** | UK adequacy / transfer rules differ from EU — cite **UK** text only |

### T7 — DPA 2018 national provisions

| | |
|--|--|
| **Primary** | DPA 2018 Parts that supplement UK GDPR (exemptions, enforcement framework, etc.) — verify revised Act |
| **Signals** | Explicit DPA 2018 cites; ICO registration claims |
| **Gaps** | Only assess with evidence; do not invent exemption lists |

### T8 — Law enforcement / intelligence regimes (gate)

| | |
|--|--|
| **Primary** | DPA 2018 Parts 3–4 (law enforcement / intelligence) |
| **Signals** | Competent-authority processing |
| **Gaps** | **Not assessed** for ordinary commercial SaaS unless evidence shows LE processing |

### T9 — ICO / enforcement orientation

| | |
|--|--|
| **Use** | Supervisory authority orientation only |
| **Rule** | No “ICO always requires X” without primary statute/UK GDPR cite |

## Out of scope alone

PECR/ePrivacy marketing rules, sector regulators, forthcoming Data (Use and
Access) style reforms until reflected in primary text and this pack is updated.

## Report rule

Disclaimer required. Cite UK GDPR Art. / DPA 2018 s. from legislation.gov.uk.
Never claim “UK GDPR compliant” or “ICO certified.”
