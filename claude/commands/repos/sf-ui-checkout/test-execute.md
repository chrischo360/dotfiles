Execute tests for sf-ui-checkout.

Steps:

1. Verify we're in sf-ui-checkout repository:
   ```bash
   git remote -v | grep -q 'sf-ui-checkout' || { echo "❌ Not in sf-ui-checkout repository"; exit 1; }
   ```

2. Ask what to run via AskUserQuestion:
   "Which tests?"
   Options:
     - Unit tests - `yarn test`
     - Watch mode - `yarn test --watch`
     - Specific file - prompt for path, then `yarn test <path>`
     - Manual browser verification - open checkout URLs and verify in browser

3. Run the selected command.

4. For manual browser verification: open the dev URLs:
   - Cart: `https://wayfaircom.csnzoo.com/v/checkout/basket/show`
   - Checkout: `https://secure.wayfaircom.csnzoo.com/v/checkout/onepage/view?ft_override_enable_webpack_checkout=ON&webpack-localhost-apps[]=sf-ui-checkout&devbox=sde-php8ccho`

5. On failure: show output, ask how to proceed.

6. After completion: invoke `global:test-log` to record the session.

Related commands:
- `/test-env` - Start the full dev environment (webpack, SSH, realsync) before testing

Notes:
- Unit tests don't require the full dev environment
- Manual browser tests require full env from `/test-env` (full dev environment option)
- Devbox override param: `devbox=sde-php8ccho`
