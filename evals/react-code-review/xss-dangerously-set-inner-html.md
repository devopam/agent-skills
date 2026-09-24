# Eval: XSS via dangerouslySetInnerHTML

## Setup
Component passes unsanitized user HTML to dangerouslySetInnerHTML.

## Expected
- Critical or Important security finding
- Mentions XSS risk

## Fail if
- No security finding on that pattern
