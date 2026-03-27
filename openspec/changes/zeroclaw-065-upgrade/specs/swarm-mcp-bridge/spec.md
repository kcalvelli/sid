## REMOVED Requirements

### Requirement: Swarm gateway endpoint
**Reason**: Swarm is not configured in Sid's config.toml (no `[swarm]` section, no delegate agents). The `/api/swarm` endpoint's only consumer was the zeroclaw MCP server, which has been removed. Patch 0013 and 0015 dropped.
**Migration**: No migration needed — feature was never actively used.
