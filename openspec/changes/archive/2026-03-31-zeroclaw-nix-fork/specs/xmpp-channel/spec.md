## MODIFIED Requirements

### Requirement: XMPP channel configuration
The channel SHALL be configured via `[channels_config.xmpp]` in config.toml with the following fields:
- `jid` (string, required): Full JID for the bot (e.g., `sid@example.com`)
- `password` (string, required): XMPP account password (injected by the NixOS module's preStart script from the configured `passwordFile`, not by activation-time sed replacement)
- `server` (string, optional): Server hostname to connect to (defaults to JID domain)
- `port` (integer, optional): Server port (defaults to 5222)
- `ssl_verify` (boolean, optional): Whether to verify TLS certificates (defaults to true)
- `muc_rooms` (array of strings, optional): MUC room JIDs to auto-join on startup
- `muc_nick` (string, optional): Nick to use in MUC rooms (defaults to capitalized JID local part)

#### Scenario: Minimal configuration
- **WHEN** config contains only `jid` and `password`
- **THEN** the channel SHALL connect to the JID's domain on port 5222 with TLS verification enabled, use capitalized local part as MUC nick, and join no rooms

#### Scenario: Full configuration
- **WHEN** config contains jid, password, server, port, ssl_verify=false, muc_rooms=["lounge@conference.example.com"], muc_nick="Sid"
- **THEN** the channel SHALL connect to the specified server:port, skip TLS verification, join the listed rooms as "Sid"

#### Scenario: Default muc_nick derivation
- **WHEN** JID is `sid@example.com` and `muc_nick` is not set
- **THEN** the MUC nick SHALL default to "Sid" (local part with first letter capitalized)

### Requirement: NixOS module XMPP options
The NixOS module SHALL provide `services.zeroclaw.channels.xmpp` as a typed submodule. When enabled, the module SHALL:
- Generate `[channels_config.xmpp]` in the base config.toml (without the password)
- Inject the XMPP password from the configured `passwordFile` via the preStart script
- Accept options for `jid`, `server`, `port`, `sslVerify`, `mucRooms`, `mucNick`, and `passwordFile`

#### Scenario: XMPP enabled via new module
- **WHEN** `services.zeroclaw.channels.xmpp = { enable = true; jid = "sid@calvelli.dev"; passwordFile = "/run/agenix/xmpp-password"; server = "edge.tailnet.ts.net"; }`
- **THEN** the base config.toml SHALL contain the XMPP section without the password, and the preStart script SHALL inject the password from the file at service start

#### Scenario: XMPP disabled (default)
- **WHEN** `services.zeroclaw.channels.xmpp.enable` is not set or false
- **THEN** no `[channels_config.xmpp]` section SHALL appear in config.toml

### Requirement: XMPP channel feature-gated in Cargo build
The XMPP channel SHALL be gated behind a `channel-xmpp` Cargo feature flag. The feature SHALL be enabled in the fork's `nix/package.nix` build features. When the feature is not enabled, no XMPP-related code SHALL be compiled.

#### Scenario: Build with XMPP feature enabled
- **WHEN** the fork's nix package builds with `channel-xmpp` feature
- **THEN** the XMPP channel code SHALL compile and the channel SHALL be available for configuration

#### Scenario: Build without XMPP feature
- **WHEN** `channel-xmpp` is not in build features
- **THEN** XMPP channel code SHALL not be compiled and `[channels_config.xmpp]` SHALL be ignored

### Requirement: XMPP source lives in fork source tree
The XMPP channel implementation (`xmpp.rs`) SHALL exist as a committed file at `src/channels/xmpp.rs` in the fork's `main` branch. It SHALL NOT be copied from an external location during build. The module declaration and config schema wiring SHALL also be commits on the `sid` branch.

#### Scenario: Source file location
- **WHEN** checking out the `sid` branch of the fork
- **THEN** `src/channels/xmpp.rs` SHALL exist as a tracked file in the repository
