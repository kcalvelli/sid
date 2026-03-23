## MODIFIED Requirements

### Requirement: Daily morning briefing email
The system SHALL send a single morning briefing email to keith@calvelli.dev each day after 06:30 local time, containing weather, calendar, email summary, and service health information. The briefing SHALL be triggered by a cron-based SOP rather than the heartbeat subsystem.

#### Scenario: SOP cron trigger fires after 06:30
- **WHEN** the `morning-briefing` SOP's cron trigger fires after 06:30 local time AND no briefing has been sent today (per `.watchdog-state.json`)
- **THEN** the system SHALL request approval (supervised mode), then gather briefing data (weather, calendar, email, health), compose and send a briefing email, and update `last_briefing` in state to today's date

#### Scenario: Briefing already sent today
- **WHEN** the `morning-briefing` SOP triggers AND a briefing has already been sent today
- **THEN** the SOP step SHALL complete with a skip note and the run SHALL mark as completed

#### Scenario: Before 06:30
- **WHEN** the SOP cron expression is configured
- **THEN** the cron expression SHALL NOT fire before 06:30 local time (expression: `30 6 * * *` with timezone `America/New_York`)

## ADDED Requirements

### Requirement: Session review SOP
The system SHALL run a session review SOP on a cron schedule that checks recent conversation history and updates workspace `MEMORY.md` if notable information was discussed.

#### Scenario: Session review finds notable content
- **WHEN** the `session-review` SOP fires and recent conversations contain notable information
- **THEN** the system SHALL update `MEMORY.md` in the workspace with relevant notes

#### Scenario: Session review finds nothing notable
- **WHEN** the `session-review` SOP fires and recent conversations are routine
- **THEN** the system SHALL complete the run with no workspace changes

### Requirement: Quiet hours SOP
The system SHALL have a `stay-quiet` SOP that enforces quiet behavior — no proactive outreach unless actionable alerts exist.

#### Scenario: No actionable alerts
- **WHEN** the `stay-quiet` SOP fires during its scheduled window
- **THEN** the system SHALL complete silently with no outbound messages

#### Scenario: Critical alert during quiet hours
- **WHEN** a critical weather alert or service failure is detected during the quiet window
- **THEN** the system SHALL bypass quiet hours and send an immediate alert (per existing critical weather alert requirement)
