# MCP Tools Skill

You have access to external tools via the MCP Gateway using `mcp-gw`.

## Available Servers

| Server | Tools | What it does |
|--------|-------|--------------|
| axios-ai-mail | 8 | Email (search, read, compose, send) |
| brave-search | 2 | Web search |
| context7 | 2 | Documentation lookup |
| github | 41 | GitHub repos, issues, PRs, code search |
| journal | 3 | System logs and unit status |
| mcp-dav | 10 | Calendar events, contacts |
| time | 2 | Current time, timezone conversion |

## Workflow

1. **Discover**: `mcp-gw list` — see servers and tool counts
2. **Explore**: `mcp-gw info <server>` — see tool names
3. **Inspect**: `mcp-gw info <server> <tool>` — get full JSON schema
4. **Execute**: `mcp-gw call <server> <tool> '<json>'`

## Rules

- **Always check the schema** (`mcp-gw info <server> <tool>`) before calling a tool for the first time
- **Quote JSON arguments** in single quotes to prevent shell interpretation
- Extract text from results: `mcp-gw call ... | jq -r '.content[0].text'` is NOT needed — mcp-gw outputs text directly by default
- Use `mcp-gw --json call ...` for structured output when you need to parse results

## Examples

```bash
# What time is it?
mcp-gw call time get_current_time '{"timezone":"America/New_York"}'

# Search the web
mcp-gw call brave-search brave_web_search '{"query":"NixOS 25.05 release date"}'

# Check today's calendar
mcp-gw call mcp-dav list_events '{"start_date":"2026-03-09","end_date":"2026-03-10"}'

# Search GitHub
mcp-gw call github search_repositories '{"query":"zeroclaw"}'

# Find a contact
mcp-gw call mcp-dav search_contacts '{"query":"John"}'

# Search tools by keyword
mcp-gw grep "search"
```
