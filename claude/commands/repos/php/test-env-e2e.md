Set up the E2E test environment for the PHP monorepo.

Establishes SSH connectivity and starts realsync to sync local files to the remote dev server for full-stack testing.

Steps:

1. Verify we're in the PHP repository:
   ```bash
   git remote -v | grep -q 'php' || { echo "❌ Not in PHP repository"; exit 1; }
   ```

2. Verify SSH connectivity to dev server:
   ```bash
   ssh -o ConnectTimeout=5 webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal echo "ok" \
     || { echo "❌ Dev server unreachable — check VPN/SSH config"; exit 1; }
   ```

3. Start realsync to sync local files to remote:
   ```bash
   realsync ~/codebase
   ```

4. Confirm realsync is ready before proceeding.

What this does:
- Validates SSH access to the PHP dev server
- Starts real-time file sync so local changes are reflected on the remote server

Error handling:
- SSH unreachable: Check VPN is connected; devbox alias is `sde-php8ccho`
- Realsync fails: Verify `~/codebase` path exists on remote

Related commands:
- `/test-env-code` - Install PHP deps before this step
- `/test-execute` - Run tests after environment is ready

Notes:
- Dev server: `webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal`
- Devbox alias: `sde-php8ccho`
