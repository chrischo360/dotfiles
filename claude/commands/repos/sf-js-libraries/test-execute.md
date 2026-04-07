Execute tests for sf-js-libraries.

Steps:

1. Verify we're in sf-js-libraries repository:
   ```bash
   git remote -v | grep -q 'sf-js-libraries' || { echo "❌ Not in sf-js-libraries repository"; exit 1; }
   ```

2. Ask what to run via AskUserQuestion:
   "Which tests?"
   Options:
     - All libraries - `yarn test` from repo root (if configured)
     - Specific library - `cd <library-path> && yarn test`
     - Watch mode - `cd <library-path> && yarn test --watch`

3. Run the selected command.

4. On failure: show output, ask how to proceed.

5. After completion: invoke `global:test-log` to record the session.
   Include which library was tested in the "What" field.

Related commands:
- `/test-env` - Install dependencies before running
- `/prepublish` - Full workflow: publish pre-release + test in sf-ui-web/sf-ui-checkout

Notes:
- For changes destined for a consumer repo, `/prepublish` is the more complete test path
- Unit tests here catch library-level bugs; integration testing happens via prepublish
