## 1. Project Setup

- [x] 1.1 Create `mcp-servers/zeroclaw/` directory with Python project structure (pyproject.toml, src layout)
- [x] 1.2 Add dependencies: `mcp` SDK, `httpx` (async HTTP client), `slixmpp` (XMPP client library)
- [x] 1.3 Create main entry point (`__main__.py`) that initializes FastMCP server with stdio transport
- [x] 1.4 Add configuration module that reads all env vars (`ZEROCLAW_GATEWAY_URL`, `ZEROCLAW_GATEWAY_TOKEN`, XMPP vars, Pushover vars) with validation

## 2. Gateway HTTP Client

- [x] 2.1 Implement shared async HTTP client with bearer token auth header injection
- [x] 2.2 Add error handling for gateway unavailability (connection refused, timeouts)

## 3. Memory Tools

- [x] 3.1 Implement `memory_store` tool — POST to `/api/memory` with key/value payload
- [x] 3.2 Implement `memory_recall` tool — GET from `/api/memory` with optional query parameter
- [x] 3.3 Implement `memory_forget` tool — DELETE to `/api/memory/{key}`

## 4. Cron Tools

- [x] 4.1 Implement `cron_list` tool — GET from `/api/cron`
- [x] 4.2 Implement `cron_add` tool — POST to `/api/cron` with schedule, message, and description
- [x] 4.3 Implement `cron_remove` tool — DELETE to `/api/cron/{id}`
- [x] 4.4 Implement `cron_run` tool — POST to `/api/cron/{id}/run`

## 5. XMPP Send Tool

- [x] 5.1 Implement `xmpp_send` tool with connect-per-invocation model using slixmpp
- [x] 5.2 Handle MUC room vs direct message detection based on recipient JID
- [x] 5.3 Graceful degradation — tool unavailable if XMPP env vars missing, other tools still work

## 6. Pushover Tool

- [x] 6.1 Implement `pushover_send` tool — POST to `https://api.pushover.net/1/messages.json`
- [x] 6.2 Support optional priority and sound parameters
- [x] 6.3 Graceful degradation — tool unavailable if Pushover env vars missing, other tools still work

## 7. NixOS Integration

- [x] 7.1 Create Nix package derivation for the MCP server (Python with dependencies)
- [x] 7.2 Register `zeroclaw-mcp` as a new server in mcp-gw configuration
- [x] 7.3 Wire environment variables (gateway URL/token, XMPP creds, Pushover creds) into systemd service via agenix secrets
- [x] 7.4 Add the MCP server binary to the service PATH

## 8. Verification

- [x] 8.1 Test MCP server starts and responds to tool list request via stdio
- [x] 8.2 Verify memory tools work end-to-end through mcp-gw → MCP server → gateway
- [x] 8.3 Verify cron tools work end-to-end through mcp-gw → MCP server → gateway
- [x] 8.4 Verify XMPP send works through mcp-gw → MCP server → XMPP server
- [x] 8.5 Verify Pushover send works through mcp-gw → MCP server → Pushover API
