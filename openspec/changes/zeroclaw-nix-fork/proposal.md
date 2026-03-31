## Why

ZeroClaw's upstream GitHub account (zeroclaw-labs) has been suspended, leaving Sid's build broken — `nix flake update` returns HTTP 404. Our flake.nix depends on fetching source from GitHub, and we maintain 12 patch files + 2 injected source files that must be rebased on every upstream release. Even before the suspension, this patch workflow was the most fragile part of the build. Forking ZeroClaw into a Nix-focused repository gives us build sovereignty, eliminates the patch workflow, and creates a proper reusable NixOS module — while preserving the ability to sync with upstream if/when it returns.

## What Changes

- **Fork ZeroClaw** to `kcalvelli/zeroclaw` from the local clone at `~/Projects/zeroclaw`, preserving full git history (4,141 commits, all tags through v0.6.5)
- **Merge Sid's 12 patches and 2 source files** as proper commits on a `sid` branch off the `v0.6.5` tag, eliminating all `.patch` files from the sid repo
- **Add a Nix flake** to the fork exporting `packages.{zeroclaw, zeroclaw-web, zeroclaw-desktop}` and `nixosModules.default`
- **Create a generic NixOS module** with typed options: freeform `settings` attrset rendered to TOML, per-channel submodules with `*File` secret options (no more sed placeholder injection), systemd hardening, and `environmentFiles` for sops-nix/agenix compatibility
- **BREAKING**: Sid's `flake.nix` changes from building ZeroClaw itself to consuming the fork's package and module outputs. The `modules/nixos/default.nix` is replaced by a thin NixOS config that sets options on the fork's module.
- **BREAKING**: `patches/` directory and all `.patch` files removed from the sid repo
- **Establish upstream sync strategy**: document a rebasing workflow for pulling upstream changes onto the `sid` branch, with clear conventions for conflict resolution and feature flagging

## Capabilities

### New Capabilities
- `nix-module`: Generic, reusable NixOS module for ZeroClaw with typed options, freeform settings, declarative channel configuration, and secret file injection — replacing Sid's bespoke config templating
- `upstream-sync`: Branch strategy and documented workflow for maintaining a fork that can cleanly rebase onto upstream releases when zeroclaw-labs returns

### Modified Capabilities
- `patch-management`: Patches become commits on the fork's `sid` branch; the patch generation/application workflow is replaced by git branch management
- `xmpp-channel`: Source file (`xmpp.rs`) moves from sid's `patches/` directory into the fork's source tree as a proper commit
- `openai-proxy`: Source file (`openai_proxy.rs`) moves from sid's `patches/` directory into the fork's source tree as a proper commit

## Impact

- **sid repo**: `flake.nix` simplified (no more `buildRustPackage`/`buildNpmPackage`, no patches, no `postPatch`). `modules/nixos/default.nix` replaced. `patches/` directory removed. ~600 lines of Nix deleted.
- **New repo**: `kcalvelli/zeroclaw` created on GitHub with flake, NixOS module, and `sid` branch carrying custom features
- **Build**: Cargo/npm hashes move to the fork — sid repo no longer needs to track them
- **Deployment**: NixOS config switches from `services.sid` to `services.zeroclaw` with Sid-specific option values
- **Upstream risk**: If zeroclaw-labs returns, we can `git remote add upstream` and rebase. If they don't, we own the full source. The fork's `master` branch tracks upstream exactly; `sid` branch carries our customizations.
- **Secrets**: Migration from sed-injected placeholders to systemd `EnvironmentFile` / `LoadCredential` — more secure, no plaintext secrets in activation scripts
