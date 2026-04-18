# Raycast

Script commands: `~/dotfiles/raycast/`

## Setup

1. Open Raycast Settings (`⌘,`)
2. Go to Extensions → Script Commands
3. Add Script Directory: `~/dotfiles/raycast`

## CodeForces Commands

- `CF Next Problem` - Find next unsolved problem
- `CF Add Progress` - Log completed problem
- `CF Show Progress` - View training stats

## Adding New Commands

1. Create a `.sh` file in `~/dotfiles/raycast/`
2. Add Raycast metadata headers
3. Make executable: `chmod +x script-name.sh`

**Template:**
```bash
#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Your Command Title
# @raycast.mode fullOutput
# @raycast.packageName Package Name
# @raycast.icon 🎯
# @raycast.description What this command does
# @raycast.author cc446g

source ~/.zshrc
your-command
```

**Output modes:** `fullOutput` for text, `compact` for minimal, `silent` for background.
