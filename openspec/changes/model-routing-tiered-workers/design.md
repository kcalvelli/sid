## Context

Sid operates through claude-code (Opus, subscription) for all interactions. ZeroClaw's native tool registry is invisible to claude-code because it bypasses the agent loop. The `zeroclaw-mcp` server already bridges some gateway tools (memory, cron, xmpp, pushover) to Claude Code via MCP. SOPs were added but can't execute steps without a native provider.

Sid's input on this design: "Don't make everything go through workers. Direct calls for simple stuff, workers for complex stuff, and clear boundaries for which is which."

## Goals / Non-Goals

**Goals:**
- Sid (Opus/claude-code) stays as the personality and orchestration layer for interactive chat
- Native Anthropic workers (Haiku/Sonnet) handle multi-step structured tasks via ZeroClaw's agent loop
- Sid can dispatch to workers via `swarm_invoke` MCP tool and render to canvas via `canvas_update` MCP tool
- SOPs execute autonomously on native providers via per-SOP provider override
- Worker failures notify via Pushover

**Non-Goals:**
- Replacing claude-code as the default provider for chat
- Routing simple MCP tool calls through workers (memory_recall, cron_list, xmpp_send stay direct)
- Running Opus through the API (subscription handles chat)
- Building a full routing rules engine — keep it simple: direct MCP for simple calls, workers for complex orchestration

## Decisions

### 1. Two-tier tool access, not one-size-fits-all
Simple tool calls (memory, cron, xmpp, pushover) continue via direct MCP as today. Multi-step tasks and native-only features (swarms, SOPs, canvas data pipelines) go through workers. The boundary: if it's a single tool call, direct MCP. If it's multiple steps or needs ZeroClaw's agent loop, dispatch to a worker.

### 2. Worker persona: minimal for execution, Sid-lite for user-facing output
Execution workers get a brief operational system prompt ("You are a task executor. Execute precisely. Return structured results."). SOPs that produce user-facing content (morning briefing email) get a stripped-down Sid persona so the output sounds like him.

### 3. Sonnet for judgment, Haiku for data gathering
Workers that write to persistent state (memory, workspace files) or make judgment calls use Sonnet. Workers that fetch/transform data use Haiku. This maps to two delegate agents: `worker` (Haiku) and `researcher` (Sonnet).

### 4. Canvas is Tier 1 (direct MCP)
`canvas_update` is a direct MCP tool so Sid can render and iterate interactively. For data-driven canvas (weather widget, news brief), Sid dispatches a worker to gather data, then renders it himself. This keeps the creative loop tight.

### 5. SOP provider override via patch
Add `provider` and `model` fields to ZeroClaw's SOP TOML schema. When present, the SOP engine creates a dedicated provider instance for that SOP's execution. When absent, falls back to the primary agent's provider. Small surgical patch — ~30 lines in `src/sop/engine.rs` and `src/sop/types.rs`.

### 6. Fail fast + Pushover notify on worker failure
Workers use ReliableProvider's built-in retry (2 retries, 500ms backoff) for transient errors. SOP-level: fail the run, log to audit trail, push a Pushover notification. No SOP-level retry or escalation — keep it simple. Error context (step name, tool that failed, error message) included in the notification.

### 7. Anthropic API key via agenix
Reuse the existing `anthropic-oauth-token` secret if it works for API auth. Otherwise add a new `anthropic-api-key` secret. Wire into ZeroClaw config as `api_key` for the native provider.

## Risks / Trade-offs

- **Latency on swarm_invoke**: Round-trip through MCP → gateway → Haiku worker → back. Acceptable for multi-step tasks (SOPs, data gathering) but would be painful for simple operations — hence the two-tier boundary.
- **SOP patch maintenance**: New patch to maintain across zeroclaw upgrades. Small scope (~30 lines) minimizes conflict surface. Could be upstreamed if the feature proves useful.
- **Haiku quality for SOPs**: Haiku may struggle with complex judgment. Mitigated by using Sonnet for judgment-heavy tasks and having Sid review worker output for user-facing content.
- **Cost unpredictability**: API usage is pay-per-token vs. subscription flat rate. Mitigated by existing cost tracking ($5/day, $100/month limits) and per-model cost config. Estimated $2-5/month for automated tasks.
