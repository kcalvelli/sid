# Email Channel Spec

## Service Configuration

- Config.toml SHALL include `[channels_config.email]` when `cfg.email.enable` is true
- Email password SHALL be injected from agenix secret at activation time via sed placeholder
- `curl` SHALL NOT be in `allowed_commands` or service PATH
- Email skill SHALL document native channel behavior, not curl API
- Watchdog skill SHALL send alerts via native email channel
- HEARTBEAT.md SHALL NOT include inbox polling (IMAP IDLE handles it)

## Reply Threading

### Requirement: Email subject preserved for reply threading
The email channel SHALL extract the subject from incoming emails into the `thread_ts` field on `ChannelMessage`. When sending replies, the channel SHALL use `thread_ts` as the reply subject with "Re: " prefix if no explicit subject is provided. Implemented via Sid patch 0008.

#### Scenario: Inbound email populates thread_ts
- **WHEN** an incoming email has content starting with "Subject: Meeting Notes"
- **THEN** the `ChannelMessage.thread_ts` field is set to "Meeting Notes"

#### Scenario: Reply uses thread_ts as subject
- **WHEN** a reply is sent and `message.subject` is None and `message.thread_ts` is "Meeting Notes"
- **THEN** the email is sent with subject "Re: Meeting Notes"

#### Scenario: Reply with existing Re: prefix
- **WHEN** a reply is sent and `message.thread_ts` is "Re: Meeting Notes"
- **THEN** the email is sent with subject "Re: Meeting Notes" (no double prefix)

#### Scenario: Explicit subject takes precedence
- **WHEN** a reply is sent with `message.subject` set to "New Topic"
- **THEN** the email is sent with subject "New Topic" regardless of `thread_ts`
