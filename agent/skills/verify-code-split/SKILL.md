---
name: verify-code-split
description: >-
  Verify whether a next/dynamic() or React.lazy() change actually splits code
  into a separate bundle chunk, using build artifacts (react-loadable-manifest.json,
  bundle analyzer, static chunk files) rather than assumptions. Use when reviewing
  or authoring a PR that claims to code-split/lazy-load a component for performance,
  or when asked to verify a code-split "actually reduces initial JS" for a route.
  Applies to any Next.js (or webpack-based) monorepo; repo-specific commands
  below were validated in wayfair-shared/sf-ui-web.
---

# Verify Code Split

`next/dynamic()` / `React.lazy()` syntax does not guarantee a real bundle split.
The most common way it silently fails: the target module (or a sibling export
from the same module specifier) is **also imported statically** somewhere in
the same file/bundle graph, so webpack still includes it in the initial chunk.
This skill builds both branches and diffs concrete artifacts to prove (or
disprove) that a split actually happened — no live server, no Lighthouse
required for this check.

This does NOT measure real-world LCP/INP/CLS/Speed Index. It only proves
whether the underlying bundle mechanics changed, which is a prerequisite for
any of those metrics to improve. If the user wants real Web Vitals numbers,
that requires running the app and Lighthouse — say so explicitly rather than
presenting this analysis as a runtime performance measurement.

## When to use

- Reviewing a PR that adds `dynamic(() => import(...))` and claims a bundle-size
  or perf win.
- Before/after comparison requested for a specific route's "initial JS".
- Sanity-checking whether an existing dynamic import is a no-op (empty chunk
  files in the manifest is the tell).

## Prerequisites / gotchas (sf-ui-web specifics — adapt for other repos)

- Find the target app's workspace name from its `package.json` (`"name"`
  field) — do not assume it matches the directory name (e.g. `apps/core-funnel`
  is `@wayfair/sf-ui-core-funnel`).
- `apps/core-funnel` already wires `@next/bundle-analyzer` behind
  `ANALYZE=true` in `next.config.js` — no new tooling needed. Check the
  target app's `next.config.js` for the same pattern before assuming it's
  available.
- Building an app directly with `yarn workspace <app> build` **skips building
  its workspace lib dependencies** and will fail with `Module not found` for
  `@repo/*` / `@wayfair/*` packages that don't have a `dist/` yet. Build deps
  first via turbo:
  ```bash
  yarn turbo run build --filter=...@wayfair/sf-ui-core-funnel --output-logs=errors-only
  ```
  (`...pkg` = pkg + everything it depends on. This can take 15-20 minutes
  cold; it's a one-time cost per checkout, cached afterward by turbo/dist
  mtimes as long as you don't switch to a branch with lib changes.)
- If you hit `Cannot find module '@repo/x'` even after the turbo build, run
  `yarn install` first — new workspace packages need to be linked before
  turbo can resolve them.
- Full production builds of this app take ~8-10 minutes and use significant
  memory (`NODE_OPTIONS=--max-old-space-size=12288` is already set in the
  `build` script). Run them with `run_in_background: true` and poll with
  `get_output`, not a blocking foreground call.
- Confirm the PR only touches app-level files (not libs) before skipping the
  turbo dependency build on the second branch:
  ```bash
  git diff origin/main...<branch> --stat
  ```
  If libs changed too, rerun the turbo dependency build after checking out
  that branch.
- The working tree must be clean before switching branches (`git status --short`).
  Note which branch you started on and switch back to it when done.

## Workflow

### Step 1: Build the "before" baseline

```bash
git checkout --detach origin/main   # or whatever the base branch is
yarn install                        # only if workspace deps changed
yarn turbo run build --filter=...<workspace-name> --output-logs=errors-only
ANALYZE=true yarn workspace <workspace-name> build
```

Save/copy anything you'll need before the next build overwrites `.next/`:
```bash
mkdir -p /tmp/bundle-compare
cp apps/<app>/.next/analyze/client.html /tmp/bundle-compare/client-before.html
cp apps/<app>/.next/react-loadable-manifest.json /tmp/bundle-compare/loadable-before.json
```

### Step 2: Build the "after" (PR) branch

```bash
git checkout --detach origin/<pr-branch>
git diff origin/main...HEAD --stat   # confirm scope, rebuild deps if libs changed
ANALYZE=true yarn workspace <workspace-name> build
```

### Step 3: Diff `react-loadable-manifest.json`

This file is the ground truth for every `dynamic()`/`lazy()` boundary Next
recorded and which chunk files back it.

```bash
python3 -c "
import json
d = json.load(open('apps/<app>/.next/react-loadable-manifest.json'))
for k, v in d.items():
    if '<target-module-or-component>'.lower() in k.lower():
        print(k)
        print(' id:', v['id'], 'files:', v['files'])
"
```

- **New entry with a non-empty `files` list** → a real, separate chunk was
  created for that dynamic import. Good sign.
- **New entry with `files: []`** → the dynamic import point was recorded but
  produced *zero* additional chunk files. This means the target module is
  already reachable synchronously from the same entry (commonly: a sibling
  export from the same module specifier is still statically imported nearby).
  The split is a no-op.

### Step 4: Diff the actual chunk containing the target code

Find which physical chunk(s) contain the component/string of interest, on
both builds, and compare chunk IDs and sizes:

```bash
grep -l "TargetComponentName\b" apps/<app>/.next/static/chunks/*.js
du -h <matching-chunk-file>
```

- If the **same chunk ID** shows up on both branches at roughly the **same
  size**, the code did not move — confirms the manifest finding from Step 3.
- If the target code disappears from the large shared chunk and a smaller,
  new chunk (matching the manifest's `files` entry) contains it instead, the
  split worked.

### Step 5: (Optional, more thorough) Route-level chunk trace

For app-router pages, `.next/server/app/<route>/page_client-reference-manifest.js`
lists client module boundaries reachable from that specific route, with
`async` flags per module — useful for tracing whether a component is treated
as sync vs. async from that route's entry specifically, though it's harder to
parse (JSON blob followed by trailing JS statements — extract with a regex up
to the point `JSONDecodeError` fails, or just `grep` for `async` near the
module path).

### Step 6: Restore state

```bash
git checkout <original-branch>
git status --short   # should be clean
```

## Reporting the result

Be explicit about what was and wasn't measured:

- State plainly that this is a **build-artifact diff**, not a runtime
  performance test — no Lighthouse, no live server, no Network tab.
- If the split failed: name the exact reason (e.g. "X and Y are still
  statically imported from the same specifier in the same file, so webpack
  can't create a separate chunk"), and point to the concrete artifact
  evidence (manifest entry + chunk size match).
- If the split worked: report the new chunk's size and confirm it's excluded
  from the chunks required by the route's initial page entry.
- If the user wants real LCP/INP/CLS/Speed Index numbers, say that requires
  a live build (`next start`) or Lighthouse run against a served page, which
  this workflow does not do, and offer to do that as a separate step.
