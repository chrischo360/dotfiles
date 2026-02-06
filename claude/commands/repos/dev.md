---
description: Show available dev commands for current repository
---

Get context on available development commands for this repository.

Run this command to discover what's available:

```bash
dev :docs
```

This outputs LLM-friendly markdown documentation including:
- Available commands for the current context
- Multi-step scripts (like `dev :run setup`, `dev :run pr:check`)
- Clean commands and their effects
- Usage tips

## Quick Reference

**Common commands:**
- `dev build` - Build the project
- `dev rebuild` - Quick rebuild (codegen + lib:build)
- `dev start` - Start dev server (context-aware)
- `dev lint` / `dev format` / `dev typecheck` / `dev test` - Code quality
- `dev clean:all` - Full clean

**Multi-step scripts:**
- `dev :run setup` - Full setup (install + codegen + build + start)
- `dev :run quick` - Quick rebuild (codegen + build)
- `dev :run fullreset` - Clean everything and rebuild
- `dev :run pr:check` - Pre-PR checks (format + lint + typecheck + build + test)

**Meta commands:**
- `dev :list` - List available commands
- `dev :scripts` - List available scripts
- `dev :info` - Show project detection info

After running `dev :docs`, use the appropriate commands based on the task.
