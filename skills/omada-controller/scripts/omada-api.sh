#!/usr/bin/env bash
# Omada Controller Open API wrapper.
# Handles env loading, authentication, and API calls in one shot.
#
# Usage:
#   bash skills/omada-controller/scripts/omada-api.sh                    # Health check (no args)
#   bash skills/omada-controller/scripts/omada-api.sh <METHOD> <PATH> [JSON_BODY]
#
# Examples:
#   bash skills/omada-controller/scripts/omada-api.sh
#   bash skills/omada-controller/scripts/omada-api.sh GET /sites
#   bash skills/omada-controller/scripts/omada-api.sh GET /sites/{siteId}/devices
#   bash skills/omada-controller/scripts/omada-api.sh POST /sites/{siteId}/cmd/devices/reboot '{"deviceMacs":["AA-BB-CC-DD-EE-FF"]}'
#   bash skills/omada-controller/scripts/omada-api.sh GET /v3/api-docs --raw
#
# The path is relative to /openapi/v1/{omadacId} unless it starts with /v2 or /v3.
# Add --raw as the last argument to skip jq formatting.
#
# Requires: OMADA_URL, OMADA_CLIENT, OMADA_SECRET in .env

set -euo pipefail

# --- Load environment ---

if [[ -f .env ]]; then
  export $(grep -v '^#' .env | grep -v '^\s*$' | xargs)
fi

for var in OMADA_URL OMADA_CLIENT OMADA_SECRET; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: ${var} is not set. Add it to .env" >&2
    exit 1
  fi
done

# --- Health check (no args) ---

if [[ $# -eq 0 ]]; then
  RESPONSE=$(curl -sk "${OMADA_URL}/api/info")
  ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errorCode')
  if [[ "$ERROR_CODE" != "0" ]]; then
    echo "Error: Cannot reach controller at ${OMADA_URL}" >&2
    exit 1
  fi
  OMADAC_ID=$(echo "$RESPONSE" | jq -r '.result.omadacId')
  echo "Controller reachable at ${OMADA_URL}"
  echo "Controller ID: ${OMADAC_ID}"
  echo "Controller name: $(echo "$RESPONSE" | jq -r '.result.controllerName // "N/A"')"
  exit 0
fi

# --- Parse arguments ---

METHOD="${1:?Usage: omada-api.sh <METHOD> <PATH> [JSON_BODY] [--raw]}"
API_PATH="${2:?Usage: omada-api.sh <METHOD> <PATH> [JSON_BODY] [--raw]}"
BODY="${3:-}"
RAW=false

# Check for --raw flag in any position after method/path
for arg in "$@"; do
  if [[ "$arg" == "--raw" ]]; then
    RAW=true
    # Clear BODY if it was set to --raw
    [[ "$BODY" == "--raw" ]] && BODY=""
  fi
done

# --- Authenticate ---

OMADAC_ID=$(curl -sk "${OMADA_URL}/api/info" | jq -r '.result.omadacId')
if [[ -z "$OMADAC_ID" || "$OMADAC_ID" == "null" ]]; then
  echo "Error: Failed to get omadacId from ${OMADA_URL}/api/info" >&2
  exit 1
fi

TOKEN_RESPONSE=$(curl -sk -X POST \
  "${OMADA_URL}/openapi/authorize/token?grant_type=client_credentials" \
  -H "Content-Type: application/json" \
  -d "{\"omadacId\":\"${OMADAC_ID}\",\"client_id\":\"${OMADA_CLIENT}\",\"client_secret\":\"${OMADA_SECRET}\"}")

ERROR_CODE=$(echo "$TOKEN_RESPONSE" | jq -r '.errorCode')
if [[ "$ERROR_CODE" != "0" ]]; then
  echo "Error: Auth failed — $(echo "$TOKEN_RESPONSE" | jq -r '.msg')" >&2
  exit 1
fi

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.result.accessToken')

# --- Build URL ---

# /v3/api-docs is a special case — no auth prefix
if [[ "$API_PATH" == /v3/* ]]; then
  FULL_URL="${OMADA_URL}${API_PATH}"
# /v2 endpoints use /openapi/v2/{omadacId}
elif [[ "$API_PATH" == /v2/* ]]; then
  FULL_URL="${OMADA_URL}/openapi/v2/${OMADAC_ID}${API_PATH#/v2}"
# Everything else uses /openapi/v1/{omadacId}
else
  FULL_URL="${OMADA_URL}/openapi/v1/${OMADAC_ID}${API_PATH}"
fi

# --- Make request ---

CURL_ARGS=(-sk -X "$METHOD" -H "Authorization: AccessToken=${ACCESS_TOKEN}")

if [[ -n "$BODY" ]]; then
  CURL_ARGS+=(-H "Content-Type: application/json" -d "$BODY")
fi

RESPONSE=$(curl "${CURL_ARGS[@]}" "$FULL_URL")

if [[ "$RAW" == true ]]; then
  echo "$RESPONSE"
else
  echo "$RESPONSE" | jq .
fi
