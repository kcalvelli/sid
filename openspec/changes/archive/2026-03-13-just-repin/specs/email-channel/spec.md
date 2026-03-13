## MODIFIED Requirements

### Requirement: Email subject preserved for reply threading
The email channel SHALL extract the subject from incoming emails into the `thread_ts` field on `ChannelMessage`. When sending replies, the channel SHALL use `thread_ts` as the reply subject with "Re: " prefix if no explicit subject is provided.

This requirement is still implemented via Sid patch 0008. During rebase, the outbound path SHOULD leverage upstream's `message.subject` field if it simplifies the implementation, but the inbound `thread_ts` extraction remains necessary (upstream still sets `thread_ts: None`).

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
