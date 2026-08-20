# Grading criteria: retrieval — Business Applications

Tests whether `project-incubation` picks the right category for a
multi-tenant B2B SaaS product and applies the multi-tenancy decision rule
correctly — a small number of paying customers to start should point at
the shared-schema + RLS default, not a heavier isolation pattern.

## Must show

- Selects **Business Applications** as the category.
- Recommends **modular monolith** as the default starting architecture
  (not microservices) for a small team at this stage.
- Recommends **shared-schema multi-tenancy with Postgres Row-Level
  Security** as the default enforcement mechanism, stated as the
  opinionated default (not hedged as "one of three equal options") —
  reserving schema-per-tenant/database-per-tenant for a stated compliance
  or scale forcing function this scenario doesn't have.
- If auth comes up: distinguishes RBAC as the starting default from
  ABAC, rather than jumping straight to a complex permission system for a
  small early-stage team.

## Should not show

- Recommending database-per-tenant or schema-per-tenant as the default
  for a handful of customers with no stated compliance/scale forcing
  function.
- Recommending microservices as the starting architecture.
- Routing this to Backend & API Services (this project owns a UI
  end-users interact with directly, which is the Business Applications
  distinguishing signal).
