## 1. Foundation & Configuration

- [ ] 1.1 Add `channel-twilio` Cargo feature flag to `Cargo.toml` with conditional dependencies (`reqwest` already exists; add `hmac`, `sha1` for signature validation)
- [ ] 1.2 Add Twilio NixOS module options (`services.sid.twilio.enable`, `accountSid`, `phoneNumber`, `webhookBaseUrl`, `voiceEnabled`, `escalationPhoneNumber`, `allowedSenders`, `voiceMaxDurationSecs`, `voiceGreeting`, `contacts`)
- [ ] 1.3 Add agenix secret for Twilio Auth Token (`sid-twilio-auth-token`) and wire placeholder substitution in activation script
- [ ] 1.4 Generate `[channels_config.twilio]` config section in `configToml` (matching pattern of `telegramConfig`, `emailConfig`, `xmppConfig`)
- [ ] 1.5 Add `channel-twilio` to `buildFeatures` in the Nix flake when `services.sid.twilio.enable = true`

## 2. Twilio Shared Infrastructure

- [ ] 2.1 Create `src/channels/twilio/mod.rs` with config deserialization struct (`TwilioConfig`: account_sid, auth_token, phone_number, webhook_base_url, allowed_senders, sms_enabled, voice_enabled, voice_max_duration_secs, voice_greeting, contacts)
- [ ] 2.2 Implement Twilio request signature validation function (HMAC-SHA1 of URL + sorted POST params, base64-encoded, compared to `X-Twilio-Signature`)
- [ ] 2.3 Implement Twilio REST API client helper (POST to `api.twilio.com` with Basic auth using Account SID / Auth Token)

## 3. SMS Channel

- [ ] 3.1 Implement `TwilioSmsChannel` struct implementing the `Channel` trait (`name`, `send`, `listen`, `start_typing`, `stop_typing`, `health_check`)
- [ ] 3.2 Register `/twilio/sms` webhook POST route on the gateway with signature validation middleware
- [ ] 3.3 Implement inbound SMS handler: parse Twilio POST params (`From`, `Body`), filter by `allowed_senders`, create `ChannelMessage`, respond with empty TwiML `<Response/>`
- [ ] 3.4 Implement outbound SMS via `send()`: POST to Twilio Messages API with `To`, `From`, `Body`
- [ ] 3.5 Implement `health_check()` via GET to Twilio Account API
- [ ] 3.6 Register `TwilioSmsChannel` in the channel registry when `[channels_config.twilio]` is present and `sms_enabled = true`

## 4. Voice Channel

- [ ] 4.1 Register `/twilio/voice` webhook POST route: respond with TwiML greeting + `<Gather input="speech">` pointing action to `/twilio/voice/process`
- [ ] 4.2 Register `/twilio/voice/process` webhook POST route: extract `SpeechResult` and `From`, create `ChannelMessage` with channel `"twilio-voice"`
- [ ] 4.3 Implement agent response → TwiML conversion: render ElevenLabs TTS audio to temporary gateway URL and use `<Play>`, with `<Say>` fallback
- [ ] 4.4 Implement conversation loop: each response TwiML ends with another `<Gather>` for continued input
- [ ] 4.5 Implement goodbye detection: match "goodbye"/"bye"/"hang up" in `SpeechResult`, respond with `<Say>Later.</Say><Hangup/>`
- [ ] 4.6 Implement max duration enforcement: track call start time per `CallSid`, respond with timeout message + `<Hangup/>` when exceeded
- [ ] 4.7 Implement outbound calls via Twilio REST API: create call with TwiML URL served by gateway (notification mode and interactive mode)
- [ ] 4.8 Implement contact name mapping: look up `From` number in `contacts` config, format sender as "Name (+number)" or raw number
- [ ] 4.9 Return `<Reject/>` TwiML for inbound calls when `voice_enabled = false`

## 5. Agent Tools

- [ ] 5.1 Implement `twilio_send_sms` tool: validate E.164 `to`, POST to Messages API, return message SID or error
- [ ] 5.2 Implement `twilio_call` tool: validate E.164 `to`, create call via REST API with gateway-served TwiML, support `interactive` parameter
- [ ] 5.3 Register tools in tool registry gated on Twilio config presence (`twilio_call` additionally gated on `voice_enabled`)
- [ ] 5.4 Add cost-awareness language to tool descriptions

## 6. Enhanced Escalation

- [ ] 6.1 Extend `escalate_to_human` urgency enum to include `"medium"` and `"critical"` levels
- [ ] 6.2 Implement medium-urgency handler: send SMS to `escalation_phone_number` via `twilio_send_sms`, fall back to Pushover if Twilio unavailable
- [ ] 6.3 Implement critical-urgency handler: place interactive voice call to `escalation_phone_number` via `twilio_call`, fall back to Pushover if voice unavailable
- [ ] 6.4 Update `escalate_to_human` tool schema to document the four urgency levels (low, medium, high, critical)

## 7. Integration & Testing

- [ ] 7.1 Add Twilio channel to cross-channel awareness (agent context includes active Twilio channels alongside Telegram/Email/XMPP)
- [ ] 7.2 Write unit tests for signature validation (valid, invalid, missing header)
- [ ] 7.3 Write unit tests for SMS allowed_senders filtering (specific numbers, wildcard, non-allowed)
- [ ] 7.4 Write unit tests for contact name mapping
- [ ] 7.5 Write unit tests for goodbye detection and max duration logic
- [ ] 7.6 Manual integration test: send SMS to Twilio number, verify round-trip through agent
- [ ] 7.7 Manual integration test: call Twilio number, verify voice conversation loop
- [ ] 7.8 Manual integration test: trigger escalation at each urgency level, verify routing
