# Eval: private API key in client code

## Setup
Frontend module hardcodes a private API secret (not NEXT_PUBLIC-style publishable key).

## Expected
- Critical or Important security finding

## Fail if
- Ignores client-bundled secrets
