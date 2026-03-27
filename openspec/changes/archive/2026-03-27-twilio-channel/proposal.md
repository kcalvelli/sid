## Why

Sid currently reaches Keith via Telegram, Email, XMPP, and the web dashboard — all internet-dependent channels. SMS and voice calls via Twilio add a carrier-grade fallback that works when data is spotty, and open up voice-interactive and proactive-outreach use cases that no current channel supports. Keith already has a Twilio account, so the barrier to entry is configuration, not procurement.

## What Changes

- New Twilio SMS channel: inbound SMS via webhook → agent loop, outbound SMS via Twilio REST API
- New Twilio voice channel: inbound calls transcribed (Deepgram) → agent loop → TTS (ElevenLabs) response; outbound calls initiated by agent
- Enhanced escalation routing: `escalate_to_human` gains SMS and voice-call urgency tiers
- Agent-initiated messaging tools: `twilio_send_sms` and `twilio_call` exposed in the tool registry
- NixOS module additions: `services.sid.twilio.*` options, agenix secret plumbing, Cargo feature gate `channel-twilio`

## Capabilities

### New Capabilities
- `twilio-sms-channel`: Inbound/outbound SMS messaging via Twilio, implementing the Channel trait
- `twilio-voice-channel`: Inbound/outbound voice calls via Twilio with speech-to-text and TTS integration
- `twilio-agent-tools`: Agent-exposed tools for proactive SMS and voice outreach

### Modified Capabilities
- `escalate-to-human`: Add SMS (medium urgency) and voice call (critical urgency) escalation routes alongside existing Pushover (high) and morning-briefing queue (low)

## Impact

- **Rust crate**: New `channel-twilio` feature flag; new Twilio channel module with SMS + voice logic
- **Dependencies**: `twilio-rs` or raw `reqwest` calls to Twilio REST API; Twilio webhook endpoint on the gateway
- **NixOS module**: New `services.sid.twilio.*` options; agenix secrets for Account SID, Auth Token, phone number
- **Gateway**: New webhook route(s) for Twilio inbound SMS and voice callbacks
- **Existing spec**: `escalate-to-human` gains two new urgency tiers
- **Network**: Twilio webhook requires public-facing HTTPS endpoint (gateway already binds 0.0.0.0)
