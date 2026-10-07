---
name: project-incubation-retrieval-ml-model-development
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

We want to adapt an existing open-weight 7B language model to our own
support-ticket data so it picks up our internal terminology. We have a
single A100 GPU and a modest budget — no interest in training anything
from scratch. We also want to be able to answer "which exact dataset and
hyperparameters produced this checkpoint" months later when someone asks.

Help me set this repo up properly.
