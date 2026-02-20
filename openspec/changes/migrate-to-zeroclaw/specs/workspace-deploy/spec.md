## ADDED Requirements

### Requirement: Immutable workspace identity files as Nix store symlinks
The system SHALL deploy IDENTITY.md, SOUL.md, USER.md, AGENTS.md, HEARTBEAT.md, and TOOLS.md as symlinks from `/var/lib/sid/workspace/` pointing to Nix store paths. These files SHALL be read-only and immutable — the agent MUST NOT be able to modify its own personality files.

#### Scenario: Identity files are read-only symlinks
- **WHEN** the NixOS activation script runs
- **THEN** `/var/lib/sid/workspace/IDENTITY.md`, `SOUL.md`, `USER.md`, `AGENTS.md`, `HEARTBEAT.md`, and `TOOLS.md` are symlinks to paths under `/nix/store/`

#### Scenario: Agent cannot modify identity files
- **WHEN** the sid user attempts to write to any identity file
- **THEN** the write fails with a permission error (files are in the read-only Nix store)

### Requirement: Verbatim copy of identity files from GenX64
IDENTITY.md, SOUL.md, USER.md, AGENTS.md, and HEARTBEAT.md SHALL be copied verbatim from the GenX64 repository with zero modifications to content, formatting, or structure. AGENTS.md MAY have openclaw-specific tool call syntax updated to zeroclaw equivalents if any exist.

#### Scenario: Identity files match GenX64 originals
- **WHEN** the workspace files are compared to their GenX64 counterparts
- **THEN** IDENTITY.md, SOUL.md, USER.md, and HEARTBEAT.md are byte-identical to GenX64 originals

### Requirement: TOOLS.md documents ZeroClaw tools
The system SHALL include a new TOOLS.md file in the workspace that documents the tools and capabilities available to Sid through ZeroClaw, replacing the GenX64 TOOLS.md which referenced the old email API and shell execution model.

#### Scenario: TOOLS.md exists and documents ZeroClaw capabilities
- **WHEN** `/var/lib/sid/workspace/TOOLS.md` is read
- **THEN** it documents ZeroClaw's available tools including email, shell execution boundaries, and what is NOT available

### Requirement: Writable workspace directory for MEMORY.md
The NixOS activation script SHALL create `/var/lib/sid/workspace/` as a directory owned by `sid:sid`. MEMORY.md SHALL NOT be created, stubbed, or referenced by Nix — it is copied in manually at deploy time from the live GenX64 instance.

#### Scenario: Workspace directory is writable by sid
- **WHEN** the NixOS activation script runs
- **THEN** `/var/lib/sid/workspace/` exists and is owned by `sid:sid` with write permissions for the sid user

#### Scenario: MEMORY.md is not managed by Nix
- **WHEN** the NixOS configuration is inspected
- **THEN** no Nix expression creates, stubs, or references MEMORY.md — it exists only if manually placed

### Requirement: Skills directories deployed as symlinks
The system SHALL deploy skills/cynic/, skills/watchdog/, and skills/email/ as symlinks from `/var/lib/sid/skills/` pointing to Nix store paths. skills/browser/ SHALL NOT be deployed.

#### Scenario: Skills symlinks exist for cynic, watchdog, email
- **WHEN** the NixOS activation script runs
- **THEN** `/var/lib/sid/skills/cynic`, `/var/lib/sid/skills/watchdog`, and `/var/lib/sid/skills/email` are symlinks to Nix store paths

#### Scenario: Browser skill is not deployed
- **WHEN** `/var/lib/sid/skills/` is listed
- **THEN** no `browser` directory or symlink exists

### Requirement: Secrets directory with secrets.nix
The repository SHALL include `secrets/secrets.nix` declaring agenix public keys, `secrets/telegram-bot-token.age`, and `secrets/genxbot-email-password.age`. The email secret filename SHALL remain `genxbot-email-password.age` to reuse the existing encrypted file from GenX64.

#### Scenario: Secrets structure matches expected layout
- **WHEN** the secrets/ directory is listed
- **THEN** it contains `secrets.nix`, `telegram-bot-token.age`, and `genxbot-email-password.age`
