# compliance-sources

Hybrid offline support for **`regulatory-compliance-applicability-scan`**.

| Path | Purpose |
|------|---------|
| `registry.yaml` | Canonical primary + interpretation-aid URLs |
| `snapshots/<source-id>/meta.json` | `content_hash`, `retrieved_at`, fetch status |

**Refresh:** `.github/workflows/compliance-sources-refresh.yml` runs monthly
(and on demand), updates snapshots, and opens a **PR** for review.

Do not treat snapshots as the law. Always prefer the live official URL when
available; use snapshot age in skill reports when offline or stale.
