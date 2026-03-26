## 1. Version Bump and Build

- [x] 1.1 Update `flake.nix` ZeroClaw input from `v0.6.2` to `v0.6.3`
- [x] 1.2 Run `nix flake lock --update-input zeroclaw` to update flake.lock
- [x] 1.3 Attempt initial build, capture cargoHash mismatch, update hash in flake.nix
- [x] 1.4 Verify clean build completes with new hash — zeroclaw 0.6.3 binary produced, also updated npmDepsHash and removed memory-postgres feature (now built-in)

## 2. Patch Rebase

- [x] 2.1 Apply patch 0001 (futures/async-stream crate deps) — still needed, regenerated for v0.6.3
- [x] 2.2 Apply patch 0002 (message timestamps) — regenerated for v0.6.3
- [x] 2.3 Apply patch 0003 (XMPP channel wiring) — regenerated for v0.6.3
- [x] 2.4 Apply patch 0004 (webhook agent loop) — applied cleanly
- [x] 2.5 Apply patch 0005 (v1/models endpoint) — applied cleanly, kept (upstream SSE proxy doesn't replace this)
- [x] 2.6 Apply patch 0006 (OpenAI proxy wiring) — regenerated for v0.6.3
- [x] 2.7 Apply patch 0007 (email self-loop prevention) — applied cleanly
- [x] 2.8 Apply patch 0008 (email reply subject threading) — regenerated for v0.6.3
- [x] 2.9 Apply patch 0009 (email Sent folder IMAP append) — applied cleanly
- [x] 2.10 Apply patch 0010 (Telegram context prefix) — applied cleanly
- [x] 2.11 Apply patch 0011 (Claude Code capability reporting) — applied cleanly
- [x] 2.12 Apply patch 0012 (Claude Code permission check bypass) — applied cleanly
- [x] 2.13 Apply patch 0013 (swarm gateway endpoint) — applied cleanly
- [x] 2.14 Apply patch 0014 (SOP provider override) — applied cleanly
- [x] 2.15 Apply patch 0015 (swarm agentic agent loop) — applied cleanly
- [x] 2.16 Apply patch 0016 (canvas WebSocket subprotocol) — applied cleanly
- [x] 2.17 Apply patch 0017 (CanvasStore shared singleton) — regenerated for v0.6.3
- [x] 2.18 Verify `openai_proxy.rs` and `xmpp.rs` replacement files still compile against v0.6.3 — build succeeded
- [x] 2.19 Renumber patches if any were dropped, update flake.nix patch list — no patches dropped, all 17 retained
- [x] 2.20 Build with full rebased patch set — verify clean compilation — zeroclaw 0.6.3 builds successfully

## 3. Cost-Optimized Routing

- [x] 3.1 Research v0.6.3 config schema for routing strategy — uses `[[model_routes]]` with `hint:cost-optimized`, not a global strategy key
- [x] 3.2 Add `[[model_routes]]` for cost-optimized and reasoning hints to NixOS module
- [x] 3.3 Add `max_tokens` to worker (2048) and researcher (8192) agent configs in NixOS module
- [ ] 3.4 Verify routing selects cheapest provider when cost-optimized is enabled

## 4. Anthropic SSE Streaming

- [x] 4.1 Research v0.6.3 anthropic provider streaming config keys — SSE streaming is always-on (stream=true hardcoded), no config needed
- [x] 4.2 No config change needed — anthropic SSE streaming is default behavior in v0.6.3
- [ ] 4.3 Verify streaming works on anthropic fallback path

## 5. Fallback Notifications

- [x] 5.1 Research v0.6.3 fallback notification config — built-in, appends footer when cross-family fallback occurs, no config needed
- [x] 5.2 No config change needed — fallback notifications are automatic in v0.6.3
- [ ] 5.3 Test: trigger provider fallback and verify user sees notification

## 6. BM25 Memory Search

- [x] 6.1 Research v0.6.3 memory search_mode config key — `search_mode = "bm25"` in `[memory]` section
- [x] 6.2 Add `search_mode = "bm25"` to `[memory]` section in NixOS module
- [ ] 6.3 Test memory retrieval returns relevant results with BM25

## 7. Web UI Enhancements

- [ ] 7.1 Verify collapsible thinking/reasoning UI works in web channel after upgrade
- [ ] 7.2 Verify markdown rendering in web chat messages
- [ ] 7.3 Verify responsive mobile sidebar with hamburger toggle
- [x] 7.4 Rebuild web frontend from v0.6.3 source — npmDepsHash updated, builds from v0.6.3 source

## 8. New Tools

- [ ] 8.1 Verify `escalate_to_human` tool appears in tool registry after upgrade
- [x] 8.2 Wire Pushover as high-urgency escalation target — no config needed, tool reads PUSHOVER_TOKEN and PUSHOVER_USER_KEY from workspace .env (already wired)
- [ ] 8.3 Verify `report_template` tool appears in tool registry after upgrade
- [ ] 8.4 Test report_template invocation from morning-briefing SOP context

## 9. Integration Testing

- [ ] 9.1 Deploy with `nixos-rebuild test` — verify gateway starts
- [ ] 9.2 Verify Telegram channel connects and responds
- [ ] 9.3 Verify email channel sends/receives
- [ ] 9.4 Verify web/canvas channel loads with new UI
- [ ] 9.5 Verify OpenAI proxy endpoint works (Home Assistant compatibility)
- [ ] 9.6 Verify memory save/retrieve cycle
- [ ] 9.7 Verify TTS and transcription still work
- [ ] 9.8 Verify SOP cron execution (morning-briefing fires)
- [ ] 9.9 Verify cost tracking and limits function
- [ ] 9.10 `nixos-rebuild switch` for production deployment
