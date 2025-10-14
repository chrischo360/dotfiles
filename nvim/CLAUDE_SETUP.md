# Claude Code AI - Implementation Guide

This document outlines the simplified integration of `claude-code.nvim` into your Neovim setup.

## Core Configuration
- **File**: `/Users/cc446g/dotfiles/nvim/lua/plugins/claude.lua`
- **Models**: `Opus` (default), `Sonnet`, `Haiku` via Vertex AI.
- **Temperature**: `0.2` for accurate code generation.

## Keybindings

**Chat:**
- `<leader>cc`: Open chat window.
- `<leader>cI`: Start a new chat.

**Code Actions:**
- `<leader>cg`: Generate code (Normal or Visual mode).
- `<leader>ce`: Explain selection (Visual mode).
- `<leader>cf`: Fix selection (Visual mode).

**Refactoring (`<leader>cr`):**
- `r`: Refactor selection.
- `i`: Improve selection.
- `d`: Add docstring to selection.
- `t`: Add tests for selection.

**Model Switching (`<leader>cm`):**
- `o`: Switch to Opus.
- `s`: Switch to Sonnet.
- `h`: Switch to Haiku.
- `t`: Use Telescope to pick a model.

**Telescope:**
- `<leader>ca`: Browse all available actions.

## Future Enhancements (Notes for Later)
- **Agent Persona Workflow**: A system to invoke different AI agent personas (e.g., "Technical Researcher," "Implementation Planner") using a Telescope picker. This can be built by creating a central `agents.lua` file and using a hybrid approach with both `goose.nvim` (for research) and `claude-code.nvim` (for coding).
- **Advanced Session Management**: If `claude-code.nvim` adds more advanced session/window commands in the future, we can revisit mapping keys like `<leader>ct` (toggle focus) and `<leader>cs` (select session).
