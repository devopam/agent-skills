# Pack: domain-fintech

**Primary orientation:** PCI DSS (Payment Card Industry Data Security Standard) and related SSC documents  
**Registry:** `pci-dss-ssc`  
**Runnable:** yes  
**Not a government privacy statute** — industry standard often contractually binding for card acceptance.

## Themes

| ID | Theme | Signals in repo | Gap orientation |
|----|--------|-----------------|----------------|
| T1 | Cardholder data environment (CDE) scope | Payment forms, gateways, vault refs | Map where PAN/track data could exist |
| T2 | Storage prohibition / minimization | Logs, analytics of card fields | Prefer tokenization; no full PAN in app logs |
| T3 | Transmission security | TLS config, API clients | Encrypt card data in transit |
| T4 | Access control & authentication | Admin UIs to payment admin | Least privilege; MFA for CDE access |
| T5 | Logging & monitoring | Audit of payment ops | Retain security logs per DSS requirements |
| T6 | Vendor / SAQ posture | README claims "PCI compliant" | **Never certify**; note SAQ/ROC is external |
| T7 | Key management | Secrets for payment keys | HSM/KMS orientation only |

## Rules

- **Suggest applicability only — do not claim PCI DSS validation or "compliant".**  
- Prefer primary SSC docs over blogs.  
- Pair with jurisdictional privacy packs when personal data of payers is processed.
