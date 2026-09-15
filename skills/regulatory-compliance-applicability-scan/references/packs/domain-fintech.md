# Pack: domain-fintech

**Type:** Domain overlay — pair with regional privacy packs  
**Primary (payments security):** PCI DSS — https://www.pcisecuritystandards.org/standards/  
**Registry id:** `pci-dss-ssc`  
**Runnable:** yes for **card-data security orientation** only

## Scope

| In | Out |
|----|-----|
| Whether cardholder data appears in scope; high-level PCI themes; processor inventory | Claiming PCI certified |
| | RBI / PSD2 / GLBA deep packs until separately authored |

## Themes

| Theme | Orientation | Signals |
|-------|-------------|---------|
| CHD in environment | Store/process/transmit account data? | Stripe elements; card forms; PAN in logs |
| Minimize SAD/PAN | No SAD in logs/analytics | Logging config; debug dumps |
| Providers | Gateways as processors/service providers | Stripe/Adyen; KYC vendors |
| Policy alignment | Privacy packs still required for personal data | Always pair |

## Remediation style

Point at SAQ/ROC awareness and architecture patterns — **not** “you are PCI compliant.”
