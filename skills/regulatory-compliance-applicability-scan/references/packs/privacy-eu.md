# Pack: privacy-eu (GDPR)

**Primary:** Regulation (EU) 2016/679  
**Registry id:** `eu-gdpr-2016-679`  
**Official entry:** EUR-Lex CELEX `32016R0679`  
**Snapshot:** see `compliance-sources/snapshots/eu-gdpr-2016-679/` after refresh

This card is an orientation structure for agents. Verify wording against the
official text before reliance.

## When to suggest this pack

- Users or customers in EU/EEA, or establishment in EU/EEA
- Offering goods/services to individuals in EU/EEA or monitoring behaviour
- Repo signals: “GDPR”, EU regions, EU legal entity

## Obligation themes (v0)

| Theme | Primary anchors (indicative) | Repo signals |
|-------|------------------------------|--------------|
| Scope & roles | Arts. 1–4; Art. 24/28 (controller/processor) | Privacy policy role language; DPA templates |
| Territorial / material scope | Arts. 2–3 | Markets; establishment; monitoring features |
| Lawful basis & transparency | Arts. 5–6; 12–14 | Notices; consent UX; policy | 
| Data subject rights | Arts. 15–22 | Export/delete flows; support runbooks |
| Processors & subprocessors | Art. 28; Art. 32 (security) | Vendor list; DPA; SDK inventory |
| International transfers | Arts. 44–49 | Cross-border hosting; SCCs mentions |
| Security of processing | Art. 32 | Encryption, access control docs (high level) |
| Personal data breaches | Arts. 33–34 | Incident runbook |
| Accountability records | Arts. 5(2), 30 | ROPA-like docs; retention schedule |

## Typical Critical / Important gaps

- Processing personal data with **no** privacy notice or lawful-basis story
- No path for access/erasure when the product clearly holds accounts
- Unlisted subprocessors / analytics SDKs with no processor terms story
- Transfers implied by US-only hosting with no transfer mechanism mentioned

## Not assessed (unless evidence)

- DPIA necessity deep-dive, LIA, children’s age-gate product design details
- National member-state derogations
