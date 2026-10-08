---
name: react-code-review-hooks-exhaustive-deps-disabled
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the react-code-review skill.

Scenario: ESLint config turns off `react-hooks/exhaustive-deps` for the whole project, tier=web.

Target code (review this; it is the only code available):

```json
// .eslintrc.json
{ "extends": ["react-app"], "rules": { "react-hooks/exhaustive-deps": "off" } }
// src/Profile.jsx
useEffect(() => { load(userId); }, []);
```
