## ADDED Requirements

### Requirement: Store memory via MCP tool
The MCP server SHALL expose a `memory_store` tool that accepts a key and value, and persists the memory by calling the ZeroClaw gateway's `POST /api/memory` endpoint with the bearer token.

#### Scenario: Successful memory store
- **WHEN** the `memory_store` tool is called with key "user_preference" and value "dark mode"
- **THEN** the server SHALL POST to `{ZEROCLAW_GATEWAY_URL}/api/memory` with the key-value payload and return a success confirmation

#### Scenario: Gateway unavailable during store
- **WHEN** the `memory_store` tool is called and the gateway is unreachable
- **THEN** the server SHALL return an error message indicating the gateway is unavailable

### Requirement: Recall memory via MCP tool
The MCP server SHALL expose a `memory_recall` tool that accepts an optional query string and retrieves memories by calling the ZeroClaw gateway's `GET /api/memory` endpoint.

#### Scenario: Recall all memories
- **WHEN** the `memory_recall` tool is called with no query
- **THEN** the server SHALL GET `{ZEROCLAW_GATEWAY_URL}/api/memory` and return all stored memories

#### Scenario: Recall with query filter
- **WHEN** the `memory_recall` tool is called with query "preference"
- **THEN** the server SHALL pass the query parameter to the gateway and return matching memories

### Requirement: Forget memory via MCP tool
The MCP server SHALL expose a `memory_forget` tool that accepts a key and deletes the memory by calling the ZeroClaw gateway's `DELETE /api/memory` endpoint.

#### Scenario: Successful memory deletion
- **WHEN** the `memory_forget` tool is called with key "user_preference"
- **THEN** the server SHALL DELETE `{ZEROCLAW_GATEWAY_URL}/api/memory/{key}` and return a success confirmation

#### Scenario: Forget nonexistent key
- **WHEN** the `memory_forget` tool is called with a key that does not exist
- **THEN** the server SHALL forward the gateway's response (which may be a 404 or no-op) and return an appropriate message

### Requirement: Bearer token authentication for memory endpoints
All memory tool calls to the gateway SHALL include an `Authorization: Bearer {ZEROCLAW_GATEWAY_TOKEN}` header.

#### Scenario: Missing gateway token
- **WHEN** the MCP server starts without `ZEROCLAW_GATEWAY_TOKEN` set
- **THEN** the server SHALL fail to start with a clear error message indicating the missing credential
