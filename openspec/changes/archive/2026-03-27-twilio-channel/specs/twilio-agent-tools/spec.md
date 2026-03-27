## ADDED Requirements

### Requirement: twilio_send_sms tool

The agent SHALL have access to a `twilio_send_sms` tool that sends an SMS message via Twilio. Parameters: `to` (E.164 phone number, required), `body` (message text, required). The tool SHALL return success with the Twilio message SID, or an error description on failure.

#### Scenario: Send SMS to a phone number
- **WHEN** the agent calls `twilio_send_sms` with `to = "+15551234567"` and `body = "Deploy complete, all systems green."`
- **THEN** the system SHALL POST to the Twilio Messages API and return the message SID on success

#### Scenario: Invalid phone number
- **WHEN** the agent calls `twilio_send_sms` with `to = "not-a-number"`
- **THEN** the tool SHALL return an error indicating the phone number is invalid

#### Scenario: Twilio API error
- **WHEN** the agent calls `twilio_send_sms` and the Twilio API returns an error (e.g., insufficient funds)
- **THEN** the tool SHALL return the Twilio error message

### Requirement: twilio_call tool

The agent SHALL have access to a `twilio_call` tool that initiates an outbound voice call via Twilio. Parameters: `to` (E.164 phone number, required), `message` (text to speak, required), `interactive` (boolean, optional, defaults to `false`). When `interactive = false`, the call delivers the message and hangs up. When `interactive = true`, the call delivers the message and gathers a spoken response.

#### Scenario: Notification call
- **WHEN** the agent calls `twilio_call` with `to = "+15551234567"`, `message = "The backup job failed"`, `interactive = false`
- **THEN** the system SHALL place a call that speaks the message and hangs up, returning the call SID

#### Scenario: Interactive call
- **WHEN** the agent calls `twilio_call` with `to = "+15551234567"`, `message = "Deploy failed. Should I rollback?"`, `interactive = true`
- **THEN** the system SHALL place a call that speaks the message, gathers a response, and routes it back through the agent loop

#### Scenario: Call not answered
- **WHEN** the agent calls `twilio_call` and the recipient does not answer
- **THEN** the tool SHALL return a status indicating the call was not answered

### Requirement: Tool descriptions include cost awareness

The tool descriptions for `twilio_send_sms` and `twilio_call` SHALL mention that these actions incur Twilio usage costs, so the agent can factor cost into its decision-making.

#### Scenario: SMS tool description
- **WHEN** the tool registry is loaded
- **THEN** `twilio_send_sms` description SHALL include "Sends an SMS via Twilio (incurs per-message cost)"

#### Scenario: Call tool description
- **WHEN** the tool registry is loaded
- **THEN** `twilio_call` description SHALL include "Places a voice call via Twilio (incurs per-minute cost)"

### Requirement: Tools gated behind Twilio channel enablement

The `twilio_send_sms` and `twilio_call` tools SHALL only be registered in the tool registry when the `channel-twilio` feature is enabled and `[channels_config.twilio]` is present in config. The `twilio_call` tool SHALL additionally require `voice_enabled = true`.

#### Scenario: Twilio enabled, voice disabled
- **WHEN** `[channels_config.twilio]` is configured with `voice_enabled = false`
- **THEN** `twilio_send_sms` SHALL be available but `twilio_call` SHALL NOT be registered

#### Scenario: Twilio enabled, voice enabled
- **WHEN** `[channels_config.twilio]` is configured with `voice_enabled = true`
- **THEN** both `twilio_send_sms` and `twilio_call` SHALL be available

#### Scenario: Twilio not configured
- **WHEN** no `[channels_config.twilio]` section exists
- **THEN** neither `twilio_send_sms` nor `twilio_call` SHALL be registered
