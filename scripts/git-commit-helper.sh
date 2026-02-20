#!/bin/bash
# Helper script to generate git commit commands in a copyable format

set -e

# Check if files and message were provided
if [ $# -lt 2 ]; then
    echo "Usage: git-commit-helper.sh \"<commit message>\" <file1> <file2> ..."
    echo ""
    echo "Example:"
    echo "  git-commit-helper.sh \"Add new feature\" file1.txt file2.txt"
    exit 1
fi

COMMIT_MSG="$1"
shift
FILES="$@"

# Create temporary file
TEMP_FILE=$(mktemp)

# Write the git command to temp file
cat > "$TEMP_FILE" << 'OUTER_EOF'
git add FILES_PLACEHOLDER && git commit -m "$(cat <<'EOF'
COMMIT_MSG_PLACEHOLDER
EOF
)"
OUTER_EOF

# Replace placeholders
sed -i.bak "s|FILES_PLACEHOLDER|$FILES|g" "$TEMP_FILE"
# Handle multi-line commit message
echo "$COMMIT_MSG" | awk '{gsub(/COMMIT_MSG_PLACEHOLDER/, ""); print}' > /tmp/commit_msg_temp
awk 'NR==FNR{msg=msg (NR>1?"\n":"") $0; next} /COMMIT_MSG_PLACEHOLDER/{print msg; next} 1' /tmp/commit_msg_temp "$TEMP_FILE" > "$TEMP_FILE.new"
mv "$TEMP_FILE.new" "$TEMP_FILE"
rm -f "$TEMP_FILE.bak" /tmp/commit_msg_temp

# Output the file path and show the command
echo "Git command written to: $TEMP_FILE"
echo ""
echo "To execute, run:"
echo "  bash $TEMP_FILE"
echo ""
echo "Command contents:"
cat "$TEMP_FILE"
echo ""
echo "Or copy it with:"
echo "  pbcopy < $TEMP_FILE"
