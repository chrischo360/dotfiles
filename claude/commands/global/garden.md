Deploy to a Garden ephemeral namespace using `garden-deploy`.

**Steps:**

1. Check `project.garden.yml` exists in the current directory. If not, error: "Run from the root of a Garden-enabled repo."

2. Auto-detect namespace:
   ```bash
   NAMESPACE=$(wf_garden namespace show 2>/dev/null)
   ```

3. If namespace found, confirm via AskUserQuestion:
   "Deploy to **${NAMESPACE}**?"
   - Yes — proceed
   - No, use a different namespace — prompt for namespace string
   - Create a new one — run `wf_garden namespace create --testNS=true` and parse output for `ephemeral-xxxx`

   If no namespace found, ask via AskUserQuestion:
   "No namespace found for this branch. What would you like to do?"
   - Create one — run `wf_garden namespace create --testNS=true` and parse output for `ephemeral-xxxx`
   - Enter manually — prompt for namespace string

4. Ask what to deploy via AskUserQuestion:
   "Deploy options for **${NAMESPACE}**?"
   - All services — `garden-deploy ${NAMESPACE}`
   - Specific service — prompt for service name, run `garden-deploy ${NAMESPACE} <service>`
   - With sync — `garden-deploy ${NAMESPACE} --sync`
   - Custom flags — prompt for flags, run `garden-deploy ${NAMESPACE} <flags>`

5. Confirm the final command, then run it.

6. On failure: show error output and ask how to proceed (retry, show logs via `garden logs <service>`, validate config via `garden validate`, exit).
