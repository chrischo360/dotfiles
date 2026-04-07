Set up the code test environment for sf-ui-web.

Ensures dependencies are installed and the repo is in a testable state for unit/integration tests.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Run codegen (tests may depend on generated GraphQL types):
   ```bash
   yarn gql:codegen
   ```

4. Build libraries (tests depend on built lib artifacts):
   ```bash
   yarn lib:build
   ```

What this does:
- **Install**: Ensures all node_modules are up to date
- **Codegen**: Regenerates GraphQL types so tests have correct type definitions
- **Lib build**: Builds internal libraries that test files import from

Error handling:
- If yarn install fails: Check for node version mismatch or registry issues
- If codegen fails: May need a running GraphQL server or schema file

Related commands:
- `/test-execute` - Run tests after environment is ready
- `/quick-rebuild` - Faster alternative (codegen + lib:build only, skips yarn install)

Notes:
- Skip yarn install if node_modules exists and yarn.lock hasn't changed
- Codegen only needed if schema files changed since last run
