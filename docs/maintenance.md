# Maintenance

## Updating Configurations

All configs are version-controlled. After making changes:
```bash
cd ~/dotfiles
git add .
git commit -m "Update configuration"
git push
```

## Managing Packages

**Add a new tool:**
```bash
# Add to .mise.toml manually, then:
mise install
```

**Update tools:**
```bash
mise upgrade          # Update all tools
mise upgrade node     # Update specific tool
```

**macOS-only packages (GUI apps, fonts, macOS-specific tools):**
```bash
# Add to Brewfile.macos, then:
brew bundle --file=~/dotfiles/Brewfile.macos
```

**Check tool availability:**
```bash
mise registry <tool-name>   # Search mise registry
mise list                   # List installed tools
mise ls --current           # Show which config file provides each tool
```

## Troubleshooting

- If symlinks break, re-run the install script
- Check symlink status: `ls -la ~/.zshrc ~/.tmux.conf`
- Verify paths match your username in scripts
- mise not found: `export PATH="$HOME/.local/bin:$PATH"`
- Tool missing: `cd ~/dotfiles && mise install`
