---
description: Show available commands and tools for current context
---

Display all available commands, tools, and workflows based on the current repository and context.

Steps:

1. **Detect current repository and show available commands**
   ```bash
   # Get repository info
   REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
   CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
   HAS_UNSTAGED=$(git diff --quiet 2>/dev/null || echo "yes")
   HAS_PR=$(gh pr view --json url -q '.url' 2>/dev/null)

   echo "📋 Available Commands for: $REPO_NAME"
   echo ""

   # Show context-aware recommendations
   echo "## Recommended Next Steps"
   echo ""
   if [[ "$REPO_NAME" == "sf-ui-web" ]]; then
     if [[ -n "$HAS_UNSTAGED" ]]; then
       echo "✓ You have uncommitted changes"
       echo "  → /pr-build      - Commit + sync + rebuild + format (prepares branch for PR)"
       echo "  → /pr-check      - Validate changes before committing"
       echo ""
     elif [[ -z "$HAS_PR" ]]; then
       echo "✓ Branch ready, no PR yet"
       echo "  → /pr-build      - Final cleanup before creating PR"
       echo "  → gh pr create   - Create pull request"
       echo ""
     elif [[ -n "$HAS_PR" ]]; then
       echo "✓ PR exists: $HAS_PR"
       echo "  → /pr-watch      - Monitor CI checks"
       echo "  → /pr-push       - Push + watch + auto-diagnose failures"
       echo "  → /pr-automerge  - Auto-merge when checks pass"
       echo ""
     fi
   else
     if [[ -n "$HAS_UNSTAGED" ]]; then
       echo "✓ You have uncommitted changes"
       echo "  → Review changes and commit when ready"
       echo ""
     elif [[ -n "$HAS_PR" ]]; then
       echo "✓ PR exists: $HAS_PR"
       echo "  → /pr-watch      - Monitor CI checks"
       echo ""
     fi
   fi

   # Show global commands (always available)
   echo "## Global Commands"
   echo ""
   echo "- /pr-template     - Generate PR description from git diff"
   echo "- /pr-watch        - Monitor GitHub PR CI checks"
   echo "- /pr-dashboard    - View all PRs for a repository"
   echo "- /create-command  - Generate new Claude command"
   echo "- /cherry-pick-merge - Cherry-pick commits workflow"
   echo "- /buffers         - Fetch Neovim buffers"
   echo "- /commands        - Show this help (current command)"
   echo ""

   # Show repo-specific commands based on detected repo
   case "$REPO_NAME" in
     "sf-ui-web")
       echo "## sf-ui-web Commands"
       echo ""
       echo "- /pr              - PR workflow menu (interactive)"
       echo "- /pr-build        - Prepare branch for PR (commit + sync + rebuild + format)"
       echo "- /pr-push         - Push changes + watch PR checks + diagnose failures with fixes"
       echo "- /pr-check        - Run full pre-PR validation (format + lint + typecheck + build + test)"
       echo "- /pr-automerge    - Watch PR checks and auto-merge when all pass"
       echo "- /quick-rebuild   - Fast rebuild (regenerate GraphQL types + build libraries)"
       echo ""
       ;;
     "block-builder-api")
       echo "## block-builder-api Commands"
       echo ""
       echo "- /prepublish      - Test GraphQL schema changes in sf-ui-web"
       echo ""
       ;;
     "sf-js-libraries")
       echo "## sf-js-libraries Commands"
       echo ""
       echo "- /prepublish      - Test pre-published library changes in consuming repos"
       echo ""
       ;;
     "notes")
       echo "## notes Commands"
       echo ""
       echo "- /archive-week    - Archive current weekly plan and create new one"
       echo ""
       ;;
   esac

   # Show dev CLI commands if available
   if command -v dev &> /dev/null; then
     echo "## dev CLI (Context-Aware Development Commands)"
     echo ""
     echo "Run 'dev :docs' for full documentation, or see quick reference:"
     echo ""
     echo "**Common commands:**"
     echo "- dev build        - Build the project"
     echo "- dev rebuild      - Quick rebuild (codegen + lib:build)"
     echo "- dev start        - Start dev server (context-aware)"
     echo "- dev lint / format / typecheck / test - Code quality"
     echo "- dev clean:all    - Full clean"
     echo ""
     echo "**Multi-step scripts:**"
     echo "- dev :run setup       - Full setup (install + codegen + build + start)"
     echo "- dev :run quick       - Quick rebuild (codegen + build)"
     echo "- dev :run fullreset   - Clean everything and rebuild"
     echo "- dev :run pr:check    - Pre-PR checks (format + lint + typecheck + build + test)"
     echo ""
     echo "**Meta commands:**"
     echo "- dev :list        - List available commands"
     echo "- dev :scripts     - List available scripts"
     echo "- dev :info        - Show project detection info"
     echo "- dev :docs        - Show LLM-friendly documentation"
     echo ""
   fi

   # Show scout CLI commands if in a git repo
   if git rev-parse --is-inside-work-tree &> /dev/null; then
     echo "## scout CLI (GitHub/CI Automation)"
     echo ""
     echo "**GitHub commands:**"
     echo "- scout check <PR_URL>           - Monitor PR CI checks"
     echo "- scout check --auto-merge       - Auto-merge when checks pass"
     echo "- scout pr-dashboard <owner/repo> - View all PRs"
     echo "- scout review-queue <owner/repo> - Find PRs needing review"
     echo "- scout auto-approve <owner/repo> - Auto-approve Dependabot PRs"
     echo ""
     echo "**Buildkite commands:**"
     echo "- scout buildkite-watch <URL>    - Monitor Buildkite builds"
     echo ""
   fi
   ```

What this does:
- **Auto-detects** current repository from git
- **Shows global commands** (always available)
- **Shows repo-specific commands** (based on detected repo)
- **Shows dev CLI commands** (if dev CLI is installed)
- **Shows scout CLI commands** (if in a git repository)
- **Provides quick reference** without needing to run multiple commands

Output format:
- Organized by scope (Global → Repo-Specific → dev CLI → scout CLI)
- Command name + brief description
- Contextual based on where you are

Examples:

**In sf-ui-web repository:**
Shows all global commands + sf-ui-web specific commands + dev CLI + scout CLI

**In dotfiles repository:**
Shows global commands + dev CLI (if available) + scout CLI

**In unknown repository:**
Shows only global commands + scout CLI

Related commands:
- `/dev` - Show dev CLI commands for current repo
- `/create-command` - Create new Claude command
- `dev :docs` - Show full dev CLI documentation
- `scout --help` - Show scout CLI help

Notes:
- Command availability depends on current context (repository, installed tools)
- Commands are automatically registered as skills from `~/dotfiles/claude/commands/`
- Global commands work anywhere, repo commands work only in their respective repos
- dev CLI commands are context-aware (different behavior in root vs apps/* vs libs/*)

Anti-Patterns to Avoid:
- Don't run commands you don't understand - use /commands first to see what's available
- Don't assume a command exists - check /commands output to verify
- Don't use repo-specific commands outside their repository
