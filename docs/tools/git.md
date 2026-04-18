# Git

Config: `~/dotfiles/git/gitconfig` → `~/.gitconfig`
Global gitignore: `~/dotfiles/git/gitignore_global`
Hooks path: `~/dotfiles/git/hooks/`

## Global Gitignore

Ignores personal tool configs across all repos:
- `.mise.toml`, `.yarnrc.yml` — tool configs
- `.DS_Store`, `Thumbs.db` — OS files
- `.idea/`, `.vscode/` — editor dirs
- `.claude/`, `.cursor/*`, `.pi/` — AI assistant configs
- `npm-debug.log*`, `yarn-*.log*` — debug logs
- `.buildkite/local-checks.json`, `.buildkite/local-checks.sh` — local CI

## Git Hooks

Configured via: `git config --global core.hooksPath ~/dotfiles/git/hooks`

### post-checkout

Automatically runs `sfb -d -r` when switching branches in sf-ui-web.

- Branch checkout: runs
- File checkout: skipped
- Other repos: skipped

What it does:
1. Detects branch change in sf-ui-web
2. Runs `sfb -d -r` (clean dist + rebuild with cache)

**Skip for one checkout:**
```bash
SKIP_AUTO_CLEAN=1 git checkout <branch>
```

**Disable globally:**
```bash
git config --global --unset core.hooksPath
```

**Re-enable:**
```bash
git config --global core.hooksPath ~/dotfiles/git/hooks
```
