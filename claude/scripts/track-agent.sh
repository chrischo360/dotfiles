#!/bin/bash

# Agent usage tracking hook
# Logs custom agent invocations to ~/.claude/agent-usage.log

AGENT_LOG="$HOME/.claude/agent-usage.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Get agent info from environment variables (if available)
AGENT_NAME="${CLAUDE_SUBAGENT_NAME:-unknown}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
PROJECT="${PWD}"

# Only log custom agents (skip built-in ones)
case "$AGENT_NAME" in
    implementation-planner|project-discovery-researcher|task-coordinator-qa)
        echo "$TIMESTAMP | Session: $SESSION_ID | Agent: $AGENT_NAME | Project: $PROJECT" >> "$AGENT_LOG"
        ;;
    *)
        # Skip built-in agents like Explore, Plan, etc.
        ;;
esac
