# Claude Code - Quick Reference Card

## 🚀 Quick Start
```vim
<leader>cc    " Open Claude chat
<leader>cg    " Generate code
<leader>ca    " Browse all actions (Telescope)
```

## 📋 Keybindings Cheat Sheet

### Chat & Generation
```
cc  - Open chat             cI  - New chat
cg  - Generate code (N/V)   ce  - Explain code (V)
cf  - Fix code (V)          ca  - All actions (Telescope)
```

### Refactoring (cr_)
```
crr - Refactor selected     cri - Improve code
crd - Add docstring         crt - Add tests
```

### Models (cm_)
```
cmo - Use Opus (powerful)   cms - Use Sonnet (balanced)
cmh - Use Haiku (fast)      cmt - Telescope model picker
```

## 🎯 Common Workflows

**Generate Function**
```
1. <leader>cg
2. Type: "Create a function to validate email"
3. Review and accept
```

**Refactor Code**
```
1. Visually select code
2. <leader>crr
3. Type: "Convert to async/await"
4. Review changes
```

**Add Tests**
```
1. Visually select function
2. <leader>crt
3. Review generated tests
```

**Explain Code**
```
1. Visually select code
2. <leader>ce
3. Read explanation
```

## 🔧 Model Selection

**Opus** (Default) - Most powerful
**Sonnet** - Balanced
**Haiku** - Fastest

Use `<leader>cmh` for quick tasks, `<leader>cmo` for complex ones.

## 🆚 Goose vs Claude

**Use Goose (`<leader>g`) when:**
- Multi-file operations needed
- Git/filesystem tasks
- Complex multi-step workflows

**Use Claude (`<leader>c`) when:**
- Quick code generation
- Code explanations
- Focused refactoring
- Adding tests/docs

## 📁 Files
- `lua/plugins/claude.lua` - Main configuration
- `lua/plugins/which-key.lua` - Keybinding groups

## 🔐 Authentication
```bash
gcloud auth application-default login
```

Project: `wf-gcp-us-sf-genai-pilot-sbx`
Region: `us-east5`
Temperature: `0.2`

## 📝 Window Navigation
Use standard Vim commands to move between Claude windows:
- `<C-w>w` - Cycle through windows
- `<C-w>h/j/k/l` - Move to specific window
- `<C-w>q` - Close current window
