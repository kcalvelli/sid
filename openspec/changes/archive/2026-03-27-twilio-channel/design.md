## Context

Sid's channel architecture is config-driven: each channel implements the `Channel` trait (`name`, `send`, `listen`, `start_typing`, `stop_typing`, `health_check`), and presence of a `[channels_config.<name>]` section in config.toml enables it at runtime. Channels are feature-gated at compile time via Cargo features. The NixOS module plumbs secrets via agenix placeholder substitution.

Twilio's API model is webhook-based: Twilio POSTs inbound SMS/voice events to a URL you configure, and you respond with TwiML (XML) or fire REST API calls for outbound actions. This differs from Telegram (long-polling) and XMPP (persistent connection) but fits the existing gateway HTTP infrastructure — the gateway already binds `0.0.0.0` with public HTTPS.

Sid already has a Deepgram transcription pipeline and ElevenLabs TTS pipeline, both configured and active. Voice calls can tap directly into these.

## Goals / Non-Goals

**Goals:**
- SMS channel that works like any other Sid channel (send/receive, cross-channel awareness)
- Voice calls with real-time speech-to-text → agent → text-to-speech flow
- Escalation routing that uses SMS and voice as urgency tiers
- Agent tools for proactive outreach (`twilio_send_sms`, `twilio_call`)
- Follow existing patterns: Cargo feature gate, NixOS module, agenix secrets

**Non-Goals:**
- WhatsApp integration (Keith doesn't use it)
- MMS / media messages over SMS (text-only for now; can add later)
- Conference calls or call transfers
- Twilio Programmable Video
- Recording or archiving calls
- Multi-number support (single Twilio number)

## Decisions

### 1. Single `channel-twilio` feature gate covering both SMS and voice

SMS and voice share the same Twilio credentials (Account SID, Auth Token, phone number) and webhook infrastructure. Splitting into two feature gates adds complexity with no benefit — if you have a Twilio account, you have both.

**Alternative considered:** Separate `channel-twilio-sms` and `channel-twilio-voice` features. Rejected because credentials are shared and voice without SMS (or vice versa) is an unusual deployment.

### 2. Webhook routes on the existing gateway, not a separate HTTP server

The gateway already listens on a public port with token-based auth. Adding `/twilio/sms` and `/twilio/voice` webhook routes avoids running a second HTTP listener. Twilio webhook validation (request signature) provides authentication instead of gateway pairing tokens.

**Alternative considered:** Standalone webhook server. Rejected because it duplicates HTTP infrastructure and complicates NixOS networking.

### 3. Twilio request signature validation for webhook auth

Twilio signs every webhook request with the Auth Token. Validating this signature ensures only Twilio can trigger inbound message processing — no gateway pairing token needed for these routes.

### 4. Voice flow: TwiML `<Gather>` with speech input → Deepgram → agent → TwiML `<Say>` via ElevenLabs

Inbound voice calls answered with TwiML that gathers speech. The gathered audio is sent to Deepgram (existing pipeline) for transcription, routed through the agent loop, and the response is synthesized via ElevenLabs TTS and streamed back as TwiML `<Play>` (pre-rendered audio URL) or `<Say>` (Twilio's built-in TTS as fallback). The call loops: gather → process → respond → gather again, until the caller hangs up or says "goodbye."

**Alternative considered:** Twilio's built-in speech recognition. Rejected because Deepgram is already configured and provides better accuracy with the existing pipeline.

### 5. Outbound calls via Twilio REST API with TwiML Bin or inline TwiML

Agent-initiated calls use the Twilio REST API to place the call, with a TwiML URL served by the gateway that speaks the agent's message. The call can optionally gather a response (interactive) or just deliver and hang up (notification).

### 6. Escalation tiers: low → queue, medium → SMS, high → Pushover, critical → voice call

Extends `escalate_to_human` with two new urgency levels. Existing "low" and "high" behavior unchanged. New "medium" sends an SMS. New "critical" places a voice call. This is additive — no breaking change.

**Alternative considered:** Replacing Pushover with SMS for "high." Rejected because Pushover delivers richer notifications (sound, vibration patterns, priority levels) and Keith already has it configured.

### 7. Raw `reqwest` calls to Twilio REST API, not a Twilio SDK crate

The Twilio REST API is simple (form-encoded POST to `api.twilio.com`). Adding a `twilio-rs` crate dependency for a handful of endpoints is unnecessary. `reqwest` is already a dependency.

## Risks / Trade-offs

- **[Webhook reachability]** Twilio must reach the gateway over public HTTPS. → The gateway already binds publicly; ensure Twilio's webhook URL is configured correctly and DNS/TLS are in place.
- **[Voice latency]** The gather → transcribe → agent → TTS → play loop adds latency to voice conversations. → Acceptable for a personal assistant; not targeting real-time conversational UX. Can optimize later with streaming if needed.
- **[SMS cost]** Each SMS segment costs ~$0.0079. Agent-initiated messaging could accumulate. → Cost tracking already exists; SMS costs are low. Agent tools should document cost implications in their descriptions.
- **[Twilio number acquisition]** Keith needs a Twilio phone number with SMS and voice capability. → This is a one-time Twilio console action, documented in setup instructions.
- **[Caller ID / spam filtering]** Outbound calls from Twilio numbers may be flagged by carriers. → Register the number with Twilio's Trust Hub / SHAKEN/STIR. Out of scope for this change but noted.

## Open Questions

- Should voice calls have a maximum duration timeout? (Suggest 10 minutes to avoid runaway calls.)
- Should the agent be told the caller's phone number, or should it be mapped to a contact name via config? (Suggest: config-based contact map with fallback to raw number.)
