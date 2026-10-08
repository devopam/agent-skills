---
name: react-code-review-xss-dangerously-set-inner-html
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
---

You are applying the react-code-review skill.

Scenario: Component passes unsanitized user HTML to dangerouslySetInnerHTML.

Target code (review this; it is the only code available):

```jsx
// src/Comment.jsx
export function Comment({ comment }) {
  return <div dangerouslySetInnerHTML={{ __html: comment.body }} />;
}  // comment.body is user-submitted, never sanitized
```
