---
name: react-code-review
description: >
  Review frontend React code for code quality, performance, and business logic
  issues. Follows structured checklists with urgency metadata and templated
  output. Use when the user requests a review of .tsx, .ts, or .js files, or
  before committing frontend changes.
---

# React Code Review

## Intent

Use this skill whenever the user asks to review frontend code (especially `.tsx`, `.ts`, or `.js` files). Two review modes:

1. **Pending-change review** — inspect staged/working-tree files slated for commit and flag checklist violations before submission.
2. **File-targeted review** — review the specific file(s) the user names and report the relevant checklist findings.

## Checklist

The following existing skills serve as the canonical rule set per category. Load the relevant one during review:

- **Code quality** — `composition-patterns`, `react-elm-architecture`
- **Performance** — `react-render-optimization`, `react-bundle-optimization`
- **Business logic / data** — `react-data-fetching`, `react-elm-architecture`

Flag each rule violation with urgency metadata (`urgent` / `suggestion`) so the reviewer can prioritize.

## Review Process

1. Open the relevant component/module. Gather lines that relate to class names, React Flow hooks, prop memoization, and styling.
2. For each rule in the review point, note where the code deviates and capture a representative snippet.
3. Compose the review per the template below. Group violations first by urgency, then by category order (Code Quality, Performance, Business Logic).

## Required output

When invoked, the response must follow one of the two templates:

### Template A (any findings)

# Code review
Found <N> urgent issues need to be fixed:

## 1 <brief description of bug>
FilePath: <path> line <line>
<relevant code snippet or pointer>

### Suggested fix
<brief description of suggested fix>

---
... (repeat for each urgent issue) ...

Found <M> suggestions for improvement:

## 1 <brief description of suggestion>
FilePath: <path> line <line>
<relevant code snippet or pointer>

### Suggested fix
<brief description of suggested fix>

---
... (repeat for each suggestion) ...

If no urgent issues, omit that section. If no suggestions, omit that section.

If issue count > 10, summarize as "10+ urgent issues" or "10+ suggestions" and output only the first 10.

If Template A is used and at least one issue requires code changes, append a follow-up question: "Would you like me to use the Suggested fix section to address these issues?"

### Template B (no issues)

## Code review
No issues found.

