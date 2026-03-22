# buildkite-local-checks

Generate executable bash scripts from Buildkite YAML pipeline files to run CI checks locally.

## Usage

```bash
# Generate checks (auto-detects pipeline file)
cd ~/codebase/sf-ui-web
bk-local

# Generate from specific pipeline
bk-local .buildkite/pipeline-merge-queue.yml

# Run generated checks
./.buildkite/local-checks.sh
./.buildkite/local-checks.sh --skip-tests
./.buildkite/local-checks.sh --skip-build
./.buildkite/local-checks.sh --only "Lint"
```

## What It Does

1. Parses Buildkite YAML pipeline files
2. Extracts runnable commands from steps
3. Filters out CI-specific operations (deploys, artifacts, K8s steps)
4. Generates two files:
   - `.buildkite/local-checks.sh` - executable bash script
   - `.buildkite/local-checks.json` - JSON manifest of checks

## Features

- Auto-detects common pipeline file names
- Works across repo types (Node.js monorepos, Java/Maven, etc.)
- Cleans commands (removes CI env vars, echo statements, buildkite-agent calls)
- Generated script supports flags: `--skip-tests`, `--skip-build`, `--only`
- Colored output with pass/fail summary

## Requirements

- Node.js
- js-yaml (`npm install -g js-yaml`)

## Examples

**sf-ui-web (Node.js monorepo)**:
```bash
cd ~/codebase/sf-ui-web
bk-local .buildkite/pipeline-merge-queue.yml
./.buildkite/local-checks.sh --skip-tests
```

**block-builder-api (Java/Maven)**:
```bash
cd ~/codebase/block-builder-api
bk-local .buildkite/test.yml
./.buildkite/local-checks.sh --only "unit"
```

## Files

- **Script**: `~/dotfiles/scripts/codebase/buildkite-local-checks.mjs`
- **Alias**: `bk-local` (defined in `~/dotfiles/zsh/custom/05-aliases.zsh`)
- **Generated** (per-repo, gitignored):
  - `.buildkite/local-checks.sh`
  - `.buildkite/local-checks.json`
