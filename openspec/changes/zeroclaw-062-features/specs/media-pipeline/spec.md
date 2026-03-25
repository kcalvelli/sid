## ADDED Requirements

### Requirement: Media pipeline enablement
The system SHALL enable the media pipeline via `[media_pipeline] enabled = true` in the gateway config, activating automatic processing of inbound media.

#### Scenario: Enable media pipeline
- **WHEN** the NixOS module generates `config.toml` with `[media_pipeline] enabled = true`
- **THEN** inbound messages containing media attachments SHALL be automatically processed before reaching the agent

### Requirement: Audio transcription
The media pipeline SHALL automatically transcribe audio attachments on inbound messages, appending the transcript to the message text.

#### Scenario: Voice message transcription
- **WHEN** a Telegram voice message is received
- **THEN** the media pipeline SHALL transcribe the audio and include the transcript text in the message delivered to the agent

#### Scenario: Audio transcription failure
- **WHEN** audio transcription fails (API error, unsupported format)
- **THEN** the original message SHALL be delivered to the agent with a note that transcription failed

### Requirement: Image description
The media pipeline SHALL automatically describe images attached to inbound messages using built-in vision capabilities.

#### Scenario: Photo with caption
- **WHEN** a Telegram photo with caption is received
- **THEN** the media pipeline SHALL generate a description of the image and include it alongside the caption in the message delivered to the agent

### Requirement: Video summarization
The media pipeline SHALL summarize video attachments on inbound messages.

#### Scenario: Short video received
- **WHEN** a video attachment under the size limit is received
- **THEN** the media pipeline SHALL extract key frames, describe them, and include a summary in the message delivered to the agent
