Intelligently fetch relevant files from Neovim's tracked buffers based on the current conversation context.

Steps:

1. Detect the current project root by running `git rev-parse --show-toplevel` or use current directory
2. Read buffer tracking manifest from `~/.local/share/nvim/buffer_tracking/manifest.json` to find the project hash
3. Read buffer tracking file `~/.local/share/nvim/buffer_tracking/project-{hash}.json` to get all tracked buffers
4. Analyze the current conversation to identify:
   - Keywords and topics being discussed
   - File types or languages mentioned
   - Specific components or features being worked on
   - Any file paths explicitly mentioned
5. Filter tracked buffers to select relevant ones based on:
   - File paths matching conversation keywords (e.g., if discussing "nvim config", prioritize files in nvim/)
   - File extensions relevant to the task (e.g., if discussing shell config, prioritize .sh, .zsh, .bash files)
   - High importance scores (files with high access/save counts are more likely relevant)
   - Filename matches (e.g., if discussing "settings", include settings.json)
6. For each selected file:
   - Read the file contents using the Read tool
   - Include a brief explanation of why it's relevant to the current task
7. If no relevant files found, explain which buffers are available and ask if user wants to see all tracked files
8. Limit to top 5-8 most relevant files to avoid overwhelming context

Example output:
```
Reading relevant buffers for current task...

**Relevant files identified (3):**

1. /Users/cc446g/dotfiles/nvim/lua/plugins/bufferin.lua
   - Relevance: Contains bufferin plugin config (mentioned in conversation)
   - Importance: High (access: 25, saves: 10)

[File contents shown using Read tool]

2. /Users/cc446g/dotfiles/nvim/lua/config/buffer-importance-simple.lua
   - Relevance: Buffer tracking implementation (directly related to task)
   - Importance: Medium (access: 12, saves: 5)

[File contents shown using Read tool]

3. /Users/cc446g/dotfiles/claude/commands/repos/notes/archive-week.md
   - Relevance: Example slash command format (needed for implementation)
   - Importance: Low (access: 3, saves: 1)

[File contents shown using Read tool]
```
