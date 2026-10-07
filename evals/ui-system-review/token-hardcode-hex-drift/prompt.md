---
name: ui-system-review-token-hardcode-hex-drift
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Web pack confirmed. Evidence from the tree:

- `src/theme/tokens.css` defines `--color-primary` and a spacing scale.
- Product UI under `src/features/**` contains many `#3B82F6`, `#fff`, and
  `padding: 13px` / `margin: 7px` literals instead of tokens.
- User: "Audit UI consistency."

Produce findings and scores focused on tokens/theme.

The project to review is in the current working directory.
