## REMOVED Requirements

### Requirement: MCP memory tool access
**Reason**: Native ZeroClaw tools (`memory_store`, `memory_recall`, `memory_purge`) replace MCP path. The zeroclaw MCP server is removed.
**Migration**: Use native memory tools directly. Remove `mcp-gw call zeroclaw memory_*` examples from TOOLS.md.
