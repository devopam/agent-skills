# Testing (React)

## Checks
1. React Testing Library for components (prefer user-centric queries).
2. Hooks tested where complex.
3. E2E (Playwright/Cypress) for critical flows (web+).
4. a11y checks in CI optional but valued.
5. MSW or equivalent for API mocking.

## Critical
- No component or E2E tests for a non-trivial production UI (enterprise).

## Important
- Enzyme-era patterns; testing implementation details only.
