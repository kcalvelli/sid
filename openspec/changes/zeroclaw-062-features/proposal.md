## Why

ZeroClaw v0.6.2 ships 11 new features that were compiled into the Sid build (16 patches applied cleanly) but remain dormant — they need configuration, wiring, and validation to go live. Enabling these features unlocks automation (routines engine, SOP cron), richer interaction (personality, media pipeline, ask-user), and new tooling (llm-task, memory-purge, Tauri desktop) that together close the gap between what ZeroClaw can do and what Sid actually uses.

## What Changes

- **Enable routines engine** — Configure `routines.toml` with event-triggered automation (cron, webhook, channel patterns dispatching to SOP triggers, shell commands, messages)
- **Enable personality system** — Load `SOUL.md` and `IDENTITY.md` from workspace, replacing manual `AGENTS.md` bootstrap
- **Enable media pipeline** — Set `[media_pipeline] enabled = true` for auto-transcription of audio, image description, and video summarization on inbound messages
- **Enable deterministic SOPs** — Configure `deterministic = true` on applicable SOPs for step-by-step execution without LLM round-trips, with checkpoint steps for human approval
- **Evaluate Tauri desktop app** — Build and assess the native desktop client in `apps/tauri`
- **Enable llm-task tool** — Lightweight sub-agent calls for structured JSON-only tasks
- **Enable memory-purge tool** — Memory cleanup and maintenance capability
- **Enable ask-user tool** — Interactive cross-channel user prompting and confirmations
- **Wire SOP cron dispatch** — Connect `check_sop_cron_triggers` into the gateway scheduler or implement via the routines engine
- **Fix Pushover env path** — Correct Sid's native pushover tool `.env` path resolution
- **Validate canvas WebSocket** — Confirm patch 0016 WebSocket subprotocol fix works post-deploy

## Capabilities

### New Capabilities
- `routines-engine`: Event-triggered automation via `routines.toml` — cron, webhook, and channel-pattern triggers dispatching to configurable actions
- `personality-system`: Native `SOUL.md`/`IDENTITY.md` loading from workspace for agent identity and behavior
- `media-pipeline`: Automatic transcription, image description, and video summarization on inbound messages
- `deterministic-sops`: Step-by-step SOP execution without LLM, with checkpoint/approval gates
- `tauri-desktop`: Native desktop client evaluation, build, and integration
- `llm-task-tool`: Lightweight sub-agent tool for structured JSON-only tasks
- `memory-purge-tool`: Memory cleanup and maintenance tool
- `ask-user-tool`: Cross-channel interactive prompting and confirmation tool

### Modified Capabilities
- `sop-automation`: Wire SOP cron dispatch into gateway scheduler or routines engine
- `zeroclaw-mcp-pushover`: Fix `.env` path resolution for native pushover tool
- `canvas-mcp-bridge`: Validate WebSocket subprotocol fix (patch 0016) post-deploy

## Impact

- **Config files**: `routines.toml` (new), `SOUL.md`/`IDENTITY.md` (new), ZeroClaw gateway config updates for media pipeline, deterministic SOPs, and new tools
- **Gateway**: Scheduler changes for SOP cron dispatch; new tool registrations for llm-task, memory-purge, ask-user
- **SOP schema**: New `deterministic` field and checkpoint step type
- **Build**: Tauri desktop app requires Rust/Tauri build toolchain evaluation
- **Patches**: No new patches expected — all features already compiled in v0.6.2 build; changes are configuration and wiring
- **Existing specs affected**: sop-automation, zeroclaw-mcp-pushover, canvas-mcp-bridge (delta specs needed)
