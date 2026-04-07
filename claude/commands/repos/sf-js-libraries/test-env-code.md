Set up the code test environment for sf-js-libraries.

sf-js-libraries is a monorepo of JavaScript libraries. Each library may have its own test setup.

Steps:

1. Verify we're in sf-js-libraries repository:
   ```bash
   git remote -v | grep -q 'sf-js-libraries' || { echo "❌ Not in sf-js-libraries repository"; exit 1; }
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Ask which library to test via AskUserQuestion:
   "Which library?"
   Options:
     - All libraries - run from repo root
     - Specific library - prompt for library name/path (e.g. `packages/my-lib`)

4. If a specific library: navigate to its directory and verify it has a test script:
   ```bash
   cd <library-path>
   jq -r '.scripts.test // empty' package.json
   ```

What this does:
- **Install**: Ensures all workspace dependencies are resolved
- **Library selection**: Scopes setup to avoid running unrelated library tests

Error handling:
- If library has no test script: Report and exit — may need to check jest/vitest config directly

Related commands:
- `/test-execute` - Run tests after environment is ready
- `/prepublish` - Full cross-repo testing workflow (publish pre-release + test in consumer)

Notes:
- Libraries are yarn workspaces — `yarn install` at root handles all packages
- Format check before testing: `yarn format:check` in the library directory
