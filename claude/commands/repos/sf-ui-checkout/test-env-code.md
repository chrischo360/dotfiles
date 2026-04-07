Set up the code test environment for sf-ui-checkout.

Installs dependencies and updates GraphQL types. For unit tests — no SSH, webpack server, or realsync needed.

Steps:

1. Verify we're in sf-ui-checkout repository:
   ```bash
   git remote -v | grep -q 'sf-ui-checkout' || { echo "❌ Not in sf-ui-checkout repository"; exit 1; }
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Update GraphQL types (tests may depend on generated types):
   ```bash
   yarn gql:update-all
   ```

What this does:
- **Install**: Ensures all node_modules are up to date
- **GraphQL update**: Regenerates types so tests have accurate type definitions

Error handling:
- If yarn install fails: Check node version or registry connectivity
- If gql:update-all fails: May require network access to GraphQL server

Related commands:
- `/test-env-e2e` - Start full dev environment for E2E testing
- `/test-execute` - Run unit tests after this setup
