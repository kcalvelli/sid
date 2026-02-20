## ADDED Requirements

### Requirement: ZeroClaw systemd service runs as sid user
The system SHALL run a `zeroclaw.service` systemd unit as the `sid` system user. The service SHALL start after `network-online.target`. The service type SHALL be `simple` with automatic restart on failure.

#### Scenario: Service starts successfully
- **WHEN** `systemctl start zeroclaw` is executed
- **THEN** ZeroClaw starts as the `sid` user with `WorkingDirectory=/var/lib/sid` and the process is running

#### Scenario: Service restarts on failure
- **WHEN** the ZeroClaw process exits with a non-zero code
- **THEN** systemd restarts the service after a 10-second delay (RestartSec=10)

### Requirement: Dedicated sid system user with isolation
The system SHALL create a `sid` system user with group `sid`, home directory `/var/lib/sid`, shell `/sbin/nologin`, and `isSystemUser = true`. The home directory SHALL be created automatically.

#### Scenario: User exists with correct properties
- **WHEN** the NixOS configuration is activated
- **THEN** user `sid` exists with home `/var/lib/sid`, group `sid`, shell `/sbin/nologin`, and `createHome = true`

### Requirement: ZeroClaw config.toml deployed via NixOS
The system SHALL deploy a `config.toml` file at `/var/lib/sid/.zeroclaw/config.toml` owned by `sid:sid` with mode `0400`. The config SHALL include the following sections: `[memory]` (sqlite backend, auto_save), `[heartbeat]` (enabled, 30 min interval), `[gateway]` (127.0.0.1:18789, require_pairing, no public bind), `[autonomy]` (supervised level, workspace_only, allowed_commands list, forbidden_paths list), `[channels_config.telegram]` (enabled), `[secrets]` (encrypt), `[identity]` (openclaw format). The config SHALL NOT include an `api_key` field — authentication is handled by ZeroClaw's subscription auth profile system.

#### Scenario: Config file deployed with correct permissions
- **WHEN** the NixOS activation script runs
- **THEN** `/var/lib/sid/.zeroclaw/config.toml` exists with owner `sid:sid` and mode `0400`

#### Scenario: Config contains required sections
- **WHEN** the config file is read
- **THEN** it contains `default_provider = "anthropic"`, `default_model = "claude-opus-4-5"`, `[memory]`, `[heartbeat]`, `[gateway]`, `[autonomy]`, `[channels_config.telegram]`, `[secrets]`, and `[identity]` sections with the specified values

#### Scenario: Telegram token injected from agenix
- **WHEN** the NixOS activation script runs and agenix has decrypted the telegram-bot-token secret
- **THEN** the Telegram bot token is injected into the config.toml `[channels_config.telegram]` section

### Requirement: Subscription auth profile directory
The system SHALL create `/var/lib/sid/.zeroclaw/` owned by `sid:sid` with mode `0700`. ZeroClaw stores auth profiles at `~/.zeroclaw/auth-profiles.json` encrypted at rest.

#### Scenario: Auth directory exists with correct permissions
- **WHEN** the NixOS activation script runs
- **THEN** `/var/lib/sid/.zeroclaw/` exists with owner `sid:sid` and mode `0700`

### Requirement: Systemd service hardening
The ZeroClaw service SHALL apply systemd hardening directives: `ProtectSystem=strict`, `ProtectHome=tmpfs`, `NoNewPrivileges=true`, `PrivateTmp=true`. The service SHALL have `ReadWritePaths` set to `/var/lib/sid`.

#### Scenario: Service runs with hardening enabled
- **WHEN** `systemd-analyze security zeroclaw` is run
- **THEN** the service has ProtectSystem=strict, NoNewPrivileges=yes, and PrivateTmp=yes active

### Requirement: Agenix secrets for Telegram and email
The system SHALL declare agenix secrets for `telegram-bot-token.age` (owner: sid) and `genxbot-email-password.age` (owner: sid). The secret files SHALL be sourced from `../../secrets/` relative to the module.

#### Scenario: Secrets decrypted and owned by sid
- **WHEN** the system boots and agenix activates
- **THEN** the decrypted telegram bot token and email password are accessible to the sid user with mode 0400

### Requirement: Heartbeat replaces watchdog and inbox-check timers
ZeroClaw's `[heartbeat]` configuration with `interval_minutes = 30` SHALL replace the separate `genxbot-watchdog` and `genxbot-inbox-check` systemd timers. The agent's behavior during heartbeat is defined by HEARTBEAT.md in the workspace.

#### Scenario: No separate watchdog or inbox-check timers exist
- **WHEN** the NixOS configuration is activated
- **THEN** no `genxbot-watchdog.timer` or `genxbot-inbox-check.timer` systemd units exist — heartbeat scheduling is handled by ZeroClaw internally

### Requirement: Flake input uses ZeroClaw
The `flake.nix` SHALL declare `zeroclaw` as an input with URL `github:zeroclaw-labs/zeroclaw`. The flake SHALL NOT include `nix-openclaw` or `claude-api-proxy` inputs.

#### Scenario: Flake builds with zeroclaw input
- **WHEN** `nix flake check` is run
- **THEN** the flake resolves the `zeroclaw` input from `github:zeroclaw-labs/zeroclaw` and the NixOS module references the zeroclaw package
