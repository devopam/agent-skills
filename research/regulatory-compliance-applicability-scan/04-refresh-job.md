# Monthly source refresh job

## Goals

- Detect changes at official primary URLs (and optional watch URLs)
- Update `last_checked` / `content_hash` under `compliance-sources/snapshots/`
- **Open a PR** for human review — never silent-merge legal-source changes
- Scale by registry only (new sources = new YAML rows)

## Workflow

- File: `.github/workflows/compliance-sources-refresh.yml`
- Schedule: monthly + `workflow_dispatch`
- Script: `scripts/compliance-sources/refresh.py`

## Algorithm

1. Load `compliance-sources/registry.yaml`
2. For each source with `check_frequency` in {monthly, weekly}:
   - GET `primary_url` (and `watch_urls` if any)
   - Normalize body where practical; SHA-256 hash
   - Compare to existing `meta.json`
3. Write updated meta; collect changed / failed / unchanged
4. Create PR with summary table

## Maintainer follow-up on “changed”

- Page redesign only → accept hash update
- Substantive legal change → update obligation cards + evals + CHANGELOG note
