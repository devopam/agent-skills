I'm building a new backend service (Python, FastAPI) that exposes a REST
API. Two things it needs to do internally: (1) call a couple of flaky
third-party APIs, so it needs to retry failed calls sensibly instead of
giving up immediately; (2) once a day, pull a report file that could be
anywhere from a few MB to a few GB and produce a cleaned-up CSV export
from it.

What should I use for the retry logic and for the report-processing step,
and why?
