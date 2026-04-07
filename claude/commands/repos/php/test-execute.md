Execute tests for the PHP monorepo.

Steps:

1. Verify we're in the PHP repository:
   ```bash
   git remote -v | grep -q 'php' || { echo "❌ Not in PHP repository"; exit 1; }
   ```

2. Ask what to run via AskUserQuestion:
   "Which tests?"
   Options:
     - PHPUnit - run unit test suite
     - Code style check - `php-sniff` on changed files
     - Code style fix - `php-fix` on changed files
     - Specific test class - prompt for class path

3. Run the selected command:
   - PHPUnit: `./vendor/bin/phpunit` (or project-specific path)
   - Style check: `php-sniff` (alias in ~/dotfiles/zsh/custom/05-aliases.zsh)
   - Style fix: `php-fix` (alias in ~/dotfiles/zsh/custom/05-aliases.zsh)
   - Specific class: prompt for path, run with `--filter` or direct path

4. On failure: show output, ask how to proceed.

5. After completion: invoke `global:test-log` to record the session.

Related commands:
- `/test-env` - Verify PHP toolchain and optionally start SSH/realsync

Notes:
- `php-sniff` and `php-fix` use PHPCodeSniffer with CSNStores standard
- They automatically target git-changed PHP files when run with no arguments
- PHP binary: `/opt/homebrew/opt/php@8.1/bin/php`
