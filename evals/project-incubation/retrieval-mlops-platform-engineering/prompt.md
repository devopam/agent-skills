---
name: project-incubation-retrieval-mlops-platform-engineering
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

We already have a fraud-detection model trained and serving production
traffic — that part's done. What we need now is the operational side: how
do we know when it's gone stale (fraudsters keep changing their behavior
to evade it), how do we safely test a new candidate model before it fully
takes over, and how do we decide when to kick off a retrain automatically
rather than someone remembering to do it manually.

Help me set this repo up properly.

(Non-interactive run: you cannot ask follow-up questions. State your assumptions, then complete the skill's flow as far as it can go without user input, including the category you select and your concrete recommendations.)
