#!/usr/bin/env node

/**
 * buildkite-local-checks.mjs
 *
 * Generic tool to convert Buildkite YAML pipelines into local check scripts.
 * Works across repos (Node.js monorepos, Java/Maven, etc.)
 *
 * Usage:
 *   bk-local [pipeline-file]
 *   bk-local .buildkite/pipeline-merge-queue.yml
 *   bk-local  # Auto-detects pipeline file
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ANSI colors
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function error(message) {
  log(`Error: ${message}`, 'red');
  process.exit(1);
}

// Try to import js-yaml
let yaml;
try {
  // Try dynamic import first
  yaml = await import('js-yaml');
} catch (e) {
  // Try loading from global node_modules
  try {
    const { execSync } = await import('child_process');
    const globalPath = execSync('npm root -g', { encoding: 'utf8' }).trim();
    const yamlPath = path.join(globalPath, 'js-yaml', 'index.js');
    const { createRequire } = await import('module');
    const require = createRequire(import.meta.url);
    yaml = require(yamlPath);
  } catch (err) {
    // Final fallback
    try {
      const { createRequire } = await import('module');
      const require = createRequire(import.meta.url);
      yaml = require('js-yaml');
    } catch (finalErr) {
      // Will be handled in parseYaml
    }
  }
}

/**
 * Parse YAML file
 */
function parseYaml(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');

  if (yaml) {
    try {
      return yaml.load(content);
    } catch (e) {
      error(`Failed to parse YAML: ${e.message}`);
    }
  } else {
    error('js-yaml not available. Install with: npm install -g js-yaml');
  }
}

/**
 * Auto-detect pipeline file in current directory
 */
function detectPipelineFile() {
  const candidates = [
    '.buildkite/pipeline-merge-queue.yml',
    '.buildkite/pipeline-dev.yml',
    '.buildkite/pipeline.yml',
    '.buildkite/build.yml',
    '.buildkite/test.yml',
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  error('No Buildkite pipeline file found. Tried: ' + candidates.join(', '));
}

/**
 * Check if step should be skipped
 */
function shouldSkipStep(step, stepName) {
  // Skip non-command steps
  if (step.block || step.trigger || step.wait) {
    return true;
  }

  // Skip deploy/QA/ephemeral steps
  const skipKeywords = [
    'deploy', 'qa build', 'ephemeral', 'docker build',
    'helm', 'kubernetes', 'k8s',
    'install dependencies', // yarn install steps
  ];

  const lowerLabel = (stepName || '').toLowerCase();
  if (skipKeywords.some(keyword => lowerLabel.includes(keyword))) {
    return true;
  }

  return false;
}

/**
 * Extract commands from various step formats
 */
function extractCommands(step) {
  const commands = [];

  // Direct commands array
  if (step.commands && Array.isArray(step.commands)) {
    commands.push(...step.commands);
  }

  // Single command string
  if (step.command && typeof step.command === 'string') {
    commands.push(step.command);
  }

  // Docker compose plugin commands (block-builder-api style)
  if (step.plugins) {
    for (const plugin of Object.values(step.plugins)) {
      if (typeof plugin === 'object') {
        if (plugin['docker-compose']?.command) {
          commands.push(plugin['docker-compose'].command);
        }
        if (plugin.command) {
          commands.push(plugin.command);
        }
      }
    }
  }

  return commands;
}

/**
 * Clean individual command
 */
function cleanCommand(cmd) {
  // Remove echo statements (logging only)
  if (cmd.trim().startsWith('echo ')) {
    return null;
  }

  // Remove buildkite-agent commands
  if (cmd.includes('buildkite-agent')) {
    return null;
  }

  // Remove commands that require CI secrets/auth
  const requiresSecrets = [
    'BUILDKITE_DECRYPT',
    'GITHUB_API_TOKEN',
    'GITHUB_CLOUD_API_TOKEN',
    'ARTIFACTORY_AUTH',
  ];
  if (requiresSecrets.some(secret => cmd.includes(secret))) {
    return null;
  }

  // Strip environment variables
  cmd = cmd
    .replace(/CYPRESS_INSTALL_BINARY=0\s*/g, '')
    .replace(/PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1\s*/g, '')
    .replace(/CI=true\s*/g, '')
    .replace(/EXIT_STATUS=\$\?\s*/g, '');

  // Remove --silent flag from tests (want output locally)
  cmd = cmd.replace(/--silent\s*/g, '');

  // Remove artifact uploads
  if (cmd.includes('tar ') || cmd.includes('artifact upload')) {
    return null;
  }

  return cmd.trim() || null;
}

/**
 * Check if step might require CI infrastructure
 */
function detectInfrastructureWarnings(stepName, commands) {
  const warnings = [];

  // Check for auth/secrets requirements
  const requiresAuth = [
    'register', 'graphql client', 'api', 'publish',
  ];
  if (requiresAuth.some(keyword => stepName.toLowerCase().includes(keyword))) {
    warnings.push('may require authentication/secrets');
  }

  // Check for Docker dependencies
  const allCommands = commands.join(' ');
  if (allCommands.includes('docker') || allCommands.includes('docker-compose')) {
    warnings.push('requires Docker');
  }

  return warnings;
}

/**
 * Extract runnable checks from pipeline
 */
function extractChecks(pipeline) {
  const checks = [];

  if (!pipeline.steps || !Array.isArray(pipeline.steps)) {
    error('No steps found in pipeline');
  }

  for (const step of pipeline.steps) {
    const stepName = step.label || step.key || 'Unknown';

    if (shouldSkipStep(step, stepName)) {
      log(`  Skipping: ${stepName}`, 'gray');
      continue;
    }

    const rawCommands = extractCommands(step);
    if (rawCommands.length === 0) {
      log(`  Skipping: ${stepName} (no commands)`, 'gray');
      continue;
    }

    // Clean commands
    const cleanedCommands = rawCommands
      .map(cleanCommand)
      .filter(cmd => cmd !== null);

    if (cleanedCommands.length === 0) {
      log(`  Skipping: ${stepName} (no runnable commands)`, 'gray');
      continue;
    }

    // Detect potential issues
    const warnings = detectInfrastructureWarnings(stepName, cleanedCommands);

    checks.push({
      label: stepName,
      commands: cleanedCommands,
      warnings: warnings.length > 0 ? warnings : undefined,
    });

    const warningSuffix = warnings.length > 0 ? ` (⚠️  ${warnings.join(', ')})` : '';
    log(`  Extracted: ${stepName}${warningSuffix}`, 'green');
  }

  return checks;
}

/**
 * Generate bash script from checks
 */
function generateBashScript(checks) {
  const script = `#!/bin/bash
set -e

# Track failures
FAILED_CHECKS=()
SKIPPED_CHECKS=()

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m' # No Color

# Parse flags
SKIP_TESTS=false
SKIP_BUILD=false
ONLY_CHECK=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --only)
      ONLY_CHECK="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-tests] [--skip-build] [--only <check-name>]"
      exit 1
      ;;
  esac
done

run_check() {
  local label="$1"
  local cmd="$2"
  local warning="$3"

  # Skip if --only specified and doesn't match
  if [[ -n "$ONLY_CHECK" ]] && [[ ! "$label" =~ "$ONLY_CHECK" ]]; then
    return
  fi

  # Skip tests if requested
  if [[ "$SKIP_TESTS" == true ]] && [[ "$label" =~ [Tt]est|[Cc]ypress|[Jj]est|[Pp]laywright ]]; then
    SKIPPED_CHECKS+=("$label")
    return
  fi

  # Skip builds if requested
  if [[ "$SKIP_BUILD" == true ]] && [[ "$label" =~ [Bb]uild ]]; then
    SKIPPED_CHECKS+=("$label")
    return
  fi

  echo ""
  echo "========================================"
  echo "Running: $label"
  if [[ -n "$warning" ]]; then
    echo -e "\${YELLOW}⚠️  Warning: $warning\${NC}"
  fi
  echo "========================================"

  if eval "$cmd"; then
    echo -e "\${GREEN}✓ $label passed\${NC}"
  else
    echo -e "\${RED}✗ $label failed\${NC}"
    FAILED_CHECKS+=("$label")
  fi
}

# Run all checks
${checks.map(check => {
  const escapedCmd = check.commands.join(' && ').replace(/'/g, "'\\''");
  const warning = check.warnings ? check.warnings.join(', ') : '';
  return `run_check "${check.label}" '${escapedCmd}' "${warning}"`;
}).join('\n')}

# Summary
echo ""
echo "========================================"
echo "Summary"
echo "========================================"

if [[ \${#SKIPPED_CHECKS[@]} -gt 0 ]]; then
  echo -e "\${YELLOW}Skipped \${#SKIPPED_CHECKS[@]} check(s):\${NC}"
  for check in "\${SKIPPED_CHECKS[@]}"; do
    echo "  - $check"
  done
fi

if [[ \${#FAILED_CHECKS[@]} -eq 0 ]]; then
  echo -e "\${GREEN}All checks passed!\${NC}"
  exit 0
else
  echo -e "\${RED}Failed \${#FAILED_CHECKS[@]} check(s):\${NC}"
  for check in "\${FAILED_CHECKS[@]}"; do
    echo "  - $check"
  done
  exit 1
fi
`;

  return script;
}

/**
 * Main
 */
function main() {
  const args = process.argv.slice(2);
  const pipelineFile = args[0] || detectPipelineFile();

  if (!fs.existsSync(pipelineFile)) {
    error(`Pipeline file not found: ${pipelineFile}`);
  }

  log(`Parsing: ${pipelineFile}`, 'blue');

  const pipeline = parseYaml(pipelineFile);
  const checks = extractChecks(pipeline);

  if (checks.length === 0) {
    error('No runnable checks found in pipeline');
  }

  log(`\nExtracted ${checks.length} check(s)`, 'green');

  // Write bash script
  const scriptPath = '.buildkite/local-checks.sh';
  const scriptDir = path.dirname(scriptPath);

  if (!fs.existsSync(scriptDir)) {
    fs.mkdirSync(scriptDir, { recursive: true });
  }

  const bashScript = generateBashScript(checks);
  fs.writeFileSync(scriptPath, bashScript, { mode: 0o755 });
  log(`\nGenerated: ${scriptPath}`, 'green');

  // Write JSON manifest
  const jsonPath = '.buildkite/local-checks.json';
  fs.writeFileSync(jsonPath, JSON.stringify({ checks }, null, 2));
  log(`Generated: ${jsonPath}`, 'green');

  // Usage info
  log('\nUsage:', 'blue');
  log('  ./.buildkite/local-checks.sh');
  log('  ./.buildkite/local-checks.sh --skip-tests');
  log('  ./.buildkite/local-checks.sh --skip-build');
  log('  ./.buildkite/local-checks.sh --only "Lint"');
}

main();
