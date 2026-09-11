Web pack confirmed. Evidence from the tree:

- `src/theme/tokens.css` defines `--color-primary` and a spacing scale.
- Product UI under `src/features/**` contains many `#3B82F6`, `#fff`, and
  `padding: 13px` / `margin: 7px` literals instead of tokens.
- User: "Audit UI consistency."

Produce findings and scores focused on tokens/theme.
