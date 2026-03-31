## Context

Sid currently builds ZeroClaw from source via a Nix flake that fetches from `github:zeroclaw-labs/zeroclaw/v0.6.5`. The build applies 10 patch files to the server package, 2 patch files to the desktop package, and copies 2 full source files (`xmpp.rs`, `openai_proxy.rs`) via `postPatch`. The NixOS module in `modules/nixos/default.nix` (756 lines) generates a TOML config via string interpolation and injects secrets with sed replacements during activation.

Upstream is currently unreachable (GitHub account suspended). The local clone at `~/Projects/zeroclaw` has the full history (4,141 commits) through `master` which is 7 commits ahead of `v0.6.5`. The fork will be published as `kcalvelli/zeroclaw-nix`.

## Goals / Non-Goals

**Goals:**
- Build sovereignty: Sid can build and deploy without any dependency on zeroclaw-labs GitHub
- Eliminate patch workflow: 12 `.patch` files + 2 source files become git commits
- Proper NixOS module: typed options, freeform settings, no string templating or sed injection
- Upstream sync path: clean strategy for rebasing when/if zeroclaw-labs returns
- Repo name `zeroclaw-nix` signals this is a Nix-focused packaging fork, not a competing project

**Non-Goals:**
- Diverging from ZeroClaw's Rust source beyond our existing customizations
- Supporting non-NixOS deployment methods (Docker, bare install) in the fork's flake
- Rewriting or refactoring ZeroClaw internals
- Publishing to FlakeHub or nixpkgs — this is a personal fork

## Decisions

### 1. Branch strategy: `upstream` + `sid` branches, not rebase-onto-tag

**Decision**: Maintain two branches:
- `upstream/master` — exact mirror of zeroclaw-labs/zeroclaw master (read-only tracking branch)
- `main` — our integration branch: release tag + nix packaging + all feature patches (XMPP, OpenAI proxy, email fixes, etc.)

`main` is the default branch and the one downstream consumers point at (`github:kcalvelli/zeroclaw-nix`). It contains everything needed to build and deploy.

**Upstream sync workflow**: When upstream releases v0.6.6, fetch and update `upstream/master`, then merge the new tag into `main`. Nix files never conflict (upstream doesn't have them). Feature patches may conflict on the files they touch — resolve inline during the merge.

**Why two branches, not three?** The feature patches (XMPP, OpenAI proxy, etc.) are general-purpose ZeroClaw enhancements, not Sid-specific. There's no reason to separate them from the nix packaging. Fewer branches = simpler sync, and `git log upstream/master..main` still cleanly shows all fork-specific commits.

### 2. Nix packaging lives on `main`, not in a `nix/` overlay

**Decision**: Add `flake.nix`, `nix/package.nix`, `nix/web.nix`, `nix/desktop.nix`, and `nix/module.nix` directly to `main`.

**Rationale**: These files don't exist upstream, so they never conflict during merges. Keeping them in-tree (vs a separate overlay repo) means `nix build github:kcalvelli/zeroclaw-nix` just works — no multi-repo coordination.

### 3. NixOS module design: freeform settings + typed channel submodules

**Decision**: Two-tier option structure:
- `services.zeroclaw.settings` — freeform attrset rendered to TOML via `lib.generators.toFormat "toml"`. Any ZeroClaw config key works without module changes.
- `services.zeroclaw.channels.<name>` — typed submodules for channels that need secret file injection (telegram, email, xmpp). These generate their `[channels_config.*]` TOML sections and handle `*File` options.

**Why freeform for settings?** ZeroClaw's config surface is large and changes often. A fully typed module would need updates for every upstream config addition. Freeform means new config keys work immediately — just add them to your NixOS config.

**Why typed for channels?** Channels need secret injection (`botTokenFile`, `passwordFile`). This can't be freeform because we need to read the file and merge the value into the TOML at service start time. A `preStart` script reads `*File` options and patches the generated TOML — a targeted 10-line script, not the current 80-line sed gauntlet.

**Alternative considered**: Fully freeform with `environmentFiles` only. Rejected because ZeroClaw reads secrets from config.toml, not environment variables — we need the TOML patching step.

### 4. Secret injection: preStart file reads, not activation-time sed

**Decision**: The module generates a base `config.toml` in the nix store (read-only, no secrets). A `preStart` script copies it to the state directory and patches in secrets from `*File` options using a small TOML-aware script (or targeted sed on known keys).

**Why this is better**:
- Secrets never appear in the nix store
- No activation script running as root touching service files
- Secrets are injected at service start, not system activation — they're fresher after secret rotation
- `systemd-creds` / `LoadCredential` is an option for future hardening

### 5. Sid repo becomes a thin consumer

**Decision**: After migration, sid's `flake.nix`:
- Imports `zeroclaw-nix` as an input (`github:kcalvelli/zeroclaw-nix` — points to `main`, the default branch)
- Uses the fork's package and NixOS module
- Sets Sid-specific option values (persona, channels, cost limits, agents)
- Manages secrets via agenix (unchanged)
- Keeps `web/pwa/` for the PWA overlay (passed as a module option)

**What's removed from sid**: `patches/`, `modules/nixos/default.nix`, all `buildRustPackage`/`buildNpmPackage` logic, cargo/npm hashes.

### 6. Initial fork point: v0.6.5 tag, not master

**Decision**: Branch `main` from the `v0.6.5` tag, not from upstream master (which is 7 commits ahead). Nix packaging commits go on first, then feature patches on top.

**Rationale**: v0.6.5 is what we've been running and tested. The 7 commits on master are post-release (Rust edition upgrade, CI fixes) — we can merge them later. Starting from a known-good release tag reduces risk.

## Risks / Trade-offs

**[Upstream returns with breaking changes]** → The `upstream/master` tracking branch lets us inspect changes before merging. If upstream rewrites the config schema or channel API, our `sid` branch patches will conflict — but this is the same risk we already had with patch files, and now we have proper git tooling (diff, merge, cherry-pick) instead of manual hunk editing.

**[Upstream never returns]** → We own the full source and can maintain it indefinitely. The Rust codebase is well-structured. Our patches touch <1% of the source. Dependency updates (cargo, crates.io) are the main ongoing cost.

**[Fork drift makes sync painful]** → Mitigated by keeping customizations minimal, well-documented, and using merge (not rebase) for upstream updates so history stays clear. `git log upstream/master..main` always shows exactly what's fork-specific. If a patch gets upstreamed, we drop the commit during the next merge.

**[NixOS module maintenance burden]** → The freeform settings approach means the module only needs updates when the secret injection or channel configuration patterns change, not for every new config key. This is the same pattern used by Garage, Attic, and other Nix-native services.

**[Two repos to manage]** → Acceptable trade-off. The fork changes rarely (only on upstream releases or when adding new patches). Day-to-day Sid work stays in the sid repo. The alternative (monorepo) makes upstream sync impossible.

## Migration Plan

1. **Create the fork repo** (`kcalvelli/zeroclaw-nix`) from local clone
2. **Set up branches**: `main` from v0.6.5 tag, add nix packaging commits, create `sid` branch, apply patches as commits
3. **Build and test the fork's flake** independently (`nix build github:kcalvelli/zeroclaw-nix/sid`)
4. **Update sid's flake.nix** to consume the fork
5. **Replace sid's NixOS module** with option values for the fork's module
6. **Remove patches/** and old module from sid
7. **Deploy and verify** all channels, gateway, desktop app
8. **Rollback**: If anything breaks, revert sid's flake.nix to the previous commit — the old build (still in nix store) works immediately

## Open Questions

- **PWA overlay**: Should the fork's module accept a `pwaOverlay` option, or should sid continue to handle PWA injection in its own flake? Leaning toward a module option for cleanliness.
- **Desktop package**: The desktop build has its own 2 patches (gateway URL, CSP). Should these also be `sid` branch commits, or are they generic enough for `main`? The gateway URL env var patch seems generally useful.
- **Upstream license**: The flake.nix declares Apache 2.0. Should verify this matches what was in the repo before the suspension. The local clone should have a LICENSE file.
