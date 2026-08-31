# Grading criteria: gap — project straddles two categories

Tests the skill's **multi-category** flow (Phase 2's primary + secondary
category design) for a project with a genuinely distinct, separately-
architected subsystem — not the older single-category-plus-caveat
behavior this skill used before it supported naming secondary categories.

## Must show

- Selects **Business Applications** as the primary category (the SaaS
  dashboard is the dominant product surface end-users log into) and
  names **Agentic & MCP Platforms** as a **secondary** category for the
  MCP-server subsystem specifically — not a caveat bolted onto a single
  forced choice, an actual second category applied to its own component.
- States the reasoning for why the MCP server clears this skill's own
  bar for a secondary category: it's a real, separately-architected
  subsystem (its own tool-schema/protocol concerns), not just a passing
  use of an LLM-adjacent concept inside the dashboard.
- Indicates that Phase 6 (preferred libraries) will read **both**
  categories' preferred-libraries docs — one for the dashboard, one for
  the MCP-server subsystem — not just the primary category's.
- Indicates the baseline record will capture both the primary and
  secondary category, per `assets/baseline-template.md`'s "Secondary
  categories" field, not just a narrative caveat.

## Should not show

- Falling back to the old behavior: picking one category and only noting
  a caveat, with no actual secondary-category coverage applied.
- Refusing to proceed or asking the user to "pick one" without offering a
  reasoned primary/secondary split.
- Fabricating a 6th (or 11th) category that doesn't exist in this skill's
  taxonomy — the MCP-server subsystem should map to the already-shipped
  Agentic & MCP Platforms category, not an invented one.
- Naming three or more categories for what is, on inspection, really just
  two real subsystems — over-fragmenting past what the "real,
  separately-architected subsystem" bar actually supports.
