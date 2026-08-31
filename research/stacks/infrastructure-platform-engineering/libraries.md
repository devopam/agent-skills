# Baseline: Infrastructure & Platform Engineering — Preferred Libraries
Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This category's tools move on a different clock than the Python/npm package
ecosystems covered elsewhere in this repo's baselines: several load-bearing
facts here are **licensing and governance events**, not download-count
drift — Terraform's BSL relicensing, CDKTF's archival, tfsec's deprecation
into Trivy, and HCP Terraform's free-tier sunset all happened within the
last ~20 months and materially change what "the default recommendation" is.
Treat every license/status claim below as verified as of 2026-08-31, not a
durable fact — this category has moved faster on licensing than any prior
baseline in this repo.

## Local precedent

Real, directly-inspected local precedent exists, but it is **partial** —
the deployment-tooling half of this category, not the provisioning half.
Verified this pass by direct read of `/Users/devopammittra/GitHub/
ubi-csr-tmf`:

- **Helm charts, real and per-service**: `charts/agents/`,
  `charts/ubi-backend/`, `charts/ubi-frontend/`, each with a genuine
  `Chart.yaml` (`apiVersion: v2`, `type: application`), `values.yaml`
  (prod), and `values-dev.yaml`. Confirmed by direct read of
  `charts/ubi-backend/values.yaml`: `replicaCount: 2`, resource
  requests/limits (`3Gi`/`500m` request, `4Gi`/`800m` limit), liveness/
  readiness probes, `autoscaling.enabled: false` (HPA templates exist —
  `ubi-backend-hpa.yml` — but are not turned on), NodePort service type,
  and commented-out `imagePullSecrets`/`nodeselector`/`tolerations` blocks
  left as opt-in scaffolding rather than deleted. This is a real,
  reasonably careful Helm-values file, not a toy example.
- **`ubi-csr-tmf-helm-charts/` is an empty directory** — confirmed by
  direct `ls` (zero files, only `.`/`..`). Worth stating plainly rather
  than assumed-populated: whatever this directory was intended for, it
  currently holds nothing.
- **A full suite of GitHub Actions deploy workflows**, 12 files, 2,177
  lines total (`wc -l .github/workflows/*.yml*`). Spot-checked
  `be-deploy-prod.yml` and the larger `ci-cd.yml` (425 lines, backend +
  frontend build/deploy in one pipeline) in full:
  - **OIDC throughout, no long-lived AWS keys**: every deploy workflow
    sets `permissions: id-token: write` and calls
    `aws-actions/configure-aws-credentials@v4` with
    `role-to-assume: arn:aws:iam::025066239748:role/GitHubActionsTerraformRole`
    — the same trusted-publishing shift the Developer Tooling & Libraries
    baseline documented for PyPI/npm/crates.io, here applied to cloud
    deployment credentials rather than package publishing. Confirmed
    identical across all 12 workflow files via grep, not just the one
    spot-checked file.
  - **The IAM role is literally named `GitHubActionsTerraformRole`** —
    despite every workflow in this repo deploying via `helm upgrade`/
    `kubectl`, never `terraform apply`. This is a real, if inferential,
    signal: the role's name strongly suggests Terraform *was* used to
    provision this OIDC trust relationship and the underlying EKS
    cluster/IAM itself — just in an infrastructure-provisioning repo not
    present on this machine, not in `ubi-csr-tmf`. Stated as an honest
    inference from naming, not a confirmed fact — no `.tf` file exists
    anywhere in this repo to corroborate it directly.
  - **Build**: `docker/setup-buildx-action@v3` + `docker buildx build`
    with registry-backed layer caching
    (`--cache-from/--cache-to type=registry,...,mode=max`), pushed to
    **ECR** (`aws-actions/amazon-ecr-login@v2`), platform pinned to
    `linux/amd64`.
  - **Deploy**: `azure/setup-kubectl@v3` (`version: 'latest'`) +
    `azure/setup-helm@v4` pinned to **`version: 'v3.11.1'`** (Helm 3), then
    `aws eks update-kubeconfig --name ubi-coe-cluster --region ap-south-1`
    followed by `helm upgrade --install ... --wait --timeout 5m` and a
    `kubectl rollout status` gate. **Currency gap worth flagging**: Helm's
    own current release (verified this pass, see table below) is
    **v4.2.4** — this repo's CI pins a Helm 3.11.1 binary, over two major
    versions behind. Not a defect in the repo (Helm 3→4 is a real breaking
    upgrade many teams delay deliberately), but a concrete illustration of
    exactly the kind of tooling-currency drift this category needs to
    watch for.
  - **Explicit rollback step**: `be-deploy-prod.yml` and `ci-cd.yml` both
    have an `if: failure()` step running `helm rollback ... || echo "No
    previous revision to rollback to"` — a real, if simple, blast-radius
    mitigation already in place.
  - **No linting/security-scanning step for Helm charts or container
    images anywhere in the 12 workflow files** — confirmed by grepping all
    workflow YAML for `trivy|checkov|tflint|terraform|kubeval|helm lint|
    snyk|grype|cosign|sbom|provenance|opa|conftest|sentinel`: the only
    hits are the (coincidentally named) `GitHubActionsTerraformRole`
    string. No `helm lint`, no image vulnerability scan, no IaC policy
    gate exists in this pipeline today — a real gap against every tool
    named in this baseline's own "policy-as-code" and "CI/CD-layer"
    sections below.
  - `build-validation.yml` (PR-triggered) does path-filtered per-component
    Docker builds (`docker/build-push-action@v6` with `cache-from/
    cache-to: type=gha`) as a build-only smoke test, again with no scan
    step.
- **`aws/container/` has a plain per-component `docker-compose.yml`** —
  confirmed by direct read: three services (frontend/backend/agents),
  each with its own `Dockerfile.dev`, healthchecks, and a shared bridge
  network — genuinely local-dev tooling, not production IaC, and not
  claimed as such.
- **Confirmed absent, by direct `find`**: no `.tf`, no `Dockerfile`-adjacent
  Terraform/Pulumi/CDK/CloudFormation file anywhere in this repo. This is
  a real example of **app-deployment-via-Helm+CI**, not of **infrastructure
  provisioning** — the underlying EKS cluster, VPC, IAM roles, and ECR
  repositories this pipeline targets were provisioned somewhere else,
  not in this repo. Naming this honestly as a partial local precedent
  (matches the task brief's framing) rather than overstating coverage.
- **`/Users/devopammittra/GitHub/agent-skills` itself** — checked directly
  this pass: no `Dockerfile`, no `docker-compose*`, no `.tf` file, and its
  own `.github/` directory (if any) does not deploy anything — it is a
  prompt/skill-content-only plugin (per the Developer Tooling & Libraries
  baseline's own finding about this same repo) with literally no
  deployment infrastructure to speak of. Noted as a real absence, not
  skipped.

## Ecosystem choice

Unlike the Python/TypeScript ecosystem split in prior baselines, this
category doesn't split cleanly by programming language — its tools are
mostly standalone Go binaries (Terraform, OpenTofu, Helm, ArgoCD's CLI,
Trivy, tflint, k9s all ship as single compiled binaries) distributed via
GitHub Releases, Homebrew, and OS package managers rather than PyPI/npm.
Two real, narrower language surfaces do appear and are named explicitly
rather than glossed over:

- **HCL** (HashiCorp Configuration Language) — Terraform/OpenTofu's own
  config DSL, and **general-purpose languages via CDK-style tooling**
  (TypeScript/Python/Java/C#/Go for AWS CDK; TypeScript/Python/Java/C#/Go
  for the now-archived CDKTF) — a real, distinct "IaC-via-real-programming-
  language" alternative to HCL, covered in the IaC-tools table below.
  **Pulumi** is a third distinct point on this same axis: general-purpose
  languages (TypeScript, Python, Go, C#, Java, YAML) with no separate
  DSL at all.
- **Rego** — Open Policy Agent's policy language, the closest thing this
  category has to a cross-tool "policy DSL," used identically across
  Terraform-plan gating, Kubernetes admission control, and CI/CD checks
  (see Policy-as-code section).

Because of this, this baseline's tables use **GitHub stars/forks/issues/
`pushed_at` + CNCF graduation status + latest-release tag** as the
adoption-signal shape (direct `gh api repos/<owner>/<repo>` fetches,
matching the convention from prior baselines), rather than PyPI/npm
download counts, which mostly don't apply to this category's tools.

## In scope

### IaC tools — impact: high — depth: table + decision rule

**Terraform's license status, verified precisely rather than assumed**:
direct fetch of `hashicorp/terraform`'s own `LICENSE` file (raw GitHub,
not the repo metadata API, which reports `NOASSERTION`) confirms Terraform
is licensed under the **Business Source License (BSL) 1.1**, scoped to
"Terraform Version 1.6.0 or later" — every current release is
**source-available, not OSI-approved open source**. The licensor is now
**International Business Machines Corporation** (IBM completed its
HashiCorp acquisition in 2025), not HashiCorp. The BSL's Additional Use
Grant permits ordinary production use but restricts offering Terraform
itself, hosted or embedded, in competition with IBM's own paid Terraform
products; per the license's own Change License provision, each BSL-covered
release converts to MPL 2.0 four years after that release's date — this
is a rolling per-version conversion, not a single fixed date for the whole
project. Terraform 1.5.7 was the last release under plain MPL 2.0.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **OpenTofu** (`opentofu/opentofu`) — **default for new HCL-based IaC** | Drop-in Terraform replacement/fork, HCL-native, forked from the last MPL Terraform release (1.5.x) | **MPL-2.0** (confirmed via GitHub repo metadata) | The direct community response to Terraform's BSL move: a **Linux Foundation-governed** (confirmed via direct fetch of opentofu.org — "under the Linux Foundation's stewardship," explicitly to de-risk future licensing changes), genuinely OSI-approved-open-source continuation with real feature *additions* Terraform itself lacks (state encryption since v1.7, early variable/local evaluation since v1.8, resource-exclusion flags and provider `for_each` since v1.9) — not just a stale fork. Direct fetch of opentofu.org also reports 3,900+ providers and 23,600+ modules in its ecosystem, with Harness/Gruntwork/Spacelift/env0/Scalr/Buildkite/Cloudflare/Datadog as engineering sponsors | 2026-08-31 | Direct GitHub fetch: 29,984 stars, 1,342 forks, 322 open issues, pushed 2026-08-28 (active); latest release `v1.12.6` |
| **Terraform** (`hashicorp/terraform`) | HCL-native IaC — still the largest single ecosystem of providers/modules and the tool most existing runbooks/tutorials assume | **BSL 1.1** (source-available, not OSI-approved; see callout above) | Named as the honest incumbent, not the default recommendation for a **new** project given the licensing status — the right choice for a team already standardized on Terraform Cloud/Enterprise, Sentinel policies, or an existing large Terraform estate where migrating to OpenTofu is a real but non-trivial provider-compatibility exercise | 2026-08-31 | Direct GitHub fetch: 49,582 stars, 10,614 forks, 1,922 open issues, pushed 2026-08-28 (still very active despite the licensing shift); latest release `v1.16.0` |
| **Pulumi** (`pulumi/pulumi`) | General-purpose-language IaC (TypeScript, Python, Go, C#, Java, or YAML) — no separate DSL at all | **Apache-2.0** | The real alternative for a team that wants IaC expressed in a language its developers already write, with actual loops/conditionals/functions/package-manager reuse rather than HCL's more limited expression language; genuinely OSI-open, unlike Terraform's current status | 2026-08-31 | Direct GitHub fetch: 25,629 stars, 1,420 forks, 2,451 open issues, pushed 2026-08-31 (very active); latest release `v3.260.0` |
| **AWS CDK** (`aws/aws-cdk`) | AWS-only infrastructure defined in a general-purpose language (TypeScript/Python/Java/C#/Go), synthesizes to CloudFormation under the hood | Apache-2.0 | The right choice specifically for an AWS-only estate wanting CDK's language ergonomics without CDKTF's now-abandoned multi-cloud ambitions — still actively maintained, unlike the row below | 2026-08-31 | Direct GitHub fetch: 12,880 stars, 4,614 forks, 2,856 open issues, pushed 2026-08-29 (active); AWS's own project |
| CDKTF (`hashicorp/terraform-cdk`) | CDK-style, general-purpose-language authoring that synthesizes to Terraform HCL/JSON — **named to flag an active deprecation, not as a recommendation** | MPL-2.0 | **Do not adopt for new projects — officially archived.** HashiCorp announced CDKTF would sunset on **2025-12-10**, stating it "did not find product-market fit at scale" and that HashiCorp/IBM would focus investment on core Terraform instead; the GitHub repo confirms `archived: true` with `pushed_at: 2025-12-10`, matching the announcement exactly. Existing users are told to migrate to plain Terraform/HCL, or to AWS CDK directly if AWS-only | 2026-08-31 | Direct GitHub fetch: 5,073 stars, 515 forks, 389 open issues, **archived, last push 2025-12-10** — read-only, no further commits possible |
| **AWS CloudFormation** | AWS-native, fully managed IaC service — no separate binary/repo to install | N/A — a managed AWS service, not licensable/installable software (same category as this repo's existing CloudFormation-adjacent precedent in other baselines) | The zero-extra-tooling default for an AWS-only shop that wants IaC with no separate state-backend or policy-engine decision to make (AWS manages state internally); the tradeoff is single-cloud lock-in and a markup language many teams find more verbose than HCL/Pulumi's general-purpose-language options | 2026-08-31 | Not a fetchable repo — a hosted AWS service; adoption signal is AWS's own platform ubiquity, not a GitHub metric |

**Decision rule, per user decision (post-Checkpoint-F review): OpenTofu
named as the default, with Terraform kept a fully legitimate first-class
choice, not a lesser fallback**: new HCL-shaped IaC project with no
existing Terraform Cloud/Sentinel investment → **OpenTofu** (OSI-open,
Linux-Foundation governed, real feature parity-plus, and confirmed at
parity with Terraform on native S3 locking — see State-management table
above); a team already standardized on Terraform Cloud/Enterprise and
Sentinel, an existing large Terraform estate, or a team that specifically
wants the largest current pool of tutorials/Stack-Overflow-era reference
material and the largest absolute provider/module registry → **Terraform**
remains the right choice, and migrating that investment to OpenTofu is a
real, deliberate project of its own, not a free win a team should feel
pressured into; team wants infrastructure expressed in a general-purpose
language with the richest language ergonomics → **Pulumi**; AWS-only
estate wanting CDK-style authoring → **AWS CDK**, not CDKTF (archived);
AWS-only shop wanting zero extra tooling and comfortable with AWS's
native syntax → **CloudFormation**. **The identical decision shape recurs
one layer over, for secrets management** (see the new section below):
HashiCorp Vault underwent the same BSL/IBM relicensing as Terraform
itself, with **OpenBao** as its own Linux-Foundation-governed open fork —
default-to-the-open-fork for new work, Vault remains legitimate for an
existing HCP-ecosystem investment, is not a one-off Terraform-specific
situation.

### State-management / drift tooling — impact: high — depth: table + commercial-tier trap

**State-locking mechanics changed materially within the last two years,
verified this pass rather than assumed from the older "S3 + DynamoDB
lock table" convention**: AWS added native S3 object-lock-based state
locking, and Terraform 1.10 added support for it; **Terraform 1.11
promoted the `use_lockfile` S3-backend parameter to generally available
and marked the `dynamodb_table`/`dynamodb_endpoint` arguments deprecated**
— DynamoDB-based locking is now the **legacy** path, not the current
recommendation, for any Terraform/OpenTofu project using an S3 backend.
Requires an S3 bucket with Object Lock enabled **at bucket-creation time**
(cannot be retrofitted onto an existing bucket without Object Lock). This
baseline could not confirm from this pass whether OpenTofu has shipped
the equivalent `use_lockfile` support on the same timeline as Terraform
1.10/1.11 — flagged as an open question below rather than assumed.

**Commercial-tier trap, directly parallel to this repo's own Apollo/Kong
(backend-api-services) and LangGraph (agentic-mcp-platforms) callouts —
now direct-fetch-verified on the pricing-tier figures, follow-up pass
2026-08-31**: direct fetch of `hashicorp.com/en/products/terraform/pricing`
confirms the current tier structure verbatim: **Essentials
$0.10/resource/month, Standard $0.47, Premium $0.99** (each also quoted as
an hourly rate), plus a fourth **IBM Terraform Enterprise** self-managed
tier at custom pricing — a 5,000-resource estate runs roughly
$2,350/month on Standard. The page's own FAQ ("Is there still a free
version of HCP Terraform?") independently confirms a free tier
exists/existed, though the page itself doesn't spell out historical
sunset dates or the exact current resource cap — those specifics (**legacy
free plan end-of-life 2026-03-31**, announced via email only on
2025-12-15, replacement free tier capped at **500 managed resources, one
policy set of ≤5 policies, one concurrent run**) remain sourced to Scalr's
own learning-center page, a competitor's account, cross-corroborated by
several independent secondary sources agreeing on the same dates — treat
the tier pricing as primary-sourced and the historical sunset-timeline
specifics as strongly-corroborated-but-secondary. A single real-world EKS
cluster with its networking/IAM/security-groups routinely exceeds 500
resources. `terraform import` was
separately locked behind the Business tier as of January 2025, per the
same source. This is exactly the kind of "free tier looks fine until your
real infrastructure size hits it" trap this repo's convention calls out
explicitly — not independently corroborated against HashiCorp's own
pricing page this pass, so treat the exact dollar figures as
directionally accurate rather than primary-sourced.

| Option | For | License/model | Why recommended (or not) | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| **S3 native locking** (`use_lockfile`, Terraform ≥1.11 / **OpenTofu ≥1.10.0, confirmed parity**) | Self-managed remote state + locking with no second AWS service | N/A — a backend feature of Terraform/OpenTofu itself, not a separate tool | The current default for a self-managed backend: "the entire locking mechanism lives inside S3 — no second service, no second set of IAM permissions, no second resource to provision" (vs. the old DynamoDB-table approach) | 2026-08-31 | Direct fetch of OpenTofu's own GitHub Releases API, follow-up pass 2026-08-31: v1.10.0's release notes carry an identical "### Native S3 Locking" entry with the same `use_lockfile = true` parameter — OpenTofu is not behind Terraform on this feature, resolving this baseline's own first-pass open question |
| S3 + DynamoDB lock table (legacy) | The pre-2024 self-managed-backend convention — **named to flag deprecation, not as a recommendation for new projects** | N/A — built-in backend feature | Still works, still documented, but the `dynamodb_table` argument is now marked deprecated in Terraform's own docs; a new project should reach for `use_lockfile` instead unless already running this pattern | 2026-08-31 | Search-corroborated only this pass |
| **HCP Terraform** (formerly Terraform Cloud) | Managed remote state + run pipeline + Sentinel policy gating, tightly coupled to HashiCorp's own product line | Commercial SaaS (HCP Terraform itself; **does not work with OpenTofu** — Sentinel specifically requires Terraform Cloud/Enterprise) | The default if a team is already standardized on Terraform (not OpenTofu) and wants HashiCorp's own managed run pipeline — see the free-tier-sunset trap above before committing | 2026-08-31 | Free-tier EOL and pricing figures per the callout above, search-corroborated |
| **Atlantis** (`runatlantis/atlantis`) | Self-hosted, PR-based Terraform/OpenTofu plan/apply automation — comments plan output directly on the pull request | Apache-2.0 | The genuinely free, fully self-hosted alternative for a team that wants Terraform-Cloud-style PR-driven plan/apply gating without any commercial run-platform dependency; single-team-oriented rather than a full multi-tenant governance platform | 2026-08-31 | Direct GitHub fetch: 9,269 stars, 1,330 forks, 900 open issues, pushed 2026-08-31 (very active) |
| **Spacelift** (commercial) | Multi-IaC run platform (Terraform, OpenTofu, Pulumi, CloudFormation, Kubernetes, Ansible) with a Rego-based policy engine | Proprietary/commercial | The multi-IaC choice when a team runs more than one of Terraform/OpenTofu/Pulumi/CloudFormation and wants one governance plane across all of them; free plan capped at 2 users/1 worker per search-corroborated pricing pages, paid tiers start ~$250/month with SSO/audit-logs gated to Enterprise | 2026-08-31 | Not independently fetched (no public repo — commercial SaaS); search-corroborated pricing only |
| **Scalr** (commercial) | Drop-in Terraform-Cloud-style remote-operations backend, state in Scalr-managed storage or a customer-owned bucket | Proprietary/commercial | Named as the closest architectural match to HCP Terraform itself among the alternatives (same remote-operations-backend model), billed per-run rather than per-concurrency, with governance features not gated to a top tier per its own marketing — a real alternative for a team burned by the HCP Terraform free-tier sunset who wants a similar operating model elsewhere | 2026-08-31 | Not independently fetched (commercial SaaS); search-corroborated only |
| **env0** (rebranding to "env zero") (commercial) | Multi-IaC (Terraform, OpenTofu, Terragrunt, Pulumi, CloudFormation) SaaS with built-in FinOps cost tracking, OPA-based policy | Proprietary/commercial | Named for completeness alongside Spacelift/Scalr; distinguishing feature per search corroboration is its built-in cost/budget tooling and per-apply (not per-resource) pricing model | 2026-08-31 | Not independently fetched (commercial SaaS); search-corroborated only |

### Policy-as-code / blast-radius gating — impact: high — depth: table + licensing trap

**Sentinel is fully proprietary and Terraform-Cloud/Enterprise-only —
confirmed, not a licensing gray area the way some other tools in this
repo's prior baselines were.** Sentinel has no public GitHub repository
(`hashicorp/sentinel` returns 404) and, per multiple 2026 comparison
sources, "does not work with OpenTofu at all" — a hard architectural
lock-in, not a soft preference, for any team on OpenTofu rather than
Terraform Cloud/Enterprise.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **OPA (Open Policy Agent)** (`open-policy-agent/opa`) — **default cross-tool policy engine** | General-purpose policy engine (Rego language) usable identically across Terraform-plan gating, Kubernetes admission control, and CI/CD checks | Apache-2.0 | **CNCF Graduated** (accepted 2018-03-29, graduated 2021-01-29) — the only policy engine in this table that is both open and portable across the whole stack this category covers (IaC + Kubernetes + CI), vs. Sentinel's single-vendor lock-in | 2026-08-31 | Direct GitHub fetch: 12,179 stars, 1,667 forks, 337 open issues, pushed 2026-08-28 (active); latest release `v1.20.1` |
| **Conftest** (`open-policy-agent/conftest`) | Runs OPA/Rego policies directly against structured config files (Terraform plan JSON, Kubernetes YAML, Dockerfiles, etc.) as a standalone CLI, no server needed | Apache-2.0 (confirmed via direct `LICENSE` fetch — GitHub's metadata API misreported `NOASSERTION`, the same detection artifact the Developer Tooling & Libraries baseline flagged repeatedly) | The practical "OPA for CI" packaging — the tool a pipeline actually invokes (`conftest test plan.json`) rather than standing up a full OPA server, directly relevant to the blast-radius-gating concern this category names explicitly | 2026-08-31 | Direct GitHub fetch: 3,256 stars, 358 forks, 52 open issues, pushed 2026-08-25 (active); latest release `v0.69.0`; same `open-policy-agent` org as OPA itself |
| HashiCorp Sentinel | Policy-as-code embedded in Terraform Cloud/Enterprise's own run pipeline, rich access to plan/state/config data via a purpose-built HSL | **Proprietary** — no public repo, closed-source, HCP Terraform/Terraform Enterprise-only | **Not recommended for a new OpenTofu-based or multi-tool estate** — genuinely stronger integration with Terraform Cloud/Enterprise's own plan data than OPA's more general approach, but a hard vendor lock: doesn't run against OpenTofu at all, doesn't apply outside Terraform Cloud/Enterprise. Named because a team already paying for Terraform Cloud/Enterprise gets it "for free" as part of that platform, not because it's an open recommendation | 2026-08-31 | No fetchable repo (proprietary); search-corroborated positioning only |
| **Checkov** (`bridgecrewio/checkov`) | Static-analysis policy scanning purpose-built for IaC (Terraform/OpenTofu/CloudFormation/Kubernetes/Helm/Dockerfile/serverless), ships thousands of built-in checks | Apache-2.0 | Overlaps with OPA/Conftest but ships a much larger built-in ruleset out of the box rather than requiring hand-written Rego — the pragmatic choice when a team wants broad default coverage (CIS benchmarks, common misconfigurations) rather than a from-scratch custom policy set | 2026-08-31 | Direct GitHub fetch: 8,976 stars, 1,400 forks, 166 open issues, pushed 2026-08-30 (very active); latest release `3.3.16` |

### Secrets management — impact: high — depth: table + licensing trap (added per user request)

**HashiCorp Vault underwent the identical BSL/IBM relicensing as
Terraform itself** — confirmed via direct fetch of `hashicorp/vault`'s own
`LICENSE` file (not GitHub's metadata API, which misreports it as
`NOASSERTION`): "Licensor: International Business Machines Corporation
(IBM)... Licensed Work: Vault Version 1.15.0 or later" — the same BSL 1.1
terms, the same IBM licensor, as Terraform's own license (see the IaC
tools callout above). This is a genuinely new finding this pass, not
carried from the original baseline draft: the OpenTofu-style
default-to-the-open-fork calculus applies to secrets management too, not
just IaC provisioning.

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **OpenBao** (`openbao/openbao`) — **default for new Vault-shaped secrets infrastructure** | Drop-in Vault-API-compatible secrets server — dynamic/short-lived credential issuance, transit encryption, PKI, the same core feature set Vault itself offers | **MPL-2.0**, Linux-Foundation-governed | The direct Vault-side analog to OpenTofu: forked from the last MPL-licensed Vault release specifically in response to the same BSL relicensing event, genuinely OSI-open where Vault itself now isn't | 2026-08-31 | Direct GitHub fetch: 7,217 stars, 551 forks, 308 open issues, pushed 2026-08-28 (active) |
| **HashiCorp Vault** (`hashicorp/vault`) | The original, still-dominant dedicated secrets-management server — dynamic secrets, transit encryption, PKI, extensive plugin ecosystem | **BSL 1.1** (source-available, not OSI-approved; IBM licensor — see callout above) | Named as the honest incumbent, not the new-project default given its licensing status — the right choice for a team already running Vault in production or invested in HashiCorp's own Vault Enterprise/HCP Vault ecosystem, same reasoning as Terraform's own entry above | 2026-08-31 | Direct GitHub fetch: 36,190 stars, 4,748 forks, 1,431 open issues, pushed 2026-08-28 (still very active despite the licensing shift) |
| **External Secrets Operator** (`external-secrets/external-secrets`) | Kubernetes controller that syncs secrets *live* from an external system (Vault, OpenBao, AWS/Azure/GCP secret managers) into native `Secret` objects | Apache-2.0 | The connective-tissue tool between any of the servers/managers in this table and an actual running Kubernetes workload — a cluster never needs its own copy of the source-of-truth secret, only a synced reference to it | 2026-08-31 | Direct GitHub fetch: 6,819 stars, 1,406 forks, 266 open issues, pushed 2026-08-28 (active) |
| **SOPS** (`getsops/sops`) | Encrypts individual values inside a structured file (YAML/JSON/ENV/INI) via KMS/PGP/age, keeping the file's structure human-readable while values stay ciphertext — the file is safe to commit straight into git | **MPL-2.0** | **CNCF Sandbox** (accepted 2023-05-17, still Sandbox as of this pass, next maturity review scheduled 2026-09-22 per search corroboration) — the standard choice for a GitOps-driven repo that wants secrets to live in the same git history as everything else, encrypted rather than absent | 2026-08-31 | Direct GitHub fetch: 22,973 stars, 1,075 forks, 442 open issues, pushed 2026-08-31 (very active) |
| **Sealed Secrets** (`bitnami-labs/sealed-secrets`) | A cluster-side controller one-way-decrypts a git-committed `SealedSecret` CRD into a real Kubernetes `Secret` at apply time — only the cluster's own private key can decrypt it | Apache-2.0 | The Kubernetes-native alternative to SOPS for teams that want the "encrypted secret lives in git" property expressed as a first-class Kubernetes CRD rather than a generic encrypted file format; **worth a maintenance watch, not a hard trap**: it lives under the `bitnami-labs` GitHub org, and Broadcom's 2025 shift of the broader Bitnami catalog to a paid "Bitnami Secure Images" model was search-corroborated as **not** affecting this specific project's open GitHub repo/image publishing, but the org's broader direction is worth monitoring | 2026-08-31 | Direct GitHub fetch: 9,264 stars, 773 forks, 67 open issues, pushed 2026-08-27 (active) |

**Decision rule**: a dedicated secrets server with dynamic/short-lived
credentials → **OpenBao** by default, **Vault** if already invested in
HashiCorp's ecosystem; already on one cloud and want zero extra
infrastructure → that cloud's own secret manager (AWS Secrets Manager/
Azure Key Vault/GCP Secret Manager, not independently table-compared this
pass since each is a managed service tied to its own cloud, not a
licensable product); a GitOps-driven repo wanting secrets encrypted
in-place in git → **SOPS**; a Kubernetes-native equivalent expressed as a
CRD → **Sealed Secrets**; connecting any of the above to a running
cluster → **External Secrets Operator**, which is complementary to, not
competing with, every other row in this table.

### Kubernetes tooling — impact: high — depth: table + decision rule

**Real local precedent applies directly here**: `ubi-csr-tmf`'s three
Helm charts and its CI pinning Helm 3.11.1 (vs. current 4.2.4) are the
concrete evidence base for this section, not a generic survey.

| Tool | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Helm** (`helm/helm`) — **default templating/package-manager layer** | Kubernetes package manager — the templating engine this repo's own `charts/*/Chart.yaml`+`values*.yaml` structure already uses | Apache-2.0 | **CNCF Graduated** (accepted 2018-06-01, graduated 2020-05-01) — the dominant Kubernetes packaging convention, exactly what the local precedent already uses; the only currency gap found is CI pinning v3.11.1 against a current v4.2.4 (see Local precedent) | 2026-08-31 | Direct GitHub fetch: 30,197 stars, 7,768 forks, 456 open issues, pushed 2026-08-28 (active); latest release **`v4.2.4`** — a full major version ahead of what this repo's own CI pins |
| **Kustomize** (`kubernetes-sigs/kustomize`) | Overlay-based, template-free YAML customization (base + per-environment patches) | Apache-2.0 | The declarative alternative to Helm's templating approach — no separate binary install needed since it ships **bundled inside `kubectl` itself** (`kubectl apply -k`/`kubectl kustomize`, present since Kubernetes 1.14, the bundled version updated on its own cadence separate from the standalone CLI); a `kubernetes-sigs` project, not itself a separately CNCF-graduated project | 2026-08-31 | Direct GitHub fetch: 12,149 stars, 2,415 forks, 187 open issues, pushed 2026-08-31 (active); latest standalone-CLI release `kustomize/v5.8.1` |
| **Argo CD** (`argoproj/argo-cd`) | Pull-based GitOps continuous-delivery controller with a strong built-in web UI, per-application sync view | Apache-2.0 | **CNCF Graduated** (2022) — the default when a team wants GitOps with a polished out-of-box UI for visualizing sync/drift state per application; the more commonly reached-for of the two GitOps controllers in most current comparisons | 2026-08-31 | Direct GitHub fetch: 24,039 stars, 7,822 forks, 4,433 open issues, pushed 2026-08-31 (very active); latest release `v3.5.2` |
| **Flux** (`fluxcd/flux2`) | Composable GitOps toolkit (source/kustomize/helm/notification controllers as separate pluggable pieces), no bundled UI of its own | Apache-2.0 | **CNCF Graduated** (2022) — the choice when a team wants a more composable, controller-per-concern architecture (and is comfortable pairing it with a separate UI or none at all) rather than Argo CD's more monolithic, UI-first design | 2026-08-31 | Direct GitHub fetch: 8,376 stars, 778 forks, 254 open issues, pushed 2026-08-25 (active); latest release `v2.9.4` |
| **k9s** (`derailed/k9s`) | Terminal UI for navigating/managing live Kubernetes clusters (pods, logs, exec, resource editing) without hand-writing `kubectl` commands | Apache-2.0 | The dominant terminal-based cluster-operator tool — no GUI/Electron overhead, works over SSH, genuinely the most-starred tool in this entire Kubernetes-tooling table | 2026-08-31 | Direct GitHub fetch: 34,469 stars, 2,265 forks, 94 open issues, pushed 2026-08-29 (active); latest release `v0.51.0` |
| **FreeLens** (`freelensapp/freelens`) | Graphical (Electron) Kubernetes IDE — the actively-maintained continuation for a team wanting a GUI rather than k9s's terminal UI | MIT | **Named specifically because the obvious "Lens" answer is now a licensing trap**: Mirantis (which acquired Lens) moved Lens Desktop to a commercial, account-gated freemium product, and **OpenLens (the formerly-open core) is now itself unmaintained** — last significant release late 2024, per multiple 2026 sources. FreeLens is the community fork created in 2024 specifically to keep a genuinely open GUI alive after that; it is the current answer, not "OpenLens" | 2026-08-31 | Direct GitHub fetch: 5,498 stars, 325 forks, 218 open issues, pushed **2026-08-30** (active) — vs. `lensapp/lens` itself, direct GitHub fetch: MIT license, 23,231 stars, but pushed **2025-02-11**, over 18 months stale, confirming the "upstream gone quiet, fork is where activity lives" pattern this repo's prior baselines flagged for setuptools/bump2version/tower-lsp |

**Decision rule**: templating/packaging a Kubernetes app → **Helm**
(matches this repo's own local precedent); pure overlay/patch composition
with zero extra binary → **Kustomize** (already bundled in `kubectl`);
GitOps continuous delivery with a strong built-in UI → **Argo CD**;
composable, UI-agnostic GitOps controller architecture → **Flux**;
terminal-based cluster operations → **k9s**; GUI-based cluster operations
→ **FreeLens**, not Lens/OpenLens.

### Container registries and build tooling — impact: med — depth: table

| Option | For | License/model | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| **Amazon ECR** | AWS-native container registry — the local precedent's own choice (`aws-actions/amazon-ecr-login@v2`, `ECR_REPOSITORY: csr-tmf-portal/backend`) | N/A — managed AWS service | Zero-friction default when the deploy target is already EKS/AWS, IAM-native auth (no separate registry credential to manage) — real local precedent, not a generic pick | 2026-08-31 | Not a fetchable repo — real local evidence instead: confirmed in `be-deploy-prod.yml`/`ci-cd.yml` |
| GHCR (GitHub Container Registry) | Registry co-located with the GitHub Actions CI that builds the image, no separate cloud-provider registry account needed | N/A — managed GitHub service | The right choice when the deploy target isn't tied to one cloud provider's own registry, or for open-source/public images wanting free anonymous pulls | 2026-08-31 | Not independently fetched — named as a comparison point only, not deep-researched this pass |
| Docker Hub | The original, most widely-recognized public registry | N/A — managed service (Docker Inc.) | Named for completeness; anonymous pull-rate limits make it a weaker default for CI-heavy pipelines than ECR/GHCR unless already paying for a Docker Hub plan | 2026-08-31 | Not independently fetched this pass |
| GCR / Artifact Registry | GCP-native registry (Artifact Registry is GCR's current, actively-developed successor) | N/A — managed GCP service | Named for completeness as the GCP-equivalent of ECR; not researched further since GCP isn't this baseline's or the local precedent's deployment target | 2026-08-31 | Not independently fetched this pass |
| **BuildKit** (`moby/buildkit`) + **Buildx** (`docker/buildx`) | The build engine (BuildKit) and its `docker buildx` CLI front-end — exactly what the local precedent uses (`docker/setup-buildx-action@v3`, registry-backed layer caching) | Both Apache-2.0 | Real local precedent again: `be-deploy-prod.yml` uses `docker buildx build --cache-from/--cache-to type=registry,...,mode=max` — registry-persisted build cache across CI runs, a genuinely distinctive choice worth naming rather than generic "Docker build" | 2026-08-31 | BuildKit direct GitHub fetch: 10,218 stars, 1,501 forks, 914 open issues, pushed 2026-08-31 (very active); Buildx direct GitHub fetch: 4,491 stars, 676 forks, 390 open issues, pushed 2026-08-28 |
| **Cloud Native Buildpacks** (`buildpacks/pack` CLI) | Builds container images directly from source with no hand-written Dockerfile, auto-detecting language/runtime | Apache-2.0 | **CNCF Graduated 2026-08-11** — freshly graduated as of this pass; the announcement cites 535 contributors across 164 organizations, 20+ adopters (DigitalOcean, GitLab, Google, HashiCorp, Spring, VMware), and a concrete production result (a 500+-application enterprise estate cutting vulnerability-patch turnaround from weeks to hours via centralized buildpack updates). The right choice when a team wants to eliminate hand-maintained Dockerfiles entirely and standardize base-image patching centrally — not a fit for the local precedent's own hand-written multi-stage Dockerfiles, named here as the current alternative philosophy | 2026-08-31 | Direct GitHub fetch: 2,992 stars, 360 forks, 192 open issues, pushed 2026-08-19; CNCF graduation confirmed via direct fetch of CNCF's own 2026-08-11 announcement; latest release `v0.40.9` |

### Internal developer platform (IDP) tooling — impact: med — depth: table

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Backstage** (`backstage/backstage`) — **dominant open default** | Spotify-originated developer portal / software catalog — service ownership, docs, scaffolding templates, plugin ecosystem | Apache-2.0 | **CNCF Incubating** (accepted 2020-09-08, moved to Incubating 2022-03-15) — **not yet Graduated**, a real, current distinction worth stating rather than assuming graduated status the way Helm/OPA/Argo/Flux/Buildpacks all now are; still the dominant open-source developer-portal choice by a wide margin on every adoption signal fetched this pass | 2026-08-31 | Direct GitHub fetch: 34,277 stars, 7,595 forks, 436 open issues, pushed 2026-08-30 (very active); latest release `v1.54.6` |
| Port (commercial) | Managed (SaaS) developer-portal alternative, positioned as the low-setup-overhead option | Proprietary/commercial | The pragmatic choice for a small/mid-size team that wants Backstage's cataloging value without running/maintaining a Backstage instance themselves | 2026-08-31 | Not independently fetched — commercial SaaS, no public repo; search-corroborated positioning only |
| Cortex / OpsLevel (commercial) | Scorecard-driven service-maturity/ownership platforms (SLOs, runbook checks, security-scan gates surfaced as org-wide compliance scores) | Proprietary/commercial | A materially different value proposition from Backstage's catalog-first model — worth naming as a distinct category ("maturity scorecards as the product") rather than a like-for-like Backstage substitute | 2026-08-31 | Not independently fetched — commercial SaaS; search-corroborated only |
| Spotify Portal for Backstage / Roadie (commercial) | Managed-hosting distributions of Backstage itself (same open-source core, hosted/operated by a vendor) | Backstage core remains Apache-2.0; the hosting/management layer is commercial | The right pick for a team that wants Backstage's actual data model/plugin ecosystem specifically, without operating the Backstage instance itself | 2026-08-31 | Not independently fetched — commercial hosting layer; search-corroborated only |

### CI/CD-layer add-ons for IaC/platform work — impact: med — depth: table

GitHub Actions is already this repo's own de facto default (confirmed
directly in `ubi-csr-tmf`'s 12 workflow files and by prior baselines) —
this section names what needs layering **on top of** it specifically for
IaC/Kubernetes work, matching what the local precedent's own pipeline is
currently missing (see Local precedent's "no linting/security-scanning
step" finding above).

| Tool | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **terraform-docs** (`terraform-docs/terraform-docs`) | Auto-generates a Terraform/OpenTofu module's README documentation (inputs/outputs/providers) directly from its `.tf` source | MIT | The standard "keep module docs from rotting out of sync with actual variables" tool — a direct CI-layer add-on, not a survey-only mention | 2026-08-31 | Direct GitHub fetch: 4,817 stars, 602 forks, 191 open issues, pushed 2026-08-03 (~4 weeks stale relative to this pass, worth a light flag though not alarming); latest release `v0.24.0` |
| **tflint** (`terraform-linters/tflint`) | Terraform/OpenTofu-specific linter — catches provider-specific errors and deprecated syntax `terraform validate` itself doesn't check | MPL-2.0 | The standard pre-plan linting gate; plugin architecture supports AWS/Azure/GCP provider-specific rulesets beyond generic HCL syntax checking | 2026-08-31 | Direct GitHub fetch: 5,798 stars, 407 forks, 30 open issues, pushed 2026-08-29 (active); latest release `v0.64.0` |
| **Trivy** (`aquasecurity/trivy`) — **default for IaC/container/Kubernetes-manifest scanning** | All-in-one vulnerability + misconfiguration scanner: container images, IaC files (Terraform/CloudFormation/Kubernetes/Dockerfile), and SBOM generation, in one CLI | Apache-2.0 | The consolidated current recommendation — see the deprecation callout immediately below for why this supersedes tfsec specifically; also directly closes this baseline's own local-precedent gap (no image/IaC scan step exists in `ubi-csr-tmf`'s pipeline today) | 2026-08-31 | Direct GitHub fetch: 37,703 stars, 642 forks, 259 open issues, pushed 2026-08-28 (very active); latest release `v0.74.0` |
| tfsec (`aquasecurity/tfsec`) | Terraform-specific security scanner — **named to flag an active deprecation, not as a recommendation** | MIT | **Do not adopt for new pipelines.** Aqua Security's own position, confirmed via multiple 2026 sources: "tfsec is now part of Trivy" — all 1,000+ tfsec checks were merged into Trivy's IaC-scanning mode in 2024, migration is a one-line swap (`tfsec .` → `trivy config .`, check IDs like `AVD-AWS-0086` carry over unchanged), and no new features are landing in tfsec itself | 2026-08-31 | Direct GitHub fetch: 7,034 stars, 560 forks, 18 open issues, **pushed 2026-03-25** — over 5 months stale relative to this pass, consistent with the confirmed-deprecated status |
| **Checkov** (`bridgecrewio/checkov`) | Broad-ruleset IaC/Kubernetes/Dockerfile scanner (see also Policy-as-code section above) | Apache-2.0 | Repeated here because it's equally a CI-layer add-on choice as a policy-engine choice — the two roles overlap in this category more than in most (a scanner and a policy gate are often the same tool) | 2026-08-31 | See Policy-as-code section above for full signal |

## Explicitly out of scope

- **Full multi-cloud provider-API survey** (AWS/Azure/GCP SDK specifics,
  provider-specific Terraform resource coverage) — this baseline covers
  the tooling layer that provisions/deploys, not the cloud-provider
  API surface each tool then targets.
- **Configuration-management tools** (Ansible, Chef, Puppet, SaltStack) —
  a genuinely adjacent but distinct concern (mutable-server configuration
  vs. this category's idempotent-provisioning/orchestration focus); named
  only where Spacelift/env0 listed Ansible as one of their own supported
  IaC types, not independently researched.
- **Full observability/monitoring-stack tooling** (Prometheus, Grafana,
  Datadog) — a downstream operational concern once infrastructure exists,
  not itself an infrastructure-provisioning or platform-tooling choice;
  likely belongs to a future MLOps/Platform-Engineering-adjacent doc.
- Deep secret-engine internals (Vault/OpenBao's dynamic-secret-backend
  plugin mechanics, transit-encryption key-rotation internals) beyond the
  tool-selection depth in the new Secrets Management section above —
  added per user request this pass, no longer a scoped-out gap.
- **Service-mesh tooling** (Istio, Linkerd, Cilium) — a Kubernetes-adjacent
  but functionally distinct networking-layer concern from this category's
  IaC/deployment/policy focus.
- **Cost/pricing depth beyond what's needed for the commercial-tier-trap
  callouts** (HCP Terraform, Spacelift, Pulumi Cloud) — exact current
  dollar figures for Spacelift/Scalr/env0 were search-corroborated, not
  independently direct-fetched from each vendor's own pricing page, per
  this repo's "license/self-hosting status is the durable signal, not
  exact pricing" convention from the Backend & API Services baseline.
- **A deeper OpenTofu-vs-Terraform provider-compatibility audit** — this
  pass confirmed OpenTofu's headline feature/governance claims via its
  own site, but did not independently verify provider-by-provider
  compatibility percentages some comparison sites cite.

## Sources

- Local file reads (not web sources), all 2026-08-31: `/Users/devopammittra/
  GitHub/ubi-csr-tmf/charts/{agents,ubi-backend,ubi-frontend}/{Chart.yaml,
  values.yaml,values-dev.yaml}`, `ubi-csr-tmf-helm-charts/` (confirmed
  empty via `ls`), `.github/workflows/{be-deploy-prod.yml,ci-cd.yml,
  build-validation.yml}` in full, `wc -l` + grep across all 12
  `.github/workflows/*.yml*` files for security/lint-tool mentions,
  `aws/container/docker-compose.yml`, `aws/container/` directory listing;
  directory check of `/Users/devopammittra/GitHub/agent-skills` for
  absence of any Dockerfile/`.tf`/docker-compose file
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license,
  stars, forks, open issues, `pushed_at`, `archived`) for: hashicorp/
  terraform, opentofu/opentofu, pulumi/pulumi, aws/aws-cdk, hashicorp/
  terraform-cdk, open-policy-agent/opa, open-policy-agent/conftest, helm/
  helm, kubernetes-sigs/kustomize, argoproj/argo-cd, fluxcd/flux2,
  derailed/k9s, backstage/backstage, terraform-docs/terraform-docs,
  terraform-linters/tflint, bridgecrewio/checkov, aquasecurity/trivy,
  aquasecurity/tfsec, moby/buildkit, docker/buildx, buildpacks/pack,
  lensapp/lens, freelensapp/freelens, runatlantis/atlantis — retrieved
  2026-08-31
- `gh api repos/<owner>/<repo>/releases/latest` direct fetches for
  current version tags: terraform, opentofu, pulumi, helm, argo-cd,
  flux2, opa, conftest, kustomize, checkov, trivy, tflint, terraform-docs,
  k9s, backstage, pack, atlantis — retrieved 2026-08-31
- `https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE` —
  direct fetch confirming BSL 1.1 text, "Terraform Version 1.6.0 or
  later" scoping, IBM as licensor, four-year-per-release MPL conversion
  clause — retrieved 2026-08-31
- `https://raw.githubusercontent.com/open-policy-agent/conftest/master/
  LICENSE` — direct fetch confirming Apache-2.0 (correcting GitHub
  metadata API's `NOASSERTION` misreport) — retrieved 2026-08-31
- `https://opentofu.org/` — direct WebFetch: Linux Foundation governance
  claim, 3,900+ providers/23,600+ modules figures, sponsor list, feature
  list vs. Terraform — retrieved 2026-08-31
- `https://www.cncf.io/announcements/2026/08/11/cncf-announces-graduation-
  of-cloud-native-buildpacks-advancing-the-standard-for-container-builds/`
  — direct WebFetch confirming 2026-08-11 graduation date, contributor/
  adopter figures, OpenSSF badge — retrieved 2026-08-31
- WebSearch corroboration (not independently direct-fetched primary
  source this pass, flagged inline where used): Terraform/IBM BSL
  licensing-history narrative (scalr.com, encore.dev, gruntwork.io,
  spacelift.io, controlmonkey.io, infralovers.com, yaw.sh); CDKTF
  archival announcement and reasoning (envzero.com, peterwoods.online,
  HashiCorp's own developer.hashicorp.com/terraform/cdktf pages); tfsec→
  Trivy deprecation (appsecsanta.com, oneuptime.com, spacelift.io,
  starlog.is, safeguard.sh, and GitHub's own "Tfsec is now part of Trivy"
  repo description); Lens/OpenLens/FreeLens status (alexandre-vazquez.com,
  enterno.io, atmosly.com, radarhq.io, k8studio.io, srexpert.cloud); S3
  native locking / DynamoDB deprecation timeline (freecodecamp.org,
  multiple Medium posts, anantacloud.com, bschaatsbergen.com); HCP
  Terraform free-tier EOL and pricing (scalr.com's own learning-center
  page, the single most load-bearing of these citations given the
  concrete dates it provides); Spacelift/Scalr/env0 comparison and
  pricing (scalr.com, env0.com, spacelift.io, futurepicker.com,
  bunnyshell.com); Sentinel-vs-OPA positioning and OpenTofu
  incompatibility (scalr.com, oneuptime.com, spacelift.io, yrkan.com,
  cloudatler.com, codingprotocols.com, engineering.tachtech.net);
  Pulumi Cloud free-tier/self-hosted-state figures (vendr.com,
  spacelift.io, checkthat.ai, pulumi.com's own pricing/self-hosting
  pages); Backstage-alternatives landscape (qovery.com, encore.dev,
  port.io, roadie.io, digitalapi.ai, riftmap.dev, wetheflywheel.com);
  CNCF graduation-status roundup for Argo/Flux/OPA/Helm/Backstage
  (cncf.io's own project pages and announcement archive, redhat.com,
  venturebeat.com); kubectl's bundled Kustomize status (kustomize.io,
  kubectl.docs.kubernetes.io) — all retrieved 2026-08-31
- **Secrets management, follow-up pass 2026-08-31 (added per user
  request)**: `gh api repos/{hashicorp/vault, openbao/openbao,
  external-secrets/external-secrets, getsops/sops,
  bitnami-labs/sealed-secrets}` direct fetches for license/stars/activity;
  `raw.githubusercontent.com/hashicorp/vault/main/LICENSE` direct fetch
  confirming BSL 1.1/IBM licensor; SOPS's CNCF Sandbox status and Sealed
  Secrets' Bitnami-catalog-change immunity — both search-corroborated,
  not independently direct-fetched
- `https://raw.githubusercontent.com/opentofu/opentofu/main/CHANGELOG.md`
  and the GitHub Releases API (`gh api repos/opentofu/opentofu/releases`)
  — direct fetch, follow-up pass 2026-08-31: confirms v1.10.0 shipped
  "Native S3 Locking" with the identical `use_lockfile = true` parameter,
  resolving this baseline's own open question on OpenTofu/Terraform
  lockfile parity
- `https://www.hashicorp.com/en/products/terraform/pricing` — direct
  fetch, follow-up pass 2026-08-31: confirms the Essentials/Standard/
  Premium per-resource pricing tiers and an FAQ acknowledging a free
  tier's existence, strengthening (though not fully primary-sourcing) the
  free-tier-sunset timeline

## Open questions for the user

**Resolved this pass (2026-08-31 follow-up):** HCP Terraform's per-resource
pricing tiers are now direct-fetch-confirmed from HashiCorp's own pricing
page (see the commercial-tier-trap callout above); the historical
sunset-timeline specifics (exact 2025-12-15/2026-03-31 dates) remain
sourced to Scalr's page, cross-corroborated by several independent
secondary sources, judged sufficient given the pricing page's own FAQ
independently confirms a free tier's existence. Secrets-management tooling
is now in scope, per user decision — see the new section above. The
OpenTofu-vs-Terraform framing is resolved per user decision: OpenTofu
named as the default, with Terraform kept fully legitimate (not a lesser
fallback) for an existing HCP/Sentinel investment, a large existing
Terraform estate, or a team prioritizing the largest current tutorial/
registry base — see the updated Decision rule above.

- **Spacelift/Scalr/env0/Port/Cortex/OpsLevel pricing and feature claims
  are entirely search-corroborated, no public repos to direct-fetch**
  (they're commercial SaaS). Is search-corroboration acceptable for these
  commercial-only rows specifically, consistent with how the Backend &
  API Services baseline treated Litestar/Traefik/PactFlow's version
  numbers, or does the authoring pass need a direct fetch of each
  vendor's own pricing page before publishing specific dollar figures?

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/infrastructure-platform-engineering.md
  — est. 430–510 lines (8 category tables/sections — IaC tools with
  decision rule, state-management/drift tooling with the HCP Terraform
  commercial-tier-trap callout, policy-as-code/blast-radius gating with
  the Sentinel lock-in callout, the new secrets-management section with
  its own Vault/OpenBao licensing-trap callout, Kubernetes tooling with
  decision rule, container registries/build tooling, internal developer
  platform tooling, CI/CD-layer IaC add-ons — plus the Local-precedent
  section's own real findings (OIDC-role-naming inference, Helm 3→4
  currency gap, missing-scan-step gap) carried forward as authored-doc
  content, not
  just baseline-only detail, matching the Developer Tooling & Libraries
  baseline's structure and rough length).
