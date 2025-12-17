# Git Hooks

Global git hooks configured via `git config --global core.hooksPath ~/dotfiles/git/hooks`

## post-checkout

Automatically runs `sfb -d -r` when switching branches in sf-ui-web.

**Triggers:**
- Branch checkout: ✅ Runs
- File checkout: ❌ Skips
- Other repos: ❌ Skips

**What it does:**
1. Detects branch change in sf-ui-web
2. Shows message with branch names
3. Runs `sfb -d -r` (clean dist + rebuild with cache)
4. Shows completion message

**To skip:**
```bash
SKIP_AUTO_CLEAN=1 git checkout <branch>
```

**To disable globally:**
```bash
git config --global --unset core.hooksPath
```

**To re-enable:**
```bash
git config --global core.hooksPath ~/dotfiles/git/hooks
```
