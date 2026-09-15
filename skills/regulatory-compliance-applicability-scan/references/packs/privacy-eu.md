# Pack: privacy-eu (GDPR — union baseline)

**Primary:** Regulation (EU) 2016/679  
**Registry id:** `eu-gdpr-2016-679`  
**Official:** EUR-Lex CELEX `32016R0679`

## Scope

| In | Out |
|----|-----|
| GDPR obligations common across EU/EEA | Member-state derogations and national statutes |
| | ePrivacy/cookie national regimes (unless separate overlay) |
| | UK (use future `privacy-uk`) |

For DE/FR/IT (etc.) nuance, use **`privacy-eu-*` overlays** when available;
otherwise report **Not covered** for national-specific requirements.
See research doc `08-eu-member-state-variations.md`.

## When to suggest

EU/EEA users, establishment, or monitoring; README “GDPR”; EU legal entity.

## Obligation themes (v0)

| Theme | Primary anchors | Repo signals |
|-------|-----------------|--------------|
| Scope & roles | Arts. 1–4; 24; 28 | Policy role language; DPAs |
| Territorial / material scope | Arts. 2–3 | Markets; establishment |
| Lawful basis & transparency | Arts. 5–6; 12–14 | Notices; consent UX |
| Special categories | Art. 9 | Health/biometric flags |
| Child consent age | Art. 8 | **Flag national age** — detail in overlays |
| Data subject rights | Arts. 15–22 | Export/delete flows |
| Processors | Art. 28 | Vendor/SDK list |
| Transfers | Arts. 44–49 | Cross-border hosting; SCCs |
| Security | Art. 32 | High-level security docs |
| Breaches | Arts. 33–34 | Incident runbook |
| Accountability | Arts. 5(2), 30 | ROPA-like docs; retention |

## Typical gaps

- Personal data processing with no notice/lawful-basis story  
- No access/erasure path for account holders  
- Analytics SDKs with no processor story  
- Transfers with no mechanism mentioned  

## Not assessed here

National employment/health laws, cookie-banner legality under national ePrivacy,
member-state DPO thresholds — **overlays or Not covered**.
