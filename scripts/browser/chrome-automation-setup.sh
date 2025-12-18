#!/bin/bash
# Helper script to open Chromium for GitHub authentication

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node "$SCRIPT_DIR/setup-github-auth.mjs"
