# Pack: domain-healthcare-pharma

**Type:** Domain overlay  
**US primary:** 45 CFR Part 164 (HIPAA Privacy/Security/Breach) — https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164  
**Registry id:** `us-hipaa-45-cfr-164`  
**Runnable:** yes **only when** US PHI + covered entity / business associate signals justify HIPAA themes

## Scope

| In | Out |
|----|-----|
| HIPAA orientation when CE/BA + PHI evidence | Treating every wellness app as HIPAA |
| GDPR Art. 9 cross-ref via privacy-eu when EU health data | National EU health laws without overlays |
| | India/ME health sector statutes until packed |

## Themes (US HIPAA gate)

| Theme | Primary orientation | Signals |
|-------|---------------------|---------|
| Applicability | CE/BA definitions | “HIPAA,” BAAs, covered entity language |
| Privacy uses/disclosures | 45 CFR 164 Subpart E | Auth forms; TPO |
| Security (ePHI) | Subpart C | Security rule policies |
| Breach | Subpart D | Breach runbook |
| BA agreements | Organizational requirements | Signed BAA templates |

If signals weak → state HIPAA **uncertain / out** and fall back to regional privacy only.
