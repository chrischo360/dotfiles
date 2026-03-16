Research accomplishments and log to promotion file with interactive guidance.

Steps:

1. Parse command arguments
   - Check for `--week N` flag to specify week number for backfill
   - Check for `--date YYYY-MM-DD` flag to specify date for backfill
   - Default: use current week if no flags provided

2. Determine target week details
   - If --week provided: use specified week number
   - If --date provided: calculate ISO week number from date
   - Default: calculate current ISO week number using `date +%V`
   - Calculate week's Monday-Friday date range in format YYYY-MM-DD
   - Store week number and date range for later use

3. Locate week file
   - Current week: `~/notes/plans/week.md`
   - Backfill week: search `~/notes/plans/archive/` for file matching pattern `*week-{N}_*.md` or `*week-{N}.md`
   - If backfill week file not found, list available archive files and exit with error
   - Extract week header to confirm date range

4. Research GitHub activity (via gh CLI)
   **Merged PRs authored this week:**
   ```bash
   gh pr list --repo wayfair/sf-ui-web --state merged --author @me --limit 100 --json number,title,mergedAt,url,files
   ```
   - Filter results where mergedAt falls within week's date range
   - For each PR, check file count and paths to identify scope:
     * Multi-component PRs (3+ directories) = project ownership candidate
     * iOS-specific (files in ios/ or *.swift) = iOS section candidate
     * Documentation (README, .md files) = docs/knowledge sharing candidate
   - Store: PR number, title, URL, file count, primary component/directory

   **PRs reviewed with substantive comments:**
   ```bash
   gh search prs --reviewed-by @me --merged --limit 100 --json number,title,mergedAt,url,repository
   ```
   - Filter results where mergedAt falls within week's date range
   - For each PR, fetch review details:
     ```bash
     gh pr view {number} --repo {repo} --json reviews
     ```
   - Filter for reviews with body content (substantive comments, not just approvals)
   - Count comment length to identify substantive reviews (>50 chars)
   - Store: PR number, title, URL, repo, review comment count

5. Research Jira tickets (from week file)
   - Read week file content
   - Extract PGL-XXX references using regex: `PGL-\d+`
   - For each unique ticket ID found:
     * Parse associated task text from surrounding context
     * Check if task is completed `[x]` or in progress `[ ]`
     * Store: ticket ID, task description, completion status

6. Extract completed tasks (from week file)
   - Parse all lines matching pattern: `- [x] <task description>`
   - Group by day (Monday-Friday sections) if possible
   - Identify proactive work indicators:
     * Tasks without PGL ticket references
     * Tasks with keywords: "propose", "identify", "surface", "drive", "improve"
     * Tasks in Backlog section marked complete
   - Store: task text, day, proactive flag

7. Research Glean content (via company_search MCP)
   **IMPORTANT:** Handle MCP availability gracefully
   - Check if Glean MCP (company_search) is available
   - If available, search for authored content:
     ```
     Query: "author:@me created:{monday_date} to {friday_date}"
     Datasources: ["confluence", "google_drive", "infohub", "slack"]
     ```
   - Parse results and categorize:
     * Confluence: RFCs, technical designs, project docs
     * Infohub: knowledge sharing articles, documentation
     * Google Drive: presentations, design docs, spreadsheets
     * Slack: filter for substantive messages (exclude standup updates)
       - Look for: announcements, technical help, project updates, discussions
       - Exclude: short replies (<100 chars), standup messages, emoji reactions
   - Store: title, source, URL, content type
   - If MCP unavailable or times out: log warning, continue without Glean data

8. Parse promotion file context for goal alignment
   - Read `~/notes/plans/promotion_summer_2026.md`
   - Extract **5 Development Goals** with concrete targets:
     * Goal 1 - Project Scope & Impact: 2 full-scope projects, 1 RFC, 1 proactive improvement
     * Goal 2 - Hunger & Proactiveness: 1 tech debt/quick win per month
     * Goal 3 - iOS Ownership: 1 iOS initiative, be go-to person by EOQ2
     * Goal 4 - Knowledge Sharing: 1 doc per project, 1 presentation, share AI tooling
     * Goal 5 - Community & Collaboration: substantive reviews, speak up 2x/sprint
   - Extract **Mike Review feedback** (promotion process insights):
     * Key themes: Support → Ownership, visibility matters, portfolio focus
     * Areas to improve: timeline commitments, expand knowledge (HFC, Member Total Benefits)
     * Calibration notes: 20 L1s, 10 picked; RFCs/code reviews matter
   - Extract **Metrics Dashboard** requirements
   - Parse existing **Weekly Log** entries to calculate current progress:
     * Count full-scope projects logged (target: 2 by summer)
     * Count RFCs/technical designs (target: 1 by summer)
     * Count proactive improvements shipped (target: 1 by summer)
     * Count docs written per project
     * Count iOS initiatives (target: 1 by summer)
     * Count tech debt/quick wins per month (target: 1/month)
   - Calculate **gaps**: targets - current progress for each goal

9. Organize findings by weekly check-in sections with goal alignment
   Map research data to promotion file sections **and track progress toward development goals**:

   **Shipped / moved forward:**
   - Merged PRs (title + URL)
   - Completed tasks with PGL tickets
   - Slack announcements of shipped features (from Glean)
   - **Goal tracking**: Does this count toward full-scope projects (Goal 1)?

   **Code reviews (substantive):**
   - PRs reviewed with comment counts >50 chars
   - Format: "PR #{number}: {title} ({comment_count} comments)" + URL
   - **Goal tracking**: Meets Goal 5 (Community & Collaboration)

   **Proactive (surfaced, proposed, drove — not assigned):**
   - Tasks flagged as proactive (no PGL ticket or proactive keywords)
   - GitHub issues/discussions you created
   - Slack messages identifying problems or proposing solutions
   - **Goal tracking**: Counts toward Goal 1 (proactive improvement) and Goal 2 (tech debt/quick win)

   **Docs / knowledge sharing:**
   - PRs with documentation changes (README, .md files)
   - Confluence pages, Infohub articles (from Glean)
   - Slack technical explanations or help provided (from Glean)
   - **Goal tracking**: Tracks toward Goal 4 (1 doc per project, presentations)

   **Project ownership moments:**
   - Multi-component PRs (3+ directories or 10+ files)
   - End-to-end features you drove
   - Tasks indicating full ownership (kickoff → delivery)
   - **Goal tracking**: Directly measures Goal 1 (2 full-scope projects target)

   **iOS:**
   - PRs with iOS-specific files (ios/, *.swift, iOS-related components)
   - iOS-tagged tickets from week file
   - **Goal tracking**: Tracks toward Goal 3 (1 iOS initiative, be go-to person)

10. Interactive entry with AskUserQuestion (goal-aware prompts)
    For each section, present findings with goal-alignment context:

    **Present findings with development goal context:**
    - Show categorized items with descriptions and URLs
    - **Include goal progress indicators**:
      * "Shipped / moved forward" → Show full-scope project count (X/2 target)
      * "Proactive" → Show tech debt/quick wins this month (X/1 target)
      * "Docs / knowledge sharing" → Show docs written per project
      * "Project ownership" → Show full-scope projects (X/2 target)
      * "iOS" → Show iOS initiatives (X/1 target), note if below target
    - **Include Mike's feedback reminders** where relevant:
      * Project ownership section: "Remember: Support → Ownership"
      * Proactive section: "Mike emphasized: pick up things outside of tickets"
      * Docs section: "Portfolio matters: RFCs, code reviews"
    - Mark items as auto-detected vs user-added

    **Use AskUserQuestion for each section:**
    - Question format: "What should we include in '{section name}'? (Goal: {relevant_target})"
    - Options for each item found:
      * Label: Short description (e.g., "PR #123: Update HFC banner")
      * Description: Full context (files changed, ticket link, goal alignment)
    - MultiSelect: true (allow selecting multiple items)
    - Present "Other" option for manual entry

    **Section order with goal context:**
    1. Shipped / moved forward (Goal 1: track toward 2 full-scope projects)
    2. Code reviews (substantive) (Goal 5: Community & Collaboration)
    3. Proactive (surfaced, proposed, drove) (Goal 1 & 2: proactive improvement, tech debt)
    4. Docs / knowledge sharing (Goal 4: 1 doc per project, 1 presentation)
    5. Project ownership moments (Goal 1: 2 full-scope projects target)
    6. iOS (Goal 3: 1 iOS initiative, be go-to person)

    **After gathering selections:**
    - Show draft weekly log entry with goal progress summary
    - Allow user to edit/refine items before final update

10. Update promotion_summer_2026.md
    - Read `~/notes/plans/promotion_summer_2026.md`
    - Locate `## Weekly Log` section
    - Check if entry for target week already exists:
      * Pattern: `### Week {N} — {date}`
      * If exists: ask user to append, replace, or skip
    - Format new entry:
      ```markdown
      ### Week {N} — {date_range}
      **Shipped / moved forward:**
      - {item 1}
      - {item 2}

      **Code reviews (substantive):**
      - {item}

      **Proactive (surfaced, proposed, drove — not assigned):**
      - {item}

      **Docs / knowledge sharing:**
      - {item}

      **Project ownership moments:**
      - {item}

      **iOS:**
      - {item}
      ```
    - Insert entry after `## Weekly Log` comment (most recent on top)
    - Preserve existing entries below
    - Use Edit tool to update file

11. Output summary with goal progress tracking
    - Confirm weekly log updated for Week {N}
    - Show path to promotion file
    - **Display development goal progress summary:**
      ```
      Goal Progress Update:

      Goal 1 - Project Scope & Impact:
      ✓ Full-scope projects: X/2 (on track | behind)
      ✓ RFCs/technical designs: X/1 (on track | behind)
      ✓ Proactive improvements: X/1 (on track | behind)

      Goal 2 - Hunger & Proactiveness:
      ✓ Tech debt/quick wins this month: X/1 (on track | behind)

      Goal 3 - iOS Ownership:
      ✓ iOS initiatives: X/1 (on track | behind)
      ⚠ No iOS work logged this week (if applicable)

      Goal 4 - Knowledge Sharing:
      ✓ Docs written per project: tracking...
      ✓ Presentations: X/1 (on track | behind)

      Goal 5 - Community & Collaboration:
      ✓ Substantive code reviews: logged this week
      ✓ Speaking up in planning: tracking...

      Mike's Feedback Reminders:
      - Support → Ownership: [relevant accomplishment this week]
      - Timeline commitments: [if delays encountered]
      - Visibility: [docs/Slack summaries logged]
      ```
    - **Highlight gaps and suggest focus areas:**
      * If no iOS work: "Consider picking up iOS work next week (Goal 3)"
      * If no proactive work: "Look for tech debt to surface (Goal 2)"
      * If no docs: "Document your shipped work (Goal 4)"
      * If behind on full-scope projects: "Ask Sarthak/Mike for project ownership (Goal 1)"
    - Suggest next steps: review entry, run `/archive-week` if current week complete

Error Handling:
- **No week.md found (backfill):** List available archive files, exit with error
- **GitHub CLI not authenticated:** `gh auth status` fails → skip GitHub data, warn user
- **Glean MCP unavailable:** Log warning "Glean MCP unavailable, skipping RFC/docs/Slack search", continue
- **MCP timeout (300s):** Log warning with timeout message, continue with partial data
- **No data found:** Ask if user wants to manually enter all accomplishments
- **Week already logged:** Use AskUserQuestion to offer: "Append", "Replace", "Skip"
- **Invalid --week or --date:** Show error with valid format examples

Options:
- `--week N` - Log to specific ISO week number (backfill mode)
- `--date YYYY-MM-DD` - Log to week containing this date (backfill mode)

Examples:
- `/log-wins` - Research and log current week
- `/log-wins --week 12` - Backfill week 12 from archive
- `/log-wins --date 2026-03-09` - Backfill week of March 9

What this does:
- **Research Phase:** Gathers PRs (merged + reviewed), Jira tickets, completed tasks, and Glean content (RFCs, docs, Slack)
- **Interactive Phase:** Guides you through 6 weekly check-in sections with smart categorization
- **Update Phase:** Appends formatted entry to promotion_summer_2026.md (most recent on top)

Data Sources:
- **GitHub (gh CLI):** Merged PRs authored, PRs reviewed with comments
- **Jira (week.md):** PGL-XXX ticket references from tasks
- **week.md (local):** Completed tasks `[x]`, proactive work identification
- **Glean MCP (company_search):** RFCs, Confluence docs, Infohub articles, Slack messages

Technical Details:
- **ISO Week Calculation:** Uses `date +%V` for current week, validates week numbers 1-53
- **Date Range Filtering:** Monday-Friday of target week in YYYY-MM-DD format
- **Glean Search:** Gracefully handles MCP timeout (300s), continues without Glean data if unavailable
- **Archive Naming:** Matches `YYYY-week-NN*.md` pattern (e.g., `2026-week-12_mar-09.md`)

Anti-Patterns to Avoid:
- Don't replace existing week entries without asking - always offer append/replace/skip
- Don't auto-commit changes to promotion file - user reviews first
- Don't skip sections with no data - present empty section, allow manual entry
- Don't use interactive bash prompts (fzf, read, select) - use AskUserQuestion only
- Don't fail completely if Glean MCP unavailable - gracefully degrade to GitHub/Jira/tasks only
- Don't include non-substantive code reviews - filter for comments >50 chars
- Don't categorize standup Slack messages as accomplishments - filter for substantive content

Related commands:
- `/archive-week` - Archive current week and create new one
- `/pr-template` - Generate PR description (feeds into "Shipped" section)
