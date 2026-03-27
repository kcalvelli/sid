## ADDED Requirements

### Requirement: Inbound voice calls answered with speech gathering

The gateway SHALL expose a `/twilio/voice` POST endpoint for Twilio inbound voice webhooks. When a call arrives, the endpoint SHALL respond with TwiML that plays a greeting and gathers speech input using `<Gather input="speech" action="/twilio/voice/process" speechTimeout="auto">`. The greeting SHALL be "Hey, this is Sid. What's up?"

#### Scenario: Inbound call answered
- **WHEN** Twilio POSTs an inbound voice webhook to `/twilio/voice` with `From=+15551234567`
- **THEN** the gateway SHALL respond with TwiML containing a `<Say>` greeting and `<Gather>` for speech input

#### Scenario: Caller speaks
- **WHEN** the caller speaks during the `<Gather>` phase
- **THEN** Twilio SHALL POST the `SpeechResult` to `/twilio/voice/process`

#### Scenario: Caller says nothing
- **WHEN** the `<Gather>` times out with no speech detected
- **THEN** the TwiML SHALL `<Say>` "I didn't catch that. Try again or hang up." and re-gather

### Requirement: Voice speech processed through agent loop

The `/twilio/voice/process` endpoint SHALL receive Twilio's `SpeechResult` (transcribed text), create a `ChannelMessage` with channel `"twilio-voice"`, sender as the caller's phone number, and content as the transcribed speech. The agent's response SHALL be converted to TwiML for playback.

#### Scenario: Speech result routed to agent
- **WHEN** Twilio POSTs `SpeechResult="What's the server status?"` from `+15551234567`
- **THEN** a `ChannelMessage` SHALL be created with sender `+15551234567`, content `"What's the server status?"`, and channel `"twilio-voice"`

#### Scenario: Agent response spoken back
- **WHEN** the agent responds with "All systems nominal, CPU at 12 percent"
- **THEN** the endpoint SHALL respond with TwiML `<Say>` containing the response text, followed by another `<Gather>` to continue the conversation

### Requirement: Voice call uses ElevenLabs TTS when available

When the TTS pipeline is enabled and ElevenLabs is configured, the voice response SHALL be pre-rendered as audio via ElevenLabs and played back with TwiML `<Play>` for higher-quality speech. When TTS is unavailable, the response SHALL fall back to Twilio's built-in `<Say>` voice.

#### Scenario: TTS available — use Play
- **WHEN** ElevenLabs TTS is enabled and the agent produces a response
- **THEN** the response audio SHALL be generated via ElevenLabs, served at a temporary gateway URL, and played via TwiML `<Play>{audio_url}</Play>`

#### Scenario: TTS unavailable — fallback to Say
- **WHEN** TTS is not enabled or ElevenLabs fails
- **THEN** the response SHALL be delivered via TwiML `<Say voice="Polly.Matthew">{response}</Say>`

### Requirement: Voice conversation loops until hangup or goodbye

After each agent response is played, the call SHALL loop back to `<Gather>` for the next caller input. The loop SHALL terminate when the caller hangs up or says a phrase containing "goodbye", "bye", or "hang up."

#### Scenario: Conversation continues
- **WHEN** the agent response is played and the caller continues speaking
- **THEN** a new `<Gather>` SHALL capture the next input and route it through the agent loop

#### Scenario: Caller says goodbye
- **WHEN** the caller's `SpeechResult` contains "goodbye", "bye", or "hang up" (case-insensitive)
- **THEN** the endpoint SHALL respond with TwiML `<Say>` "Later." followed by `<Hangup/>`

#### Scenario: Caller hangs up
- **WHEN** Twilio detects the caller has disconnected
- **THEN** the call session SHALL be cleaned up with no further processing

### Requirement: Voice call maximum duration

Voice calls SHALL have a configurable maximum duration, defaulting to 10 minutes. When the maximum is reached, the call SHALL play "We've been chatting a while. Catch you later." and hang up.

#### Scenario: Call reaches maximum duration
- **WHEN** a voice call has been active for 10 minutes (default)
- **THEN** the next gather cycle SHALL respond with a goodbye message and `<Hangup/>`

#### Scenario: Custom max duration
- **WHEN** `voice_max_duration_secs = 300` is configured
- **THEN** the call SHALL be limited to 5 minutes

### Requirement: Outbound voice calls via Twilio REST API

The system SHALL support placing outbound voice calls via the Twilio REST API. An outbound call SHALL connect to the recipient, play a TTS message, and optionally gather a response. The TwiML for the call SHALL be served by a temporary gateway endpoint.

#### Scenario: Notification call (no interaction)
- **WHEN** an outbound call is placed with `interactive = false` and message "Deploy complete, all green"
- **THEN** Twilio SHALL call the recipient, play the message via TTS, and hang up

#### Scenario: Interactive call
- **WHEN** an outbound call is placed with `interactive = true` and message "Hey, the deploy failed. Want me to rollback?"
- **THEN** Twilio SHALL call the recipient, play the message, and `<Gather>` a speech response to route back through the agent loop

### Requirement: Voice webhook signature validation

All voice webhook routes (`/twilio/voice`, `/twilio/voice/process`) SHALL validate Twilio's `X-Twilio-Signature` header. Requests with invalid or missing signatures SHALL be rejected with HTTP 403.

#### Scenario: Valid signature on voice webhook
- **WHEN** a voice webhook request has a valid `X-Twilio-Signature`
- **THEN** the request SHALL be processed normally

#### Scenario: Invalid signature on voice webhook
- **WHEN** a voice webhook request has an invalid `X-Twilio-Signature`
- **THEN** the request SHALL be rejected with HTTP 403

### Requirement: Voice channel configuration

Voice features SHALL be controlled via the shared `[channels_config.twilio]` section:
- `voice_enabled` (boolean, optional): Enable voice channel; defaults to `false`
- `voice_max_duration_secs` (integer, optional): Maximum call duration in seconds; defaults to `600`
- `voice_greeting` (string, optional): Greeting spoken when answering; defaults to "Hey, this is Sid. What's up?"

#### Scenario: Voice enabled
- **WHEN** `voice_enabled = true`
- **THEN** the `/twilio/voice` and `/twilio/voice/process` webhook routes SHALL be registered

#### Scenario: Voice disabled (default)
- **WHEN** `voice_enabled` is not set or false
- **THEN** voice webhook routes SHALL NOT be registered and inbound calls SHALL receive a TwiML `<Reject/>` response

### Requirement: Contact name mapping for voice callers

The channel SHALL support an optional `contacts` configuration mapping phone numbers to display names. When a known number calls, the `sender` field on `ChannelMessage` SHALL include the display name (e.g., "Keith (+15551234567)"). Unknown numbers SHALL use the raw E.164 number.

#### Scenario: Known contact calls
- **WHEN** `contacts = { "+15551234567" = "Keith" }` and a call arrives from `+15551234567`
- **THEN** the `ChannelMessage.sender` SHALL be `"Keith (+15551234567)"`

#### Scenario: Unknown contact calls
- **WHEN** a call arrives from `+15559999999` which is not in the contacts map
- **THEN** the `ChannelMessage.sender` SHALL be `"+15559999999"`
