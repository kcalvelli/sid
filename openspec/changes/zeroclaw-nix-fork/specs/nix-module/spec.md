## ADDED Requirements

### Requirement: Freeform settings rendered to TOML
The NixOS module SHALL accept a `services.zeroclaw.settings` option of type freeform attrset. The module SHALL render this attrset to a `config.toml` file using Nix's TOML generator. Any valid ZeroClaw config key SHALL be expressible in this attrset without module changes.

#### Scenario: Simple settings
- **WHEN** `services.zeroclaw.settings = { default_provider = "claude-code"; default_model = "claude-opus-4-6"; cost.daily_limit_usd = 5.0; }`
- **THEN** the generated `config.toml` SHALL contain those keys with correct TOML types and nesting

#### Scenario: Unknown upstream config key
- **WHEN** a new ZeroClaw version adds `[experimental.foo]` and the user sets `services.zeroclaw.settings.experimental.foo = "bar"`
- **THEN** the module SHALL render it to TOML without error, requiring no module code changes

### Requirement: Typed channel submodules with secret file injection
The NixOS module SHALL provide typed submodule options under `services.zeroclaw.channels` for channels that require secrets. Each channel submodule SHALL accept `*File` options (e.g., `botTokenFile`, `passwordFile`) that reference paths to files containing secret values. Supported channels: `telegram`, `email`, `xmpp`.

#### Scenario: Telegram channel with secret file
- **WHEN** `services.zeroclaw.channels.telegram = { enable = true; botTokenFile = "/run/agenix/telegram-token"; allowFrom = [ 12345 ]; }`
- **THEN** the module SHALL generate a `[channels_config.telegram]` TOML section and the `preStart` script SHALL read the token from the file and inject it into the config

#### Scenario: Email channel with secret file
- **WHEN** `services.zeroclaw.channels.email = { enable = true; passwordFile = "/run/agenix/email-password"; imapHost = "london.mxroute.com"; username = "genxbot@calvelli.us"; }`
- **THEN** the module SHALL generate a `[channels_config.email]` TOML section with the password injected from the file at service start

#### Scenario: Channel disabled by default
- **WHEN** `services.zeroclaw.channels.telegram.enable` is not set
- **THEN** no `[channels_config.telegram]` section SHALL appear in the generated config

### Requirement: Secret injection via preStart
The module SHALL generate a base `config.toml` in the nix store containing no secrets. A `preStart` script SHALL copy this file to the service state directory and inject secrets from `*File` options before the main process starts. Secrets SHALL NOT appear in the nix store, activation scripts, or environment variables.

#### Scenario: Base config contains no secrets
- **WHEN** inspecting the nix store path of the generated config
- **THEN** it SHALL contain no secret values — only placeholder markers or absent secret fields

#### Scenario: preStart injects secrets
- **WHEN** the zeroclaw systemd service starts
- **THEN** the `preStart` script SHALL read each configured `*File` path and inject the contents into the config copy in the state directory

#### Scenario: Secret file missing
- **WHEN** a configured `*File` path does not exist at service start
- **THEN** the `preStart` script SHALL fail with a clear error message naming the missing file, and the service SHALL NOT start

### Requirement: Environment files support
The module SHALL accept a `services.zeroclaw.environmentFiles` option (list of paths) that are passed to systemd's `EnvironmentFile` directive. This provides sops-nix and agenix compatibility for secrets that ZeroClaw reads from environment variables.

#### Scenario: Environment file with API keys
- **WHEN** `services.zeroclaw.environmentFiles = [ "/run/agenix/zeroclaw-env" ]`
- **THEN** the systemd unit SHALL include `EnvironmentFile=/run/agenix/zeroclaw-env`

### Requirement: Systemd hardening
The module SHALL apply systemd security hardening equivalent to the current Sid module: `ProtectHome`, `ProtectSystem=strict`, `PrivateTmp`, `NoNewPrivileges`, `CapabilityBoundingSet=""`, restricted address families, and `SystemCallFilter=@system-service`. The state directory SHALL be the only writable path.

#### Scenario: Hardened service unit
- **WHEN** inspecting the generated systemd unit
- **THEN** all hardening directives from the current sid module SHALL be present

### Requirement: Configurable service identity
The module SHALL accept `services.zeroclaw.user` and `services.zeroclaw.group` options (defaulting to "zeroclaw") for the system user and group. The module SHALL create the user and group, set up the state directory, and configure file ownership.

#### Scenario: Custom user name
- **WHEN** `services.zeroclaw.user = "sid"` and `services.zeroclaw.group = "sid"`
- **THEN** the service SHALL run as user "sid", the state directory SHALL be owned by "sid:sid"

#### Scenario: Default user
- **WHEN** user/group options are not set
- **THEN** the service SHALL create and run as user "zeroclaw" with group "zeroclaw"

### Requirement: Firewall and port options
The module SHALL accept `services.zeroclaw.port` (default 18789) and `services.zeroclaw.openFirewall` (default false) options. When `openFirewall` is true, the module SHALL open the configured port in the NixOS firewall.

#### Scenario: Firewall opened
- **WHEN** `services.zeroclaw.openFirewall = true` and `services.zeroclaw.port = 18789`
- **THEN** TCP port 18789 SHALL be added to `networking.firewall.allowedTCPPorts`

### Requirement: Extra packages in service PATH
The module SHALL accept `services.zeroclaw.extraPackages` (list of packages) added to the service's `PATH`. The module SHALL always include baseline packages (bash, coreutils, git, gnugrep, gnused, jq, curl).

#### Scenario: Claude Code in PATH
- **WHEN** `services.zeroclaw.extraPackages = [ pkgs.claude-code pkgs.msmtp ]`
- **THEN** the service's PATH SHALL include claude-code, msmtp, and all baseline packages

### Requirement: PWA overlay option
The module SHALL accept an optional `services.zeroclaw.pwaOverlay` path option. When set, the web build SHALL inject the PWA manifest, service worker, icons, and registration module from this path, replacing the upstream web assets.

#### Scenario: PWA overlay provided
- **WHEN** `services.zeroclaw.pwaOverlay = ./web/pwa`
- **THEN** the web package build SHALL copy manifest.json, service-worker.js, icons, and sw-register.ts from the overlay path into the web source before building

#### Scenario: No PWA overlay
- **WHEN** `services.zeroclaw.pwaOverlay` is not set
- **THEN** the web package SHALL build with upstream assets unmodified

### Requirement: Flake exports packages and module
The fork's `flake.nix` SHALL export `packages.${system}.zeroclaw`, `packages.${system}.zeroclaw-web`, `packages.${system}.zeroclaw-desktop`, and `nixosModules.default` for `x86_64-linux` and `aarch64-linux`.

#### Scenario: Build server package
- **WHEN** running `nix build github:kcalvelli/zeroclaw-nix/sid`
- **THEN** the output SHALL be the zeroclaw binary with all `sid` branch patches applied

#### Scenario: Import NixOS module
- **WHEN** a NixOS config includes `imports = [ zeroclaw-nix.nixosModules.default ]`
- **THEN** `services.zeroclaw` options SHALL be available
