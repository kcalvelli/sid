## Context

ZeroClaw upstream includes a Tauri v2 desktop app at `apps/tauri/` — a Rust system tray application that wraps the web UI via WebKitGTK WebView. It connects to the gateway at `http://127.0.0.1:42617/_app/`, auto-pairs for authentication, and provides tray icons for health status.

Currently, the Sid flake packages only the server binary (`zeroclaw`) and web frontend (`zeroclaw-web`). The desktop app has no Nix derivation. Keith wants it installed on two NixOS desktops: mini (where Sid runs locally) and edge (which accesses mini's gateway over Tailscale).

A separate PWA effort is in progress — both approaches will coexist (PWA for mobile/browser, Tauri for native desktop tray).

## Goals / Non-Goals

**Goals:**
- Package `zeroclaw-desktop` as a Nix derivation in the Sid flake
- Support runtime gateway URL configuration via environment variable
- Proper WebKitGTK/GTK runtime wrapping for NixOS
- Installable on both mini (local gateway) and edge (remote gateway via Tailscale)
- XDG autostart so the tray app launches on login

**Non-Goals:**
- Bundling the web frontend into the Tauri app (it loads from the gateway)
- macOS or Windows support (both targets are x86_64-linux)
- NixOS module with options — simple package in `environment.systemPackages` is sufficient
- Mobile Tauri builds (the `gen/android` and `gen/apple` dirs exist upstream but are out of scope)

## Decisions

### 1. Runtime gateway URL via environment variable

**Decision:** Patch the Tauri app to read `ZEROCLAW_GATEWAY_URL` at startup, defaulting to `http://127.0.0.1:42617`. Override both the WebView URL and the `GatewayClient` base URL.

**Alternatives:**
- Build-time patching (two derivations with different URLs) — rejected because it doubles the cargoHash maintenance and the Rust deps are identical
- Config file — rejected because an env var is simpler and aligns with NixOS patterns (wrap with `makeWrapper`)

### 2. Single package with per-host wrapping

**Decision:** Build one `zeroclaw-desktop` package. Each host sets the gateway URL via environment in the `.desktop` autostart file or a wrapper script.

**Rationale:** The binary is identical across hosts. Only the gateway endpoint differs. Per-host config belongs in NixOS host configs, not in the package.

### 3. CSP adjustment for Tailscale access

**Decision:** Patch `tauri.conf.json` CSP to also allow the Tailscale domain pattern. The CSP currently only allows `127.0.0.1:*`. For edge, it needs to allow `mini.taile0fb4.ts.net:*`.

**Approach:** Rather than hardcoding the Tailscale domain, broaden the CSP to allow `https://*` and `wss://*` connections (the app is a local desktop client, not a public website — strict CSP is less critical).

### 4. WebKitGTK runtime wrapping

**Decision:** Use `wrapGAppsHook3` which handles `GIO_EXTRA_MODULES`, `GDK_PIXBUF_MODULE_FILE`, `GSETTINGS_SCHEMA_DIR`, and `XDG_DATA_DIRS` automatically. This is the standard pattern for GTK apps in nixpkgs.

### 5. Build from workspace root with `--package`

**Decision:** Use the zeroclaw source root as `src` (same as the server build) but build only the `zeroclaw-desktop` package via `buildAndTestSubdir` or `cargoBuildFlags = ["-p" "zeroclaw-desktop"]`. This shares the `Cargo.lock` at the workspace root.

**Rationale:** The Tauri app is a workspace member. Building from `apps/tauri/` alone would miss the workspace-level `Cargo.lock` and potentially workspace dependencies.

## Risks / Trade-offs

- **WebKitGTK runtime issues** → Mitigated by `wrapGAppsHook3`, which is battle-tested for GTK apps in nixpkgs. May need iteration on the exact dependency set.
- **cargoHash churn** → The desktop app pulls in tauri, webkit2gtk-sys, etc. which differ from the server's deps. The `cargoHash` will be independent and change on ZeroClaw version bumps. Acceptable maintenance cost.
- **Tauri build.rs codegen** → `tauri_build::build()` needs `tauri.conf.json` and `capabilities/` present at build time. These are in the source tree so should work, but may need `postPatch` adjustments if paths are wrong relative to the build dir.
- **Gateway unreachable at startup** → The app already handles this gracefully (health poller retries). On edge, if mini is down, the tray shows disconnected. No additional handling needed.
