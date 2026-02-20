## 1. Repository Scaffold

- [x] 1.1 Create `flake.nix` with `zeroclaw` (github:zeroclaw-labs/zeroclaw), `nixpkgs` (nixos-unstable), and `agenix` inputs; define `nixosModules.default` importing `./modules/nixos`
- [x] 1.2 Create directory structure: `modules/nixos/`, `secrets/`, `workspace/`, `skills/cynic/`, `skills/watchdog/`, `skills/email/`

## 2. Secrets

- [x] 2.1 Create `secrets/secrets.nix` with edge public key declaring `telegram-bot-token.age` and `genxbot-email-password.age`
- [ ] 2.2 Copy `telegram-bot-token.age` and `genxbot-email-password.age` from GenX64 (placeholder — actual .age files copied at deploy time)

## 3. Workspace Identity Files

- [x] 3.1 Copy `IDENTITY.md` verbatim from GenX64
- [x] 3.2 Copy `SOUL.md` verbatim from GenX64
- [x] 3.3 Copy `USER.md` verbatim from GenX64
- [x] 3.4 Copy `AGENTS.md` verbatim from GenX64 (update any openclaw-specific tool call syntax to zeroclaw equivalents if present)
- [x] 3.5 Copy `HEARTBEAT.md` verbatim from GenX64
- [x] 3.6 Create `TOOLS.md` documenting ZeroClaw's available tools for Sid (email, shell execution, restrictions)

## 4. Skills

- [x] 4.1 Copy `skills/cynic/SKILL.md` verbatim from GenX64
- [x] 4.2 Copy `skills/watchdog/SKILL.md` verbatim from GenX64
- [x] 4.3 Copy `skills/email/SKILL.md` verbatim from GenX64

## 5. NixOS Module — User and Directories

- [x] 5.1 Create `modules/nixos/default.nix` with `sid` system user definition (isSystemUser, group sid, home /var/lib/sid, shell /sbin/nologin, createHome)
- [x] 5.2 Add activation script creating workspace directories: `/var/lib/sid/workspace/`, `/var/lib/sid/skills/`, `/var/lib/sid/.zeroclaw/`, `/var/lib/sid/.local/share/sid/`
- [x] 5.3 Add activation script deploying workspace identity files as Nix store symlinks (IDENTITY.md, SOUL.md, USER.md, AGENTS.md, HEARTBEAT.md, TOOLS.md)
- [x] 5.4 Add activation script deploying skills directories as Nix store symlinks (cynic, watchdog, email)

## 6. NixOS Module — Secrets

- [x] 6.1 Add agenix secret declarations for `telegram-bot-token.age` (owner: sid) and `genxbot-email-password.age` (owner: sid)
- [x] 6.2 Import agenix module in flake.nix nixosModules definition

## 7. NixOS Module — ZeroClaw Config and Service

- [x] 7.1 Add activation script writing `config.toml` to `/var/lib/sid/.zeroclaw/config.toml` (owned by sid, mode 0400) with all required sections (no api_key — subscription auth used)
- [x] 7.2 Add Telegram bot token injection from agenix secret into config.toml via activation script
- [x] 7.3 Create `zeroclaw.service` systemd unit: runs as sid, WorkingDirectory=/var/lib/sid, ExecStart=zeroclaw agent, After=network-online.target, Restart=on-failure, RestartSec=10
- [x] 7.4 Add systemd hardening to zeroclaw.service: ProtectSystem=strict, ProtectHome=tmpfs, NoNewPrivileges, PrivateTmp, ReadWritePaths=/var/lib/sid

## 8. NixOS Module — Log Export Timer

- [x] 8.1 Create `sid-log-export.service` oneshot unit: runs as root, collects last 24h priority 0-4 journal entries (kernel, thermald, smartd, failed units), writes to `/var/lib/sid/.local/share/sid/watchdog.log`, chowns to sid:sid
- [x] 8.2 Create `sid-log-export.timer`: OnBootSec=5min, OnUnitActiveSec=15min, enabled by default
