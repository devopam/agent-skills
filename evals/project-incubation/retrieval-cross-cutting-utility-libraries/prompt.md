---
name: project-incubation-retrieval-cross-cutting-utility-libraries
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm building a new backend service (Python, FastAPI) that exposes a REST
API. Two things it needs to do internally: (1) call a couple of flaky
third-party APIs, so it needs to retry failed calls sensibly instead of
giving up immediately; (2) once a day, pull a report file that could be
anywhere from a few MB to a few GB and produce a cleaned-up CSV export
from it.

What should I use for the retry logic and for the report-processing step,
and why?

(Non-interactive run: you cannot ask follow-up questions. State your assumptions, then complete the skill's flow as far as it can go without user input, including the category you select and your concrete recommendations.)
