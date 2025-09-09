# 🚀 AI Config Quick Start

## Setup (One-time)
```bash
~/dotfiles/ai-sync init           # Initialize the system
cp ~/dotfiles/ai-config/.env.template ~/dotfiles/ai-config/.env
# Edit .env with your tokens
```

## Daily Usage
```bash
~/dotfiles/ai-sync status         # Check system status
~/dotfiles/ai-sync sync           # Full sync all tools
~/dotfiles/ai-sync mcp            # Sync just MCP servers
```

## Your Current Setup
✅ **15 MCP servers** configured from your Cline setup
✅ **Perfect format compatibility** - matches your existing config exactly
✅ **All tools supported**: Goose, Cursor, Cline, Claude Desktop
✅ **Automatic backups** before any changes
✅ **Environment variables** safely templated

## Generated Configurations
- **Cline**: `~/dotfiles/ai-config/templates/cline/cline_config.json`
- **Goose**: `~/dotfiles/ai-config/templates/goose/mcp_servers.json`  
- **Cursor**: `~/dotfiles/ai-config/templates/cursor/mcp_servers.json`

## Next Steps
1. Set up your `.env` file with actual tokens
2. Run `~/dotfiles/ai-sync sync` to deploy everywhere
3. Restart your AI tools to pick up new configs
4. Add new MCP servers by editing `registry.yaml`

🎯 **Your Cline config is fully preserved and now manageable from one place!**
