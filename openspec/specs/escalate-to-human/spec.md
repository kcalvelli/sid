## ADDED Requirements

### Requirement: Escalate-to-human tool with urgency routing
The system SHALL expose an `escalate_to_human` tool that routes escalation requests based on urgency level, replacing or supplementing the basic `ask_user` tool for auto-mode SOPs.

#### Scenario: High-urgency escalation sends Pushover notification
- **WHEN** the `escalate_to_human` tool is invoked with urgency "high" during an auto-mode SOP
- **THEN** the system sends a Pushover notification (using existing Pushover config) and logs the escalation

#### Scenario: Low-urgency escalation queues for next session
- **WHEN** the `escalate_to_human` tool is invoked with urgency "low"
- **THEN** the escalation is queued and included in the next morning-briefing SOP output

#### Scenario: Tool available in tool registry
- **WHEN** the ZeroClaw tool registry is loaded
- **THEN** `escalate_to_human` is listed as an available tool with urgency parameter
