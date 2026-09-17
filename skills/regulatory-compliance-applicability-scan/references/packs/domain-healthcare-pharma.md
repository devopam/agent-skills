# Pack: domain-healthcare-pharma

**Primary (US):** HIPAA Privacy, Security, and Breach Notification Rules — **45 CFR Part 160 and Part 164**  
**Registry:** `us-hipaa-45-cfr-164`  
**Runnable:** yes  
**Gate:** Only apply HIPAA themes when **PHI** (or clear covered-entity/business-associate signals) is in scope. No PHI → state gate and do not invent HIPAA findings.

## Themes (when PHI / CE–BA in scope)

| ID | Theme | Repo signals | Gap orientation |
|----|--------|--------------|----------------|
| T1 | PHI identification | Health records, claims, clinical notes | Inventory PHI data flows |
| T2 | Minimum necessary | Broad exports, admin dumps | Limit uses/disclosures |
| T3 | Access controls | Shared logins, open EHR APIs | Unique IDs, emergency access policies |
| T4 | Audit controls | Missing access logs | Record who accessed PHI |
| T5 | Transmission security | Unencrypted health APIs | Integrity + encryption in transit |
| T6 | BA / vendor | Third-party health processors | BAA orientation — legal, not code |
| T7 | Breach notification readiness | No incident runbooks | Process gap — not a code cert |

## Non-US healthcare

For EU health data, pair with **`privacy-eu`** (+ member overlay) and special-category rules — do not treat HIPAA as global.  
Pharma clinical-trial / GxP regimes beyond HIPAA are **out of pack** unless later expanded — mark **Not covered** if user asks only for those.

## Rules

- No "HIPAA compliant" claims.  
- Prefer eCFR text for Part 164.  
