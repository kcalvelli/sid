## 1. Patches

- [x] 1.1 Create patch for `apps/tauri/src/lib.rs` to read `ZEROCLAW_GATEWAY_URL` env var and override the WebView URL and GatewayClient base URL at startup
- [x] 1.2 Create patch for `apps/tauri/tauri.conf.json` to broaden CSP allowing connections to any host (not just 127.0.0.1)

## 2. Nix Package

- [x] 2.1 Add `zeroclaw-desktop` derivation to `flake.nix` using `buildRustPackage` with `-p zeroclaw-desktop` cargo flags
- [x] 2.2 Add WebKitGTK, GTK3, libsoup_3, glib-networking, librsvg as buildInputs and `wrapGAppsHook3` as nativeBuildInput
- [x] 2.3 Add `postPatch` step to apply the gateway URL and CSP patches
- [x] 2.4 Add XDG autostart `.desktop` file in `postInstall`
- [x] 2.5 Compute and set `cargoHash` for the desktop app's dependency tree

## 3. Verification

- [x] 3.1 Run `nix build .#zeroclaw-desktop` and verify the binary is produced
- [x] 3.2 Verify the binary launches and shows the system tray icon
- [x] 3.3 Verify `ZEROCLAW_GATEWAY_URL` env var overrides the gateway connection
