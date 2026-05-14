#!/usr/bin/env node

import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const PR_COMPLEXITY_TARGET_LINES = 1200;
const TYPICAL_ADJUSTED_FACTOR = 0.87;
const MIN_ADJUSTED_CHANGES = 2;
const DIVISOR =
  (PR_COMPLEXITY_TARGET_LINES * TYPICAL_ADJUSTED_FACTOR) / 10;

const FILE_TYPE_WEIGHTS = {
  CODE: 1,
  TEST: 0.6,
  STYLE: 0.3,
  TEMPLATE: 0.25,
  CONFIG: 0.25,
  DATA: 0.2,
  DOC: 0.1,
  GENERATED: 0,
  ASSET: 0,
};

const CHANGE_TYPE_WEIGHTS = {
  ADDED: 0.8,
  MODIFIED: 1,
  REMOVED: 0.1,
  RENAMED: 0,
};

const CODE_DENSITIES = new Map([
  ['.py', {new: 0.85, modified: 0.92}],
  ['.rb', {new: 0.85, modified: 0.92}],
  ['.go', {new: 0.8, modified: 0.9}],
  ['.sql', {new: 0.8, modified: 0.9}],
  ['.graphql', {new: 0.75, modified: 0.85}],
  ['.gql', {new: 0.75, modified: 0.85}],
  ['.js', {new: 0.7, modified: 0.85}],
  ['.jsx', {new: 0.7, modified: 0.85}],
  ['.mjs', {new: 0.7, modified: 0.85}],
  ['.cjs', {new: 0.7, modified: 0.85}],
  ['.ts', {new: 0.65, modified: 0.8}],
  ['.tsx', {new: 0.65, modified: 0.8}],
  ['.java', {new: 0.55, modified: 0.75}],
  ['.kt', {new: 0.55, modified: 0.75}],
  ['.kts', {new: 0.55, modified: 0.75}],
  ['.swift', {new: 0.6, modified: 0.8}],
  ['.php', {new: 0.7, modified: 0.85}],
  ['.rs', {new: 0.75, modified: 0.88}],
  ['.c', {new: 0.75, modified: 0.88}],
  ['.cc', {new: 0.75, modified: 0.88}],
  ['.cpp', {new: 0.75, modified: 0.88}],
  ['.h', {new: 0.65, modified: 0.8}],
  ['.hpp', {new: 0.65, modified: 0.8}],
]);

const STYLE_EXTENSIONS = new Set([
  '.css',
  '.scss',
  '.sass',
  '.less',
  '.pcss',
]);

const TEMPLATE_EXTENSIONS = new Set([
  '.html',
  '.htm',
  '.hbs',
  '.handlebars',
  '.j2',
  '.jinja',
  '.jinja2',
  '.liquid',
  '.twig',
]);

const DOC_EXTENSIONS = new Set([
  '.adoc',
  '.markdown',
  '.md',
  '.mdx',
  '.rst',
  '.txt',
]);

const DATA_EXTENSIONS = new Set([
  '.csv',
  '.json',
  '.json5',
  '.jsonc',
  '.po',
  '.toml',
  '.xml',
  '.yaml',
  '.yml',
]);

const ASSET_EXTENSIONS = new Set([
  '.avif',
  '.eot',
  '.gif',
  '.ico',
  '.jpeg',
  '.jpg',
  '.mov',
  '.mp3',
  '.mp4',
  '.otf',
  '.pdf',
  '.png',
  '.svg',
  '.ttf',
  '.webm',
  '.webp',
  '.woff',
  '.woff2',
]);

const CONFIG_BASENAMES = new Set([
  '.babelrc',
  '.browserslistrc',
  '.dockerignore',
  '.editorconfig',
  '.eslintignore',
  '.eslintrc',
  '.gitattributes',
  '.gitignore',
  '.lintstagedrc',
  '.npmrc',
  '.nvmrc',
  '.prettierignore',
  '.prettierrc',
  '.stylelintrc',
  '.yarnrc.yml',
  'biome.json',
  'biome.jsonc',
  'codeowners',
  'dockerfile',
  'jest.config.js',
  'jest.config.mjs',
  'jest.config.ts',
  'jsconfig.json',
  'knip.json',
  'makefile',
  'package.json',
  'playwright.config.ts',
  'turbo.json',
]);

const GENERATED_BASENAMES = new Set([
  'composer.lock',
  'gemfile.lock',
  'npm-shrinkwrap.json',
  'package-lock.json',
  'pnpm-lock.yaml',
  'poetry.lock',
  'wgql-persisted-query-manifest.json',
  'yarn.lock',
]);

function lowerPath(filePath) {
  return filePath.replace(/\\/g, '/').toLowerCase();
}

function extensionFor(filePath) {
  const normalizedPath = lowerPath(filePath);

  if (normalizedPath.endsWith('.d.ts')) {
    return '.ts';
  }

  return path.extname(normalizedPath);
}

function isGeneratedFile(filePath) {
  const normalizedPath = lowerPath(filePath);
  const basename = path.basename(normalizedPath);

  return (
    GENERATED_BASENAMES.has(basename) ||
    normalizedPath.includes('/__generated__/') ||
    normalizedPath.includes('/generated/') ||
    normalizedPath.includes('/codegen/') ||
    /\.generated\./.test(normalizedPath) ||
    normalizedPath === '.graphql/schema.json' ||
    normalizedPath === '.graphql/schema.monolith.json'
  );
}

function isTestFile(filePath) {
  const normalizedPath = lowerPath(filePath);

  return (
    normalizedPath.includes('/__tests__/') ||
    normalizedPath.includes('/test/') ||
    normalizedPath.includes('/tests/') ||
    /\.(spec|test)\.[cm]?[jt]sx?$/.test(normalizedPath)
  );
}

function isConfigFile(filePath) {
  const normalizedPath = lowerPath(filePath);
  const basename = path.basename(normalizedPath);

  return (
    CONFIG_BASENAMES.has(basename) ||
    basename.startsWith('dockerfile') ||
    basename.startsWith('makefile') ||
    /^tsconfig(?:\..*)?\.json$/.test(basename) ||
    /(?:^|[.-])config\.(?:cjs|js|json|jsonc|mjs|ts|ya?ml)$/.test(
      basename
    ) ||
    /(?:^|[.-])rc\.(?:cjs|js|json|jsonc|mjs|ts|ya?ml)$/.test(basename) ||
    normalizedPath.startsWith('.github/workflows/') ||
    normalizedPath.startsWith('.buildkite/') ||
    /(^|\/)config(?:s)?\/.+\.(?:json|jsonc|ya?ml)$/.test(normalizedPath)
  );
}

export function classifyFile(filePath) {
  const normalizedPath = lowerPath(filePath);
  const ext = extensionFor(normalizedPath);

  if (isGeneratedFile(normalizedPath)) {
    return 'GENERATED';
  }

  if (ASSET_EXTENSIONS.has(ext)) {
    return 'ASSET';
  }

  if (isTestFile(normalizedPath) && CODE_DENSITIES.has(ext)) {
    return 'TEST';
  }

  if (normalizedPath.endsWith('.css.ts') || STYLE_EXTENSIONS.has(ext)) {
    return 'STYLE';
  }

  if (DOC_EXTENSIONS.has(ext)) {
    return 'DOC';
  }

  if (isConfigFile(normalizedPath)) {
    return 'CONFIG';
  }

  if (TEMPLATE_EXTENSIONS.has(ext)) {
    return 'TEMPLATE';
  }

  if (CODE_DENSITIES.has(ext)) {
    return 'CODE';
  }

  if (DATA_EXTENSIONS.has(ext)) {
    return 'DATA';
  }

  return 'DATA';
}

function densityFor(filePath, fileType, effectiveChangeType) {
  const ext = extensionFor(filePath);
  const useNewDensity = effectiveChangeType === 'ADDED';
  const densityKey = useNewDensity ? 'new' : 'modified';
  const basename = path.basename(lowerPath(filePath));

  if (fileType === 'STYLE') {
    return useNewDensity ? 0.5 : 0.6;
  }

  if (fileType === 'TEMPLATE') {
    return useNewDensity ? 0.5 : 0.65;
  }

  if (fileType === 'DOC') {
    return 0.35;
  }

  if (fileType === 'CONFIG') {
    if (basename.startsWith('dockerfile') || basename.startsWith('makefile')) {
      return useNewDensity ? 0.65 : 0.78;
    }

    if (ext === '.yaml' || ext === '.yml') {
      return 0.6;
    }

    if (ext === '.json' || ext === '.jsonc') {
      return 0.5;
    }

    return useNewDensity ? 0.6 : 0.75;
  }

  if (fileType === 'DATA') {
    if (ext === '.yaml' || ext === '.yml') {
      return 0.6;
    }

    if (ext === '.po' || ext === '.csv') {
      return 0.3;
    }

    return 0.5;
  }

  if (fileType === 'ASSET') {
    return 0.05;
  }

  if (fileType === 'GENERATED') {
    return GENERATED_BASENAMES.has(basename) ? 0.15 : 0.05;
  }

  return CODE_DENSITIES.get(ext)?.[densityKey] ?? (useNewDensity ? 0.65 : 0.8);
}

function deriveChangeType(status) {
  const statusCode = status.charAt(0);

  if (statusCode === 'A' || statusCode === 'C') {
    return 'ADDED';
  }

  if (statusCode === 'D') {
    return 'REMOVED';
  }

  if (statusCode === 'R') {
    return 'RENAMED';
  }

  return 'MODIFIED';
}

function effectiveChangeTypeFor(changeType, changes) {
  if (changeType === 'RENAMED' && changes > 0) {
    return 'MODIFIED';
  }

  return changeType;
}

function normalizeFile(file) {
  const additions = Number(file.additions ?? 0);
  const deletions = Number(file.deletions ?? 0);
  const changes = Number(file.changes ?? additions + deletions);
  const status = file.status ?? 'M';
  const changeType = file.changeType ?? deriveChangeType(status);
  const filePath = file.path ?? file.filePath;

  if (!filePath) {
    throw new Error('Cannot score a file without a path.');
  }

  return {
    additions,
    changeType,
    changes,
    deletions,
    oldPath: file.oldPath ?? null,
    path: filePath,
    status,
  };
}

function fileTypeWeightFor(fileType, configOnly) {
  if (fileType === 'CONFIG' && configOnly) {
    return 1;
  }

  return FILE_TYPE_WEIGHTS[fileType] ?? 0;
}

function countBy(files, property) {
  return files.reduce((counts, file) => {
    const value = file[property];
    counts[value] = (counts[value] ?? 0) + 1;
    return counts;
  }, {});
}

function formatCounts(counts, labels) {
  return Object.entries(counts)
    .filter(([, count]) => count > 0)
    .map(([key, count]) => `${count} ${labels[key] ?? key}`)
    .join(', ');
}

function buildJustification(result) {
  if (result.scoredFiles.length === 0) {
    return 'Empty PR (all files excluded from weighted PR score calculation)';
  }

  const excluded = [];

  if (result.excludedCounts.excludedType > 0) {
    excluded.push(`${result.excludedCounts.excludedType} excluded types`);
  }

  if (result.excludedCounts.renamed > 0) {
    excluded.push(`${result.excludedCounts.renamed} pure renames`);
  }

  if (result.excludedCounts.trivial > 0) {
    excluded.push(
      `${result.excludedCounts.trivial} trivial (low complexity)`
    );
  }

  const changeCounts = countBy(result.scoredFiles, 'effectiveChangeType');
  const labels = {
    ADDED: 'new',
    MODIFIED: 'modified',
    REMOVED: 'deleted',
    RENAMED: 'renamed',
  };
  const changeSummary = formatCounts(changeCounts, labels);
  const prefix = excluded.length > 0 ? `Excluded: ${excluded.join(', ')}; ` : '';

  return `${prefix}${result.scoredFiles.length} files; total adjusted: ${result.totalAdjustedChanges.toFixed(
    1
  )}; raw score: ${result.rawScore.toFixed(2)}; [${changeSummary}]`;
}

export function isNetRevertTitle(title) {
  if (!title.startsWith('Revert ')) {
    return false;
  }

  const occurrences = title.match(/Revert/g)?.length ?? 0;
  return occurrences % 2 === 1;
}

export function scorePullRequest(files, options = {}) {
  const normalizedFiles = files.map(normalizeFile);
  const configOnly =
    normalizedFiles.length > 0 &&
    normalizedFiles.every((file) => classifyFile(file.path) === 'CONFIG');
  const scoredFiles = [];
  const excludedCounts = {
    excludedType: 0,
    renamed: 0,
    trivial: 0,
  };

  const scoredInputFiles = normalizedFiles.map((file) => {
    const fileType = classifyFile(file.path);
    const effectiveChangeType = effectiveChangeTypeFor(
      file.changeType,
      file.changes
    );
    const density = densityFor(file.path, fileType, effectiveChangeType);
    const fileTypeWeight = fileTypeWeightFor(fileType, configOnly);
    const changeTypeWeight =
      CHANGE_TYPE_WEIGHTS[effectiveChangeType] ?? CHANGE_TYPE_WEIGHTS.MODIFIED;
    const adjustedChanges =
      file.changes * density * fileTypeWeight * changeTypeWeight;
    const scoredFile = {
      ...file,
      adjustedChanges,
      changeTypeWeight,
      density,
      effectiveChangeType,
      fileType,
      fileTypeWeight,
    };

    if (file.changeType === 'RENAMED' && file.changes === 0) {
      excludedCounts.renamed += 1;
      return {...scoredFile, excludedReason: 'pure rename'};
    }

    if (fileTypeWeight === 0) {
      excludedCounts.excludedType += 1;
      return {...scoredFile, excludedReason: 'excluded type'};
    }

    if (adjustedChanges < MIN_ADJUSTED_CHANGES) {
      excludedCounts.trivial += 1;
      return {...scoredFile, excludedReason: 'trivial'};
    }

    scoredFiles.push(scoredFile);
    return scoredFile;
  });

  const totalAdjustedChanges = scoredFiles.reduce(
    (total, file) => total + file.adjustedChanges,
    0
  );
  const fileCountFactor =
    scoredFiles.length === 0
      ? 0
      : 1 + 0.25 * (1 - Math.exp(-scoredFiles.length / 10));
  const rawScore =
    scoredFiles.length === 0
      ? 0
      : 1 + (totalAdjustedChanges * fileCountFactor) / DIVISOR;
  const computedScore =
    scoredFiles.length === 0
      ? 0
      : Math.max(1, Math.min(10, Math.round(rawScore)));
  const isRevert =
    options.isRevert ?? isNetRevertTitle(options.title ?? '');
  const isSlush = Boolean(options.isSlush);
  const result = {
    configOnly,
    excludedCounts,
    fileCountFactor,
    files: scoredInputFiles,
    isRevert,
    isSlush,
    rawScore,
    score: computedScore,
    scoredFiles,
    totalAdjustedChanges,
  };
  const baseJustification = buildJustification(result);

  if (isSlush) {
    return {
      ...result,
      justification:
        `Slush branch PR: score is 0 because child PRs already account ` +
        `for the review effort; ${baseJustification}`,
      score: 0,
    };
  }

  if (isRevert) {
    return {
      ...result,
      justification:
        `Revert PR: score is 0 as this PR reverts previously merged ` +
        `work; ${baseJustification}`,
      score: 0,
    };
  }

  return {...result, justification: baseJustification};
}

function gitOutput(args, options = {}) {
  return execFileSync('git', args, {
    cwd: options.cwd ?? process.cwd(),
    encoding: options.encoding ?? 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

function hasGitRef(ref) {
  try {
    gitOutput(['rev-parse', '--verify', '--quiet', ref]);
    return true;
  } catch {
    return false;
  }
}

function defaultBaseRef() {
  const candidates = ['origin/main', 'upstream/main', 'main', 'master'];
  const base = candidates.find(hasGitRef);

  if (!base) {
    throw new Error(
      `Unable to find a default base ref. Pass one explicitly with --base.`
    );
  }

  return base;
}

function mergeBase(base, head) {
  return gitOutput(['merge-base', base, head]).trim();
}

function parseNumstatValue(value) {
  return value === '-' ? 0 : Number(value);
}

export function parseNumstatZ(output) {
  const tokens = output.toString('utf8').split('\0');
  const entries = [];
  let index = 0;

  while (index < tokens.length) {
    const header = tokens[index++];

    if (!header) {
      break;
    }

    const fields = header.split('\t');
    const additions = parseNumstatValue(fields[0]);
    const deletions = parseNumstatValue(fields[1]);
    let filePath = fields.slice(2).join('\t');
    let oldPath = null;

    if (filePath === '') {
      oldPath = tokens[index++];
      filePath = tokens[index++];
    }

    entries.push({
      additions,
      binary: fields[0] === '-' || fields[1] === '-',
      deletions,
      oldPath,
      path: filePath,
    });
  }

  return entries;
}

export function parseNameStatusZ(output) {
  const tokens = output.toString('utf8').split('\0');
  const entries = [];
  let index = 0;

  while (index < tokens.length) {
    const status = tokens[index++];

    if (!status) {
      break;
    }

    const statusCode = status.charAt(0);
    let oldPath = null;
    let filePath = tokens[index++];

    if (statusCode === 'R' || statusCode === 'C') {
      oldPath = filePath;
      filePath = tokens[index++];
    }

    entries.push({
      oldPath,
      path: filePath,
      status,
    });
  }

  return entries;
}

function diffFiles(options) {
  const base = options.base ?? defaultBaseRef();
  const head = options.head ?? 'HEAD';
  const mergeBaseRef = options.includeWorkingTree ? mergeBase(base, head) : null;
  const diffSpec = mergeBaseRef ?? `${base}...${head}`;
  const diffLabel = options.includeWorkingTree
    ? `${mergeBaseRef}..working tree`
    : diffSpec;
  const nameStatusOutput = gitOutput(
    ['diff', '--name-status', '-z', '--find-renames', diffSpec],
    {encoding: 'buffer'}
  );
  const numstatOutput = gitOutput(
    ['diff', '--numstat', '-z', '--find-renames', diffSpec],
    {encoding: 'buffer'}
  );
  const statusEntries = parseNameStatusZ(nameStatusOutput);
  const numstatByPath = new Map(
    parseNumstatZ(numstatOutput).map((entry) => [entry.path, entry])
  );

  return {
    base,
    diffLabel,
    diffSpec,
    files: statusEntries.map((entry) => {
      const stats = numstatByPath.get(entry.path) ?? {
        additions: 0,
        deletions: 0,
      };

      return {
        ...entry,
        additions: stats.additions,
        changes: stats.additions + stats.deletions,
        deletions: stats.deletions,
      };
    }),
    head,
  };
}

function readArgValue(args, index, option) {
  const value = args[index + 1];

  if (!value || value.startsWith('--')) {
    throw new Error(`${option} requires a value.`);
  }

  return value;
}

function parseArgs(argv) {
  const options = {
    base: null,
    head: 'HEAD',
    includeWorkingTree: false,
    isRevert: null,
    isSlush: false,
    json: false,
    maxFiles: 80,
    title: '',
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--base' || arg === '-b') {
      options.base = readArgValue(argv, index, arg);
      index += 1;
    } else if (arg === '--head') {
      options.head = readArgValue(argv, index, arg);
      index += 1;
    } else if (arg === '--title') {
      options.title = readArgValue(argv, index, arg);
      index += 1;
    } else if (arg === '--max-files') {
      options.maxFiles = Number(readArgValue(argv, index, arg));
      index += 1;
    } else if (arg === '--include-working-tree') {
      options.includeWorkingTree = true;
    } else if (arg === '--json') {
      options.json = true;
    } else if (arg === '--revert') {
      options.isRevert = true;
    } else if (arg === '--slush') {
      options.isSlush = true;
    } else if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!Number.isFinite(options.maxFiles) || options.maxFiles < 0) {
    throw new Error('--max-files must be a non-negative number.');
  }

  return options;
}

function helpText() {
  return `Usage:
  sage-pr-score [options]

Options:
  -b, --base <ref>          Base branch/ref. Defaults to origin/main, then main.
      --head <ref>          Head branch/ref. Defaults to HEAD.
      --include-working-tree
                            Score committed and uncommitted local changes.
      --title <title>       PR title, used for net-revert detection.
      --revert              Force revert PR scoring.
      --slush               Force slush branch scoring.
      --json                Print machine-readable JSON.
      --max-files <number>  Number of file rows to print. Defaults to 80.
  -h, --help                Show this help.

Notes:
  The script implements the documented V9 math against a local git diff.
  Offline mode cannot discover slush branches from GitHub history, so pass
  --slush when you already know the PR is a slush branch.`;
}

function formatNumber(value, digits = 1) {
  return value.toFixed(digits);
}

function formatHuman(result, context, options) {
  const lines = [
    `Weighted PR score: ${result.score}/10`,
    `Range: ${context.diffLabel}`,
    result.justification,
    `Config-only: ${result.configOnly ? 'yes' : 'no'}`,
  ];

  if (result.files.length === 0) {
    lines.push('', 'No changed files found in this diff.');
    return lines.join('\n');
  }

  lines.push(
    '',
    `Raw score: ${formatNumber(result.rawScore, 2)}`,
    `Total adjusted changes: ${formatNumber(result.totalAdjustedChanges)}`,
    `File count factor: ${formatNumber(result.fileCountFactor, 3)}`,
    '',
    'Files:'
  );

  const visibleFiles = result.files.slice(0, options.maxFiles);

  for (const file of visibleFiles) {
    const marker = file.excludedReason ? 'excluded' : 'scored';
    const change = `${file.additions}+/${file.deletions}-`;
    const adjusted = formatNumber(file.adjustedChanges);

    lines.push(
      `  ${marker.padEnd(8)} ${file.status.padEnd(5)} ${file.fileType.padEnd(
        9
      )} ${String(change).padStart(11)} -> ${String(adjusted).padStart(
        6
      )}  ${file.path}`
    );
  }

  if (result.files.length > visibleFiles.length) {
    lines.push(
      `  ... ${result.files.length - visibleFiles.length} more files omitted`
    );
  }

  return lines.join('\n');
}

async function main() {
  const options = parseArgs(process.argv.slice(2));

  if (options.help) {
    console.log(helpText());
    return;
  }

  const context = diffFiles(options);
  const result = scorePullRequest(context.files, options);

  if (options.json) {
    console.log(JSON.stringify({...context, ...result}, null, 2));
    return;
  }

  console.log(formatHuman(result, context, options));
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
