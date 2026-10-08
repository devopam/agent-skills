---
name: ui-system-review-evidence-required-no-invent
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

User: "Audit UI system consistency for this repo."

Available evidence is thin: only `package.json` shows `react` and
`tailwindcss`. No feature UI files were provided in context yet.

The agent has not searched the tree beyond the manifest.
