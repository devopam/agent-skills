# Packs roadmap

## Release posture

**0.15.0 deferred** until coverage expansion is a logical win (not a partial
first-wave-only ship). Continue research → cards → evals before plugin bump.

## Current wave (runnable)

privacy-eu ± de/fr/it · privacy-in · privacy-us/ca/br · privacy-ae/sa ·
domain-fintech · domain-healthcare-pharma

## Coverage expansion (in progress)

| Pack | Research | Cards | Evals |
|------|----------|-------|-------|
| privacy-cn (PIPL) | Started | — | — |
| privacy-kr (PIPA) | Started | — | — |
| privacy-jp (APPI) | Started | — | — |
| privacy-ru (152-FZ) | Started | — | — |

Then: further EU overlays, more US states, free-zone regimes.

## Infra

Refresh script: **3 attempts**, backoff 2s/5s/10s, 20s timeout (see 04-refresh-job).
