## ADDED Requirements

### Requirement: Channel messages carry send-time timestamps

When a message arrives from any channel (Telegram, Discord, CLI), the system SHALL prepend a bracketed ISO-8601 timestamp with UTC offset to the message content before it enters conversation history. The timestamp SHALL be derived from the channel's `ChannelMessage.timestamp` field (unix epoch seconds), converted to local time.

Format: `[%Y-%m-%dT%H:%M:%S%:z] <original content>`

#### Scenario: Telegram message receives timestamp
- **WHEN** a Telegram message with content "Hey Sid" and unix timestamp 1740336202 arrives
- **THEN** the ChatMessage content passed to the LLM SHALL be `[2026-02-23T15:43:22-05:00] Hey Sid` (timestamp converted to local time with offset)

#### Scenario: Timestamp uses channel's original send time
- **WHEN** a channel message was sent at 15:43:22 but processed by ZeroClaw at 15:43:25
- **THEN** the timestamp SHALL reflect 15:43:22 (the send time), not 15:43:25

### Requirement: Heartbeat messages carry dispatch-time timestamps

When a heartbeat task is dispatched, the system SHALL prepend a bracketed ISO-8601 timestamp with UTC offset to the heartbeat prompt. The timestamp SHALL be generated from `chrono::Local::now()` at dispatch time.

#### Scenario: Heartbeat task receives timestamp
- **WHEN** the heartbeat dispatches task "Update Memory" at local time 2026-02-23T06:30:08-05:00
- **THEN** the prompt sent to the LLM SHALL be `[2026-02-23T06:30:08-05:00] [Heartbeat Task] Update Memory`

### Requirement: Webhook messages carry receipt-time timestamps

When a message arrives via the gateway webhook endpoint, the system SHALL prepend a bracketed ISO-8601 timestamp with UTC offset to the message content. The timestamp SHALL be generated from `chrono::Local::now()` at receipt time.

#### Scenario: Webhook message receives timestamp
- **WHEN** a webhook POST with body `{"message": "status check"}` is received at 2026-02-23T10:00:00-05:00
- **THEN** the message passed to the agent SHALL be `[2026-02-23T10:00:00-05:00] status check`

### Requirement: Assistant messages are not stamped

The system SHALL NOT modify assistant/LLM response content. Only user-role and system-injected messages (heartbeat, webhook) receive timestamps.

#### Scenario: LLM response passes through unmodified
- **WHEN** the LLM generates a response "Load is fine, stop asking"
- **THEN** the response SHALL be stored and displayed without any timestamp prefix

### Requirement: Timestamp format is consistent across all sources

All timestamps SHALL use the same format regardless of message source: `[%Y-%m-%dT%H:%M:%S%:z]`. The timezone offset SHALL reflect the host system's local time as determined by `chrono::Local` (reading `/etc/localtime`).

#### Scenario: Format consistency
- **WHEN** a channel message and a heartbeat message arrive in the same conversation
- **THEN** both SHALL have timestamps in identical `[YYYY-MM-DDTHH:MM:SS±HH:MM]` format
