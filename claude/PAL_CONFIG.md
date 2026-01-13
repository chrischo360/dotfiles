# PAL MCP Server Configuration

Multi-model orchestration for Claude Code.

## Model Orchestration Strategy

### Two-Model System

**1. Gemini (Flash/Pro)** - API lookups and supporting perspectives
- Tools: `apilookup`, `consensus` (for stance)
- Use when: API research, documentation, supporting arguments
- Example: "Use apilookup to find React hooks documentation"

**2. Cursor Opus 4.5 Thinking** - Implementation and debugging
- Tools: `clink`, `debug`, `consensus` (against/neutral stances)
- Use when: File exploration, debugging, counterarguments
- Example: "Use debug to trace race condition in login flow"

## Tool → Model Mapping

| Tool | Model | Purpose |
|------|-------|---------|
| `consensus` | Gemini 3 Pro (for) + Cursor (against/neutral) | Multi-perspective decisions |
| `debug` | Cursor | Systematic debugging |
| `apilookup` | Gemini 2.5 Flash | API documentation |
| `clink` | Cursor (Opus 4.5) | File exploration, implementation |

## Configuration Location

Edit `~/pal-mcp-server/.env`

## Current Configuration

```bash
# Models
DEFAULT_MODEL_APILOOKUP=gemini-2.5-flash
DEFAULT_MODEL_DEBUG_COMPLEX=cursor
DEFAULT_MODEL_DEBUG_SIMPLE=cursor

# Consensus
CONSENSUS_FOR_MODEL=gemini-3-pro-preview
CONSENSUS_AGAINST_MODEL=cursor
CONSENSUS_NEUTRAL_MODEL=cursor

# Tools (thinkdeep, planner, listmodels disabled)
ENABLED_TOOLS=clink,consensus,debug,apilookup
```

## Verify Configuration

After restarting Claude Code:

```bash
# Test available tools
# Should see: consensus, debug, apilookup, clink
```
