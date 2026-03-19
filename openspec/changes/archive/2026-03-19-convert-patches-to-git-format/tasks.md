## 1. Generate patch files from current Python scripts

- [x] 1.1 Clone zeroclaw at pinned commit `d2b0593b` into a temporary worktree
- [x] 1.2 Apply the Cargo.toml fix (add `futures`, `async-stream`) and commit as `0001-add-missing-crate-deps`
- [x] 1.3 Apply message timestamp patches (channels/mod.rs, daemon/mod.rs, gateway/mod.rs) and commit as `0002-message-timestamps`
- [x] 1.4 Apply XMPP channel wiring (mod.rs module decl, schema.rs config, tools/mod.rs registration) and commit as `0003-xmpp-channel-wiring`
- [x] 1.5 Apply webhook agent loop change (gateway/mod.rs) and commit as `0004-webhook-agent-loop`
- [x] 1.6 Apply `/v1/models` endpoint (gateway/mod.rs) and commit as `0005-models-endpoint`
- [x] 1.7 Apply OpenAI proxy wiring (gateway/mod.rs module decl + router) and commit as `0006-openai-proxy-wiring`
- [x] 1.8 Apply email self-loop prevention (email_channel.rs) and commit as `0007-email-self-loop-prevention`
- [x] 1.9 Apply email reply subject threading (email_channel.rs) and commit as `0008-email-reply-threading`
- [x] 1.10 Apply email Sent folder IMAP append (email_channel.rs) and commit as `0009-email-sent-folder`
- [x] 1.11 Apply image vision patches (providers/anthropic.rs) and commit as `0010-image-vision`
- [x] 1.12 Run `git format-patch` to extract all 10 commits as `.patch` files

## 2. Add patch files to repository

- [x] 2.1 Copy generated `.patch` files into `patches/` directory alongside existing `xmpp.rs` and `openai_proxy.rs`
- [x] 2.2 Verify each `.patch` file has a descriptive commit message header and clean unified diff

## 3. Rewrite flake.nix patch application

- [x] 3.1 Add all `.patch` files to the `patches` attribute on `buildRustPackage`
- [x] 3.2 Replace the ~560-line `postPatch` with file copies only (`cp xmpp.rs`, `cp openai_proxy.rs`)
- [x] 3.3 Remove `${pkgs.python3}` from `postPatch` references

## 4. Verify build equivalence

- [x] 4.1 Build with `nix build` and confirm successful compilation
- [x] 4.2 Diff the patched source tree (new approach) against a reference build (old approach) to confirm identical output
- [ ] 4.3 Deploy to `mini` and verify zeroclaw service starts and passes a basic smoke test (Telegram message, heartbeat fires)
