# Glean MCP Extension for Pi (OAuth)

This extension connects Pi to Glean's Remote MCP server using OAuth authentication, following the same approach as Claude Code.

## Features

- ✅ OAuth device flow authentication (same as Claude)
- ✅ Automatic token refresh
- ✅ Stores tokens in `~/.pi/agent/glean-oauth.json`
- ✅ All Glean MCP tools: search, chat, code_search, employee_search, read_document, user_activity, gmail_search, meeting_lookup, read_memory

## Setup

### 1. Set Environment Variable

Add to your shell config (already done in `~/dotfiles/zsh/custom/01-env.zsh`):

```bash
export GLEAN_INSTANCE="wayfair"  # or GLEAN_SUBDOMAIN
```

### 2. Enable the Extension in Pi

Update `~/.pi/agent/settings.json`:

```json
{
  "extensions": [
    "~/.pi/agent/extensions/mcp-glean-oauth",  // OAuth version (recommended)
    // OR
    "~/.pi/agent/extensions/mcp-glean",        // Token-based version
    "~/.pi/agent/extensions/mcp-sourcegraph",
    "~/.pi/agent/extensions/session-status",
    "~/.pi/agent/extensions/web-tools"
  ]
}
```

### 3. First-Time OAuth Setup

**Option A: Automatic (when you first use a Glean tool in Pi)**

The extension will automatically initiate OAuth device flow when you first use any Glean tool. Just follow the prompts in Pi's output.

**Option B: Manual (using helper script)**

```bash
node ~/dotfiles/scripts/dev/pi-glean-oauth.mjs
```

This will:
1. Display a URL and code
2. You visit the URL and enter the code
3. Tokens are saved to `~/.pi/agent/glean-oauth.json`

### 4. Test It

In Pi, try:
```
use glean_search to find recent documents about authentication
```

## Token Management

### Check Token Status

```bash
node ~/dotfiles/scripts/dev/pi-glean-oauth.mjs
```

### Refresh Token

Tokens auto-refresh when they expire, but you can manually refresh:

```bash
node ~/dotfiles/scripts/dev/pi-glean-oauth.mjs
```

### Reset OAuth (force new device flow)

```bash
node ~/dotfiles/scripts/dev/pi-glean-oauth.mjs --reset
```

Or manually delete:

```bash
rm ~/.pi/agent/glean-oauth.json
```

## Comparison: OAuth vs Token-Based

### OAuth Version (`mcp-glean-oauth`) - **Recommended**

✅ Pros:
- Same approach as Claude Code
- Tokens auto-refresh (long-lived)
- No need to manage API tokens manually
- Works with Wayfair's SSO

❌ Cons:
- Requires initial device flow setup
- Stores tokens in `~/.pi/agent/glean-oauth.json`

### Token-Based Version (`mcp-glean`)

✅ Pros:
- Simpler - just set `GLEAN_MCP_TOKEN` env var
- No OAuth flow needed

❌ Cons:
- Requires manual API token from Glean admin
- Token might expire and need manual refresh
- Currently using invalid/expired token

## Troubleshooting

### "Authentication required" or "invalid_token"

The extension will automatically try to refresh the token once. If that fails:

```bash
rm ~/.pi/agent/glean-oauth.json
node ~/dotfiles/scripts/dev/pi-glean-oauth.mjs
```

### Extension not loading

Check Pi's logs for errors. Make sure the extension path is correct in `settings.json`.

### OAuth flow times out

The device code expires after 10 minutes. Just run the script again.

## Architecture

This extension:
1. Uses Glean's Remote MCP server: `https://wayfair-be.glean.com/mcp/default`
2. Implements OAuth device flow (RFC 8628)
3. Stores tokens with refresh capability
4. Calls MCP tools via HTTP/JSON-RPC

Same design as Claude Code's Glean integration.
