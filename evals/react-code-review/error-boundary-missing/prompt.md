---
name: react-code-review-error-boundary-missing
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the react-code-review skill.

Scenario: Multi-route React app, no error boundary components, tier=web.

Target code (review this; it is the only code available):

```jsx
// src/App.jsx
export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/billing" element={<Billing />} />
      <Route path="/settings" element={<Settings />} />
    </Routes>
  );
}  // no ErrorBoundary component anywhere in src/
```
