#!/usr/bin/env bash
# outline-pull.sh — Sync Outline collection → ~/notes/outline/ (one-way, Outline → local)
#
# Usage:
#   outline-pull.sh              # Poll for changes and pull updated docs
#   outline-pull.sh --full       # Force re-download all docs (ignore timestamp cache)

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
PULL_DIR="${OUTLINE_PULL_DIR:-$HOME/outline}"

LOG_FILE="${TMPDIR:-/tmp}/outline-pull.log"
TIMESTAMP_CACHE="${TMPDIR:-/tmp}/outline-pull-timestamps.json"

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

# Timestamp cache: doc_id → updatedAt string
[[ -f "$TIMESTAMP_CACHE" ]] || echo '{}' > "$TIMESTAMP_CACHE"

ts_get() { jq -r --arg k "$1" '.[$k] // empty' "$TIMESTAMP_CACHE"; }
ts_set() {
  local tmp
  tmp=$(mktemp)
  jq --arg k "$1" --arg v "$2" '.[$k] = $v' "$TIMESTAMP_CACHE" > "$tmp" && mv "$tmp" "$TIMESTAMP_CACHE"
}

# ── Path resolution ───────────────────────────────────────────────────────────

# JSON file used as key-value map: {id: {title, parentDocumentId}}
DOC_MAP_FILE="${TMPDIR:-/tmp}/outline-pull-docmap.$$.json"

load_doc_map() {
  local all_docs="$1"
  # Build {id: {title, parent}} map from doc list
  echo "$all_docs" | jq 'map({key: .id, value: {title, parent: (.parentDocumentId // "")}}) | from_entries' > "$DOC_MAP_FILE"
}

doc_title()  { jq -r --arg id "$1" '.[$id].title  // empty' "$DOC_MAP_FILE"; }
doc_parent() { jq -r --arg id "$1" '.[$id].parent // empty' "$DOC_MAP_FILE"; }

resolve_path() {
  local doc_id="$1"
  local parts=""
  local current="$doc_id"

  while [[ -n "$current" ]]; do
    local title
    title=$(doc_title "$current")
    [[ -z "$title" ]] && break
    local safe_title
    safe_title=$(echo "$title" | tr '/' '-' | tr -cd '[:alnum:][:space:]._-' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -z "$parts" ]]; then
      parts="$safe_title"
    else
      parts="$safe_title/$parts"
    fi
    current=$(doc_parent "$current")
  done

  echo "$parts"
}

cleanup_docmap() { rm -f "$DOC_MAP_FILE"; }
trap cleanup_docmap EXIT

# ── Fetch all docs in collection (paginated) ──────────────────────────────────

fetch_all_docs() {
  local offset=0
  local limit=25
  local all_docs='[]'

  while true; do
    local payload
    payload=$(jq -n --arg c "$COLLECTION_ID" --argjson o "$offset" --argjson l "$limit" \
      '{collectionId: $c, offset: $o, limit: $l}')

    local page
    page=$(api POST "documents.list" "$payload")

    local batch
    batch=$(echo "$page" | jq '.data // []')
    local count
    count=$(echo "$batch" | jq 'length')

    all_docs=$(echo "$all_docs $batch" | jq -s 'add')

    if (( count < limit )); then
      break
    fi
    offset=$(( offset + limit ))
    sleep 0.1
  done

  echo "$all_docs"
}

# ── Pull a single document ────────────────────────────────────────────────────

pull_doc() {
  local doc_id="$1"
  local updated_at="$2"
  local rel_path="$3"

  local response
  response=$(api POST "documents.export" \
    "$(jq -n --arg id "$doc_id" '{id: $id}')")

  local content
  content=$(echo "$response" | jq -r '.data // ""')

  local abs_path="$PULL_DIR/$rel_path.md"
  local dir
  dir=$(dirname "$abs_path")
  mkdir -p "$dir"

  printf '%s\n' "$content" > "$abs_path"
  ts_set "$doc_id" "$updated_at"
  log "Pulled: $rel_path"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  local force=false
  [[ "${1:-}" == "--full" ]] && force=true

  log "Polling Outline collection $COLLECTION_ID → $PULL_DIR"
  mkdir -p "$PULL_DIR"

  local all_docs
  all_docs=$(fetch_all_docs)

  local total
  total=$(echo "$all_docs" | jq 'length')
  log "Found $total documents"

  # Build parent/title map for path resolution
  load_doc_map "$all_docs"

  local pulled=0
  local skipped=0

  while IFS=$'\t' read -r doc_id updated_at; do
    local cached_ts
    cached_ts=$(ts_get "$doc_id")

    if [[ "$force" == false && "$cached_ts" == "$updated_at" ]]; then
      (( skipped++ )) || true
      continue
    fi

    local rel_path
    rel_path=$(resolve_path "$doc_id")

    if [[ -z "$rel_path" ]]; then
      log "WARN: Could not resolve path for doc $doc_id, skipping"
      continue
    fi

    pull_doc "$doc_id" "$updated_at" "$rel_path"
    (( pulled++ )) || true
    sleep 0.1
  done < <(echo "$all_docs" | jq -r '.[] | [.id, .updatedAt] | @tsv')

  log "Done. Pulled: $pulled, Skipped (unchanged): $skipped"
}

main "$@"
