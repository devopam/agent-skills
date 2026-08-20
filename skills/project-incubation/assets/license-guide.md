# License Guide

A chooser table for the LICENSE file `project-incubation` scaffolds at
inception, plus links to canonical text — not vendored license text
itself. Deciding *which* license and understanding its practical
obligations is the architectural decision; the legal text belongs to the
license's own canonical source, not a copy that can drift out of sync with
the real thing.

**This is not legal advice.** For anything beyond a straightforward
open-source project (dual-licensing, patent grants that matter, a
regulated industry), get real legal review before publishing a LICENSE
file.

## Chooser table

| License | When to use it | Key obligations | Canonical text |
|---|---|---|---|
| **MIT** | Default for most new open-source projects — maximum adoption, minimal friction. Good when you want the code used as widely as possible with no strings attached. | Keep the copyright notice and license text in copies/substantial portions. That's essentially it — no copyleft, no patent clause. | [opensource.org/license/mit](https://opensource.org/license/mit) |
| **Apache-2.0** | Like MIT, but you want an explicit patent grant (contributors grant patent rights, and the license terminates if someone sues over patents) — common for projects with real patent exposure, or that want NOTICE-file attribution tracking. | Same permissive baseline as MIT, plus: preserve NOTICE file content if one exists; state significant changes to modified files. | [apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0) |
| **BSD-3-Clause** | Similar permissiveness to MIT, common in academic/research-adjacent and some infrastructure projects (this is what several libraries cited across this skill's own reference docs use, e.g. pandas). | Copyright notice preserved; adds a non-endorsement clause (can't use the contributors'/organization's name to promote derived products without permission). | [opensource.org/license/bsd-3-clause](https://opensource.org/license/bsd-3-clause) |
| **MPL-2.0** | Weak/file-level copyleft — want modifications to the licensed files themselves shared back, but are fine with those files being combined with proprietary code in a larger work (unlike GPL). A middle ground between MIT/Apache and full copyleft. | Any modified *MPL-licensed files* you distribute must stay MPL and have source available. Files you add that aren't modifications of MPL code can be under any license. | [mozilla.org/MPL/2.0](https://www.mozilla.org/en-US/MPL/2.0/) |
| **GPL-3.0** | Strong copyleft — you want any distributed derivative work (not just modified files) to also be GPL and source-available. Common for end-user applications where you want to prevent proprietary forks. | Distributing a derivative work requires releasing its complete source under GPL-3.0 too. Does not extend over a network by itself (see AGPL). | [gnu.org/licenses/gpl-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html) |
| **AGPL-3.0** | Strong copyleft that also covers network use — you want a hosted/SaaS version of a derivative work to also trigger source disclosure, not just a distributed binary. Common for infrastructure software the author doesn't want re-hosted as a competing service without reciprocity. | Same as GPL-3.0, plus: offering the software (or a modified version) as a network service triggers the same source-disclosure obligation as distribution would. **Real practical bite**: internal-only self-hosting typically doesn't trigger this; modifying-and-offering-as-an-external-service does. | [gnu.org/licenses/agpl-3.0](https://www.gnu.org/licenses/agpl-3.0.en.html) |
| **Unlicense / CC0** | True public domain dedication — no attribution required at all, not even a copyright notice. Rare in practice; most projects that want "basically no restrictions" still pick MIT for its clearer legal footing across jurisdictions where public-domain dedication is ambiguous. | None. | [unlicense.org](https://unlicense.org/) · [creativecommons.org/publicdomain/zero/1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Proprietary / All rights reserved** | Closed-source by default — no LICENSE file, or an explicit "all rights reserved" notice. The right choice for internal tooling or a commercial product with no open-source intent. | No one may copy, modify, or distribute without explicit permission. | N/A — no canonical open-source text; consult legal counsel for actual terms. |

## Decision shortcut

- **"I want maximum adoption, no strings attached"** → MIT (or Apache-2.0 if patent exposure is a real concern).
- **"I want modifications shared back, but proprietary combination is fine"** → MPL-2.0.
- **"I want any derivative — including a hosted version — to stay open"** → AGPL-3.0.
- **"I want derivatives open, but don't care about network use specifically"** → GPL-3.0.
- **"This isn't open source"** → Proprietary/all rights reserved; skip this guide, get real legal terms.

For a fuller interactive chooser, [choosealicense.com](https://choosealicense.com/) covers the same ground with additional edge cases (Boost, Unlicense variants, dual-licensing).
