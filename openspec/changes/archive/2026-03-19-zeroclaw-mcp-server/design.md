## Context

Sid uses the `claude-code` provider, which shells out to `claude --print` for inference. Claude Code runs its own agent loop with its own tools, bypassing ZeroClaw's native tool registry. Four categories of ZeroClaw functionality are lost: memory (store/recall/forget), cron scheduling, XMPP messaging, and push notifications. ZeroClaw's gateway already exposes REST endpoints for memory and cron. XMPP and Pushover have no gateway endpoints.

The existing `mcp-gw` pattern (CLI wrapper around MCP servers) is proven infrastructure — Sid already uses it for email, calendar, GitHub, etc. via shell calls.

## Goals / Non-Goals

**Goals:**
- Restore memory, cron, XMPP send, and pushover functionality when using the claude-code provider
- Expose these as MCP tools accessible via `mcp-gw` (same pattern as existing tools)
- Reuse ZeroClaw's gateway API where endpoints already exist (memory, cron)
- Run as a stdio MCP server registered with the MCP gateway

**Non-Goals:**
- Replacing ZeroClaw's native tool system — this is a bridge, not a replacement
- Supporting multi-agent delegation or swarm orchestration via MCP
- Building a general-purpose ZeroClaw MCP server for other users — this is Sid-specific
- Real-time XMPP message receiving (that's the channel's job, not a tool)

## Decisions

### 1. Language: Python with `mcp` SDK

**Choice**: Python using the official `mcp` package (FastMCP pattern).

**Rationale**: The MCP Python SDK is mature, well-documented, and the `FastMCP` pattern makes it trivial to expose tools. The existing `mcp-gw` gateway already speaks MCP stdio protocol. Python is already in Sid's service PATH. TypeScript would work too but adds a Node.js runtime dependency that's heavier for NixOS packaging.

**Alternative considered**: Rust — would be consistent with ZeroClaw but the MCP Rust SDK is less mature and the development overhead is much higher for what's essentially HTTP proxy code.

### 2. Single server, four tool groups

**Choice**: One MCP server binary (`zeroclaw-mcp`) exposing all four tool groups.

**Rationale**: These tools share configuration (gateway URL, auth token) and deployment context. Separate servers would mean four entries in mcp-gw config, four processes, and redundant auth/HTTP setup. One server keeps it simple.

### 3. Gateway proxy for memory and cron, direct clients for XMPP and Pushover

**Choice**:
- Memory tools → HTTP calls to `localhost:{port}/api/memory`
- Cron tools → HTTP calls to `localhost:{port}/api/cron`
- XMPP send → Direct XMPP client connection (reuse existing credentials)
- Pushover → Direct HTTP POST to `api.pushover.net`

**Rationale**: Memory and cron already have full REST APIs on the gateway with the exact semantics we need. No point reimplementing what's already there. XMPP has no gateway endpoint and adding one would require another ZeroClaw patch — a direct XMPP client in the MCP server is simpler. Pushover is a single HTTP POST, no gateway involvement needed.

**Alternative considered for XMPP**: Adding a gateway endpoint via patch. Rejected because it's another patch to maintain against upstream, and the MCP server having its own XMPP client is more self-contained.

### 4. Authentication: Bearer token from gateway pairing

**Choice**: The MCP server reads the gateway bearer token from the same env file ZeroClaw uses. All gateway API calls include `Authorization: Bearer {token}`.

**Rationale**: The gateway already requires pairing auth (`require_pairing = true`). The paired token is generated at activation time and stored in the config. The MCP server needs this token to call the API.

### 5. Configuration via environment variables

**Choice**: All configuration via env vars, injected through the NixOS module:
- `ZEROCLAW_GATEWAY_URL` — e.g., `http://127.0.0.1:3141`
- `ZEROCLAW_GATEWAY_TOKEN` — bearer token for API auth
- `XMPP_JID` — e.g., `sid@chat.taile0fb4.ts.net`
- `XMPP_PASSWORD` — XMPP account password
- `XMPP_HOST` / `XMPP_PORT` — connection details
- `PUSHOVER_USER_KEY` / `PUSHOVER_API_TOKEN` — Pushover credentials

**Rationale**: Consistent with how ZeroClaw itself is configured. Secrets come from agenix, injected into the env file at activation.

### 6. Registration with mcp-gw

**Choice**: Register as a new server in the mcp-gw configuration, same as existing servers (brave-search, github, etc.).

**Rationale**: `mcp-gw` already handles server lifecycle, tool discovery, and invocation. The MCP server runs as a stdio subprocess managed by mcp-gw.

## Risks / Trade-offs

- **Gateway availability**: Memory and cron tools depend on the gateway being up. If ZeroClaw restarts, these tools fail temporarily. → Mitigation: These are on the same host, restarts are brief. Error messages will be clear.
- **XMPP connection management**: The MCP server runs as a stdio subprocess per invocation (mcp-gw spawns it). Establishing an XMPP connection per call adds latency. → Mitigation: For send-only operations, connect-send-disconnect is acceptable (~1s overhead). If latency is a problem, could switch to a long-running sidecar later.
- **Credential duplication**: XMPP credentials exist in both ZeroClaw's config.toml and the MCP server's env. → Mitigation: Both sourced from agenix secrets at activation time, single source of truth in the NixOS module.
- **Pushover token management**: New secret to manage. → Mitigation: Add to agenix, same pattern as existing secrets.

## Open Questions

- Should the MCP server persist an XMPP connection (long-running sidecar) or connect per invocation (stdio)? Starting with per-invocation for simplicity.
- Are there other ZeroClaw gateway endpoints worth exposing? (`/api/cost` for cost tracking, `/api/status` for health?) Could add later.
