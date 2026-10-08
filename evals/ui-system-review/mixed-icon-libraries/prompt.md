---
name: ui-system-review-mixed-icon-libraries
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Web pack confirmed. Evidence:

- Dependencies include `lucide-react`, `@heroicons/react`, and
  `@mui/icons-material`.
- No doc stating when to use which set.
- Screens import icons from all three interchangeably.

User: "Review icon usage as part of UI system audit."

The project to review is in the current working directory.
