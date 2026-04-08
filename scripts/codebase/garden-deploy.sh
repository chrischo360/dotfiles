#!/bin/bash
# garden-deploy - Deploy to a Garden ephemeral namespace from local CLI
# Usage: garden-deploy <namespace> [garden-flags...]
#
# Get your namespace first:
#   wf_garden namespace create --testNS=true
#   -> Namespace: [ephemeral-xxxx] Created
set -e

NAMESPACE="${1:-}"

if [ -z "$NAMESPACE" ]; then
  echo "Usage: garden-deploy <namespace> [garden-flags...]"
  echo ""
  echo "Get your namespace by running:"
  echo "  wf_garden namespace create --testNS=true"
  echo "  -> Namespace: [ephemeral-xxxx] Created"
  exit 1
fi

shift || true

# Ensure we're in a directory with a Garden project
if [ ! -f "project.garden.yml" ]; then
  echo "Error: project.garden.yml not found in current directory."
  echo "Run this from the root of a Garden-enabled repo."
  exit 1
fi

# Extract project name from project.garden.yml
PROJECT_NAME=$(grep '^name:' project.garden.yml | awk '{print $2}' | tr -d '"')
if [ -z "$PROJECT_NAME" ]; then
  echo "Error: Could not read project name from project.garden.yml"
  exit 1
fi

# Convert project name to SCREAMING_SNAKE_CASE for the env var name
# e.g. experience-decision-engine -> EXPERIENCE_DECISION_ENGINE
PROJECT_SNAKE=$(echo "$PROJECT_NAME" | tr '[:lower:]-' '[:upper:]_')
FEATURE_VARIANT_VAR="FEATURE_VARIANT_URL_${PROJECT_SNAKE}"

# Build the ingress hostname
HOSTNAME="kube-ephemeral-${NAMESPACE}-${PROJECT_NAME}.service.intradsm1.sdeconsul.csnzoo.com"

echo "Project:          $PROJECT_NAME"
echo "Namespace:        $NAMESPACE"
echo "Subgraph hostname: $HOSTNAME"
echo ""

export GARDEN_NAMESPACE="$NAMESPACE"
export GARDEN_ENABLE_NEW_SYNC=false
export "${FEATURE_VARIANT_VAR}=${HOSTNAME}"

# Ensure kubectl credentials are set for GKE auth
GCLOUD_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)
if [ -z "$GCLOUD_ACCOUNT" ]; then
  GCLOUD_ACCOUNT=$(gcloud config get-value account --configuration=default 2>/dev/null || true)
fi
if [ -n "$GCLOUD_ACCOUNT" ]; then
  kubectl config set-credentials "$GCLOUD_ACCOUNT" --auth-provider=gke &>/dev/null
fi

/usr/local/bin/garden deploy "$@"
