## MODIFIED Requirements

### Requirement: Pushover credentials from environment
The MCP server SHALL read Pushover credentials from environment variables: `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN`. The ZeroClaw native pushover tool SHALL also resolve these variables from the service environment file injected by the NixOS module.

#### Scenario: Missing Pushover credentials
- **WHEN** the MCP server starts without required Pushover environment variables
- **THEN** the Pushover tool SHALL be unavailable and the server SHALL log a warning, but other tools SHALL continue to function

#### Scenario: Native tool env resolution
- **WHEN** the ZeroClaw native pushover tool executes
- **THEN** it SHALL resolve `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN` from the service environment file at `/var/lib/sid/.zeroclaw/env`, not from the shell's `.env` in the workspace

#### Scenario: Env vars present after NixOS rebuild
- **WHEN** the NixOS module deploys with pushover secrets configured via agenix
- **THEN** `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN` SHALL be present in the ZeroClaw service environment and accessible to both the MCP server and native pushover tool
