## MODIFIED Requirements

### Requirement: Escalate-to-human tool with urgency routing
The system SHALL expose an `escalate_to_human` tool that routes escalation requests based on urgency level, replacing or supplementing the basic `ask_user` tool for auto-mode SOPs.

#### Scenario: Critical-urgency escalation places a voice call
- **WHEN** the `escalate_to_human` tool is invoked with urgency "critical" and Twilio voice is enabled
- **THEN** the system SHALL place an outbound voice call to the configured escalation phone number, speaking the escalation message, with `interactive = true` to gather a response

#### Scenario: Critical-urgency escalation falls back to Pushover when voice unavailable
- **WHEN** the `escalate_to_human` tool is invoked with urgency "critical" and Twilio voice is NOT enabled
- **THEN** the system SHALL fall back to sending a Pushover notification (same as "high" urgency behavior)

#### Scenario: High-urgency escalation sends Pushover notification
- **WHEN** the `escalate_to_human` tool is invoked with urgency "high" during an auto-mode SOP
- **THEN** the system sends a Pushover notification (using existing Pushover config) and logs the escalation

#### Scenario: Medium-urgency escalation sends SMS
- **WHEN** the `escalate_to_human` tool is invoked with urgency "medium" and Twilio SMS is enabled
- **THEN** the system SHALL send an SMS to the configured escalation phone number with the escalation message

#### Scenario: Medium-urgency escalation falls back to Pushover when SMS unavailable
- **WHEN** the `escalate_to_human` tool is invoked with urgency "medium" and Twilio SMS is NOT enabled
- **THEN** the system SHALL fall back to sending a Pushover notification

#### Scenario: Low-urgency escalation queues for next session
- **WHEN** the `escalate_to_human` tool is invoked with urgency "low"
- **THEN** the escalation is queued and included in the next morning-briefing SOP output

#### Scenario: Tool available in tool registry
- **WHEN** the ZeroClaw tool registry is loaded
- **THEN** `escalate_to_human` is listed as an available tool with urgency parameter accepting "low", "medium", "high", or "critical"

#### Scenario: Escalation phone number configuration
- **WHEN** `services.sid.twilio.escalationPhoneNumber` is configured
- **THEN** medium and critical escalations SHALL be sent to that phone number
