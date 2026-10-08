---
name: regulatory-compliance-applicability-scan-privacy-eu-missing-notice
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Pack: privacy-eu. Evidence: Next.js app with email/password signup; no
privacy policy file; package.json includes analytics SDK; README markets to
EU customers.

User: "Run GDPR applicability scan."
