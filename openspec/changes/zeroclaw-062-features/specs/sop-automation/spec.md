## ADDED Requirements

### Requirement: SOP cron dispatch via routines engine
SOP cron triggers SHALL be implemented through the routines engine rather than direct gateway scheduler integration. Each SOP with a cron schedule SHALL have a corresponding routine in `routines.toml`.

#### Scenario: Morning briefing cron dispatch
- **WHEN** `routines.toml` defines a routine with `trigger = { cron = "0 7 * * *" }` and `action = { sop = "morning-briefing" }`
- **THEN** the routines engine SHALL trigger the morning-briefing SOP at 07:00 daily using its configured provider and model

#### Scenario: Session review cron dispatch
- **WHEN** `routines.toml` defines a routine with a cron trigger for session-review
- **THEN** the routines engine SHALL trigger the session-review SOP on schedule

#### Scenario: Stay-quiet periodic check
- **WHEN** `routines.toml` defines a routine with a frequent cron trigger for stay-quiet
- **THEN** the routines engine SHALL trigger the stay-quiet SOP on the configured interval
