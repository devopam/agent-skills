# Monthly source refresh job

## Goals

- Detect changes at official primary URLs
- Update snapshots; open a **PR** (never silent-merge legal sources)
- Survive flaky government portals via **timed retries**

## Retry policy (script)

| Parameter | Value |
|-----------|--------|
| Max attempts | 3 |
| Backoff | 2s, 5s, 10s between attempts |
| Per-request timeout | 20s |
| Max body | 2 MB (hash sample) |

`fetch_error` after retries still writes meta (keeps previous hash) and is
reported in the PR table — maintainers may swap `primary_url` or re-run.

## Workflow

`.github/workflows/compliance-sources-refresh.yml` — monthly + `workflow_dispatch`.
