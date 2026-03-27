## ADDED Requirements

### Requirement: Desktop app installable via environment.systemPackages
The `zeroclaw-desktop` package SHALL be installable on NixOS hosts by adding it to `environment.systemPackages` in the host configuration. No NixOS module is required — it is a standalone desktop application.

#### Scenario: Install on mini (local gateway)
- **WHEN** `inputs.sid.packages.x86_64-linux.zeroclaw-desktop` is added to mini's `environment.systemPackages`
- **THEN** the `zeroclaw-desktop` binary is available in the system PATH after rebuild

#### Scenario: Install on edge (remote gateway)
- **WHEN** `inputs.sid.packages.x86_64-linux.zeroclaw-desktop` is added to edge's `environment.systemPackages`
- **THEN** the `zeroclaw-desktop` binary is available in the system PATH after rebuild

### Requirement: XDG autostart entry for login
The package SHALL include an XDG autostart `.desktop` file at `$out/etc/xdg/autostart/zeroclaw-desktop.desktop` so the tray app launches automatically on desktop login.

#### Scenario: App autostarts on login
- **WHEN** a user logs into a desktop session on a host with `zeroclaw-desktop` installed
- **THEN** the ZeroClaw tray app starts automatically in the system tray

### Requirement: Per-host gateway URL via desktop file or wrapper
For hosts accessing a remote gateway, the gateway URL SHALL be configurable. The recommended approach is wrapping the package with `makeWrapper` adding `--set ZEROCLAW_GATEWAY_URL` in the host's NixOS config, or setting the variable in the autostart `.desktop` file.

#### Scenario: Mini uses local gateway (default)
- **WHEN** `zeroclaw-desktop` is installed on mini without additional wrapping
- **THEN** it connects to `http://127.0.0.1:42617` (the default)

#### Scenario: Edge uses remote gateway via override
- **WHEN** `zeroclaw-desktop` is wrapped with `ZEROCLAW_GATEWAY_URL=http://mini.taile0fb4.ts.net:42617` on edge
- **THEN** it connects to mini's gateway over Tailscale
