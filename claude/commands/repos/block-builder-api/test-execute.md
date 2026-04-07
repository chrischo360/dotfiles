Execute tests for block-builder-api.

Steps:

1. Verify we're in block-builder-api repository:
   ```bash
   git remote -v | grep -q 'block-builder-api' || { echo "❌ Not in block-builder-api repository"; exit 1; }
   ```

2. Ask what to run via AskUserQuestion:
   "Which tests?"
   Options:
     - All modules - `./mvnw test -pl common,storefront,internal`
     - Single module - prompt for module name, then `./mvnw test -pl <module>`
     - Single test class - prompt for class, then `./mvnw test -pl <module> -Dtest=<ClassName>`

3. Run the selected command.

4. On failure: show Maven error output, ask how to proceed.

5. After completion: invoke `global:test-log` to record the session.

What this does:
- Runs JUnit tests via Maven Surefire plugin
- Supports targeting individual modules or test classes

Error handling:
- If not in block-builder-api: Exits with error message
- If tests fail: Show surefire report summary
- If compile error: Run `/test-env` first to fix formatting and recompile

Related commands:
- `/test-env` - Compile and fix formatting before running
- `/prepublish` - Full cross-repo testing workflow
