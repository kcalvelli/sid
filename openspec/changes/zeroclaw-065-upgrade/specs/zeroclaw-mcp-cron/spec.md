## REMOVED Requirements

### Requirement: MCP cron tool access
**Reason**: Native ZeroClaw tools (`cron_add`, `cron_list`, `cron_remove`, `cron_update`, `cron_run`, `cron_runs`) replace MCP path. The zeroclaw MCP server is removed.
**Migration**: Use native cron tools directly. Remove `mcp-gw call zeroclaw cron_*` examples from TOOLS.md.
