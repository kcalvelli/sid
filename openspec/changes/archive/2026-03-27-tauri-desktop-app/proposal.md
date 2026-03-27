## Why

The ZeroClaw upstream ships a Tauri desktop app (`apps/tauri/`) that provides a native system tray experience wrapping the web UI. Keith wants this installed on both mini (where Sid runs) and edge (remote access via Tailscale). Currently the Sid flake only packages the server binary and web frontend — the desktop app has no Nix derivation.

## What Changes

- Add a `zeroclaw-desktop` Nix package to `flake.nix` using `buildRustPackage` with WebKitGTK/Tauri dependencies
- Patch the Tauri app to read `ZEROCLAW_GATEWAY_URL` from environment at runtime, overriding the hardcoded `127.0.0.1:42617` gateway address
- Loosen the CSP in `tauri.conf.json` to allow connections to Tailscale domain hosts (for edge→mini access)
- Wrap the built binary with required runtime environment variables (`GIO_EXTRA_MODULES`, `GDK_PIXBUF_MODULE_FILE`, etc.)
- Add an XDG autostart `.desktop` file so the tray app launches on login

## Capabilities

### New Capabilities
- `tauri-desktop-package`: Nix derivation for building the ZeroClaw Tauri desktop app with WebKitGTK dependencies, runtime gateway URL configuration, and proper GLib/GTK wrapping
- `tauri-desktop-install`: NixOS integration for installing and autostarting the desktop app on target hosts, with per-host gateway URL configuration

### Modified Capabilities

## Impact

- `flake.nix`: New `zeroclaw-desktop` package derivation added alongside existing `zeroclaw` and `zeroclaw-mcp` packages
- Upstream source: Patches needed for runtime gateway URL configuration and CSP adjustment
- NixOS host configs (`~/.config/nixos_config/hosts/{mini,edge}.nix`): Add package to `environment.systemPackages`
- Dependencies: WebKitGTK 4.1, GTK3, libsoup 3, glib-networking, librsvg added as build/runtime inputs
- Both x86_64-linux desktop hosts affected (mini and edge)
