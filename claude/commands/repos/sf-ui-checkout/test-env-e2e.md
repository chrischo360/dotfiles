Set up the E2E test environment for sf-ui-checkout.

Launches the full multi-service dev environment: webpack dev server, server-side rendering, SSH tunnel to the remote PHP server, and realsync for file sync. Orchestrated by the `sf-ui-checkout-dev` script.

Steps:

1. Verify we're in sf-ui-checkout repository:
   ```bash
   git remote -v | grep -q 'sf-ui-checkout' || { echo "❌ Not in sf-ui-checkout repository"; exit 1; }
   ```

2. Verify SSH connectivity to dev server:
   ```bash
   ssh -o ConnectTimeout=5 webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal echo "ok" \
     || { echo "❌ Dev server unreachable — check VPN"; exit 1; }
   ```

3. Ask how to proceed via AskUserQuestion:
   "Launch or verify E2E environment?"
   Options:
     - Launch full environment - Run sf-ui-checkout-dev (opens 6 tmux panes)
     - Verify existing environment - Check if services are already running
     - Launch with debug - Run sf-ui-checkout-dev --debug

4a. Launch:
   ```bash
   sf-ui-checkout-dev
   ```
   (alias defined in ~/dotfiles/zsh/custom/05-aliases.zsh)

   Starts 6 tmux panes:
   - Webpack (`yarn && yarn watch:wf`) → ready at `localhost:8898`
   - Render watch (`yarn rndr:watch-wf`)
   - Render tunnel (`yarn rndr:tunnel`)
   - GraphQL update (`yarn gql:update-all`)
   - SSH to dev server
   - Realsync (file sync to `~/codebase`)

4b. Verify existing:
   ```bash
   curl -s http://localhost:8898/webpack/sf-ui-checkout | head -1   # webpack
   pgrep -f realsync                                                  # realsync
   pgrep -f webphp-php8ccho                                          # SSH tunnel
   ```

What this does:
- Validates SSH before launching to fail fast
- Starts all services needed for browser-based E2E testing
- Verify mode checks health of a running session without restarting

Error handling:
- SSH unreachable: VPN must be connected; devbox alias is `sde-php8ccho`
- Webpack port in use: kill existing with process-manager.sh or `pkill -f watch:wf`
- Realsync fails: Check `~/codebase` path exists on remote

Dev URLs (once running):
- Webpack: `http://localhost:8898/webpack/sf-ui-checkout`
- Cart: `https://wayfaircom.csnzoo.com/v/checkout/basket/show`
- Checkout: `https://secure.wayfaircom.csnzoo.com/v/checkout/onepage/view?ft_override_enable_webpack_checkout=ON&webpack-localhost-apps[]=sf-ui-checkout&devbox=sde-php8ccho`

Related commands:
- `/test-env-code` - Install deps before launching E2E env
- `/test-execute` - Run tests once environment is up

Notes:
- Log files: `~/dotfiles/scripts/codebase/sf-ui-checkout/logs/dev-env/`
- SSH host: `webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal`
- Devbox alias: `sde-php8ccho`
