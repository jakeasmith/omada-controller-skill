---
name: omada-controller
description: Interact with TP-Link Omada SDN Controller Open API. Use when querying or managing Omada network devices, clients, sites, access points, switches, gateways, VLANs, firewall rules, VPNs, or any Omada controller configuration. Also use when the user mentions Omada, SDN controller, or needs to authenticate against the Omada API.
license: MIT
compatibility: Requires curl and network access to an Omada SDN Controller. The controller must have Open API enabled with client credentials configured.
metadata:
  author: jakeasmith
  version: "1.0"
---

# Omada SDN Controller API

Manage TP-Link Omada SDN Controllers via the Open API (OpenAPI 3.0.1).

## Compatibility

The Open API is available in **Omada SDN Controller v5.9 and later** (both the Software Controller and Cloud-Based Controller). Earlier versions only have an undocumented internal API that uses cookie-based session auth — this skill does not cover that legacy API.

The Open API feature must be explicitly enabled by an administrator before use.

## Environment Setup

Before making any API calls, you need three environment variables. If the user has not provided these or a `.env` file does not exist, walk them through the setup:

1. **Find the controller URL** — Ask the user for their Omada Controller address. This is typically `https://<host>:8043` for the Software Controller. The port may differ if customized during installation.

2. **Create API credentials** — Guide the user to:
   - Log into the Omada Controller web UI
   - Navigate to **Global View > Settings > Platform Integration > Open API**
   - Click **Add New App**
   - Set the type to **Client** (not Gateway)
   - Copy the generated **Client ID** and **Client Secret**

3. **Create the `.env` file** — Have the user create a `.env` file in the project root:

   ```
   OMADA_URL=https://omada.example.com:8043
   OMADA_CLIENT=your-client-id
   OMADA_SECRET=your-client-secret
   ```

**Never commit `.env` to git.** Ensure `.gitignore` includes it.

Load variables before making requests:

```bash
export $(grep -v '^#' .env | xargs)
```

Do NOT use `source .env` — variables won't propagate to subshells or curl.

If auth fails, common causes are:
- The Open API feature is not enabled on the controller
- The client app type is set to Gateway instead of Client
- The controller URL is wrong or missing the port
- The client secret was rotated in the UI but not updated in `.env`

## Authentication Flow

The Open API uses OAuth2 client credentials but the flow is **not in the swagger spec**. Follow these three steps exactly.

### Step 1: Get the Controller ID

```bash
OMADAC_ID=$(curl -sk "${OMADA_URL}/api/info" | jq -r '.result.omadacId')
```

This endpoint is outside the OpenAPI spec. The `omadacId` is a path parameter in every subsequent call.

### Step 2: Obtain an Access Token

```bash
TOKEN_RESPONSE=$(curl -sk -X POST \
  "${OMADA_URL}/openapi/authorize/token?grant_type=client_credentials" \
  -H "Content-Type: application/json" \
  -d "{\"omadacId\":\"${OMADAC_ID}\",\"client_id\":\"${OMADA_CLIENT}\",\"client_secret\":\"${OMADA_SECRET}\"}")
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.result.accessToken')
```

Note the non-standard format:
- `grant_type` is a **query parameter**, not in the body
- `omadacId`, `client_id`, `client_secret` go in the **JSON body**

Tokens expire after **2 hours** (7200 seconds).

### Step 3: Authenticate Requests

All API requests use this header — it is NOT standard Bearer format:

```
Authorization: AccessToken=<token>
```

Example:

```bash
curl -sk -H "Authorization: AccessToken=${ACCESS_TOKEN}" \
  "${OMADA_URL}/openapi/v1/${OMADAC_ID}/sites?page=1&pageSize=100"
```

## Quick-Start: Full Auth Sequence

```bash
export $(grep -v '^#' .env | xargs)
OMADAC_ID=$(curl -sk "${OMADA_URL}/api/info" | jq -r '.result.omadacId')
ACCESS_TOKEN=$(curl -sk -X POST \
  "${OMADA_URL}/openapi/authorize/token?grant_type=client_credentials" \
  -H "Content-Type: application/json" \
  -d "{\"omadacId\":\"${OMADAC_ID}\",\"client_id\":\"${OMADA_CLIENT}\",\"client_secret\":\"${OMADA_SECRET}\"}" \
  | jq -r '.result.accessToken')
```

Then use `$OMADAC_ID` and `$ACCESS_TOKEN` for all subsequent calls.

## API Discovery

The controller hosts its own full OpenAPI 3.0.1 spec (~1,507 endpoints). Use it to discover any endpoint at runtime rather than hard-coding paths.

- **Swagger UI** (browser): `{OMADA_URL}/swagger-ui/index.html` — no auth required
- **OpenAPI spec** (JSON): `GET {OMADA_URL}/v3/api-docs` — no auth required, ~3.4MB

When you need to find an endpoint, fetch the spec and search it:

```bash
curl -sk "${OMADA_URL}/v3/api-docs" | jq '.paths | keys[]' | grep -i "<keyword>"
```

## Common Patterns

### Path Structure

All site-scoped endpoints follow:

```
/openapi/v1/{omadacId}/sites/{siteId}/...
```

Get the site ID first:

```bash
curl -sk -H "Authorization: AccessToken=${ACCESS_TOKEN}" \
  "${OMADA_URL}/openapi/v1/${OMADAC_ID}/sites?page=1&pageSize=100" \
  | jq '.result.data[] | {name, siteId: .id}'
```

### Pagination

Paginated endpoints accept `page` and `pageSize` query parameters and return:

```json
{
  "errorCode": 0,
  "result": {
    "totalRows": 7,
    "currentPage": 1,
    "currentSize": 100,
    "data": [...]
  }
}
```

### API Versions

Some endpoints use `/openapi/v2/` instead of `/openapi/v1/`. The swagger spec includes both.

## Gotchas

- **TLS**: The controller typically uses a self-signed cert. Always use `curl -k`.
- **MAC format**: The API uses `AA-BB-CC-DD-EE-FF` (uppercase, dashes).
- **Error handling**: Always check `errorCode` in responses. `0` = success, negative = error.
- **Token header**: `Authorization: AccessToken=<token>`, NOT `Bearer <token>`.

## References

- [scripts/omada-auth.sh](scripts/omada-auth.sh) — Reusable auth helper script
- [references/api-categories.md](references/api-categories.md) — API endpoint categories and counts
- [references/external-resources.md](references/external-resources.md) — Links to docs, examples, and integrations
