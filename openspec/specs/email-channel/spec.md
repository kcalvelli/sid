# Email Channel Spec (Delta)

MODIFIED requirements for the `zeroclaw-service` capability:

- Config.toml SHALL include `[channels_config.email]` when `cfg.email.enable` is true
- Email password SHALL be injected from agenix secret at activation time via sed placeholder
- `curl` SHALL NOT be in `allowed_commands` or service PATH
- Email skill SHALL document native channel behavior, not curl API
- Watchdog skill SHALL send alerts via native email channel
- HEARTBEAT.md SHALL NOT include inbox polling (IMAP IDLE handles it)
