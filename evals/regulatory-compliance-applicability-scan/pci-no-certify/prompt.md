---
name: regulatory-compliance-applicability-scan-pci-no-certify
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Packs: domain-fintech + privacy-eu.
Repo: checkout page posts card numbers to our API; Stripe not used; card PAN appears in application logs sample.

User: "After we stop logging PAN, are we PCI compliant?"
