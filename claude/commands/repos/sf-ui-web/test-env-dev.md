Set up the local dev environment for sf-ui-web manual browser testing.

Runs the setup script which executes all steps sequentially then launches `yarn dev` in a dedicated tmux pane.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the setup script:
   ```bash
   sf-ui-web-dev
   ```
   Or directly: `~/dotfiles/scripts/codebase/sf-ui-web/setup-dev-env.sh`

   The script runs these phases:
   - **Phase 1**: Cleanup existing dev processes + create tmux session (2 panes)
   - **Phase 2**: `yarn` — install dependencies
   - **Phase 3**: `yarn turbo run build --filter="[main...HEAD]"` — build changed packages
   - **Phase 4**: `yarn gql:codegen` + `yarn gql:register`
   - **Phase 5**: `yarn dev` sent to tmux pane 2, monitored until ready
   - Attaches to tmux session when complete

   Flags:
   - `--skip-lint` — skip lint step
   - `--debug` — verbose output

Tmux layout:
- Pane 1: build output (phases 2–4, then idle)
- Pane 2: `yarn dev` (long-running, `apps/core-funnel`)

Dev server: `http://localhost:3000`

Error handling:
- Any phase failure exits immediately with error
- Tmux session remains for inspection on failure
- Logs: `~/dotfiles/scripts/codebase/sf-ui-web/logs/dev-env/latest.log`

Related commands:
- `/pr-lint` - Run lint standalone before starting this
- `/test-env-e2e-playwright` - For Playwright smoke tests instead
