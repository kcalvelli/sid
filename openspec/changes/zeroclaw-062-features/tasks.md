## 1. Personality System

- [x] 1.1 Add `[identity]` section to NixOS module config template pointing to workspace SOUL.md and IDENTITY.md
- [x] 1.2 Remove duplicate personality/identity content from AGENTS.md (keep non-personality bootstrap content if any)
- [x] 1.3 Deploy and verify agent responses reflect SOUL.md/IDENTITY.md personality across Telegram and CLI channels — PASS

## 2. Media Pipeline

- [x] 2.1 ~~Add `[media_pipeline] enabled = true`~~ Invalid key — real config is `[transcription] enabled = true` with provider (groq/openai/deepgram/assemblyai/google)
- [x] 2.2 Add `[transcription]` config with Deepgram provider, deploy, test voice memo via Telegram — PASS (STT + TTS both working)
- [ ] 2.3 Test image description by sending a photo via Telegram and confirming agent receives description

## 3. New Tools (llm-task, memory-purge, ask-user)

- [x] 3.1 ~~Add tool registrations to config~~ Not needed — tools are compiled in and available natively (confirmed: 44 tools visible)
- [x] 3.2 Verify tools appear in agent's available tool list — PASS (llm_task, memory_purge, ask_user all visible)
- [ ] 3.3 Test `llm_task` with a structured JSON extraction prompt
- [ ] 3.4 Test `memory_purge` by purging a test memory entry
- [ ] 3.5 Test `ask_user` by triggering a prompt during a Telegram conversation

## 4. Pushover Env Fix

- [x] 4.1 Verify Pushover secrets in agenix — present
- [x] 4.2 Fix: native pushover reads `workspace/.env`, not process env — added `.env` write to activation script with `PUSHOVER_TOKEN` and `PUSHOVER_USER_KEY`
- [x] 4.3 Deploy and test pushover notification delivery end-to-end — PASS

## 5. Routines Engine and SOP Cron Dispatch

- [x] 5.1 ~~Routines engine~~ Not a valid config section — SOP cron triggers are defined inline in SOP.toml `[[triggers]]` and already registered by the built-in scheduler
- [x] 5.2 SOP cron triggers already defined: morning-briefing (6:30am), session-review (10pm), stay-quiet (11pm)
- [x] 5.3 Ask Sid to run morning-briefing SOP — PASS (executed, sent briefing email, 91s)
- [ ] 5.4 Verify stay-quiet cron runs on next scheduled trigger (check logs)

## 6. Deterministic SOPs

- [x] 6.1 Add `deterministic = true` to `stay-quiet` SOP definition in workspace
- [x] 6.2 Ask Sid to run stay-quiet SOP — PASS (executed, checked alerts, reported all quiet, 75s)
- [ ] 6.3 Check logs for deterministic execution (step-by-step without LLM round-trips) — need to verify deterministic flag is respected vs normal LLM execution

## 7. Canvas WebSocket Validation

- [x] 7.1 WebSocket upgrade to `/ws/chat` with bearer token — PASS (101 Switching Protocols, session_start received). Protocol echo only fires for `zeroclaw.v1` subprotocol, not bearer tokens (by design).
- [ ] 7.2 Ask Sid to push HTML to canvas via native `canvas` tool, verify dashboard renders
- [ ] 7.3 Test multiple simultaneous canvas sessions with different canvas IDs

## 8. Tauri Desktop Evaluation

- [x] 8.1 Attempt to build upstream ZeroClaw `apps/tauri` with Nix toolchain — no Tauri package in flake, no apps/tauri source directory, zero references in repo
- [x] 8.2 Document build result, required dependencies, and any patches needed — N/A, Tauri not present in v0.6.2
- [x] 8.3 If build succeeds, compare against web canvas UI — N/A
- [x] 8.4 Write go/no-go recommendation document — NO-GO: Tauri not available in ZeroClaw v0.6.2, web canvas is the UI
