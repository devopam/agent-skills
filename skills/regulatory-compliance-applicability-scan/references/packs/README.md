# Packs

A pack is **runnable** only when this folder has an obligation card **and**
`compliance-sources/registry.yaml` lists primary sources for it.

| Pack | Runnable |
|------|----------|
| `privacy-eu` | Yes (GDPR baseline) |
| `privacy-in` | Partial (commencement caveat) |
| `privacy-eu-de/fr/it` | Not until national primary + cards |
| Americas / ME / domains | Not until cards authored |

Unlisted country or domain → skill says **Not covered**.
