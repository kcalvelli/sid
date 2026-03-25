## Context

ZeroClaw v0.6.2 is compiled with all 16 patches and running, but 11 features remain dormant. All features are already in the binary — enablement is purely configuration and wiring in the NixOS module (`modules/nixos/default.nix`) and workspace files. No new patches are expected.

Current architecture: NixOS module templates `config.toml` with secrets injected via agenix, workspace files (`SOUL.md`, `IDENTITY.md`, `TOOLS.md`, `USER.md`, `HEARTBEAT.md`) are git-synced to `/var/lib/sid/.zeroclaw/workspace/`, and the MCP bridge (`mcp-servers/zeroclaw/`) exposes gateway tools to Claude Code.

## Goals / Non-Goals

**Goals:**
- Enable all 11 features through config changes and workspace file additions
- Keep all configuration in the NixOS module (declarative, reproducible)
- Validate features work post-deploy with concrete acceptance criteria
- Resolve the SOP cron dispatch gap carried forward from model-routing change

**Non-Goals:**
- Writing new ZeroClaw patches (everything needed is in v0.6.2)
- Migrating to a different secrets management approach
- Replacing the MCP bridge architecture
- Full Tauri desktop deployment (evaluation only this round)
- Adding new SOP definitions beyond what's needed to test deterministic mode

## Decisions

### D1: Routines engine for SOP cron dispatch (not gateway scheduler)

Use the routines engine (`routines.toml`) to handle SOP cron triggers rather than wiring `check_sop_cron_triggers` into the gateway scheduler directly.

**Why:** The routines engine is purpose-built for event-triggered automation with cron patterns. Wiring into the gateway scheduler would duplicate functionality and bypass the routines engine's pattern-matching and action-dispatch system. This also means SOP cron dispatch (feature #9) is solved by enabling the routines engine (feature #1) — two birds, one stone.

**Alternative considered:** Direct gateway scheduler integration. Rejected because it would require a new patch to wire `check_sop_cron_triggers` and the routines engine already provides cron dispatch.

### D2: Config-section enablement pattern

Each feature follows the same pattern: add or modify a TOML section in the NixOS module's config template. The three new tools (llm-task, memory-purge, ask-user) are enabled via `[tools.*]` config stanzas — they're already compiled in, just not registered.

**Why:** Consistent with existing patterns for TTS, memory, channels. Keeps everything declarative in the NixOS module.

### D3: Personality loading via workspace identity source

Configure `[identity]` to load from workspace files (`SOUL.md`, `IDENTITY.md`) natively, then remove the manual AGENTS.md bootstrap instructions that currently duplicate this content.

**Why:** `SOUL.md` and `IDENTITY.md` already exist and are well-written. Native loading eliminates the bootstrap step and ensures personality is consistent across all interaction modes (not just sessions that happen to load AGENTS.md).

### D4: Media pipeline with ElevenLabs for audio, built-in for images

Enable `[media_pipeline] enabled = true`. Audio transcription can leverage the already-configured ElevenLabs integration (TTS is wired but dormant). Image description uses ZeroClaw's built-in vision capability.

**Why:** ElevenLabs API key and TTS config already exist in agenix secrets and NixOS module. No new dependencies needed.

**Alternative considered:** Whisper self-hosted. Rejected — adds deployment complexity for marginal benefit on a single-user system.

### D5: Tauri evaluation deferred to spike

The Tauri desktop app lives in upstream ZeroClaw's `apps/tauri`, not in the Sid repo. Evaluation means: attempt to build it, assess whether it adds value over the web canvas UI, and document findings. No commitment to deploy.

**Why:** The web canvas already works (patch 0016 fixed WebSocket). Tauri may not add enough value to justify maintaining a native app build. Need information before deciding.

### D6: Deterministic SOP test with morning-briefing

Test deterministic mode by adding `deterministic = true` to the `stay-quiet` SOP (simplest, lowest risk). If successful, evaluate for morning-briefing and session-review.

**Why:** `stay-quiet` is a lightweight alert-checking SOP that doesn't need LLM judgment — ideal candidate for step-by-step execution. Morning-briefing and session-review produce user-facing content where LLM flexibility has value.

### D7: Pushover fix via NixOS env injection

The Pushover env path issue is that the native pushover tool doesn't find `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN`. These are already in agenix secrets and injected into the ZeroClaw service env file. Fix: verify the env vars are in the tool's execution environment (they should be, since the service env file is sourced globally).

**Why:** The secrets are already managed correctly. This is likely a tool-specific env inheritance issue, not a missing secret.

## Risks / Trade-offs

**[Routines engine misconfiguration]** → Start with a single cron routine (SOP dispatch) and validate before adding webhook/channel triggers. Keep `routines.toml` minimal initially.

**[Media pipeline cost]** → ElevenLabs transcription is API-billed. Mitigate by only enabling on channels where media is expected (Telegram, email attachments). Monitor usage via API dashboard.

**[Personality drift]** → Native identity loading means SOUL.md/IDENTITY.md changes take effect immediately. Mitigate by keeping these files in the git-synced workspace so changes are tracked and reviewable.

**[Deterministic SOP edge cases]** → Steps that produce unexpected output may cause the SOP to stall without LLM to recover. Mitigate by starting with `stay-quiet` (simple, predictable steps) and adding checkpoint approval gates.

**[Tauri build failure]** → Upstream Tauri app may not build with Sid's Nix toolchain. Acceptable risk since this is evaluation-only.

## Migration Plan

All features are configuration changes deployed via NixOS rebuild. Rollback is a `git revert` of the NixOS module changes and redeploy.

**Deploy order (minimize risk):**
1. Personality system + media pipeline (config flags, low risk)
2. New tools: llm-task, memory-purge, ask-user (tool registration, low risk)
3. Pushover env fix (verify and fix, low risk)
4. Routines engine + SOP cron dispatch (new config file, medium risk)
5. Deterministic SOPs on stay-quiet (SOP schema change, medium risk)
6. Canvas WebSocket validation (already deployed, just verify)
7. Tauri evaluation spike (no deploy, evaluation only)

## Open Questions

- **Q1:** Does the routines engine need its own config section in `config.toml` or is `routines.toml` loaded automatically from the workspace?
- **Q2:** What's the exact `[identity]` config syntax for workspace-based personality loading? Need to check ZeroClaw v0.6.2 docs or source.
- **Q3:** Are the three new tools (llm-task, memory-purge, ask-user) registered via `[tools.*]` config or are they automatically available once the binary includes them?
