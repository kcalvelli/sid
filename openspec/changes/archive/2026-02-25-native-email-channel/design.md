# Design Decisions

## D1: Email config injected same way as Telegram

Config.toml gets a `[channels_config.email]` section with `EMAIL_PASSWORD_PLACEHOLDER`. The activation script sed-replaces it from `/run/agenix/sid-email-password`. Same pattern as Telegram token injection.

## D2: Watchdog sends alerts via email channel

ZeroClaw's email channel has a `send()` method exposed to the agent. Watchdog instructions are rewritten to tell the agent to compose and send the email through the channel, rather than using curl to call an API.

## D3: No heartbeat inbox check needed

IMAP IDLE pushes new mail instantly. The heartbeat "Check Inbox" step is removed entirely.
