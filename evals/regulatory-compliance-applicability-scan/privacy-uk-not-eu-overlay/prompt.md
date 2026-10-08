---
name: regulatory-compliance-applicability-scan-privacy-uk-not-eu-overlay
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

User: "We only have UK customers. Run the EU GDPR pack."
Runnable: privacy-uk and privacy-eu both exist.

Simulate intake / pack suggestion.
