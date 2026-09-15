# Packs roadmap

See [07-coverage-matrix.md](07-coverage-matrix.md) and
[08-eu-member-state-variations.md](08-eu-member-state-variations.md).

## Implementation order

1. **`privacy-eu`** obligation cards + evals (union GDPR only; flag national openings)
2. **`privacy-in`**
3. **EU overlays (priority):** `privacy-eu-de`, `privacy-eu-fr`, `privacy-eu-it`
4. Americas country packs → Middle East country packs
5. `domain-fintech` / `domain-healthcare-pharma`
6. Further EU member-state overlays as needed

## Domains

| Pack | Priority |
|------|----------|
| `domain-healthcare-pharma` | 1 |
| `domain-fintech` | 1 |

## Privacy packs

| Pack | Notes |
|------|--------|
| `privacy-eu` | GDPR baseline — **no** fake national rules |
| `privacy-eu-de/fr/it` | Member-state overlays — primary national statutes |
| `privacy-in` | DPDP + commencement awareness |
| `privacy-us/ca/br` | Americas |
| `privacy-ae/sa` | Middle East |
| `privacy-uk` | Later (not an EU overlay) |
