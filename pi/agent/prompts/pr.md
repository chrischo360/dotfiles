---
description: Write a PR description from staged/recent git changes
---
Write a pull request description for these changes.

Run `git diff main...HEAD` (or `git diff --cached` if staged) to see what changed.

Format:
```
## What
[1-2 sentences: what does this PR do?]

## Why
[1-2 sentences: what problem does it solve / what value does it add?]

## How
[bullet points: key technical decisions, non-obvious implementation details]

## Testing
[how was this tested? what edge cases were considered?]
```

Keep it concise. No fluff. Engineers are busy.
$@
