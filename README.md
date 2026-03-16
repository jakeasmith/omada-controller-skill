# omada-controller-skill

A [Claude Code skill](https://skills.sh) for interacting with the TP-Link Omada SDN Controller Open API.

## What It Does

Gives Claude Code the knowledge to authenticate against and query any Omada SDN Controller endpoint — device management, client monitoring, network configuration, firmware updates, and more across 1,500+ API endpoints.

Key capabilities:
- **Authentication**: Handles the undocumented OAuth2 client credentials flow
- **API discovery**: Uses the controller's live OpenAPI spec to find endpoints at runtime
- **Common operations**: Site listing, device queries, client management, network config

## Requirements

- **Omada SDN Controller v5.9+** (Software Controller or Cloud-Based Controller)
- Open API enabled with a **Client** mode app configured
- `curl` and `jq` available in the shell

## Install

```bash
npx skills add jakeasmith/omada-controller-skill
```

Or install globally (available across all projects):

```bash
npx skills add -g jakeasmith/omada-controller-skill
```

## Setup

1. Log into the Omada Controller web UI
2. Navigate to **Global View > Settings > Platform Integration > Open API**
3. Click **Add New App**, set the type to **Client**, and copy the Client ID and Secret
4. Create a `.env` file in your project root:

   ```
   OMADA_URL=https://omada.example.com:8043
   OMADA_CLIENT=your-client-id
   OMADA_SECRET=your-client-secret
   ```

5. On first use, Claude will run a no-arg health check (`bash scripts/omada-api.sh`). When prompted, choose **"Yes, and don't ask again for bash scripts/omada-api.sh"** to allow all future calls.

   Or add the permission manually to `.claude/settings.json`:

   ```json
   {
     "permissions": {
       "allow": ["Bash(bash scripts/omada-api.sh *)"]
     }
   }
   ```

6. Ask Claude Code to interact with your controller — the skill handles auth and endpoint discovery automatically.

## Skill Contents

```
skills/omada-controller/
├── SKILL.md                          # Main skill instructions
├── scripts/
│   └── omada-api.sh                  # API wrapper (auth + request in one call)
└── references/
    ├── api-categories.md             # Endpoint categories and counts
    └── external-resources.md         # Links to docs and community resources
```

## License

MIT
