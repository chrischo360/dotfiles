# Help and reference commands

# Glob pattern cheat sheet
glob() {
  cat << 'EOF'
GLOB PATTERN CHEAT SHEET

*           Match any chars (one directory level)
**          Match any chars (recursive, crosses directories)
?           Match single character
[abc]       Match a, b, or c
[a-z]       Match any char in range
[!abc]      Match any char except a, b, c
{a,b,c}     Match a or b or c (brace expansion)

EXAMPLES:
*.js                All .js in current dir
**/*.js             All .js anywhere
src/**/*.test.ts    All .test.ts under src/
file?.txt           file1.txt, fileA.txt
*.{js,ts,jsx,tsx}   Any of those extensions
[A-Z]*.json         JSON files starting with capital

GIT USAGE:
git add **/*.ts
git add "*.{js,json}"
git ls-files '**/*.ts'  # Preview what would be added

TEST PATTERNS:
ls **/*.ts
echo **/*.json
EOF
}

# nvim-surround cheat sheet
nvim-surround() {
  cat << 'EOF'
NVIM-SURROUND CHEAT SHEET

NORMAL MODE:
ys{motion}{char}    Add surround (e.g., ysiw" - surround word with ")
ds{char}            Delete surround (e.g., ds" - delete surrounding ")
cs{old}{new}        Change surround (e.g., cs"' - change " to ')

VISUAL MODE:
S{char}             Surround selection

COMMON SURROUNDINGS:
"  '  `             Quotes
(  )  b             Parentheses (b = brackets)
[  ]                Square brackets
{  }  B             Curly braces (B = Braces)
<  >  t             Angle brackets / HTML tags

EXAMPLES:
ysiw"               Surround word with "quotes"
yss)                Surround entire line with (parentheses)
ds"                 Delete surrounding "quotes"
cs"'                Change "double" to 'single' quotes
cs'<q>              Change 'quotes' to <q>tags</q>
dst                 Delete surrounding HTML tag
cst<div>            Change tag to <div>
ysiw(               Surround with ( space padding )
ysiw)               Surround with (no space padding)

VISUAL MODE:
V S"                Select line, surround with "quotes"
v iw S*             Select word, surround with *asterisks*

TAG SURROUND:
ysiwt               Prompt for tag name, adds <tag>word</tag>
cst                 Prompt to change tag type
EOF
}

# Regex cheat sheet
regex() {
  cat << 'EOF'
REGEX CHEAT SHEET

METACHARACTERS:
.               Any character (except newline)
\d              Digit [0-9]
\D              Non-digit
\w              Word character [a-zA-Z0-9_]
\W              Non-word character
\s              Whitespace [ \t\n\r]
\S              Non-whitespace
\b              Word boundary
\B              Non-word boundary

CHARACTER CLASSES:
[abc]           Match a, b, or c
[^abc]          Match anything except a, b, or c
[a-z]           Match any lowercase letter
[A-Z]           Match any uppercase letter
[0-9]           Match any digit
[a-zA-Z0-9]     Alphanumeric

QUANTIFIERS:
*               0 or more (greedy)
+               1 or more (greedy)
?               0 or 1 (optional)
{n}             Exactly n times
{n,}            n or more times
{n,m}           Between n and m times
*?  +?  ??      Non-greedy versions

ANCHORS:
^               Start of string/line
$               End of string/line
\A              Start of string
\Z              End of string

GROUPS & REFERENCES:
(...)           Capturing group
(?:...)         Non-capturing group
\1 \2 \3        Backreference to group 1, 2, 3
(?=...)         Positive lookahead
(?!...)         Negative lookahead
(?<=...)        Positive lookbehind
(?<!...)        Negative lookbehind

ALTERNATION:
|               OR operator (cat|dog)

EXAMPLES:
^\d{3}-\d{4}$           Phone: 123-4567
\b\w+@\w+\.\w+\b        Email pattern
^https?://              URL starting with http/https
\b[A-Z]{2,}\b           Acronyms (2+ capital letters)
(\w+)\s+\1              Repeated words (the the)
(?=.*\d)(?=.*[a-z])     Lookahead: has digit AND lowercase
\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}  IP address

COMMON REPLACEMENTS:
s/(\w+)\s+(\w+)/\2 \1/  Swap two words
s/\s+/ /g               Normalize whitespace
s/[^\w\s]//g            Remove punctuation
EOF
}

# Git help - show available shortcuts
alias g='echo "Git Shortcuts:
  gs       git status -sb
  ga       git add
  gc       git commit
  gcam     git commit --amend
  gcan     git commit --amend --no-edit
  gp       git push
  gpf      git push --force-with-lease
  gpr      git pull --rebase
  gpom     git pull origin main --rebase
  gco      git checkout
  gcb      git checkout -b
  gb       checkout branch (fzf)

Log:
  gl       git log --oneline --graph
  glog     git log (pretty format)
  glg      git log --graph --all
  gls      git log --stat

Diff:
  gd       git diff

Rebase:
  grb      git rebase
  grbi     git rebase -i
  grbc     git rebase --continue
  grba     git rebase --abort

Branch:
  gbd      git branch -d
  gbD      git branch -D
  gba      git branch -a

Cleanup:
  gclean   git clean -fd
  gprune   git remote prune origin"'
