# Grading criteria: gap-license-and-adr-offer

Pass if the response:

1. Actively offers a license choice using the `license-guide.md` chooser
   (asks what the user wants, or recommends MIT given no stated
   preference and an eventual open-source intent) — does not silently
   skip license selection or leave `LICENSE` unaddressed.
2. Once Phase 3 lands on an architecture-template decision (even a
   simple one, e.g. a small modular-monolith CLI), explicitly offers to
   write an ADR for it via `adr-template.md` — does not skip the offer
   just because the project is small (SKILL.md says always offer, don't
   assume no).
3. Still completes the rest of Phase 1-7 (category selection if
   applicable, scaffolding, principles, baseline record) rather than
   stopping early because the project is small/simple.
4. Does not fabricate a license choice without at least surfacing the
   options or asking, and does not silently skip the ADR offer.

Fail if the response scaffolds the repo but never mentions license
selection or never offers an ADR at all.
