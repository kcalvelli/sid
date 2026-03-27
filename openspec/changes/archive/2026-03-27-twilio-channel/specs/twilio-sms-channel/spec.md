## ADDED Requirements

### Requirement: Twilio SMS channel implements the Channel trait

The Twilio SMS channel SHALL implement the `Channel` trait with `name()` returning `"twilio-sms"`. The channel SHALL handle inbound SMS via Twilio webhook and outbound SMS via the Twilio REST API. The `sender` field on `ChannelMessage` SHALL be the caller's phone number in E.164 format. The `reply_target` SHALL equal the `sender`.

#### Scenario: Channel name
- **WHEN** the Twilio SMS channel is initialized
- **THEN** `name()` SHALL return `"twilio-sms"`

#### Scenario: Inbound SMS creates a ChannelMessage
- **WHEN** Twilio POSTs an inbound SMS webhook to `/twilio/sms` with `From=+15551234567` and `Body="What's the server status?"`
- **THEN** a `ChannelMessage` SHALL be created with sender `+15551234567`, reply_target `+15551234567`, content `"What's the server status?"`, and channel `"twilio-sms"`

#### Scenario: Outbound SMS via send()
- **WHEN** the agent generates a response to an SMS conversation with reply_target `+15551234567`
- **THEN** the channel SHALL POST to `https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json` with `To=+15551234567`, `From={configured phone number}`, and `Body={response text}`

### Requirement: Twilio webhook signature validation

The SMS webhook route SHALL validate Twilio's `X-Twilio-Signature` header using the configured Auth Token. Requests with invalid or missing signatures SHALL be rejected with HTTP 403.

#### Scenario: Valid Twilio signature
- **WHEN** an inbound webhook request has a valid `X-Twilio-Signature` header
- **THEN** the request SHALL be processed normally

#### Scenario: Invalid Twilio signature
- **WHEN** an inbound webhook request has an invalid `X-Twilio-Signature` header
- **THEN** the request SHALL be rejected with HTTP 403 and no `ChannelMessage` SHALL be created

#### Scenario: Missing Twilio signature
- **WHEN** an inbound webhook request has no `X-Twilio-Signature` header
- **THEN** the request SHALL be rejected with HTTP 403

### Requirement: SMS webhook route on the gateway

The gateway SHALL expose a `/twilio/sms` POST endpoint for Twilio inbound SMS webhooks. This route SHALL NOT require gateway pairing token authentication (Twilio signature validation provides auth). The route SHALL respond with HTTP 200 and empty TwiML `<Response/>` after accepting the message.

#### Scenario: Webhook responds with empty TwiML
- **WHEN** a valid inbound SMS webhook is received
- **THEN** the gateway SHALL respond with `Content-Type: text/xml` and body `<?xml version="1.0" encoding="UTF-8"?><Response/>`

#### Scenario: Webhook route does not require pairing token
- **WHEN** a Twilio-signed request arrives at `/twilio/sms` without a gateway pairing token
- **THEN** the request SHALL be accepted (signature validation is sufficient)

### Requirement: Long SMS messages are split by Twilio transparently

The channel SHALL send the full response text in a single API call regardless of length. Twilio handles segmentation into multiple SMS segments automatically. No client-side splitting is required.

#### Scenario: Long response message
- **WHEN** the agent response is 500 characters (exceeding the 160-character SMS segment limit)
- **THEN** the channel SHALL send the full 500-character body in one API call and Twilio SHALL handle segmentation

### Requirement: SMS allowed senders filtering

The channel SHALL support an `allowed_senders` configuration list of E.164 phone numbers. When set to `["*"]`, all senders are accepted. When set to specific numbers, only those numbers SHALL have their messages processed. Messages from non-allowed senders SHALL be silently dropped.

#### Scenario: Allowed sender sends SMS
- **WHEN** `allowed_senders = ["+15551234567"]` and an SMS arrives from `+15551234567`
- **THEN** the message SHALL be processed

#### Scenario: Non-allowed sender sends SMS
- **WHEN** `allowed_senders = ["+15551234567"]` and an SMS arrives from `+15559999999`
- **THEN** the message SHALL be silently dropped

#### Scenario: Wildcard allows all senders
- **WHEN** `allowed_senders = ["*"]` and an SMS arrives from any number
- **THEN** the message SHALL be processed

### Requirement: Twilio SMS channel configuration

The channel SHALL be configured via `[channels_config.twilio]` in config.toml with the following fields:
- `account_sid` (string, required): Twilio Account SID
- `auth_token` (string, required): Twilio Auth Token (injected from agenix secret)
- `phone_number` (string, required): Twilio phone number in E.164 format
- `webhook_base_url` (string, required): Public base URL for webhook callbacks (e.g., `https://sid.example.com`)
- `allowed_senders` (array of strings, optional): E.164 numbers allowed to message; defaults to `["*"]`
- `sms_enabled` (boolean, optional): Enable SMS channel; defaults to `true`
- `voice_enabled` (boolean, optional): Enable voice channel; defaults to `false`

#### Scenario: Minimal configuration
- **WHEN** config contains account_sid, auth_token, phone_number, and webhook_base_url
- **THEN** SMS SHALL be enabled, voice SHALL be disabled, and all senders SHALL be accepted

#### Scenario: SMS disabled
- **WHEN** `sms_enabled = false`
- **THEN** the `/twilio/sms` webhook route SHALL NOT be registered and inbound SMS SHALL not be processed

### Requirement: NixOS module Twilio options

The NixOS module SHALL provide `services.sid.twilio.enable` and related options. When enabled, the module SHALL:
- Add `[channels_config.twilio]` to the generated config.toml
- Inject the Twilio Auth Token from an agenix secret via placeholder substitution
- Add the `channel-twilio` Cargo feature to `buildFeatures`

#### Scenario: Twilio enabled in NixOS config
- **WHEN** `services.sid.twilio.enable = true` with account_sid, phone_number, and webhook_base_url configured
- **THEN** the activation script SHALL generate a `[channels_config.twilio]` section in config.toml with the auth_token placeholder replaced by the agenix secret value

#### Scenario: Twilio disabled (default)
- **WHEN** `services.sid.twilio.enable` is not set or false
- **THEN** no `[channels_config.twilio]` section SHALL appear in config.toml

### Requirement: Twilio channel feature-gated in Cargo build

The Twilio channel SHALL be gated behind a `channel-twilio` Cargo feature flag. When the feature is not enabled, no Twilio-related code SHALL be compiled.

#### Scenario: Build with Twilio feature enabled
- **WHEN** `buildFeatures` includes `channel-twilio`
- **THEN** the Twilio channel code SHALL compile and the channel SHALL be available for configuration

#### Scenario: Build without Twilio feature
- **WHEN** `buildFeatures` does not include `channel-twilio`
- **THEN** Twilio channel code SHALL not be compiled and `[channels_config.twilio]` SHALL be ignored

### Requirement: SMS health check via Twilio API

The `health_check()` method SHALL verify connectivity by calling the Twilio Account API (`GET /2010-04-01/Accounts/{AccountSid}.json`). A successful 200 response means the channel is healthy.

#### Scenario: Healthy Twilio connection
- **WHEN** `health_check()` is called and the Twilio API returns HTTP 200
- **THEN** `health_check()` SHALL return `true`

#### Scenario: Unhealthy Twilio connection
- **WHEN** `health_check()` is called and the Twilio API returns an error or times out
- **THEN** `health_check()` SHALL return `false`
