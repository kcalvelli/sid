## REMOVED Requirements

### Requirement: MCP pushover tool access
**Reason**: Native ZeroClaw `pushover_send` tool replaces MCP path. The zeroclaw MCP server is removed.
**Migration**: Use native `pushover_send` tool directly. Remove `mcp-gw call zeroclaw pushover_send` examples from TOOLS.md.
