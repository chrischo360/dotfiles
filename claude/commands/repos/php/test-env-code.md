Set up the code test environment for the PHP monorepo.

Verifies the local PHP toolchain and installs Composer dependencies. For PHPUnit and code style checks — no SSH or remote services needed.

Steps:

1. Verify we're in the PHP repository:
   ```bash
   git remote -v | grep -q 'php' || { echo "❌ Not in PHP repository"; exit 1; }
   ```

2. Verify PHP 8.1 is available:
   ```bash
   /opt/homebrew/opt/php@8.1/bin/php --version || { echo "❌ PHP 8.1 not found"; exit 1; }
   ```

3. Install Composer dependencies:
   ```bash
   cd includes/sdk/composer-packages && composer install
   ```

What this does:
- Validates local PHP 8.1 binary is accessible
- Installs Composer packages needed for PHPUnit and PHPCodeSniffer

Error handling:
- PHP not found: `brew install php@8.1` or check Homebrew prefix
- Composer not found: `brew install composer`

Related commands:
- `/test-execute` - Run PHPUnit or php-sniff/php-fix
- `/test-env-e2e` - Set up SSH + realsync for full stack testing

Notes:
- PHP binary: `/opt/homebrew/opt/php@8.1/bin/php`
- CSNStores standard used for code style (Wayfair-specific)
