Set up the code test environment for block-builder-api.

block-builder-api is a Java/Maven project. Tests run via Maven and require a clean compile.

Steps:

1. Verify we're in block-builder-api repository:
   ```bash
   git remote -v | grep -q 'block-builder-api' || { echo "❌ Not in block-builder-api repository"; exit 1; }
   ```

2. Check Maven wrapper is available:
   ```bash
   ./mvnw --version || { echo "❌ Maven wrapper not found"; exit 1; }
   ```

3. Fix any formatting issues (tests may fail if spotless check fails):
   ```bash
   ./mvnw spotless:apply
   ```

4. Compile the project (skip tests for speed):
   ```bash
   ./mvnw clean compile -DskipTests
   ```

What this does:
- **Spotless**: Auto-fixes formatting so checkstyle doesn't block test runs
- **Clean compile**: Ensures all Java sources compile before running tests

Error handling:
- If compile fails: Show Maven error output — likely a missing dependency or syntax error
- No Docker required: Tests run in-process via Maven

Related commands:
- `/test-execute` - Run tests after environment is ready
- `/prepublish` - Full workflow for testing schema changes in sf-ui-web

Notes:
- No external services needed for unit tests
- Integration tests may require additional setup — check test class annotations
- Maven wrapper handles Java version via `.mvn/wrapper/maven-wrapper.properties`
