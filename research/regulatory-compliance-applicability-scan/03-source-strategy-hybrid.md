# Hybrid source strategy

## Layers

1. **`compliance-sources/registry.yaml`** — official URLs, citation form,
   jurisdiction, pack id, check frequency
2. **Obligation cards** (under skill `references/packs/`) — stable themes →
   article refs → repo signals → typical gaps
3. **Snapshots** (`compliance-sources/snapshots/<id>/meta.json`) —
   `retrieved_at`, `content_hash`, `primary_url`, fetch status
4. **Secondary sources** — regulator guidance (EDPB, ICO, MeitY FAQs); marked
   `role: interpretation_aid` only

## Runtime preference

1. If network available: fetch `primary_url` (or use snapshot if fetch fails)
2. Always show **citation + URL + snapshot age** when offline or stale
3. Obligation cards drive structure; live/snapshot text supports verification

## What not to store

- Full commercial reproductions of annotated codes without clear license path
- Blog posts as primary authority

Optional short excerpts in snapshots only when needed for offline evals;
prefer hash + URL.
