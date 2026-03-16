---
name: omada-controller
description: Interact with TP-Link Omada SDN Controller Open API. Use when querying or managing Omada network devices, clients, sites, access points, switches, gateways, VLANs, firewall rules, VPNs, or any Omada controller configuration. Also use when the user mentions Omada, SDN controller, or needs to authenticate against the Omada API.
license: MIT
compatibility: Requires curl and network access to an Omada SDN Controller. The controller must have Open API enabled with client credentials configured.
metadata:
  author: jakeasmith
  version: "1.5"
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

## Locating the Wrapper Script

The API wrapper script is at `scripts/omada-api.sh` relative to this skill's directory. On first use in a session, find the script path using Glob to search for `**/omada-controller/scripts/omada-api.sh`. Use the discovered absolute path for all subsequent calls. For example, if the skill is installed at `.claude/skills/omada-controller/`, the script path is `.claude/skills/omada-controller/scripts/omada-api.sh`.

## Making API Calls

**Always use the wrapper script** for all Omada API calls. It handles env loading, authentication, and URL construction automatically.

**Anti-patterns:** NEVER use curl to call the API. NEVER use prefix assignments or shell variables where the value can simply be placed in the command. Never pipe bash commands into other bash commands when you can simply parse the results yourself. Common anti-patterns include:

- curl -sk "${OMADA_URL}/api/info"
- SITE="123" && bash <script> GET "/sites/$SITE/devices?page=1&pageSize=100"
- SITE="123"; bash <script> GET "/sites/$SITE/gateways/***/ports
- SITE="123"; for mac in ...
- bash <script> GET /v3/api-docs --raw | jq '.paths["/openapi/v1/{omadacId}/sites/{siteId}/switches/{switchMac}/multi-ports/status"]' 2>/dev/null

**On first use in a session**, run the health check with no arguments. This verifies connectivity and lets the user approve the script once for all subsequent calls:

```bash
bash <script>
```

Then make API calls:

```bash
bash <script> <METHOD> <PATH> [JSON_BODY] [--raw] [--jq FILTER]
```

The path is relative to `/openapi/v1/{omadacId}` — no need to construct full URLs or manage tokens.

### Examples

```bash
# List sites
bash <script> GET /sites?page=1&pageSize=100

# List devices at a site
bash <script> GET /sites/{siteId}/devices?page=1&pageSize=100

# Reboot a device
bash <script> POST /sites/{siteId}/cmd/devices/reboot '{"deviceMacs":["AA-BB-CC-DD-EE-FF"]}'

# v2 endpoints — prefix path with /v2
bash <script> GET /v2/sites/{siteId}/setting/firewall/rules

# Fetch the OpenAPI spec for endpoint discovery
bash <script> GET /v3/api-docs --raw
```

### Path Routing

The script routes paths automatically:
- `/sites/...` → `/openapi/v1/{omadacId}/sites/...`
- `/v2/sites/...` → `/openapi/v2/{omadacId}/sites/...`
- `/v3/api-docs` → `{OMADA_URL}/v3/api-docs` (no auth prefix)

### Recommended Permission

Users should add this to their Claude Code settings to allow the script without repeated prompts:

```
Bash(bash *omada-api.sh *)
```

## API Discovery

The controller hosts its own full OpenAPI 3.0.1 spec (~1,507 endpoints). Use it to discover any endpoint at runtime rather than hard-coding paths.

- **Swagger UI** (browser): `{OMADA_URL}/swagger-ui/index.html` — no auth required
- **OpenAPI spec** (JSON):
  ```bash
  bash <script> GET /v3/api-docs --raw | jq '.paths | keys[]' | grep -i "<keyword>"
  ```

## Common Patterns

### Site ID

Most endpoints are site-scoped. Get the site ID first:

```bash
bash <script> GET /sites?page=1&pageSize=100
```

Then use it in subsequent paths: `/sites/{siteId}/devices`, `/sites/{siteId}/clients`, etc.

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

Some endpoints use `/v2/` instead of the default `/v1/`. The swagger spec includes both — prefix the path with `/v2` when needed.

## Authentication Details

The wrapper script handles auth automatically, but for reference:

1. **Controller ID**: Fetched from `GET {OMADA_URL}/api/info` (outside the OpenAPI spec)
2. **Token**: OAuth2 client credentials via `POST {OMADA_URL}/openapi/authorize/token?grant_type=client_credentials` with `omadacId`, `client_id`, `client_secret` in the JSON body (`grant_type` is a query param, not body)
3. **Header format**: `Authorization: AccessToken=<token>` (NOT `Bearer`)
4. **Expiry**: Tokens last 2 hours (7200 seconds) — the script re-authenticates each call

## Gotchas

- **TLS**: The controller typically uses a self-signed cert. Always use `curl -k`.
- **MAC format**: The API uses `AA-BB-CC-DD-EE-FF` (uppercase, dashes).
- **Error handling**: Always check `errorCode` in responses. `0` = success, negative = error.
- **Token header**: `Authorization: AccessToken=<token>`, NOT `Bearer <token>`.

## References

- [scripts/omada-api.sh](scripts/omada-api.sh) — API wrapper (handles env, auth, and requests)
- [references/api-categories.md](references/api-categories.md) — API endpoint categories and counts
- [references/external-resources.md](references/external-resources.md) — Links to docs, examples, and integrations
