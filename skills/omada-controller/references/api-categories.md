# Omada Open API Endpoint Categories

The OpenAPI spec defines **1,507 endpoints** (849 GET, 544 POST, 258 PATCH, 184 DELETE, 166 PUT) across 100+ tags.

## Major Categories

| Tag | Endpoints | Description |
|---|---|---|
| Wired Network | 90 | LAN, VLAN, port configs |
| Ap | 68 | Access point management |
| Device | 60 | Device operations (all types) |
| Profiles | 60 | Network profiles |
| VoIP | 56 | Voice over IP settings |
| Switch | 55 | Switch-specific operations |
| Gateway | 48 | Router/gateway operations |
| Stack | 43 | Switch stacking |
| Application Control | 42 | App filtering rules |
| Client | 36 | Connected client management |
| SSL VPN | 32 | SSL VPN configurations |
| VPN | 30 | VPN configurations |
| Insight | 32 | Network analytics |
| Service | 32 | Network services |
| Dashboard | 28 | Dashboard data and stats |
| Firmware | 29 | Firmware management |
| Log | 29 | Logging and audit |
| Site | 26 | Site management |
| ACL | 19 | Access control lists |
| Authentication | 19 | Portal/RADIUS auth |
| Wireless Network | 18 | SSID/WLAN configs |
| Routing | 10 | Static routes, OSPF |
| NAT | 10 | NAT rules |
| Firewall | 4 | Firewall rules |

Many categories also have `(Template)` variants for site template configurations.

## Discovering Endpoints

To find endpoints for a specific category, search the live spec:

```bash
curl -sk "${OMADA_URL}/v3/api-docs" | jq '.paths | to_entries[] | select(.value[].tags[]? == "Client") | .key'
```

Replace `"Client"` with any tag name from the table above.
