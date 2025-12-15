# PAL MCP Server Configuration

Guide for configuring PAL MCP Server with limited tools and default models.

## Configuration Location

Edit `~/dotfiles/pal-mcp-server/.env`

## Limit Available Tools

Add this to your `.env` file:

```bash
# Limit available tools (comma-separated)
ENABLED_TOOLS=clink,thinkdeep,planner,consensus,debug,apilookup,listmodels
```

## Default Models by Tool Type

Add these environment variables to set default models:

```bash
# Default model for clink (auto-selects based on complexity)
DEFAULT_MODEL_CLINK=auto

# Default model for thinkdeep (deep reasoning)
DEFAULT_MODEL_THINKDEEP=gemini-3-pro-preview

# Default model for planner (architectural thinking)
DEFAULT_MODEL_PLANNER=gemini-3-pro-preview

# Default model for consensus (mixed models for different stances)
DEFAULT_MODEL_CONSENSUS_FOR=gemini-3-pro-preview
DEFAULT_MODEL_CONSENSUS_AGAINST=gemini-2.5-flash
DEFAULT_MODEL_CONSENSUS_NEUTRAL=gemini-2.5-flash

# Default model for debug (varies by complexity)
DEFAULT_MODEL_DEBUG_COMPLEX=gemini-3-pro-preview
DEFAULT_MODEL_DEBUG_SIMPLE=gemini-2.5-flash

# Default model for apilookup (fast lookup)
DEFAULT_MODEL_APILOOKUP=gemini-2.5-flash
```

## Tool Selection Logic

**Auto-use without asking:**

- `apilookup` - When looking up API docs, versions, breaking changes
- `clink` - Quick second opinions, alternative perspectives
- `thinkdeep` - Complex investigations requiring deep reasoning
- `planner` - Planning multi-file features, migrations, system design
- `consensus` - Important architectural/tech stack decisions
- `debug` - Mysterious bugs, race conditions, hard-to-reproduce issues

## Model Selection Strategy

**Use Gemini Flash (2.5-flash) for:**
- Quick code reviews
- Simple implementations
- Syntax/style validation
- Fast lookups (apilookup)
- Supporting perspectives in consensus (against/neutral stances)

**Use Gemini Pro (3-pro-preview) for:**
- Architectural decisions
- Complex debugging (debug tool)
- Large feature planning (planner tool)
- Deep analysis (thinkdeep tool)
- Primary perspective in consensus (for stance)

## Apply Configuration

After editing `.env`:

```bash
# Restart Claude Code to reload MCP server
# The server will pick up new environment variables
```

## Verify Configuration

```bash
# In Claude Code, run:
mcp__pal__listmodels

# Check that only enabled tools are available
# Verify default models match your configuration
```
