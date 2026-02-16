# Claude Commands Map

Visualization of all Claude commands and their relationships.

## Command Categories

- [[#Global Commands]] - Work in any repository
- [[#sf-ui-web Commands]] - Specific to sf-ui-web repository
- [[#Other Repository Commands]] - Specific to other repos
- [[#External Tools]] - Underlying CLIs and scripts

---

## Global Commands

### commands
**Skill:** `global:commands`
**Purpose:** Show available commands and tools for current context

**Uses:**
- git (detect repo, branch, PR status)
- gh CLI (detect PR)

**Used by:**
- User invoked for discovery

**Related:**
- None (standalone discovery tool)

---

### buffers
**Skill:** `global:buffers`
**Purpose:** Intelligently fetch relevant files from Neovim's tracked buffers

**Uses:**
- Neovim RPC
- Shell scripts in `~/dotfiles/claude/scripts/utils/`

**Used by:**
- User invoked when working with Neovim

**Related:**
- None (standalone utility)

---

### create-command
**Skill:** `global:create-command`
**Purpose:** Generate a new Claude command from a natural language description

**Uses:**
- File I/O (creates .md files)
- Template generation

**Used by:**
- User invoked to create new commands

**Related:**
- Creates new entries in this map

---

### cherry-pick-merge
**Skill:** `global:cherry-pick-merge`
**Purpose:** Cherry-pick commits from multiple branches into a new branch with automatic conflict resolution

**Uses:**
- git (cherry-pick, merge, conflict resolution)

**Used by:**
- User invoked for complex git workflows

**Related:**
- None (standalone git utility)

---

### pr-template
**Skill:** `global:pr-template`
**Purpose:** Generate PR title and description from git changes matching your terse, technical style

**Uses:**
- git (diff, branch info)
- Optional: Glean MCP (ticket context)
- Optional: Confluence MCP (documentation)
- Optional: Jira MCP (ticket details)

**Used by:**
- [[#pr-create]] (invoked internally)
- [[#pr-cleanup]] (suggested next step)
- User invoked manually

**Related:**
- Input to PR creation workflow

---

### pr-create
**Skill:** `global:pr-create`
**Purpose:** Create GitHub PR with automated workflow (checks, template, push, create)

**Uses:**
- [[#pr-template]] ← **invokes to generate title/body**
- [[#pr-check]] ← **optionally invokes for validation** (if available)
- git (push, branch validation)
- gh CLI (create PR)

**Used by:**
- [[#pr-cleanup]] (suggested next step)
- User invoked to create PR

**Workflow:**
```
1. Pre-flight validation
2. Optional: invoke pr-check
3. Invoke pr-template → get title and body
4. Push branch
5. Create PR with gh CLI
6. Suggest next steps: pr-watch, pr-automerge
```

**Related:**
- [[#pr-watch]] (suggested next step)
- [[#pr-automerge]] (suggested next step)

---

### pr-watch
**Skill:** `global:pr-watch`
**Purpose:** Monitor GitHub PR CI checks in real-time

**Uses:**
- gh CLI (PR status)
- scout CLI (`scout check`) ← **wraps this tool**

**Used by:**
- [[#pr-submit]] ← **uses internally**
- [[#pr-diagnose]] ← **uses internally**
- [[#pr-automerge]] ← **uses internally**
- [[#pr-create]] (suggested next step)
- User invoked manually

**Related:**
- Core monitoring component reused by multiple commands

---

### pr-dashboard
**Skill:** `global:pr-dashboard`
**Purpose:** Display PR dashboard for a repository showing status of all open PRs

**Uses:**
- scout CLI (`scout pr-dashboard`) ← **wraps this tool**

**Used by:**
- User invoked for PR overview

**Related:**
- [[#pr-watch]] (monitor specific PR)

---

### buildkite-watch
**Skill:** `global:buildkite-watch`
**Purpose:** Monitor Buildkite build status with live progress and notifications

**Uses:**
- gh CLI (PR detection)
- Monitoring script (`~/dotfiles/claude/scripts/monitoring/buildkite-monitor-pr.sh`)
- scout CLI (optional, fallback)

**Used by:**
- [[#prepublish (block-builder-api)]] ← **invoked to monitor builds**
- [[#prepublish (sf-js-libraries)]] ← **invoked to monitor builds**
- User invoked manually

**Workflow:**
```
1. Auto-detect PR number (if not provided)
2. Auto-detect Buildkite context from repo
3. Delegate to monitoring script
4. Return exit codes:
   - 0 = success
   - 1 = failure
   - 2 = timeout
   - 3 = no build found
```

**Related:**
- Reusable monitoring component for prepublish workflows

---

## sf-ui-web Commands

### pr-cleanup
**Skill:** `repos:sf-ui-web:pr-cleanup`
**Purpose:** Prepare branch for PR by committing unstaged changes, syncing with main, rebuilding, and formatting

**Uses:**
- git (commit, fetch, merge, checkout)
- yarn (install, codegen, build, format, lint)

**Used by:**
- User invoked before creating PR

**Workflow:**
```
1. Save current branch
2. Fetch latest from origin
3. Commit unstaged changes (if any)
4. Update main branch + build
5. Return to feature branch + sync with main
6. Install deps + codegen
7. Format and lint
8. Show final state
```

**Next Steps:**
- [[#pr-template]] (generate PR description)
- [[#pr-create]] (create PR)

**Related:**
- Preparation step before PR creation

---

### quick-rebuild
**Skill:** `repos:sf-ui-web:quick-rebuild`
**Purpose:** Fast rebuild: regenerate GraphQL types and build libraries

**Uses:**
- dev CLI (`dev :run quick`) ← **wraps this script**
  - yarn gql:codegen
  - yarn lib:build

**Used by:**
- [[#pr-cleanup]] (includes rebuild)
- User invoked after schema changes

**Related:**
- Faster alternative to full setup

---

### pr-check
**Skill:** `repos:sf-ui-web:pr-check`
**Purpose:** Run full pre-PR validation suite (format, lint, typecheck, build, test)

**Uses:**
- dev CLI (`dev :run pr:check`) ← **wraps this script**
  - yarn format
  - yarn lint
  - yarn type-check
  - yarn lib:build
  - yarn test

**Used by:**
- [[#pr-create]] ← **optionally invoked**
- [[#pr-submit]] (includes validation)
- User invoked manually

**Related:**
- Validation component used by other commands

---

### pr-submit
**Skill:** `repos:sf-ui-web:pr-submit`
**Purpose:** Run full validation suite then watch PR CI checks

**Uses:**
- dev CLI (`dev :run pr:submit`) ← **wraps this script**
  - Runs [[#pr-check]] validation steps
  - Uses scout watch-builds (same as [[#pr-watch]])

**Used by:**
- User invoked for validation + monitoring

**Workflow:**
```
1. Run validation suite (format, lint, typecheck, build, test)
2. Watch PR checks with scout
3. Desktop notifications on completion
```

**Related:**
- [[#pr-check]] (validation portion)
- [[#pr-watch]] (monitoring portion)
- [[#pr-diagnose]] (adds failure diagnosis)
- [[#pr-automerge]] (adds auto-merge)

---

### pr-diagnose
**Skill:** `repos:sf-ui-web:pr-diagnose`
**Purpose:** Watch PR checks and diagnose failures with proposed fixes

**Uses:**
- dev CLI (`dev :run pr:diagnose`) ← **wraps this script**
  - Uses scout watch-builds (same as [[#pr-watch]])
  - Spawns Claude agent on failure

**Used by:**
- User invoked for automated diagnosis

**Workflow:**
```
1. Watch PR checks
2. On failure: spawn Claude agent
3. Agent reads logs and proposes fix
4. Desktop notification with results
5. User reviews proposed fix
6. User applies fix and runs pr-check
```

**Related:**
- [[#pr-watch]] (monitoring component)
- [[#pr-check]] (to test proposed fix)
- [[#pr-submit]] (watch without diagnosis)

---

### pr-automerge
**Skill:** `repos:sf-ui-web:pr-automerge`
**Purpose:** Watch PR checks, auto-merge when all checks pass

**Uses:**
- dev CLI (`dev :run pr:automerge`) ← **wraps this script**
  - Uses scout watch-builds (same as [[#pr-watch]])
  - gh CLI (for merge)

**Used by:**
- [[#pr-create]] (suggested next step)
- User invoked for hands-off merging

**Workflow:**
```
1. Watch PR checks
2. On success: gh pr merge --auto --squash
3. On failure: stop and report
4. Desktop notifications
```

**Related:**
- [[#pr-watch]] (monitoring component)
- [[#pr-submit]] (watch without auto-merge)

---

## Other Repository Commands

### prepublish (block-builder-api)
**Skill:** `repos:block-builder-api:prepublish`
**Purpose:** Automate testing block-builder-api GraphQL schema changes in sf-ui-web

**Uses:**
- [[#buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

**Used by:**
- User invoked when testing schema changes

**Workflow:**
```
1. Create feature variant in sf-ui-web
2. Publish to Verdaccio
3. Invoke buildkite-watch to monitor build
4. Handle exit codes from buildkite-watch
5. Test in dev environment
```

**Related:**
- [[#buildkite-watch]] (build monitoring)

---

### prepublish (sf-js-libraries)
**Skill:** `repos:sf-js-libraries:prepublish`
**Purpose:** Automate testing pre-published libraries in consuming repos

**Uses:**
- [[#buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

**Used by:**
- User invoked when testing library changes

**Workflow:**
```
1. Create feature variant in consuming repo
2. Publish to Verdaccio
3. Invoke buildkite-watch to monitor build
4. Handle exit codes from buildkite-watch
5. Test in dev environment
```

**Related:**
- [[#buildkite-watch]] (build monitoring)

---

### dev
**Skill:** `repos:dev`
**Purpose:** Show available dev commands for current repository

**Uses:**
- dev CLI (`dev :docs`)
- git (repo detection)

**Used by:**
- User invoked for discovery

**Related:**
- [[#commands]] (similar discovery tool)

---

### archive-week
**Skill:** `repos:notes:archive-week`
**Purpose:** Archive the current weekly plan and create a new one

**Uses:**
- File I/O (markdown files)
- Date utilities

**Used by:**
- User invoked weekly

**Related:**
- None (standalone notes utility)

---

## External Tools

These are the underlying CLIs that commands wrap or delegate to.

### dev CLI
**Location:** `~/dotfiles/scripts/dev/dev.sh`
**Purpose:** Context-aware development commands

**Used by:**
- [[#pr-check]] → `dev :run pr:check`
- [[#pr-submit]] → `dev :run pr:submit`
- [[#pr-diagnose]] → `dev :run pr:diagnose`
- [[#pr-automerge]] → `dev :run pr:automerge`
- [[#quick-rebuild]] → `dev :run quick`

**Features:**
- Project detection (sf-ui-web, scout, nextjs, node, python)
- Context-aware commands (root vs apps/* vs libs/*)
- Multi-step scripts with notifications
- Desktop notifications on completion

---

### scout CLI
**Location:** `~/codebase/scout` (npm package)
**Purpose:** GitHub/Buildkite automation

**Used by:**
- [[#pr-watch]] → `scout check`
- [[#pr-dashboard]] → `scout pr-dashboard`
- [[#buildkite-watch]] → `scout buildkite-watch` (delegated)

**Features:**
- PR CI check monitoring
- Auto-merge workflows
- PR dashboard views
- Buildkite build watching

---

### gh CLI
**Purpose:** GitHub official CLI

**Used by:**
- [[#pr-create]] (create PR)
- [[#pr-watch]] (PR status)
- [[#pr-automerge]] (merge PR)
- [[#buildkite-watch]] (PR detection)
- [[#commands]] (PR detection)

**Features:**
- PR creation, viewing, merging
- Authentication
- Issue management

---

## Workflow Diagrams

### Complete PR Workflow (sf-ui-web)

```
1. Development
   ├─ Make changes
   └─ pr-cleanup
       ├─ commits unstaged changes
       ├─ syncs with main
       ├─ rebuilds
       └─ formats

2. PR Creation
   └─ pr-create
       ├─ runs pr-check (optional)
       ├─ invokes pr-template
       ├─ pushes branch
       └─ creates PR with gh CLI

3. Monitoring (choose one)
   ├─ pr-watch
   │   └─ monitor only
   ├─ pr-submit
   │   ├─ validate first
   │   └─ then monitor
   ├─ pr-diagnose
   │   ├─ monitor
   │   └─ propose fixes on failure
   └─ pr-automerge
       ├─ monitor
       └─ auto-merge on success
```

### Prepublish Workflow (block-builder-api / sf-js-libraries)

```
1. Make changes to schema/library

2. Run prepublish
   ├─ creates feature variant in consuming repo
   ├─ publishes to Verdaccio
   └─ invokes buildkite-watch
       ├─ auto-detects PR and context
       ├─ monitors build progress
       └─ returns exit code

3. Handle build result
   ├─ success (0): continue to testing
   ├─ failure (1): ask to continue or exit
   ├─ timeout (2): ask to wait/skip/exit
   └─ no build (3): warn and ask to continue

4. Test in dev environment
```

---

## Command Reuse Patterns

### pr-watch (used by 3 commands)
- [[#pr-submit]]
- [[#pr-diagnose]]
- [[#pr-automerge]]

### buildkite-watch (used by 2 commands)
- [[#prepublish (block-builder-api)]]
- [[#prepublish (sf-js-libraries)]]

### pr-template (used by 1 command + manual)
- [[#pr-create]]
- Manual invocation after [[#pr-cleanup]]

### pr-check (used by 1 command + manual)
- [[#pr-create]] (optional)
- [[#pr-submit]] (included in dev script)
- Manual invocation

---

## Quick Reference

### By Use Case

**Preparing a PR:**
1. [[#pr-cleanup]] - prepare branch
2. [[#pr-create]] - create PR

**Validating changes:**
- [[#pr-check]] - full validation suite
- [[#quick-rebuild]] - just codegen + build

**Monitoring PR:**
- [[#pr-watch]] - basic monitoring
- [[#pr-submit]] - validate + monitor
- [[#pr-diagnose]] - monitor + auto-diagnose
- [[#pr-automerge]] - monitor + auto-merge

**Testing cross-repo changes:**
- [[#prepublish (block-builder-api)]] - test schema changes
- [[#prepublish (sf-js-libraries)]] - test library changes

**Discovery:**
- [[#commands]] - show available commands
- [[#dev]] - show dev CLI commands

**Utilities:**
- [[#buffers]] - fetch Neovim buffers
- [[#pr-template]] - generate PR description
- [[#pr-dashboard]] - view all PRs
- [[#cherry-pick-merge]] - git workflow
- [[#create-command]] - create new command

---

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│ Layer 1: Claude Commands (Orchestration)       │
│ - High-level workflows                          │
│ - Multi-step processes                          │
│ - User-facing commands                          │
└─────────────────────────────────────────────────┘
                    ↓ invokes
┌─────────────────────────────────────────────────┐
│ Layer 2: CLI Tools (Implementation)             │
│ - dev CLI (context-aware dev commands)          │
│ - scout CLI (GitHub/Buildkite automation)       │
│ - Monitoring scripts (buildkite-monitor-pr.sh)  │
└─────────────────────────────────────────────────┘
                    ↓ uses
┌─────────────────────────────────────────────────┐
│ Layer 3: Platform APIs (Low-level)              │
│ - gh CLI (GitHub API)                           │
│ - git (version control)                         │
│ - yarn (package management)                     │
└─────────────────────────────────────────────────┘
```

This separation allows:
- **Flexibility** - swap implementations without changing workflows
- **Reusability** - commands compose well
- **Testability** - each layer can be tested independently
- **Maintainability** - clear boundaries between concerns
