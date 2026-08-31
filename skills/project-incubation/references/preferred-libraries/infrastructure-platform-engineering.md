# Infrastructure & Platform Engineering — Preferred Libraries

Companion to [stacks/infrastructure-platform-engineering.md](../stacks/infrastructure-platform-engineering.md),
which covers architecture and selection criteria; this doc names the actual
tools/products, their licenses, and honest maintenance/adoption signal.

This category's load-bearing facts move on a different clock than a
package-manager doc's download counts: several of the entries below are
**licensing and governance events**, not popularity drift — Terraform's
BSL relicense under IBM, CDKTF's archival, tfsec's deprecation into Trivy,
and HCP Terraform's free-tier sunset all happened within roughly the last
20 months and change what "the default recommendation" actually is, not
just which tool is more popular. Real, if partial, local precedent exists
too: direct inspection of `/Users/devopammittra/GitHub/ubi-csr-tmf` (a
repo on this machine) turned up three genuine per-service Helm charts, a
2,177-line, 12-file GitHub Actions deploy pipeline with real OIDC-to-AWS
credentials and an explicit rollback step, and — just as informatively —
a **missing** IaC/container security-scanning step and a Helm version
pinned two major releases behind current. That repo covers only the
deployment half of this category (Helm + CI), not the provisioning half
(no Terraform/Pulumi/CDK file exists anywhere in it) — both findings are
woven into the Kubernetes tooling and CI/CD-layer sections below rather
than asserted as full coverage.

Every star/fork/issue/release figure below is a snapshot taken
2026-08-31. Several were independently re-fetched during this authoring
pass rather than only carried over from the research baseline, and the
drift was small enough to confirm the numbers are live and reproducible,
not stale copy-paste: OpenTofu moved from 29,984 to 29,985 stars, OpenBao
from 7,217 to 7,218, both within a day's normal traffic; HashiCorp Vault's
36,190 stars matched exactly; Helm's and Trivy's latest-release tags
(`v4.2.4` and `v0.74.0` respectively) were re-confirmed unchanged.
Separately, this pass **direct-fetched the actual pricing pages** for
Spacelift, Scalr, and env0/envzero — the three commercial multi-IaC
platforms this doc names — rather than relying solely on the baseline's
search-corroborated figures; one of those direct fetches surfaced a real
correction, detailed in the State-management section below.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [IaC tools](#iac-tools)
- [State management and drift tooling](#state-management-and-drift-tooling)
- [Policy-as-code and blast-radius gating](#policy-as-code-and-blast-radius-gating)
- [Secrets management](#secrets-management)
- [Kubernetes tooling](#kubernetes-tooling)
- [Container registries and build tooling](#container-registries-and-build-tooling)
- [Internal developer platform (IDP) tooling](#internal-developer-platform-idp-tooling)
- [CI/CD-layer add-ons for IaC/platform work](#cicd-layer-add-ons-for-iacplatform-work)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

Unlike the Python/Node/Rust split in the
[Developer Tooling & Libraries doc](developer-tooling-libraries.md#ecosystem-choice),
this category doesn't split cleanly by programming-language ecosystem at
all — its tools are mostly standalone Go binaries (Terraform, OpenTofu,
Helm, the Argo CD CLI, Trivy, tflint, k9s all ship as single compiled
binaries) distributed via GitHub Releases, Homebrew, and OS package
managers rather than PyPI/npm/crates.io. Two narrower language surfaces do
appear and are named explicitly rather than glossed over:

- **HCL** (HashiCorp Configuration Language) — Terraform/OpenTofu's own
  config DSL — versus **general-purpose-language IaC**: AWS CDK and the
  now-archived CDKTF both synthesize TypeScript/Python/Java/C#/Go down to
  CloudFormation or Terraform HCL/JSON respectively, and **Pulumi** goes
  further, using general-purpose languages (TypeScript, Python, Go, C#,
  Java, or plain YAML) with no separate DSL at all. All three points on
  this axis are covered in the IaC-tools table below.
- **Rego** — Open Policy Agent's policy language, the one genuinely
  cross-tool "policy DSL" in this category: the identical language gates
  Terraform-plan output, Kubernetes admission requests, and CI/CD checks
  (see Policy-as-code below), unlike Sentinel's Terraform-Cloud-only HSL.

Because of this, the tables below use **GitHub stars/forks/open issues/
`pushed_at` plus CNCF graduation status and the latest release tag** as
the adoption-signal shape — direct `gh api repos/<owner>/<repo>` fetches —
rather than PyPI/npm download counts, which mostly don't apply to
standalone-binary tooling. Where a tool is a managed cloud service or a
commercial SaaS with no public repository (AWS CloudFormation, HCP
Terraform, Spacelift, Scalr, env0, Port, Cortex/OpsLevel), that's stated
plainly in its own row rather than papered over with a fabricated metric.

## IaC tools

**Terraform's license, checked precisely rather than assumed**: a direct
fetch of `hashicorp/terraform`'s raw `LICENSE` file (not the GitHub repo
metadata API, which reports `NOASSERTION`) confirms Terraform is licensed
under the **Business Source License (BSL) 1.1**, scoped to "Terraform
Version 1.6.0 or later," with **International Business Machines
Corporation** — not HashiCorp — as the licensor, reflecting IBM's 2025
acquisition of HashiCorp. Every current Terraform release is
source-available, not OSI-approved open source. The BSL's Additional Use
Grant permits ordinary production use but restricts offering Terraform
itself, hosted or embedded, in competition with IBM's paid Terraform
products; the license's own Change License provision converts each
BSL-covered release to plain MPL 2.0 four years after that release's
date — a rolling per-version conversion, not one fixed date for the whole
project. Terraform 1.5.7 was the last release under plain MPL 2.0, and is
exactly the commit OpenTofu forked from.

| Library | For | License | Why recommended |
|---|---|---|---|
| **OpenTofu** (`opentofu/opentofu`) — default for new HCL-based IaC | Drop-in Terraform replacement/fork, HCL-native | **MPL-2.0** | The direct community response to Terraform's BSL move: **Linux Foundation-governed** (confirmed via direct fetch of opentofu.org — explicitly under Linux Foundation stewardship to de-risk future licensing changes), genuinely OSI-open, and shipping real feature *additions* Terraform itself lacks — state encryption since v1.7, early variable/local evaluation since v1.8, resource-exclusion flags and provider `for_each` since v1.9. opentofu.org's own figures put its ecosystem at 3,900+ providers and 23,600+ modules, with Harness/Gruntwork/Spacelift/env0/Scalr/Cloudflare/Datadog as engineering sponsors — a real coalition, not a lone fork. Direct GitHub fetch (re-confirmed this authoring pass): 29,985 stars, 1,342 forks, 322 open issues, pushed 2026-08-28; latest release `v1.12.6` |
| **Terraform** (`hashicorp/terraform`) | HCL-native IaC — still the largest single ecosystem of providers/modules and the tool most existing runbooks assume | **BSL 1.1** (source-available, not OSI-approved — see callout above) | The honest incumbent, not a lesser fallback: the right choice for a team already standardized on Terraform Cloud/Enterprise and Sentinel, or with an existing large Terraform estate where a migration to OpenTofu is a real but non-trivial provider-compatibility exercise, not a free win. Direct GitHub fetch: 49,582 stars, 10,614 forks, 1,922 open issues, pushed 2026-08-28 (still very active despite the licensing shift); latest release `v1.16.0` |
| **Pulumi** (`pulumi/pulumi`) | General-purpose-language IaC (TypeScript, Python, Go, C#, Java, or YAML) — no separate DSL at all | Apache-2.0 | The real choice for a team that wants infrastructure expressed with actual loops/conditionals/package-manager reuse rather than HCL's more limited expression language, and genuinely OSI-open where Terraform currently isn't. Direct GitHub fetch: 25,629 stars, 1,420 forks, 2,451 open issues, pushed 2026-08-31 (very active); latest release `v3.260.0` |
| **AWS CDK** (`aws/aws-cdk`) | AWS-only infrastructure defined in a general-purpose language (TypeScript/Python/Java/C#/Go), synthesizes to CloudFormation | Apache-2.0 | The right pick for an AWS-only estate wanting CDK's language ergonomics without CDKTF's now-abandoned multi-cloud ambitions — still actively maintained, unlike the row below. Direct GitHub fetch: 12,880 stars, 4,614 forks, 2,856 open issues, pushed 2026-08-29; AWS's own project |
| CDKTF (`hashicorp/terraform-cdk`) — **archived, not a recommendation** | CDK-style authoring that synthesized to Terraform HCL/JSON | MPL-2.0 | **Do not adopt for new projects.** HashiCorp archived CDKTF on **2025-12-10**, stating it "did not find product-market fit at scale" and would focus investment on core Terraform instead; the repo's `archived: true` flag and `pushed_at: 2025-12-10` match the announcement exactly. Existing users are directed to plain Terraform/HCL, or to AWS CDK directly for AWS-only estates. Direct GitHub fetch: 5,073 stars, 515 forks, 389 open issues, **archived**, last push 2025-12-10 — read-only, no further commits possible |
| **AWS CloudFormation** | AWS-native, fully managed IaC — no separate binary or repo to install | N/A — a managed AWS service, not licensable software | The zero-extra-tooling default for an AWS-only shop that wants IaC with no separate state-backend or policy-engine decision to make (AWS manages state internally); the tradeoff is single-cloud lock-in and a more verbose syntax than HCL/Pulumi. Not a fetchable repo — adoption signal is AWS's own platform ubiquity, not a GitHub metric |

**Decision rule**: new HCL-shaped IaC project with no existing Terraform
Cloud/Sentinel investment → **OpenTofu** (OSI-open, Linux-Foundation
governed, feature parity-plus, and — per the State-management section
below — now confirmed at parity with Terraform on native S3 locking).
A team already standardized on Terraform Cloud/Enterprise and Sentinel,
an existing large Terraform estate, or one that specifically wants the
largest current pool of tutorials and the largest absolute provider/
module registry → **Terraform** remains the right choice, and migrating
that investment to OpenTofu is a deliberate project of its own, not a
free win to feel pressured into. Team wants infrastructure in a
general-purpose language with the richest ergonomics → **Pulumi**;
AWS-only estate wanting CDK-style authoring → **AWS CDK**, not CDKTF
(archived); AWS-only shop wanting zero extra tooling → **CloudFormation**.

The identical decision shape recurs one layer over for secrets management
(see below): Vault underwent the same BSL/IBM relicensing as Terraform
itself, with OpenBao as its own Linux-Foundation-governed fork — this is
not a one-off Terraform-specific situation, it's a pattern IBM's
HashiCorp acquisition created across the whole product line. Worth
naming here too: `ubi-csr-tmf`'s own CI role is literally named
`GitHubActionsTerraformRole`, despite every one of its 12 workflow files
deploying exclusively via `helm upgrade`/`kubectl`, never `terraform
apply`. That's a real, if inferential, signal that Terraform (or
OpenTofu) *was* used somewhere to provision the underlying EKS
cluster/IAM/OIDC trust this pipeline targets — just in a separate
infrastructure-provisioning repo not present on this machine, not inside
`ubi-csr-tmf` itself. Stated as an honest inference from naming, not a
confirmed fact: no `.tf` file exists anywhere in that repo to corroborate
it directly.

## State management and drift tooling

**State-locking mechanics changed materially within the last two years**,
worth stating precisely rather than assuming the older "S3 + DynamoDB
lock table" convention still applies: AWS added native S3
object-lock-based state locking, Terraform 1.10 added support for it, and
**Terraform 1.11 promoted the `use_lockfile` S3-backend parameter to
generally available while marking the `dynamodb_table`/
`dynamodb_endpoint` arguments deprecated** — DynamoDB-based locking is now
the legacy path, not the current recommendation, for any Terraform/
OpenTofu project on an S3 backend. It requires an S3 bucket with Object
Lock enabled **at bucket-creation time** — it cannot be retrofitted onto
an existing bucket. Whether OpenTofu shipped the equivalent feature on the
same timeline was an open question in this doc's research baseline; a
direct fetch of OpenTofu's own `CHANGELOG.md` and GitHub Releases API
resolved it this pass — **OpenTofu v1.10.0's release notes carry an
identical "Native S3 Locking" entry with the same `use_lockfile = true`
parameter**, so OpenTofu is not behind Terraform on this specific feature.

**Commercial-tier trap, now direct-fetch-verified on the headline
figures**: a direct fetch of `hashicorp.com/en/products/terraform/pricing`
confirms the current HCP Terraform tier structure verbatim — **Essentials
$0.10/resource/month, Standard $0.47, Premium $0.99** (each also quoted as
an hourly rate), plus a fourth, custom-priced **IBM Terraform Enterprise**
self-managed tier. A 5,000-resource estate runs roughly $2,350/month on
Standard. The pricing page's own FAQ independently confirms a free tier
exists/existed, though it doesn't itself spell out the exact historical
sunset date or resource cap — those specifics (**legacy free plan
end-of-life 2026-03-31**, announced by email only on 2025-12-15,
replacement free tier capped at **500 managed resources, one policy set
of ≤5 policies, one concurrent run**, with `terraform import` separately
locked behind the Business tier since January 2025) remain sourced to a
competitor's (Scalr's) learning-center page, cross-corroborated by
several independent secondary sources agreeing on the same dates — treat
the per-resource pricing tiers as primary-sourced and the historical
sunset-timeline specifics as strongly corroborated but secondary. A
single real-world EKS cluster with its networking/IAM/security-groups
routinely exceeds 500 resources — exactly the "free tier looks fine until
your real infrastructure size hits it" trap this doc's sibling docs call
out for Apollo/Kong and LangGraph.

**A real correction surfaced this pass on Spacelift's own pricing**,
worth naming because it's the concrete illustration of why this doc's
authoring pass re-fetches rather than transcribes: the research baseline
estimated Spacelift's paid tiers start "~$250/month," search-corroborated
only. A direct fetch of `spacelift.io/pricing` this pass shows its lowest
paid tier, **"Starter +," is actually billed at $20,000/year** (roughly
$1,667/month) for unlimited users and 1–2 private workers, with Business
and Enterprise tiers above that requiring a custom quote and SSO/SAML/
audit-trail explicitly gated to Enterprise. That's roughly 6-7x the
baseline's estimate — either the baseline's figure referred to a
lower/legacy tier no longer offered, or was simply a stale or mismatched
search result; either way, the corrected figure belongs in the table
below, not the original estimate. By contrast, a direct fetch of
`scalr.com/pricing` this pass **confirms** the baseline's framing rather
than correcting it: Scalr's Business plan is genuinely $0.99/run (free up
to 50 runs/month, 2 concurrent runs included), and its own page states
explicitly "no charges for users, workspaces, resources under management,
private agents, or SAML" — governance features are not gated to a top
tier, exactly as the baseline claimed. A direct fetch of env0's pricing
page (which now 301-redirects to `envzero.com/pricing`, confirming the
"env zero" rebrand is complete, not just announced) shows a genuinely
unpublished, quote-only per-successful-apply/per-environment model for
both its paid tiers — there is no public dollar figure to get wrong or
right, which strengthens rather than contradicts the baseline's original
framing that this row is the least independently verifiable of the three.

| Library | For | License | Why recommended |
|---|---|---|---|
| **S3 native locking** (`use_lockfile`, Terraform ≥1.11 / OpenTofu ≥1.10.0 — confirmed parity) | Self-managed remote state + locking with no second AWS service | N/A — a backend feature of Terraform/OpenTofu itself | The current default for a self-managed backend: the entire locking mechanism lives inside S3, no second service or IAM permission set to provision, unlike the DynamoDB-table approach below |
| S3 + DynamoDB lock table (legacy) | The pre-2024 self-managed-backend convention — named to flag deprecation, not as a new-project recommendation | N/A — built-in backend feature | Still works and is still documented, but Terraform's own docs now mark `dynamodb_table` deprecated; a new project should reach for `use_lockfile` instead unless already running this pattern |
| **HCP Terraform** (formerly Terraform Cloud) | Managed remote state + run pipeline + Sentinel policy gating | Commercial SaaS; **does not work with OpenTofu** — Sentinel requires Terraform Cloud/Enterprise specifically | The default only for a team already standardized on Terraform (not OpenTofu) wanting HashiCorp's own managed run pipeline — see the commercial-tier trap above before committing, especially the 500-resource free-tier cap |
| **Atlantis** (`runatlantis/atlantis`) | Self-hosted, PR-based Terraform/OpenTofu plan/apply automation — comments plan output directly on the pull request | Apache-2.0 | The genuinely free, fully self-hosted alternative for PR-driven plan/apply gating with no commercial run-platform dependency; single-team-oriented rather than a full multi-tenant governance platform. Direct GitHub fetch: 9,269 stars, 1,330 forks, 900 open issues, pushed 2026-08-31 (very active) |
| **Spacelift** (commercial) | Multi-IaC run platform (Terraform, OpenTofu, Pulumi, CloudFormation, Kubernetes, Ansible) with a Rego-based policy engine | Proprietary/commercial | The multi-IaC choice when a team runs more than one of Terraform/OpenTofu/Pulumi/CloudFormation and wants one governance plane across all of them. Direct fetch of its own pricing page this pass (correcting the baseline's estimate, see callout above): free tier is 2 users/1 public worker; lowest paid tier ("Starter +") is **$20,000/year**, unlimited users, 1-2 private workers; SSO/SAML/audit-trail gated to Enterprise |
| **Scalr** (commercial) | Drop-in Terraform-Cloud-style remote-operations backend, state in Scalr-managed storage or a customer-owned bucket | Proprietary/commercial | The closest architectural match to HCP Terraform itself (same remote-operations-backend model) for a team burned by HCP Terraform's free-tier sunset. Direct fetch of its own pricing page this pass: free up to 50 runs/month, Business plan **$0.99/run** with volume discounts, explicitly no per-user/per-resource/SAML charges at any tier |
| **env0** (rebranding to "env zero," rebrand now confirmed live via a 301 redirect from env0.com) (commercial) | Multi-IaC (Terraform, OpenTofu, Terragrunt, Pulumi, CloudFormation) SaaS with built-in FinOps cost tracking, OPA-based policy | Proprietary/commercial | Distinguishing feature is built-in cost/budget tooling and a per-successful-apply/per-environment pricing model — direct fetch of its own (redirected) pricing page this pass confirms both paid tiers are genuinely quote-only, with no public dollar figure published for either, a real gap rather than an oversight in this doc's research |

## Policy-as-code and blast-radius gating

**Sentinel is fully proprietary and Terraform-Cloud/Enterprise-only** —
confirmed, not a licensing gray area the way some tools in sibling docs
are: `hashicorp/sentinel` has no public GitHub repository (returns 404),
and per multiple 2026 comparison sources it "does not work with OpenTofu
at all" — a hard architectural lock-in, not a soft preference, for any
team on OpenTofu rather than Terraform Cloud/Enterprise.

| Library | For | License | Why recommended |
|---|---|---|---|
| **OPA (Open Policy Agent)** (`open-policy-agent/opa`) — default cross-tool policy engine | General-purpose policy engine (Rego) usable identically across Terraform-plan gating, Kubernetes admission control, and CI/CD checks | Apache-2.0 | **CNCF Graduated** (accepted 2018-03-29, graduated 2021-01-29) — the only policy engine here that's both open and portable across IaC + Kubernetes + CI, versus Sentinel's single-vendor lock-in. Direct GitHub fetch: 12,179 stars, 1,667 forks, 337 open issues, pushed 2026-08-28; latest release `v1.20.1` |
| **Conftest** (`open-policy-agent/conftest`) | Runs OPA/Rego policies directly against structured config files (Terraform plan JSON, Kubernetes YAML, Dockerfiles) as a standalone CLI, no server needed | Apache-2.0 (confirmed via direct `LICENSE` fetch — GitHub's metadata API misreports `NOASSERTION`, the same detection artifact this repo's docs flag repeatedly) | The practical "OPA for CI" packaging — the tool a pipeline actually invokes (`conftest test plan.json`) rather than standing up a full OPA server. Direct GitHub fetch: 3,256 stars, 358 forks, 52 open issues, pushed 2026-08-25; latest release `v0.69.0`; same `open-policy-agent` org as OPA itself |
| HashiCorp Sentinel | Policy-as-code embedded in Terraform Cloud/Enterprise's own run pipeline, rich access to plan/state/config data via a purpose-built HSL | Proprietary — no public repo, closed-source, HCP Terraform/Terraform Enterprise-only | **Not recommended for a new OpenTofu-based or multi-tool estate.** Genuinely stronger integration with Terraform Cloud/Enterprise's own plan data than OPA's more general approach, but a hard vendor lock: doesn't run against OpenTofu at all, doesn't apply outside Terraform Cloud/Enterprise. Named because a team already paying for Terraform Cloud/Enterprise gets it "for free," not because it's an open recommendation |
| **Checkov** (`bridgecrewio/checkov`) | Static-analysis policy scanning purpose-built for IaC (Terraform/OpenTofu/CloudFormation/Kubernetes/Helm/Dockerfile/serverless), ships thousands of built-in checks | Apache-2.0 | Overlaps with OPA/Conftest but ships a much larger built-in ruleset out of the box rather than requiring hand-written Rego — the pragmatic choice for broad default coverage (CIS benchmarks, common misconfigurations) rather than a from-scratch custom policy set. Direct GitHub fetch: 8,976 stars, 1,400 forks, 166 open issues, pushed 2026-08-30 (very active); latest release `3.3.16` |

## Secrets management

**HashiCorp Vault underwent the identical BSL/IBM relicensing as
Terraform itself** — confirmed via a direct fetch of `hashicorp/vault`'s
raw `LICENSE` file (not GitHub's metadata API, which misreports it as
`NOASSERTION`): "Licensor: International Business Machines Corporation
(IBM)... Licensed Work: Vault Version 1.15.0 or later," the same BSL 1.1
terms and the same IBM licensor as Terraform's own license. The
OpenTofu-style default-to-the-open-fork calculus applies to secrets
management too, not just IaC provisioning — this is a pattern across
HashiCorp's whole post-acquisition product line, not a one-off.

| Library | For | License | Why recommended |
|---|---|---|---|
| **OpenBao** (`openbao/openbao`) — default for new Vault-shaped secrets infrastructure | Drop-in Vault-API-compatible secrets server — dynamic/short-lived credential issuance, transit encryption, PKI, the same core feature set Vault itself offers | **MPL-2.0**, Linux-Foundation-governed | The direct Vault-side analog to OpenTofu: forked from the last MPL-licensed Vault release specifically in response to the same BSL relicensing event, genuinely OSI-open where Vault itself now isn't. Direct GitHub fetch (re-confirmed this authoring pass): 7,218 stars, 551 forks, 308 open issues, pushed 2026-08-28 |
| **HashiCorp Vault** (`hashicorp/vault`) | The original, still-dominant dedicated secrets-management server — dynamic secrets, transit encryption, PKI, extensive plugin ecosystem | **BSL 1.1** (source-available, not OSI-approved; IBM licensor — see callout above) | The honest incumbent, not the new-project default given its licensing status — the right choice for a team already running Vault in production or invested in Vault Enterprise/HCP Vault, same reasoning as Terraform's own entry above. Direct GitHub fetch (re-confirmed this authoring pass): 36,190 stars, 4,748 forks, 1,431 open issues, pushed 2026-08-28 — still very active despite the licensing shift |
| **External Secrets Operator** (`external-secrets/external-secrets`) | Kubernetes controller that syncs secrets *live* from an external system (Vault, OpenBao, AWS/Azure/GCP secret managers) into native `Secret` objects | Apache-2.0 | The connective-tissue tool between any server in this table and a running Kubernetes workload — a cluster never needs its own copy of the source-of-truth secret, only a synced reference to it. Direct GitHub fetch: 6,819 stars, 1,406 forks, 266 open issues, pushed 2026-08-28 |
| **SOPS** (`getsops/sops`) | Encrypts individual values inside a structured file (YAML/JSON/ENV/INI) via KMS/PGP/age, keeping the file's structure human-readable while values stay ciphertext — safe to commit straight into git | **MPL-2.0** | **CNCF Sandbox** (accepted 2023-05-17; next maturity review scheduled 2026-09-22 per search corroboration) — the standard choice for a GitOps-driven repo that wants secrets living in the same git history as everything else, encrypted rather than absent. Direct GitHub fetch: 22,973 stars, 1,075 forks, 442 open issues, pushed 2026-08-31 (very active) |
| **Sealed Secrets** (`bitnami-labs/sealed-secrets`) | A cluster-side controller one-way-decrypts a git-committed `SealedSecret` CRD into a real Kubernetes `Secret` at apply time — only the cluster's own private key can decrypt it | Apache-2.0 | The Kubernetes-native alternative to SOPS, expressed as a first-class CRD rather than a generic encrypted file format. Worth a maintenance watch, not a hard trap: it lives under the `bitnami-labs` org, and Broadcom's 2025 shift of the broader Bitnami catalog to a paid "Bitnami Secure Images" model was search-corroborated as **not** affecting this specific project's open repo/image publishing — but the org's broader direction is worth monitoring. Direct GitHub fetch: 9,264 stars, 773 forks, 67 open issues, pushed 2026-08-27 |

**Decision rule**: a dedicated secrets server with dynamic/short-lived
credentials → **OpenBao** by default, **Vault** if already invested in
HashiCorp's ecosystem; already on one cloud and wanting zero extra
infrastructure → that cloud's own secret manager (AWS Secrets Manager/
Azure Key Vault/GCP Secret Manager — each a managed service tied to its
own cloud, not independently table-compared here since none is a
licensable product); a GitOps-driven repo wanting secrets encrypted
in-place in git → **SOPS**; a Kubernetes-native equivalent expressed as a
CRD → **Sealed Secrets**; connecting any of the above to a running
cluster → **External Secrets Operator**, which is complementary to,
not competing with, every other row above.

## Kubernetes tooling

Real local precedent applies directly here, not a generic survey:
`ubi-csr-tmf`'s three Helm charts (`charts/agents/`, `charts/ubi-backend/`,
`charts/ubi-frontend/`) each carry a genuine `Chart.yaml`
(`apiVersion: v2`, `type: application`) and separate prod/dev
`values.yaml` files. `charts/ubi-backend/values.yaml` specifically sets
`replicaCount: 2`, real resource requests/limits (`3Gi`/`500m` request,
`4Gi`/`800m` limit), liveness/readiness probes, `autoscaling.enabled:
false` even though HPA templates already exist unused, and leaves
`imagePullSecrets`/`nodeSelector`/`tolerations` commented out as opt-in
scaffolding rather than deleted — a real, reasonably careful Helm-values
file, not a toy example. Its own CI (`azure/setup-helm@v4` pinned to
`version: 'v3.11.1'`) is a genuine two-major-version currency gap against
Helm's current release: a direct `gh api` fetch this pass re-confirms
Helm's latest tag as **`v4.2.4`**. Not a defect in that repo — Helm 3→4 is
a real breaking upgrade many teams delay deliberately — but a concrete,
current illustration of exactly the tooling-currency drift this category
needs to watch for.

| Library | For | License | Why recommended |
|---|---|---|---|
| **Helm** (`helm/helm`) — default templating/package-manager layer | Kubernetes package manager — the templating engine `ubi-csr-tmf`'s own `charts/*/Chart.yaml`+`values*.yaml` structure already uses | Apache-2.0 | **CNCF Graduated** (accepted 2018-06-01, graduated 2020-05-01) — the dominant Kubernetes packaging convention, exactly what real local precedent already uses. Direct GitHub fetch: 30,197 stars, 7,768 forks, 456 open issues, pushed 2026-08-28; latest release **`v4.2.4`** (re-confirmed this authoring pass), a full major version ahead of what `ubi-csr-tmf`'s own CI pins |
| **Kustomize** (`kubernetes-sigs/kustomize`) | Overlay-based, template-free YAML customization (base + per-environment patches) | Apache-2.0 | The declarative alternative to Helm's templating approach — no separate binary install needed since it ships **bundled inside `kubectl` itself** (`kubectl apply -k`, present since Kubernetes 1.14, updated on its own cadence); a `kubernetes-sigs` project, not itself separately CNCF-graduated. Direct GitHub fetch: 12,149 stars, 2,415 forks, 187 open issues, pushed 2026-08-31; latest standalone-CLI release `kustomize/v5.8.1` |
| **Argo CD** (`argoproj/argo-cd`) | Pull-based GitOps continuous-delivery controller with a strong built-in web UI, per-application sync view | Apache-2.0 | **CNCF Graduated** (2022) — the default when a team wants GitOps with a polished out-of-box UI for visualizing sync/drift state per application; the more commonly reached-for of the two GitOps controllers in most current comparisons. Direct GitHub fetch: 24,039 stars, 7,822 forks, 4,433 open issues, pushed 2026-08-31 (very active); latest release `v3.5.2` |
| **Flux** (`fluxcd/flux2`) | Composable GitOps toolkit (source/kustomize/helm/notification controllers as separate pluggable pieces), no bundled UI of its own | Apache-2.0 | **CNCF Graduated** (2022) — the choice for a more composable, controller-per-concern architecture, paired with a separate UI or none at all, rather than Argo CD's more monolithic, UI-first design. Direct GitHub fetch: 8,376 stars, 778 forks, 254 open issues, pushed 2026-08-25; latest release `v2.9.4` |
| **k9s** (`derailed/k9s`) | Terminal UI for navigating/managing live Kubernetes clusters (pods, logs, exec, resource editing) without hand-writing `kubectl` commands | Apache-2.0 | The dominant terminal-based cluster-operator tool — no GUI/Electron overhead, works over SSH, the most-starred tool in this entire table. Direct GitHub fetch: 34,469 stars, 2,265 forks, 94 open issues, pushed 2026-08-29; latest release `v0.51.0` |
| **FreeLens** (`freelensapp/freelens`) | Graphical (Electron) Kubernetes IDE — the actively-maintained continuation for a team wanting a GUI rather than k9s's terminal UI | MIT | Named specifically because the obvious "Lens" answer is now a licensing trap: Mirantis (which acquired Lens) moved Lens Desktop to a commercial, account-gated freemium product, and **OpenLens (the formerly-open core) is now itself unmaintained** — last significant release late 2024. FreeLens is the 2024 community fork created specifically to keep a genuinely open GUI alive; it's the current answer, not "OpenLens." Direct GitHub fetch: 5,498 stars, 325 forks, 218 open issues, pushed **2026-08-30** — vs. `lensapp/lens` itself: MIT license, 23,231 stars, but pushed **2025-02-11**, over 18 months stale, the same "upstream gone quiet, fork is where activity lives" pattern the Developer Tooling & Libraries doc flags for setuptools/bump2version/tower-lsp |

**Decision rule**: templating/packaging a Kubernetes app → **Helm**
(matches real local precedent); pure overlay/patch composition with zero
extra binary → **Kustomize** (already bundled in `kubectl`); GitOps
continuous delivery with a strong built-in UI → **Argo CD**; composable,
UI-agnostic GitOps controller architecture → **Flux**; terminal-based
cluster operations → **k9s**; GUI-based cluster operations → **FreeLens**,
not Lens/OpenLens.

## Container registries and build tooling

`ubi-csr-tmf`'s own pipeline is real local precedent here too, not a
generic survey: `be-deploy-prod.yml` pushes to **Amazon ECR**
(`aws-actions/amazon-ecr-login@v2`) and builds with
`docker/setup-buildx-action@v3` + `docker buildx build
--cache-from/--cache-to type=registry,...,mode=max` — registry-persisted
build cache across CI runs, a genuinely distinctive choice worth naming
rather than a generic "Docker build."

| Library | For | License | Why recommended |
|---|---|---|---|
| **Amazon ECR** | AWS-native container registry — real local precedent's own choice (`ECR_REPOSITORY: csr-tmf-portal/backend`) | N/A — managed AWS service | Zero-friction default when the deploy target is already EKS/AWS, IAM-native auth with no separate registry credential to manage — real local precedent, not a generic pick |
| GHCR (GitHub Container Registry) | Registry co-located with the GitHub Actions CI that builds the image, no separate cloud-provider registry account needed | N/A — managed GitHub service | The right choice when the deploy target isn't tied to one cloud provider's own registry, or for open-source/public images wanting free anonymous pulls |
| Docker Hub | The original, most widely-recognized public registry | N/A — managed service (Docker Inc.) | Named for completeness; anonymous pull-rate limits make it a weaker default for CI-heavy pipelines than ECR/GHCR unless already paying for a Docker Hub plan |
| GCR / Artifact Registry | GCP-native registry (Artifact Registry is GCR's current, actively-developed successor) | N/A — managed GCP service | Named for completeness as the GCP-equivalent of ECR |
| **BuildKit** (`moby/buildkit`) + **Buildx** (`docker/buildx`) | The build engine and its `docker buildx` CLI front-end — exactly what real local precedent uses | Both Apache-2.0 | Real local precedent again: registry-persisted build cache across CI runs is a genuinely distinctive choice worth naming rather than "Docker build" generically. BuildKit direct GitHub fetch: 10,218 stars, 1,501 forks, 914 open issues, pushed 2026-08-31 (very active); Buildx direct GitHub fetch: 4,491 stars, 676 forks, 390 open issues, pushed 2026-08-28 |
| **Cloud Native Buildpacks** (`buildpacks/pack` CLI) | Builds container images directly from source with no hand-written Dockerfile, auto-detecting language/runtime | Apache-2.0 | **CNCF Graduated 2026-08-11** — freshly graduated as of this pass; CNCF's own announcement cites 535 contributors across 164 organizations, 20+ adopters (DigitalOcean, GitLab, Google, HashiCorp, Spring, VMware), and a concrete production result (a 500+-application estate cutting vulnerability-patch turnaround from weeks to hours via centralized buildpack updates). The right choice for eliminating hand-maintained Dockerfiles entirely and standardizing base-image patching centrally — not a fit for `ubi-csr-tmf`'s own hand-written multi-stage Dockerfiles, named here as the current alternative philosophy. Direct GitHub fetch: 2,992 stars, 360 forks, 192 open issues, pushed 2026-08-19; latest release `v0.40.9` |

## Internal developer platform (IDP) tooling

| Library | For | License | Why recommended |
|---|---|---|---|
| **Backstage** (`backstage/backstage`) — dominant open default | Spotify-originated developer portal / software catalog — service ownership, docs, scaffolding templates, plugin ecosystem | Apache-2.0 | **CNCF Incubating** (accepted 2020-09-08, moved to Incubating 2022-03-15) — **not yet Graduated**, a real, current distinction worth stating rather than assuming graduated status the way Helm/OPA/Argo/Flux/Buildpacks all now are; still the dominant open-source developer-portal choice by a wide margin on every adoption signal fetched. Direct GitHub fetch: 34,277 stars, 7,595 forks, 436 open issues, pushed 2026-08-30 (very active); latest release `v1.54.6` |
| Port (commercial) | Managed (SaaS) developer-portal alternative, positioned as the low-setup-overhead option | Proprietary/commercial | The pragmatic choice for a small/mid-size team that wants Backstage's cataloging value without running/maintaining a Backstage instance themselves |
| Cortex / OpsLevel (commercial) | Scorecard-driven service-maturity/ownership platforms (SLOs, runbook checks, security-scan gates surfaced as org-wide compliance scores) | Proprietary/commercial | A materially different value proposition from Backstage's catalog-first model — a distinct category ("maturity scorecards as the product"), not a like-for-like Backstage substitute |
| Spotify Portal for Backstage / Roadie (commercial) | Managed-hosting distributions of Backstage itself (same open-source core, hosted/operated by a vendor) | Backstage core remains Apache-2.0; the hosting/management layer is commercial | The right pick for a team that wants Backstage's actual data model/plugin ecosystem specifically, without operating the instance itself |

## CI/CD-layer add-ons for IaC/platform work

GitHub Actions is already the de facto default confirmed directly in
`ubi-csr-tmf`'s own 12 workflow files — this section names what needs
layering **on top of** it specifically for IaC/Kubernetes work. That same
repo is also the concrete evidence for why this section matters: grepping
all 12 workflow files for `trivy|checkov|tflint|terraform|kubeval|helm
lint|snyk|grype|cosign|sbom|provenance|opa|conftest|sentinel` turns up
**zero real hits** — the only match is the coincidentally-named
`GitHubActionsTerraformRole` string. No `helm lint`, no image
vulnerability scan, no IaC policy gate exists in that pipeline today. That
is a real, concrete gap against every tool named below, not a
hypothetical one — the fix is a one-line addition
(`trivy config .`/`trivy image ...`) to an existing workflow, not a new
pipeline.

| Library | For | License | Why recommended |
|---|---|---|---|
| **terraform-docs** (`terraform-docs/terraform-docs`) | Auto-generates a Terraform/OpenTofu module's README documentation (inputs/outputs/providers) directly from its `.tf` source | MIT | The standard "keep module docs from rotting out of sync with actual variables" tool. Direct GitHub fetch: 4,817 stars, 602 forks, 191 open issues, pushed 2026-08-03 (~4 weeks stale relative to this pass, worth a light flag though not alarming); latest release `v0.24.0` |
| **tflint** (`terraform-linters/tflint`) | Terraform/OpenTofu-specific linter — catches provider-specific errors and deprecated syntax `terraform validate` itself doesn't check | MPL-2.0 | The standard pre-plan linting gate; plugin architecture supports AWS/Azure/GCP provider-specific rulesets beyond generic HCL syntax checking. Direct GitHub fetch: 5,798 stars, 407 forks, 30 open issues, pushed 2026-08-29; latest release `v0.64.0` |
| **Trivy** (`aquasecurity/trivy`) — default for IaC/container/Kubernetes-manifest scanning | All-in-one vulnerability + misconfiguration scanner: container images, IaC files (Terraform/CloudFormation/Kubernetes/Dockerfile), and SBOM generation, in one CLI | Apache-2.0 | The consolidated current recommendation — see the deprecation callout below for why this supersedes tfsec specifically; directly closes `ubi-csr-tmf`'s own no-scan-step gap above. Direct GitHub fetch: 37,703 stars, 642 forks, 259 open issues, pushed 2026-08-28 (very active); latest release re-confirmed this authoring pass: `v0.74.0` |
| tfsec (`aquasecurity/tfsec`) — **deprecated, not a recommendation** | Terraform-specific security scanner | MIT | **Do not adopt for new pipelines.** Aqua Security's own position, confirmed across multiple 2026 sources: "tfsec is now part of Trivy" — all 1,000+ tfsec checks were merged into Trivy's IaC-scanning mode in 2024, migration is a one-line swap (`tfsec .` → `trivy config .`, check IDs like `AVD-AWS-0086` carry over unchanged), and no new features are landing in tfsec itself. Direct GitHub fetch: 7,034 stars, 560 forks, 18 open issues, **pushed 2026-03-25** — over 5 months stale relative to this pass, consistent with the confirmed-deprecated status |
| **Checkov** (`bridgecrewio/checkov`) | Broad-ruleset IaC/Kubernetes/Dockerfile scanner (see also Policy-as-code above) | Apache-2.0 | Repeated here because it's equally a CI-layer add-on choice as a policy-engine choice — a scanner and a policy gate are often the same tool in this category. See Policy-as-code above for full signal |

## Where this doc stops

A full multi-cloud provider-API survey (AWS/Azure/GCP SDK specifics,
provider-specific Terraform resource coverage) is out of scope — this doc
covers the tooling layer that provisions/deploys, not the cloud-provider
API surface each tool then targets. Configuration-management tools
(Ansible, Chef, Puppet, SaltStack) are a genuinely adjacent but distinct
concern — mutable-server configuration versus this category's
idempotent-provisioning/orchestration focus — named only where
Spacelift/env0 list Ansible as one of their own supported IaC types, not
independently researched here. Full observability/monitoring-stack
tooling (Prometheus, Grafana, Datadog) is a downstream operational
concern once infrastructure exists, not itself an infrastructure or
platform-tooling choice. Deep secrets-engine internals (Vault/OpenBao's
dynamic-secret-backend plugin mechanics, transit-encryption key-rotation
internals) are out of scope beyond the tool-selection depth in the
Secrets management section above. Service-mesh tooling (Istio, Linkerd,
Cilium) is a Kubernetes-adjacent but functionally distinct
networking-layer concern from this doc's IaC/deployment/policy focus. A
deeper OpenTofu-vs-Terraform provider-by-provider compatibility audit —
beyond OpenTofu's own headline feature/governance claims, confirmed via
its own site — was not attempted; some comparison sites cite compatibility
percentages this doc did not independently verify.

## Sources

- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license,
  stars, forks, open issues, `pushed_at`, `archived`) for: hashicorp/
  terraform, opentofu/opentofu, pulumi/pulumi, aws/aws-cdk, hashicorp/
  terraform-cdk, open-policy-agent/opa, open-policy-agent/conftest,
  helm/helm, kubernetes-sigs/kustomize, argoproj/argo-cd, fluxcd/flux2,
  derailed/k9s, backstage/backstage, terraform-docs/terraform-docs,
  terraform-linters/tflint, bridgecrewio/checkov, aquasecurity/trivy,
  aquasecurity/tfsec, moby/buildkit, docker/buildx, buildpacks/pack,
  lensapp/lens, freelensapp/freelens, runatlantis/atlantis,
  hashicorp/vault, openbao/openbao, external-secrets/external-secrets,
  getsops/sops, bitnami-labs/sealed-secrets — retrieved 2026-08-31.
- **Second-pass re-verification during this authoring pass (2026-08-31)**:
  direct `gh api` re-fetch of opentofu/opentofu (29,985 stars vs. the
  baseline's 29,984), openbao/openbao (7,218 vs. 7,217), hashicorp/vault
  (36,190, unchanged), helm/helm's and aquasecurity/trivy's
  `releases/latest` (`v4.2.4` and `v0.74.0`, both unchanged) — small
  enough drift to confirm the figures are live and reproducible, not
  stale carry-forward, the same confirmation pattern used in the
  Developer Tooling & Libraries doc's own authoring pass.
- `gh api repos/<owner>/<repo>/releases/latest` direct fetches for
  current version tags: terraform, opentofu, pulumi, helm, argo-cd,
  flux2, opa, conftest, kustomize, checkov, trivy, tflint, terraform-docs,
  k9s, backstage, pack, atlantis — retrieved 2026-08-31.
- `https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE` and
  `https://raw.githubusercontent.com/hashicorp/vault/main/LICENSE` —
  direct fetches confirming BSL 1.1 text, version scoping, IBM licensor,
  and the four-year-per-release MPL conversion clause on both — retrieved
  2026-08-31.
- `https://raw.githubusercontent.com/open-policy-agent/conftest/master/LICENSE`
  — direct fetch confirming Apache-2.0 (correcting GitHub metadata API's
  `NOASSERTION` misreport) — retrieved 2026-08-31.
- `https://opentofu.org/` — direct fetch: Linux Foundation governance
  claim, 3,900+ providers/23,600+ modules figures, sponsor list, feature
  list versus Terraform — retrieved 2026-08-31.
- `https://raw.githubusercontent.com/opentofu/opentofu/main/CHANGELOG.md`
  and `gh api repos/opentofu/opentofu/releases` — direct fetch resolving
  the baseline's open question on OpenTofu/Terraform S3-lockfile parity:
  confirms v1.10.0 shipped "Native S3 Locking" with the identical
  `use_lockfile = true` parameter — retrieved 2026-08-31.
- `https://www.hashicorp.com/en/products/terraform/pricing` — direct
  fetch confirming the Essentials/Standard/Premium per-resource pricing
  tiers and an FAQ acknowledging a free tier's existence — retrieved
  2026-08-31.
- **New this authoring pass**: direct fetches of
  `https://spacelift.io/pricing`, `https://www.scalr.com/pricing`, and
  `https://www.env0.com/pricing` (301-redirects to
  `https://www.envzero.com/pricing`) — surfaced a real correction to
  Spacelift's baseline pricing estimate ($20,000/year Starter+ tier, not
  ~$250/month), confirmed Scalr's per-run/no-governance-upcharge model as
  stated, and confirmed env0/envzero's paid tiers are genuinely
  quote-only with no public dollar figure — retrieved 2026-08-31.
- `https://www.cncf.io/announcements/2026/08/11/cncf-announces-graduation-of-cloud-native-buildpacks-advancing-the-standard-for-container-builds/`
  — direct fetch confirming the 2026-08-11 graduation date, contributor/
  adopter figures, and OpenSSF badge — retrieved 2026-08-31.
- Local file reads (all 2026-08-31): `/Users/devopammittra/GitHub/
  ubi-csr-tmf/charts/{agents,ubi-backend,ubi-frontend}/{Chart.yaml,
  values.yaml,values-dev.yaml}`, `.github/workflows/{be-deploy-prod.yml,
  ci-cd.yml,build-validation.yml}` in full, plus a grep across all 12
  `.github/workflows/*.yml*` files for security/lint-tool mentions;
  confirmed absence of any `.tf`/Dockerfile-adjacent Terraform/Pulumi/CDK/
  CloudFormation file anywhere in that repo.
- WebSearch corroboration (not independently direct-fetched primary
  source, flagged inline where used): Terraform/IBM BSL licensing-history
  narrative; CDKTF archival announcement and reasoning; tfsec→Trivy
  deprecation; Lens/OpenLens/FreeLens status; S3 native locking/DynamoDB
  deprecation timeline; HCP Terraform free-tier EOL historical dates
  (scalr.com's own learning-center page, the single most load-bearing of
  these citations given the concrete dates it provides); Sentinel-vs-OPA
  positioning and OpenTofu incompatibility; Backstage-alternatives
  landscape; CNCF graduation-status roundup for Argo/Flux/OPA/Helm/
  Backstage; kubectl's bundled Kustomize status; SOPS's CNCF Sandbox
  status; Sealed Secrets' immunity to the Bitnami-catalog paid-image
  shift — all retrieved 2026-08-31.
