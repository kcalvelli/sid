## Why

Sid runs entirely through the `claude-code` provider, which bypasses ZeroClaw's native agent loop. This means ZeroClaw's full tool registry (memory, web_fetch, email, shell, canvas, swarm, SOP tools) is compiled into the binary but invisible to Sid. SOPs can't execute steps, swarms can't orchestrate, and canvas sits disconnected. Meanwhile, Opus on the subscription is essentially free for interactive chat — the cost concern that originally drove the claude-code choice doesn't apply to conversation, only to automated tasks.

A tiered model routing architecture keeps Sid (Opus/claude-code/subscription) as the personality and orchestration layer while adding native Anthropic workers (Haiku/Sonnet via API) for structured task execution. Workers run inside ZeroClaw's native agent loop with full tool access at ~19x cheaper than Opus.

## What Changes

- **Add `swarm_invoke` MCP tool** to `zeroclaw-mcp`: Sid dispatches multi-step tasks to native ZeroClaw swarms from within claude-code. Returns structured results for Sid to present in his voice.
- **Add `canvas_update` MCP tool** to `zeroclaw-mcp`: Sid pushes HTML frames directly to the dashboard canvas for interactive visual output (news briefs, weather, prototypes).
- **Configure delegate agents**: Haiku worker (structured execution, data gathering) and Sonnet researcher (judgment tasks, memory writes) in ZeroClaw config.
- **Configure swarm definitions**: Sequential and parallel pipelines composing delegate agents.
- **Patch SOP provider override**: Add `provider` and `model` fields to `SOP.toml` so automated SOPs run on native Anthropic (Haiku/Sonnet) instead of the primary claude-code provider.
- **Add Anthropic API key**: Wire API key into agenix secrets and ZeroClaw config for the native provider.
- **Add Pushover notification on worker failure**: SOP/swarm failures push a notification rather than silently logging.

## Capabilities

### New Capabilities
- `swarm-mcp-bridge`: MCP tool bridging claude-code to ZeroClaw's native swarm orchestration
- `canvas-mcp-bridge`: MCP tool for direct canvas rendering from claude-code
- `delegate-agents`: Native Anthropic delegate agents (Haiku worker, Sonnet researcher) with ZeroClaw tool access
- `sop-provider-override`: Per-SOP provider/model configuration via patch

### Modified Capabilities
- `zeroclaw-mcp-memory`: No spec change, but workers now access memory natively (not through MCP)
- `sop-automation`: SOPs gain provider override, enabling native execution

## Impact

- **zeroclaw-mcp** (`mcp-servers/zeroclaw/`): Add `swarm_invoke` and `canvas_update` tools
- **NixOS module** (`modules/nixos/default.nix`): Add `[agents.*]` and `[swarms.*]` config sections, Anthropic API key environment variable
- **ZeroClaw patch** (new patch): Add `provider`/`model` fields to SOP TOML schema and engine
- **agenix secrets**: Add or reuse Anthropic API key secret
- **Workspace SOPs**: Update `SOP.toml` files with provider/model fields
- **Cost**: New API spend on Haiku/Sonnet — estimated $2-5/month for automated tasks
