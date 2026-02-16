# buffers

**Skill:** `global:buffers`
**Type:** Global Command

## Purpose

Intelligently fetch relevant files from Neovim's tracked buffers based on the current conversation.

## Uses

- Neovim RPC
- Shell scripts in `~/dotfiles/claude/scripts/utils/`

## Used By

- User invoked when working with Neovim

## Workflow

1. Connect to Neovim instance
2. Get list of open buffers
3. Filter relevant buffers
4. Fetch buffer contents
5. Return to Claude for context

## Related Commands

None (standalone utility)

## Tags

#global #neovim #utility #context-gathering
