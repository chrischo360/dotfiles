# Neovim

Config: `~/dotfiles/nvim/` → `~/.config/nvim/`

Live docs: `:help <topic>` inside nvim | `nvim --help`

## Leader Key

- `<leader>` = `Space`
- `<localleader>` = `\\`

## Plugin Manager

**lazy.nvim** — config at `nvim/lua/config/lazy.lua`

Lock file: `nvim/lazy-lock.json`

## Plugins

| Plugin | Purpose | Key binding |
|--------|---------|-------------|
| bufferin.nvim | Buffer list/switcher | `<leader>b` |
| Comment.nvim | Smart commenting | `gcc` line, `gc` visual, `gbc` block |
| conform.nvim | Formatting | `<leader>F` |
| diffview.nvim | Git diff/history viewer | — |
| git-conflict.nvim | Conflict resolution | — |
| hardtime.nvim | Bad habit prevention | — |
| harpoon | File bookmarks | — |
| jira.nvim | Jira integration | — |
| lsp | LSP config (tsserver, lua_ls, etc.) | — |
| lualine | Statusline | — |
| mini.nvim | Collection of small utilities | — |
| neo-tree.nvim | File explorer | — |
| oil.nvim | Directory editor | `<leader>-` |
| persisted.nvim | Session management | — |
| remote-ssh.nvim | Remote SSH files/sessions/terminals | `<leader>r…` |
| render-markdown.nvim | Markdown rendering | — |
| surround.nvim | Surround motions | — |
| telescope.nvim | Fuzzy finder | — |
| todo-comments.nvim | TODO highlights | — |
| treesitter | Syntax parsing | — |
| which-key.nvim | Keybinding hints | — |
| yanky.nvim | Yank history | — |
| octo.nvim | GitHub issues/PRs | — |
| vimtex | LaTeX | — |
| leetcode.nvim | LeetCode | — |

## Remote SSH

- Open homeserver session: `<leader>rs`
- Open homeserver server dir: `<leader>rc`
- Open homeserver dotfiles dir: `<leader>rf`
- Open remote terminal: `<leader>rT`
- In remote terminal mode, pane navigation matches normal Neovim: `<C-h/j/k/l>`
- Hide remote TUI session: `<C-\>h`

## Formatters (conform.nvim)

| Language | Formatter |
|----------|-----------|
| Lua | stylua |
| Python | isort, black |
| JavaScript/TypeScript | biome (then prettier) |

## Key Files

```
nvim/
├── init.lua                  # Entry point
├── lua/
│   ├── config/
│   │   └── lazy.lua          # Plugin manager + leader key setup
│   └── plugins/              # One file per plugin
└── lazy-lock.json            # Pinned plugin versions
```
