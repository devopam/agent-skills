# CI/CD Anti-Patterns

Recurring failure modes to flag during audits. Cross-cutting; details live
in the domain files.

| Anti-pattern | Domain | Severity guide |
|---|---|---|
| Unsafe `pull_request_target` executing PR code with secrets | Security | Critical |
| Workflow-level write-all permissions | Security | Critical / Important |
| Mutable action tags (`@v4`) on release workflows | Supply chain | Important |
| `npm install` / unpinned installs for release builds | Supply chain | Important |
| Rebuild on every environment | Artifacts | Important |
| Prod deploy from feature branch | Structure | Critical |
| No PR tests; all tests after merge only | Structure / Testing | Important |
| Required checks not enforced in branch protection | Testing | Important |
| Infinite retry on flaky tests | Testing / Speed | Minor–Important |
| Missing changelog on published libraries | Release docs | Important |
| Claimed progressive delivery without gates | Progressive delivery | Minor–Important |
| Secrets in logs / echo debug left on | Security | Critical |
| Shared writable caches across trust boundaries | Security / Speed | Important |
| CI so slow that people push with `[skip ci]` habitually | Speed | Important |
| Single personal PAT for all automation | Security | Important |

When reporting, prefer a concrete file/job reference and a fix path over
naming the anti-pattern alone.
