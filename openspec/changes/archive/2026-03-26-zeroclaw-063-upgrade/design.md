## Context

Sid runs ZeroClaw v0.6.2 with 17 custom patches and 2 replacement source files. The service is deployed via NixOS with `buildRustPackage`, secrets injected by agenix, and config.toml generated from the NixOS module. v0.6.3 was released 2026-03-26 with features that directly benefit Sid's cost-optimization priority and UX.

Current patch set (17 patches + 2 replacement files) has been stable since the zeroclaw-062-features change was completed 2026-03-25.

## Goals / Non-Goals

**Goals:**
- Bump to v0.6.3 with all existing functionality preserved
- Enable cost-optimized routing, per-provider max_tokens, anthropic SSE streaming, fallback notifications, BM25 memory search, and web UI improvements
- Drop patches that v0.6.3 absorbs upstream
- Wire escalate-to-human and report-template tools into config

**Non-Goals:**
- Enabling Discord, Matrix, or Slack channels (no accounts configured)
- mTLS, WebAuthn, macOS sandbox, Windows support (not relevant to deployment)
- Voice calls via Twilio/Telnyx (no telephony accounts)
- ACP server mode (no consumers yet)
- Changing the primary provider from claude-code

## Decisions

### D1: Rebase-then-test patch strategy
Rebase all 17 patches onto v0.6.3 one at a time. For each patch that fails to apply, inspect the upstream diff to determine if the change was absorbed. If absorbed, drop the patch. If conflicting but not absorbed, regenerate the patch from a clean v0.6.3 checkout.

*Alternative considered:* Regenerate all patches from scratch against v0.6.3. Rejected — most patches touch Sid-specific code paths that upstream doesn't modify, so they should apply cleanly. Regenerating all 17 is unnecessary work.

### D2: Test OpenAI proxy patches against upstream SSE proxy support
v0.6.3 adds "parse proxy tool events from SSE stream." Before dropping patches 0005/0006 or `openai_proxy.rs`, verify that upstream's implementation provides equivalent functionality: `/v1/models` endpoint, `/v1/chat/completions` with identity injection, and single-burst SSE streaming. If upstream is partial, keep our patches and layer on top.

*Alternative considered:* Blindly drop our proxy patches assuming upstream covers it. Rejected — our proxy has specific behaviors (identity injection, body limit, HA integration) that may not match upstream.

### D3: Additive config — feature flags for all new capabilities
All new v0.6.3 features are enabled via config.toml sections in the NixOS module. No features are force-enabled. Each gets a NixOS option with a sensible default (enabled for features we want, disabled for features we don't).

### D4: BM25 as additional search mode, not replacement
Enable BM25 keyword search alongside existing memory config. Don't replace the default search — add `search_mode = "bm25"` or equivalent config key as an option.

### D5: Keep cargoHash approach
Continue using cargoHash (or cargoLock.lockFile) for the Rust build. v0.6.3 will have a different cargo hash — update it after first successful build.

## Risks / Trade-offs

- **Patch conflicts** → Mitigated by rebasing one-at-a-time with inspection. Most patches touch Sid-only code paths.
- **Upstream SSE proxy incomplete** → Mitigated by testing before dropping patches. Keep our implementation if upstream doesn't match.
- **Config schema changes** → v0.6.3 may rename or restructure config keys. Mitigated by reading upstream changelog and config docs before updating NixOS module.
- **Build hash change** → Expected. Will need to update cargoHash after first build attempt. Standard Nix workflow.
- **Memory search behavior change** → BM25 may return different results than current default. Mitigated by testing retrieval quality before committing.

## Migration Plan

1. Update `flake.nix` input to `v0.6.3`
2. `nix flake lock --update-input zeroclaw`
3. Attempt build — capture cargoHash mismatch, update hash
4. Rebase patches one at a time, noting which apply/fail
5. For failed patches: inspect upstream, drop if absorbed, regenerate if not
6. Test OpenAI proxy equivalence
7. Add new config sections to NixOS module
8. Deploy to staging (same host, `nixos-rebuild test`)
9. Verify: gateway starts, channels connect, tools work, memory retrieves, web UI loads
10. `nixos-rebuild switch` for production

**Rollback:** Revert flake.lock and any config changes, `nixos-rebuild switch` back to v0.6.2.

## Open Questions

- Does v0.6.3's cost-optimized routing strategy require explicit `[routing]` config, or does it activate via the existing `[cost]` section?
- What is the exact config key for BM25 search mode? Need to check upstream docs.
- Does the `escalate-to-human` tool require its own config section, or is it auto-registered?
