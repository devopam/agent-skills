---
name: react-code-review-stale-fetch-race
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the react-code-review skill.

Scenario: useEffect fetch sets state without abort/stale guard when deps change quickly.

Target code (review this; it is the only code available):

```jsx
// src/Results.jsx
function Results({ query }) {
  const [rows, setRows] = useState([]);
  useEffect(() => {
    fetch(`/api/search?q=${query}`).then(r => r.json()).then(setRows);
  }, [query]);
  return <List rows={rows} />;
}
```
