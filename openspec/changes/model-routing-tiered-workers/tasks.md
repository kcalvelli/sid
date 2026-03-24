## 1. Anthropic API key and native provider config

- [x] 1.1 Add Anthropic API key to agenix secrets (or verify existing `anthropic-oauth-token` works for API auth)
- [x] 1.2 Wire API key into ZeroClaw environment in NixOS module
- [x] 1.3 Add `[agents.worker]` config section: provider=anthropic, model=claude-haiku-4-5, agentic=true, temperature=0.3, minimal system prompt
- [x] 1.4 Add `[agents.researcher]` config section: provider=anthropic, model=claude-sonnet-4-6, agentic=true, temperature=0.5, Sid-lite system prompt
- [x] 1.5 Add cost tracking prices for Haiku and Sonnet models in `[cost.prices]`

## 2. Swarm definitions

- [x] 2.1 Add `[swarms.briefing]` config: agents=[researcher, worker], strategy=sequential, description="Research then execute pipeline"
- [x] 2.2 Add `[swarms.data-gather]` config: agents=[worker], strategy=sequential, description="Single-agent data gathering"

## 3. MCP bridge tools

- [x] 3.1 Add `swarm_invoke(swarm, prompt)` tool to zeroclaw-mcp: POST to gateway swarm endpoint, return structured results with step outputs and errors
- [x] 3.2 Add `canvas_update(html, canvas_id?)` tool to zeroclaw-mcp: POST/PUT to gateway canvas endpoint, support named canvases and clearing
- [x] 3.3 Test swarm_invoke end-to-end: Sid dispatches to worker via MCP, worker executes with ZeroClaw tools, result returns to Sid

## 4. SOP provider override patch

- [x] 4.1 Create patch: add `provider` and `model` fields to SOP TOML schema (`src/sop/types.rs`)
- [x] 4.2 Create patch: SOP engine creates dedicated provider instance when override fields present (`src/sop/engine.rs`)
- [x] 4.3 Add patch to flake.nix patches list
- [x] 4.4 Update workspace SOP definitions with provider/model fields (morning-briefing: sonnet, session-review: sonnet, stay-quiet: haiku)
- [x] 4.5 Build and verify patches apply cleanly

## 5. Failure notification

- [x] 5.1 Add SOP failure Pushover notification: on run failure, send notification with SOP name, failed step, error message via existing Pushover MCP tool or direct integration

## 6. Validate and test

- [x] 6.1 Deploy and verify delegate agents load (check daemon logs)
- [x] 6.2 Test swarm_invoke from Sid via Telegram: dispatch a data-gather swarm, verify result returns
- [ ] 6.3 Test canvas_update from Sid: push an HTML frame, verify dashboard renders it
- [x] 6.4 Test SOP execution: manually trigger morning-briefing SOP, verify it runs on Sonnet with native tools (ran via sop_execute tool — executed through Sid/Claude Code path, not headless)
- [ ] 6.5 Test failure notification: trigger a SOP with a bad tool call, verify Pushover notification arrives — BLOCKED: SOP cron dispatch loop not wired into gateway (see 7.5)

## 7. Follow-up TODOs

- [x] 7.1 Patch SwarmTool to use agentic agent loop (agent::run) instead of chat_with_system — enables workers to use ZeroClaw tools (shell, web_fetch, email, memory, etc.)
- [ ] 7.2 Fix dashboard Canvas WebSocket auth — live rendering fails because WebSocket upgrade doesn't pass bearer token correctly. REST API works, only live view is broken. Upstream bug zeroclaw-labs/zeroclaw#2168 (stale web/dist assets).
- [ ] 7.3 Test SOP autonomous execution via cron trigger — BLOCKED: check_sop_cron_triggers exists but nothing calls it from the gateway main loop. Needs new patch to wire cron dispatch into gateway scheduler.
- [x] 7.4 Add Pushover notification on SOP failure (task 5.1)
- [ ] 7.5 Wire SOP cron dispatch into gateway — patch gateway/mod.rs to call check_sop_cron_triggers from the scheduler loop. Without this, SOPs only execute interactively (via sop_execute tool) not autonomously via cron.
- [ ] 7.6 Fix Sid's Pushover tool — native pushover tool needs .env file at expected path. Credentials exist in systemd env but tool looks elsewhere.
