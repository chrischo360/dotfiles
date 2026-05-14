#!/usr/bin/env bash
# outline-sync.sh — Sync ~/notes to Outline (one-way, local → Outline)
#
# Usage:
#   outline-sync.sh              # Full initial sync
#   outline-sync.sh <file>       # Sync a single file (used by fswatch)
#   outline-sync.sh --watch      # Start fswatch daemon

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ENV_FILE="$DOTFILES_DIR/.env"

# Load .env
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

OUTLINE_TOKEN="${OUTLINE_API_TOKEN:-}"
OUTLINE_URL="${OUTLINE_BASE_URL:-https://wiki.chrischomeserver.duckdns.org}"
COLLECTION_ID="${OUTLINE_COLLECTION_ID:-4ff7c484-7fea-45dc-ad28-64dbdd710000}"
NOTES_DIR="${NOTES_DIR:-$HOME/notes}"

LOG_FILE="${TMPDIR:-/tmp}/outline-sync.log"

if [[ -z "$OUTLINE_TOKEN" ]]; then
  echo "ERROR: OUTLINE_API_TOKEN not set in $ENV_FILE" >&2
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  curl -s -X "$method" \
    "$OUTLINE_URL/api/$endpoint" \
    -H "Authorization: Bearer $OUTLINE_TOKEN" \
    -H "Content-Type: application/json" \
    ${data:+-d "$data"}
}

# Get document ID by title + parentDocumentId (or collection root)
# Returns empty string if not found
find_doc() {
  local title="$1"
  local parent_id="${2:-}"

  local payload
  if [[ -n "$parent_id" ]]; then
    payload=$(jq -n --arg t "$title" --arg c "$COLLECTION_ID" --arg p "$parent_id" \
      '{query: $t, collectionId: $c, parentDocumentId: $p}')
  else
    payload=$(jq -n --arg t "$title" --arg c "$COLLECTION_ID" \
      '{query: $t, collectionId: $c}')
  fi

  local result
  result=$(api POST "documents.search" "$payload")

  # Find exact title match
  echo "$result" | jq -r --arg t "$title" \
    '.data[]? | select(.document.title == $t) | .document.id' | head -1
}

# Create a document, return its ID
create_doc() {
  local title="$1"
  local content="$2"
  local parent_id="${3:-}"

  local payload
  if [[ -n "$parent_id" ]]; then
    payload=$(jq -n --arg t "$title" --arg c "$content" \
      --arg col "$COLLECTION_ID" --arg p "$parent_id" \
      '{title: $t, text: $c, collectionId: $col, parentDocumentId: $p, publish: true}')
  else
    payload=$(jq -n --arg t "$title" --arg c "$content" \
      --arg col "$COLLECTION_ID" \
      '{title: $t, text: $c, collectionId: $col, publish: true}')
  fi

  api POST "documents.create" "$payload" | jq -r '.data.id'
}

# Update a document by ID
update_doc() {
  local doc_id="$1"
  local title="$2"
  local content="$3"

  local payload
  payload=$(jq -n --arg id "$doc_id" --arg t "$title" --arg c "$content" \
    '{id: $id, title: $t, text: $c, publish: true}')

  api POST "documents.update" "$payload" > /dev/null
}

# Ensure a folder document exists, return its ID
# Creates parent chain recursively
ensure_folder() {
  local rel_path="$1"  # e.g. "career/interviews"

  # Split into parts
  IFS='/' read -ra parts <<< "$rel_path"

  local parent_id=""
  local current_path=""

  for part in "${parts[@]}"; do
    current_path="${current_path:+$current_path/}$part"
    local cached
    cached=$(cache_get "folder:$current_path" || true)

    if [[ -n "$cached" ]]; then
      parent_id="$cached"
      continue
    fi

    local existing
    existing=$(find_doc "$part" "$parent_id")

    if [[ -n "$existing" ]]; then
      parent_id="$existing"
    else
      parent_id=$(create_doc "$part" "" "$parent_id")
      log "  Created folder: $current_path ($parent_id)"
    fi

    cache_set "folder:$current_path" "$parent_id"
  done

  echo "$parent_id"
}

# Simple file-based cache (per-run, for folder IDs)
CACHE_FILE="${TMPDIR:-/tmp}/outline-sync-cache.$$"
cache_get() { grep -m1 "^$1=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2- || true; }
cache_set() { echo "$1=$2" >> "$CACHE_FILE"; }
cleanup() { rm -f "$CACHE_FILE"; }
trap cleanup EXIT

# Persistent hash cache (survives between runs)
HASH_CACHE="${TMPDIR:-/tmp}/outline-sync-hashes.json"
[[ -f "$HASH_CACHE" ]] || echo '{}' > "$HASH_CACHE"

hash_get() {
  jq -r --arg k "$1" '.[$k] // empty' "$HASH_CACHE"
}

hash_set() {
  local tmp
  tmp=$(mktemp)
  jq --arg k "$1" --arg v "$2" '.[$k] = $v' "$HASH_CACHE" > "$tmp" && mv "$tmp" "$HASH_CACHE"
}

file_hash() {
  md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1
}

# ── Sync a single file ────────────────────────────────────────────────────────

sync_file() {
  local abs_path="$1"

  # Must be a .md file under NOTES_DIR
  [[ "$abs_path" == *.md ]] || return 0
  [[ "$abs_path" == "$NOTES_DIR"/* ]] || return 0

  # Skip symlinks, hidden files, and git files
  [[ -L "$abs_path" ]] && return 0
  [[ "$abs_path" == */.git/* ]] && return 0
  [[ "$(basename "$abs_path")" == .* ]] && return 0

  # Skip AGENTS.md, COMMAND_MAP.md (meta files)
  local basename
  basename=$(basename "$abs_path")
  [[ "$basename" == "AGENTS.md" || "$basename" == "COMMAND_MAP.md" || "$basename" == "README.md" ]] && return 0

  local rel_path="${abs_path#$NOTES_DIR/}"
  local title="${basename%.md}"
  local dir_part
  dir_part=$(dirname "$rel_path")

  local content
  content=$(cat "$abs_path")

  # Skip if content unchanged since last sync
  local current_hash stored_hash
  current_hash=$(file_hash "$abs_path")
  stored_hash=$(hash_get "$rel_path")
  if [[ "$current_hash" == "$stored_hash" ]]; then
    return 0
  fi

  # Determine parent doc ID
  local parent_id=""
  if [[ "$dir_part" != "." ]]; then
    parent_id=$(ensure_folder "$dir_part")
  fi

  # Check if doc exists
  local doc_id
  doc_id=$(find_doc "$title" "$parent_id")

  if [[ -n "$doc_id" ]]; then
    update_doc "$doc_id" "$title" "$content"
    log "Updated: $rel_path"
  else
    create_doc "$title" "$content" "$parent_id" > /dev/null
    log "Created: $rel_path"
  fi

  hash_set "$rel_path" "$current_hash"
}

# ── Full sync ─────────────────────────────────────────────────────────────────

full_sync() {
  log "Starting full sync of $NOTES_DIR → Outline collection $COLLECTION_ID"

  local count=0
  while IFS= read -r -d '' file; do
    sync_file "$file" && ((count++)) || true
    # Slight throttle to avoid hammering the API
    sleep 0.1
  done < <(find "$NOTES_DIR" -name "*.md" \
    -not -path "*/.git/*" \
    -not -name "AGENTS.md" \
    -not -name "COMMAND_MAP.md" \
    -not -name "README.md" \
    -not -type l \
    -print0)

  log "Full sync complete. Processed $count files."
}

# ── Watch mode ────────────────────────────────────────────────────────────────

watch_mode() {
  if ! command -v fswatch &>/dev/null; then
    echo "ERROR: fswatch not installed. Run: brew install fswatch" >&2
    exit 1
  fi

  log "Watching $NOTES_DIR for changes..."

  fswatch \
    --recursive \
    --include='\.md$' \
    --exclude='/\.git/' \
    --event Created \
    --event Updated \
    --event Renamed \
    --event MovedTo \
    "$NOTES_DIR" | while IFS= read -r changed_file; do
      log "Change detected: $changed_file"
      sync_file "$changed_file" || log "ERROR syncing $changed_file"
    done
}

# ── Entry point ───────────────────────────────────────────────────────────────

case "${1:-}" in
  --watch)
    watch_mode
    ;;
  "")
    full_sync
    ;;
  *)
    sync_file "$1"
    ;;
esac
