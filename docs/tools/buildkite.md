# Buildkite Local Checks

Generate and run Buildkite CI checks locally from pipeline YAML files.

Script: `~/dotfiles/scripts/codebase/buildkite-local-checks.mjs`
Alias: `bk-local`

## Usage

```bash
bk-local                                    # Auto-detect pipeline file
bk-local .buildkite/pipeline-merge-queue.yml  # Specific pipeline

./.buildkite/local-checks.sh               # Run all checks
./.buildkite/local-checks.sh --skip-tests
./.buildkite/local-checks.sh --skip-build
./.buildkite/local-checks.sh --only "Lint"
```

## Examples

**sf-ui-web:**
```bash
cd ~/codebase/sf-ui-web
bk-local .buildkite/pipeline-merge-queue.yml
./.buildkite/local-checks.sh --skip-tests
```

**block-builder-api:**
```bash
cd ~/codebase/block-builder-api
bk-local .buildkite/test.yml
./.buildkite/local-checks.sh --only "unit"
```

## What It Does

1. Parses Buildkite YAML pipeline
2. Extracts runnable commands from steps
3. Filters out CI-specific operations (deploys, artifacts, K8s)
4. Generates:
   - `.buildkite/local-checks.sh` — executable bash script
   - `.buildkite/local-checks.json` — JSON manifest

Generated files are gitignored per-repo.

## Requirements

- Node.js
- js-yaml: `npm install -g js-yaml`
