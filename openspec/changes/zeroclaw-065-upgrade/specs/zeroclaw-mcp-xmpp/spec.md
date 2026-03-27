## REMOVED Requirements

### Requirement: MCP XMPP tool access
**Reason**: Native ZeroClaw XMPP tools (`xmpp_send_message`, `xmpp_join_room`, `xmpp_leave_room`, `xmpp_set_presence`) replace MCP path. The zeroclaw MCP server is removed.
**Migration**: Use native XMPP tools directly. Remove `mcp-gw call zeroclaw xmpp_send` examples from TOOLS.md.
