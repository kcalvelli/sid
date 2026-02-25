# Implementation Tasks

- [x] Add email channel config to NixOS module (`modules/nixos/default.nix`): add `emailPasswordFile` variable, `emailConfig` string with all EmailConfig fields, insert into `configToml` after `telegramConfig`, add sed replacement for `EMAIL_PASSWORD_PLACEHOLDER`, remove `curl` from `allowed_commands` and service `path`
- [x] Add msmtp for outbound email (`modules/nixos/default.nix`): add `msmtp` to service PATH and `allowed_commands`, generate `.msmtprc` config from agenix secret in activation script
- [x] Rewrite email skill (`skills/email/SKILL.md`): document native channel for inbound/replies, document msmtp for outbound new emails, keep signature policy and etiquette
- [x] Update watchdog skill (`skills/watchdog/SKILL.md`): replace curl-based send_email with msmtp commands
- [x] Update HEARTBEAT.md (`workspace/HEARTBEAT.md`): remove "Check Inbox" section (IMAP IDLE handles incoming mail), keep memory update and stay quiet
- [x] Update TOOLS.md (`workspace/TOOLS.md`): document native channel for inbound + msmtp for outbound, add msmtp to tool list
- [x] Update MEMORY.md notes: document email architecture (inbound via IMAP IDLE, outbound via msmtp)
