## ADDED Requirements

### Requirement: Nix derivation builds zeroclaw-desktop from upstream source
The Sid flake SHALL include a `zeroclaw-desktop` package that builds the Tauri desktop app from the ZeroClaw upstream source using `rustPlatform.buildRustPackage`. The build SHALL target only the `zeroclaw-desktop` crate from the workspace using `-p zeroclaw-desktop` cargo flags.

#### Scenario: Package builds successfully
- **WHEN** `nix build .#zeroclaw-desktop` is run
- **THEN** a `zeroclaw-desktop` binary is produced in `$out/bin/`

#### Scenario: Build uses workspace Cargo.lock
- **WHEN** the derivation builds
- **THEN** it uses the `Cargo.lock` from the zeroclaw workspace root, not a crate-local lock file

### Requirement: WebKitGTK and GTK dependencies are included
The derivation SHALL include all native dependencies required by Tauri v2 on Linux: `webkitgtk_4_1`, `gtk3`, `libsoup_3`, `glib-networking`, `librsvg`, and `pkg-config` as a native build input. The package SHALL use `wrapGAppsHook3` to set up GTK runtime environment variables.

#### Scenario: Binary runs without missing library errors
- **WHEN** the built `zeroclaw-desktop` binary is executed on a NixOS desktop
- **THEN** it launches without `libwebkit2gtk`, `libgtk`, or `libsoup` shared library errors

#### Scenario: GLib networking modules are available
- **WHEN** the app makes HTTPS requests to the gateway
- **THEN** TLS works because `glib-networking` GIO modules are available via `wrapGAppsHook3`

### Requirement: Runtime gateway URL configuration
The Tauri app SHALL read the `ZEROCLAW_GATEWAY_URL` environment variable at startup. If set, it SHALL use this URL as both the WebView source and the `GatewayClient` base URL. If not set, it SHALL default to `http://127.0.0.1:42617`.

#### Scenario: Default local gateway
- **WHEN** `ZEROCLAW_GATEWAY_URL` is not set
- **THEN** the app connects to `http://127.0.0.1:42617/_app/` for the WebView and uses `http://127.0.0.1:42617` for API calls

#### Scenario: Remote gateway via environment
- **WHEN** `ZEROCLAW_GATEWAY_URL=http://mini.taile0fb4.ts.net:42617` is set
- **THEN** the app loads `http://mini.taile0fb4.ts.net:42617/_app/` in the WebView and uses `http://mini.taile0fb4.ts.net:42617` for API calls

### Requirement: CSP allows remote gateway connections
The Tauri app CSP SHALL allow connections to hosts beyond `127.0.0.1` so that the app works when pointed at a remote gateway over Tailscale.

#### Scenario: WebView loads remote gateway
- **WHEN** the gateway URL points to a Tailscale hostname
- **THEN** the WebView is not blocked by CSP from loading scripts, styles, or making API requests to that host

### Requirement: Patch creates runtime URL override in Tauri source
A patch file SHALL be created that modifies the Tauri app's `lib.rs` (or equivalent) to read `ZEROCLAW_GATEWAY_URL` from the environment and override the hardcoded gateway URL. The patch SHALL also update `tauri.conf.json` CSP to allow broader origins.

#### Scenario: Patch applies cleanly to v0.6.3 source
- **WHEN** the patch is applied during `postPatch`
- **THEN** it applies without conflicts against the ZeroClaw v0.6.3 tag
