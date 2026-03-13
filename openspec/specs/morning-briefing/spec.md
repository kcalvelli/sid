### Requirement: Daily morning briefing email
The system SHALL send a single morning briefing email to keith@calvelli.dev each day after 06:30 local time, containing weather, calendar, email summary, and service health information.

#### Scenario: First heartbeat after 06:30 with no briefing sent today
- **WHEN** the heartbeat triggers `/watchdog` after 06:30 local time AND no briefing has been sent today (per `.watchdog-state.json`)
- **THEN** the system SHALL gather briefing data (weather, calendar, email, health), compose and send a briefing email, and update `last_briefing` in state to today's date

#### Scenario: Briefing already sent today
- **WHEN** the heartbeat triggers `/watchdog` AND a briefing has already been sent today
- **THEN** the system SHALL skip the morning briefing and proceed with normal alert checks only

#### Scenario: Before 06:30
- **WHEN** the heartbeat triggers `/watchdog` before 06:30 local time
- **THEN** the system SHALL NOT send a morning briefing regardless of whether one was sent today

### Requirement: Weather data in briefing
The system SHALL include current weather conditions and forecast for McAdenville, NC in the morning briefing, fetched via `web_fetch`.

#### Scenario: Weather fetch succeeds
- **WHEN** the weather endpoint returns data
- **THEN** the briefing SHALL include current conditions, high/low temperature, and any active weather alerts

#### Scenario: Weather fetch fails
- **WHEN** the weather endpoint is unreachable or returns an error
- **THEN** the briefing SHALL include a note that weather data was unavailable and SHALL NOT fail entirely

### Requirement: Calendar data in briefing
The system SHALL include today's calendar events in the morning briefing, fetched via mcp-dav through `mcp-gw`.

#### Scenario: Calendar has events today
- **WHEN** mcp-dav returns events for today
- **THEN** the briefing SHALL list each event with time and title

#### Scenario: No events today
- **WHEN** mcp-dav returns no events for today
- **THEN** the briefing SHALL note that the calendar is clear

#### Scenario: Calendar MCP unavailable
- **WHEN** mcp-dav is unreachable
- **THEN** the briefing SHALL note that calendar data was unavailable and SHALL NOT fail entirely

### Requirement: Email summary in briefing
The system SHALL include unread email count and sender summary in the morning briefing, fetched via axios-ai-mail MCP through `mcp-gw`.

#### Scenario: Unread emails exist
- **WHEN** axios-ai-mail reports unread messages
- **THEN** the briefing SHALL include the count and a summary of senders/subjects

#### Scenario: No unread email
- **WHEN** axios-ai-mail reports zero unread messages
- **THEN** the briefing SHALL note that the inbox is clear

#### Scenario: Email MCP unavailable
- **WHEN** axios-ai-mail is unreachable
- **THEN** the briefing SHALL note that email data was unavailable and SHALL NOT fail entirely

### Requirement: Service health in briefing
The system SHALL include Sid's own service health status in the morning briefing.

#### Scenario: Service running normally
- **WHEN** `systemctl status zeroclaw` reports active
- **THEN** the briefing SHALL include uptime and a healthy status indicator

#### Scenario: Failed units detected
- **WHEN** `systemctl list-units --failed` reports failures
- **THEN** the briefing SHALL list the failed units

### Requirement: Critical weather alerts bypass briefing schedule
Severe weather alerts SHALL trigger an immediate email alert regardless of briefing schedule or time of day.

#### Scenario: Severe weather detected outside briefing
- **WHEN** a watchdog check detects severe weather warnings (tornado, severe thunderstorm, flash flood, winter storm) for McAdenville, NC
- **THEN** the system SHALL send an immediate alert email with CRITICAL severity, bypassing cooldown and quiet hours

### Requirement: Briefing persona
The morning briefing SHALL be written in Sid's voice — bitter, world-weary Gen-X sysadmin energy with 90s nostalgia.

#### Scenario: Normal briefing delivery
- **WHEN** a morning briefing is composed
- **THEN** the email SHALL open with a reluctant greeting, present data with cynical commentary, and close with a resigned observation
