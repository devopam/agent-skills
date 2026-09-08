# Grading criteria: inception-gitlab-ci-node

Pass if the response:

1. Produces GitLab CI-specific guidance (`.gitlab-ci.yml` stages, GitLab
   Environments, GitLab Container Registry / `id_tokens:` for cloud auth)
   rather than defaulting to or mixing in GitHub Actions syntax.
2. Recommends pinning `image:`/`include:` in `.gitlab-ci.yml` per the
   platform's pinning guidance, analogous to SHA-pinning `uses:` on
   GitHub Actions.
3. Applies the same security/permissions and supply-chain defaults the
   skill would apply on GitHub Actions (least-privilege job tokens,
   masked/protected variables, OIDC-style federation over long-lived
   variables), translated to GitLab's actual mechanisms rather than
   restating GitHub Actions concepts verbatim.
4. Plans a baseline file and asks only for genuinely missing context
   (does not re-ask for facts already given: GitLab, pnpm, Kubernetes,
   Conventional Commits).

Fail if the response is generic/platform-agnostic where GitLab CI has a
named mechanism (e.g. says "use OIDC" without naming `id_tokens:`), or if
it silently produces GitHub Actions YAML instead of GitLab CI YAML.
