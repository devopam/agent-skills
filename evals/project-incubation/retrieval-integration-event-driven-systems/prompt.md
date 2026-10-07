---
name: project-incubation-retrieval-integration-event-driven-systems
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

New repo for a system that listens for order events from our e-commerce
platform and fans them out to billing, shipping, and analytics — each of
those needs to know independently when an order is placed. We also need
to send webhooks to a couple of partner companies when certain things
happen. No real UI here, this is all backend plumbing between systems.

What's the right setup?
