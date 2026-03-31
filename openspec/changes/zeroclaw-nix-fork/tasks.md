## 1. Create Fork Repository

- [x] 1.1 Create `kcalvelli/zeroclaw-nix` repo on GitHub from local clone at `~/Projects/zeroclaw` (`gh repo create kcalvelli/zeroclaw-nix --public --source ~/Projects/zeroclaw --push`)
- [x] 1.2 Add `upstream` remote pointing to `https://github.com/zeroclaw-labs/zeroclaw.git`
- [x] 1.3 Push all tags (`git push --tags`)
- [x] 1.4 Verify LICENSE file exists and confirms Apache 2.0 (dual: MIT OR Apache-2.0)

## 2. Set Up Branch Structure

- [x] 2.1 Create `upstream/master` branch from current `master` (preserves exact upstream state)
- [x] 2.2 Create `main` branch from the `v0.6.5` tag and set as default branch

## 3. Nix Packaging on main

- [x] 3.1 Create `nix/package.nix` — `buildRustPackage` derivation for zeroclaw server (move from sid's flake.nix, remove patches/postPatch)
- [x] 3.2 Create `nix/web.nix` — `buildNpmPackage` derivation for zeroclaw-web with optional `pwaOverlay` argument
- [x] 3.3 Create `nix/desktop.nix` — `buildRustPackage` derivation for zeroclaw-desktop (Tauri)
- [x] 3.4 Create `nix/module.nix` — generic NixOS module with freeform `settings`, typed channel submodules (`telegram`, `email`, `xmpp`), `*File` secret options, `preStart` injection script, systemd hardening, `environmentFiles`, `extraPackages`, `user`/`group`, `port`/`openFirewall`, `pwaOverlay`
- [x] 3.5 Create `flake.nix` — exports `packages.{zeroclaw, zeroclaw-web, zeroclaw-desktop}` and `nixosModules.default` for x86_64-linux and aarch64-linux
- [x] 3.6 Generate `flake.lock` (`nix flake lock`)
- [x] 3.7 Verify `nix build .#zeroclaw` succeeds on `main` branch (vanilla ZeroClaw, no patches)

## 4. Apply Custom Patches on main

- [x] 4.1 Apply patch 0001 as commit: `feat: wire XMPP channel into channel registry and config`
- [x] 4.2 Commit `xmpp.rs` at `src/channels/xmpp.rs`
- [x] 4.3 Apply patch 0002 as commit: `feat: use full agent loop for webhook requests`
- [x] 4.4 Apply patch 0003 as commit: `feat: add v1 models endpoint for OpenAI compatible`
- [x] 4.5 Apply patch 0004 as commit: `feat: wire OpenAI-compatible v1 chat completions`
- [x] 4.6 Commit `openai_proxy.rs` at `src/gateway/openai_proxy.rs`
- [x] 4.7 Apply patch 0005 as commit: `fix: skip emails from own address to prevent reply loop`
- [x] 4.8 Apply patch 0006 as commit: `feat: preserve email subject in reply threading`
- [x] 4.9 Apply patch 0007 as commit: `feat: save sent emails to IMAP Sent folder`
- [x] 4.10 Apply patch 0008 as commit: `fix: skip permission checks in Claude Code CLI`
- [x] 4.11 Apply patch 0009 as commit: `feat: sop provider override`
- [x] 4.12 Apply patch 0010 as commit: `fix: skip noreply and bounce emails to prevent error`
- [x] 4.13 Apply patch 0011 as commit: `feat: runtime gateway URL from ZEROCLAW_GATEWAY_URL` (desktop)
- [x] 4.14 Apply patch 0012 as commit: `feat: broaden Tauri CSP for remote gateway` (desktop)
- [x] 4.15 Verify `nix build .#zeroclaw` succeeds on `main` (all patches applied)
- [x] 4.16 Verify `nix build .#zeroclaw-desktop` succeeds on `main`

## 5. Update Sid Repo — Flake

- [x] 5.1 Update `flake.nix` input: replace `github:zeroclaw-labs/zeroclaw/v0.6.5` with `github:kcalvelli/zeroclaw-nix`
- [x] 5.2 Remove `buildRustPackage` and `buildNpmPackage` blocks from sid's `flake.nix`
- [x] 5.3 Replace with package references from the fork: `zeroclaw-nix.packages.${system}.zeroclaw`, etc.
- [x] 5.4 Import `zeroclaw-nix.nixosModules.default` in the module imports
- [x] 5.5 Run `nix flake lock --update-input zeroclaw-nix` to generate new lock entry

## 6. Update Sid Repo — NixOS Configuration

- [x] 6.1 Replace `modules/nixos/default.nix` with a thin config file that sets `services.zeroclaw` options (settings, channels, user/group, port, extraPackages, environmentFiles, pwaOverlay)
- [x] 6.2 Migrate Telegram channel config to `services.zeroclaw.channels.telegram` with `botTokenFile`
- [x] 6.3 Migrate Email channel config to `services.zeroclaw.channels.email` with `passwordFile`
- [x] 6.4 Migrate XMPP channel config to `services.zeroclaw.channels.xmpp` with `passwordFile`
- [x] 6.5 Migrate freeform settings (cost, gateway, agents, swarms, TTS, transcription, autonomy, etc.)
- [x] 6.6 Migrate `environmentFiles` for API keys (XAI, Anthropic, GitHub PAT, Pushover, ElevenLabs, Deepgram)
- [x] 6.7 Migrate workspace git clone/sync logic (activation script + timer)
- [x] 6.8 Migrate agenix secret declarations (ensure paths match new `*File` options)
- [x] 6.9 Migrate msmtp configuration for outbound email

## 7. Cleanup Sid Repo

- [x] 7.1 Delete `patches/` directory (all 12 .patch files + xmpp.rs + openai_proxy.rs)
- [x] 7.2 Remove old `modules/nixos/default.nix` (replaced by thin config in 6.1)
- [x] 7.3 Verify no references to `patches/` remain in the repo (only openspec docs/archives, no functional code)

## 8. Build and Deploy Verification

- [x] 8.1 Run `nix build` from sid repo — verify zeroclaw binary is produced
- [x] 8.2 Run `nix build .#zeroclaw-desktop` — verify desktop app builds
- [ ] 8.3 Deploy to edge via `nixos-rebuild switch`
- [ ] 8.4 Verify zeroclaw service starts (`systemctl status zeroclaw`)
- [ ] 8.5 Verify Telegram channel connects and responds
- [ ] 8.6 Verify Email channel connects (IMAP/SMTP)
- [ ] 8.7 Verify XMPP channel connects and joins MUC rooms
- [ ] 8.8 Verify gateway web UI is accessible on configured port
- [ ] 8.9 Verify OpenAI-compatible endpoint responds (HA integration)
- [ ] 8.10 Verify secrets are not in nix store (`nix-store --query --references` on config path)

## 9. Documentation

- [ ] 9.1 Create `SYNC.md` in the fork documenting the upstream sync workflow (fetch, merge tag to main, update hashes, build, test, push)
- [ ] 9.2 Add a README.md to the fork explaining what it is, how to use the flake/module, and the branch structure
- [ ] 9.3 Update sid repo's openspec specs to reflect the new architecture (archive this change)
