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
