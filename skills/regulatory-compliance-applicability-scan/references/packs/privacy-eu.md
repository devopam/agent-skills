# Pack: privacy-eu (GDPR — union baseline)

**Primary:** Regulation (EU) 2016/679  
**Registry id:** `eu-gdpr-2016-679`  
**Official:** https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32016R0679  
**Runnable:** yes (union baseline only)

## Scope

| In | Out |
|----|-----|
| GDPR obligations common across EU/EEA | Member-state statutes (BDSG, etc.) — use `privacy-eu-*` overlays |
| | National ePrivacy/cookie regimes |
| | UK (`privacy-uk` later) |

If the user needs country-specific nuance and the overlay is missing: **Not
covered** for that nuance; this pack may still run alone.

## When to suggest

EU/EEA customers or establishment; monitoring behaviour in EU/EEA; “GDPR” in
product/legal docs; EU legal entity.

## Obligation themes

Evidence labels: **present / partial / missing / unknown**.

### T1 — Material and territorial scope

| | |
|--|--|
| **Primary** | Arts. 2–3 |
| **Ask** | Is personal data processed? Offering goods/services to individuals in EU/EEA or monitoring? Establishment in EU/EEA? |
| **Repo signals** | Markets list, geo targeting, EU entity, privacy policy territorial claims |
| **Gap examples** | Product clearly serves EU users with no scope analysis in docs |

### T2 — Roles (controller / processor)

| | |
|--|--|
| **Primary** | Arts. 4, 24, 28 |
| **Ask** | Does the org determine purposes/means (controller) or process on behalf of a customer (processor)? |
| **Repo signals** | Privacy policy role language; customer DPA templates; “we process on your behalf” |
| **Gap examples** | SaaS holds user PII with neither controller narrative nor processor DPA story |

### T3 — Principles and lawful basis

| | |
|--|--|
| **Primary** | Arts. 5–6 |
| **Ask** | Purpose limitation, minimization, storage limitation; which Art. 6 basis for each major processing? |
| **Repo signals** | Privacy notice purposes; consent toggles; contract necessity language |
| **Gap examples** | Account signup with no lawful-basis/purpose text; open-ended retention |

### T4 — Transparency (notices)

| | |
|--|--|
| **Primary** | Arts. 12–14 |
| **Ask** | Clear notice of identity, purposes, recipients, transfers, rights, retention? |
| **Repo signals** | `privacy.md` / site policy; in-product notices |
| **Gap examples** | Collecting emails with only a marketing checkbox and no policy link |

### T5 — Special categories

| | |
|--|--|
| **Primary** | Art. 9 |
| **Ask** | Health, biometric, etc.? Art. 9 prohibition + exception path? |
| **Repo signals** | Health fields, biometrics, “sensitive data” |
| **Gap examples** | Health questionnaire with no Art. 9 story (national rules → overlay) |

### T6 — Children (Art. 8)

| | |
|--|--|
| **Primary** | Art. 8 |
| **Ask** | ISS offered directly to children? Age of consent is **national** — flag only |
| **Repo signals** | Under-16 product, parental consent UX |
| **Gap examples** | Child-directed app with no age gate; **do not invent** a specific national age without overlay |

### T7 — Data subject rights

| | |
|--|--|
| **Primary** | Arts. 15–22 |
| **Ask** | Access, rectification, erasure, restriction, portability, objection paths? |
| **Repo signals** | Account export/delete; privacy request email/runbook |
| **Gap examples** | Consumer accounts with no delete/export mechanism described or implemented |

### T8 — Processors and subprocessors

| | |
|--|--|
| **Primary** | Art. 28 (also Art. 32 security) |
| **Ask** | Written processor terms? Subprocessor visibility? |
| **Repo signals** | SDK list (analytics, email, support); vendor DPA; subprocessors page |
| **Gap examples** | Multiple tracking SDKs, no processor/subprocessor documentation |

### T9 — International transfers

| | |
|--|--|
| **Primary** | Arts. 44–49 |
| **Ask** | Personal data leaving EEA? Adequacy, SCCs, or other Art. 46 mechanism? |
| **Repo signals** | US-only hosting; “SCCs”; transfer section in policy |
| **Gap examples** | EU users + US cloud with no transfer mechanism mentioned |

### T10 — Security of processing

| | |
|--|--|
| **Primary** | Art. 32 |
| **Ask** | Appropriate technical/organisational measures (orientation, not full sec audit) |
| **Repo signals** | Security.md, encryption-at-rest claims, access control docs |
| **Gap examples** | Public app store product with zero security narrative and secrets in repo |

### T11 — Personal data breaches

| | |
|--|--|
| **Primary** | Arts. 33–34 |
| **Ask** | Detect/notify workflow to controller/DPA/subjects as applicable? |
| **Repo signals** | Incident response runbook; security contact |
| **Gap examples** | No incident process while processing account PII |

### T12 — Accountability records

| | |
|--|--|
| **Primary** | Arts. 5(2), 30 |
| **Ask** | Records of processing (or proportionate equivalent)? Retention schedule? |
| **Repo signals** | ROPA-like docs; data inventory; retention policy |
| **Gap examples** | Scaling SaaS with no processing inventory at all |

## Scoring guidance (orientation)

Not a certification score. Optional theme labels feed the report. Composite is
less important than **severity + primary cites**. Prefer **unknown** over
invented processing.

## Remediation style

What / Why / direction / **Art. X** / evidence path — no claim of compliance
after remediation.
