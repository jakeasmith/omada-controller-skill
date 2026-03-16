#!/usr/bin/env bash
# Omada Controller Open API authentication helper.
# Sources .env, retrieves controller ID, and obtains an access token.
#
# Usage:
#   eval "$(bash scripts/omada-auth.sh)"
#   curl -sk -H "Authorization: AccessToken=${ACCESS_TOKEN}" ...
#
# Requires: OMADA_URL, OMADA_CLIENT, OMADA_SECRET in .env

set -euo pipefail

# Load .env from the project root (caller's working directory)
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

for var in OMADA_URL OMADA_CLIENT OMADA_SECRET; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: ${var} is not set. Add it to .env" >&2
    exit 1
  fi
done

# Step 1: Get controller ID
OMADAC_ID=$(curl -sk "${OMADA_URL}/api/info" | jq -r '.result.omadacId')
if [[ -z "$OMADAC_ID" || "$OMADAC_ID" == "null" ]]; then
  echo "Error: Failed to get omadacId from ${OMADA_URL}/api/info" >&2
  exit 1
fi

# Step 2: Get access token
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

# Export for eval consumption
echo "export OMADAC_ID='${OMADAC_ID}'"
echo "export ACCESS_TOKEN='${ACCESS_TOKEN}'"
