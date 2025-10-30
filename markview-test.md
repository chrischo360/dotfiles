# Markview Test Document

This is a test file to verify markview.nvim functionality.

## Features to Test

### 1. Headings
Different heading levels should render with visual hierarchy.

### 2. Text Formatting

**Bold text** and *italic text* and ***bold italic***.

Inline `code snippets` should be highlighted.

### 3. Lists

Unordered list:
- First item
- Second item
  - Nested item
  - Another nested item
- Third item

Ordered list:
1. First step
2. Second step
3. Third step

### 4. Checkboxes

- [ ] Incomplete task
- [x] Completed task
- [ ] Another incomplete task

### 5. Code Blocks

```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
  return true;
}
```

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

### 6. Blockquotes

> This is a blockquote.
> It can span multiple lines.
>
> And have multiple paragraphs.

### 7. Tables

| Feature | Status | Priority |
|---------|--------|----------|
| Preview | ✓      | High     |
| Hybrid  | ✓      | High     |
| Tables  | ?      | Medium   |

### 8. Links

[Neovim](https://neovim.io) is awesome!

### 9. Horizontal Rule

---

## Testing Instructions

1. Open this file in neovim
2. Press `<leader>mp` to toggle preview
3. Try entering insert mode (should show hybrid preview)
4. Check if all elements render correctly

---

**Last updated**: 2025-10-30
