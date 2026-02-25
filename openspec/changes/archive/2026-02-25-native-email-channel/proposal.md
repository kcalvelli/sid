# Switch Email from Curl Skill to Built-in ZeroClaw Email Channel

## Why

Sid's email currently works via `curl` calling the `axios-ai-mail` REST API on localhost:8085, but ZeroClaw has a built-in email channel (IMAP IDLE + SMTP) that connects directly to the mail server. Switching to it:

- **Eliminates middleware dependency** — `axios-ai-mail` service no longer needed for Sid's email
- **Instant email delivery** — IMAP IDLE pushes new mail instantly vs. 30-minute heartbeat polling
- **Reduces attack surface** — removes `curl` from allowed commands and service PATH

## What Changes

- Add `[channels_config.email]` to `config.toml` with IMAP/SMTP settings for `genxbot@calvelli.us` on `london.mxroute.com`
- Inject email password from existing agenix secret (`/run/agenix/sid-email-password`) via sed placeholder (same pattern as Telegram token)
- Remove `curl` from `allowed_commands` and systemd service `path`
- Rewrite `skills/email/SKILL.md` as behavioral guidance (no curl API docs)
- Update `skills/watchdog/SKILL.md` to send alerts via email channel instead of curl
- Remove inbox polling from `workspace/HEARTBEAT.md` (IMAP IDLE handles it)
- Update `workspace/TOOLS.md` to document native email channel

## Capabilities

- MODIFIED: `zeroclaw-service` — add email channel config, remove curl

## Impact

- `axios-ai-mail` service no longer needed for Sid's email use case
- Email arrives instantly (IMAP IDLE) vs. every 30 minutes (heartbeat polling)
- Watchdog alerts sent via native channel instead of curl
- Allowed senders: `["*"]` (accept from anyone)
