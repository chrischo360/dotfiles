# Raycast Script Commands

This directory contains Raycast Script Commands that provide quick access to your terminal aliases and commands.

## Setup

### Option 1: Import Scripts to Raycast (Recommended)

1. Open Raycast Settings (⌘,)
2. Go to **Extensions** → **Script Commands**
3. Click the **+** button or **"Add Script Directory"**
4. Navigate to: `~/dotfiles/raycast`
5. Select the directory

All scripts will now be available in Raycast!

### Option 2: Symlink Individual Scripts

If you prefer to keep Raycast's default script location:

```bash
# Create Raycast script commands directory if it doesn't exist
mkdir -p ~/Documents/Raycast\ Scripts

# Symlink the scripts
ln -s ~/dotfiles/raycast/*.sh ~/Documents/Raycast\ Scripts/
```

## Usage

Once set up, you can:
1. Open Raycast (⌥Space or your configured hotkey)
2. Type the command name (e.g., "CF Next Problem")
3. Press Enter to run

## Adding New Commands

To add more script commands:

1. Create a new `.sh` file in this directory
2. Add required Raycast metadata headers
3. Make it executable: `chmod +x script-name.sh`
4. Reload Raycast or wait for auto-refresh

### Template

```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Your Command Title
# @raycast.mode fullOutput
# @raycast.packageName Package Name
# @raycast.icon 🎯

# Documentation:
# @raycast.description What this command does
# @raycast.author cc446g

# Source zshrc to access aliases
source ~/.zshrc

# Your command here
your-command
```

## Notes

- Scripts source `~/.zshrc` to access your shell aliases and environment
- Use `fullOutput` mode for commands that produce text output
- Use `compact` mode for quick commands with minimal output
- Use `silent` mode for commands that should run in the background
