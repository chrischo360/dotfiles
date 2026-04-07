Deploy to a Garden ephemeral namespace using `garden-deploy`.

**Steps:**

1. Check `project.garden.yml` exists in the current directory. If not, error: "Run from the root of a Garden-enabled repo."

2. Ask for namespace via AskUserQuestion:
   "What's the ephemeral namespace?"
   - Free-text input (e.g. `ephemeral-xxxx`)
   - Hint: create one with `wf_garden namespace create --testNS=true`

3. Ask what to deploy via AskUserQuestion:
   "Deploy options for **${NAMESPACE}**?"
   - All services — `garden-deploy ${NAMESPACE}`
   - Specific service — prompt for service name, run `garden-deploy ${NAMESPACE} <service>`
   - With sync — `garden-deploy ${NAMESPACE} --sync`
   - Custom flags — prompt for flags, run `garden-deploy ${NAMESPACE} <flags>`

4. Confirm the command, then run it.

5. On failure: show error output and ask how to proceed (retry, show logs, validate config, exit).
