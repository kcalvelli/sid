## 1. Personality System

- [x] 1.1 Add `[identity]` section to NixOS module config template pointing to workspace SOUL.md and IDENTITY.md
- [x] 1.2 Remove duplicate personality/identity content from AGENTS.md (keep non-personality bootstrap content if any)
- [ ] 1.3 Deploy and verify agent responses reflect SOUL.md/IDENTITY.md personality across Telegram and CLI channels

## 2. Media Pipeline

- [x] 2.1 Add `[media_pipeline] enabled = true` to NixOS module config template
- [ ] 2.2 Deploy and test audio transcription by sending a voice message via Telegram
- [ ] 2.3 Test image description by sending a photo via Telegram and confirming agent receives description

## 3. New Tools (llm-task, memory-purge, ask-user)

- [x] 3.1 Add `llm_task` tool registration to gateway config in NixOS module
- [x] 3.2 Add `memory_purge` tool registration to gateway config in NixOS module
- [x] 3.3 Add `ask_user` tool registration to gateway config in NixOS module
- [ ] 3.4 Deploy and verify all three tools appear in agent's available tool list
- [ ] 3.5 Test `llm_task` with a structured JSON extraction prompt
- [ ] 3.6 Test `memory_purge` by purging a test memory entry
- [ ] 3.7 Test `ask_user` by triggering a prompt during a Telegram conversation

## 4. Pushover Env Fix

- [x] 4.1 Verify `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN` are present in ZeroClaw service environment (`/var/lib/sid/.zeroclaw/env`)
- [ ] 4.2 If native pushover tool reads from wrong path, fix env resolution in NixOS module (ensure service env file is sourced for tool execution)
- [ ] 4.3 Test pushover notification delivery end-to-end

## 5. Routines Engine and SOP Cron Dispatch

- [x] 5.1 Create `routines.toml` in workspace with morning-briefing cron routine (`0 7 * * *`)
- [x] 5.2 Add session-review and stay-quiet cron routines to `routines.toml`
- [x] 5.3 Add routines engine config to NixOS module if needed (resolve open question Q1: auto-load vs config section)
- [ ] 5.4 Deploy and verify routines engine loads `routines.toml` on startup (check logs)
- [ ] 5.5 Test cron dispatch by triggering morning-briefing SOP manually or waiting for scheduled run

## 6. Deterministic SOPs

- [x] 6.1 Add `deterministic = true` to `stay-quiet` SOP definition in workspace
- [ ] 6.2 Deploy and trigger stay-quiet SOP, verify it executes step-by-step without LLM round-trips
- [ ] 6.3 Test checkpoint step behavior if stay-quiet has any approval gates

## 7. Canvas WebSocket Validation

- [ ] 7.1 Connect to canvas WebSocket endpoint and verify `Sec-WebSocket-Protocol` header is echoed in 101 response
- [ ] 7.2 Test `canvas_update` MCP tool call and confirm dashboard renders HTML in real-time
- [ ] 7.3 Test multiple simultaneous canvas sessions with different canvas IDs

## 8. Tauri Desktop Evaluation

- [ ] 8.1 Attempt to build upstream ZeroClaw `apps/tauri` with Nix toolchain
- [ ] 8.2 Document build result, required dependencies, and any patches needed
- [ ] 8.3 If build succeeds, compare against web canvas UI (native integration, performance, notifications, offline)
- [ ] 8.4 Write go/no-go recommendation document
