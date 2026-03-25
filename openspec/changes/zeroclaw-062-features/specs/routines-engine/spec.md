## ADDED Requirements

### Requirement: Routines configuration file
The system SHALL load automation routines from a `routines.toml` file in the workspace directory. Each routine SHALL define a trigger (cron, webhook, or channel pattern) and an action (SOP trigger, shell command, or message).

#### Scenario: Load routines from workspace
- **WHEN** ZeroClaw starts with a `routines.toml` file in the workspace
- **THEN** the routines engine SHALL parse and register all defined routines

#### Scenario: Invalid routines file
- **WHEN** `routines.toml` contains invalid syntax or unknown trigger types
- **THEN** the system SHALL log an error identifying the invalid routine and continue loading valid routines

### Requirement: Cron-triggered routines
The routines engine SHALL support cron expressions as triggers, dispatching the configured action on schedule.

#### Scenario: SOP dispatch via cron
- **WHEN** a routine defines `trigger = { cron = "0 7 * * *" }` and `action = { sop = "morning-briefing" }`
- **THEN** the routines engine SHALL trigger the `morning-briefing` SOP at 07:00 daily

#### Scenario: Cron routine with shell action
- **WHEN** a routine defines a cron trigger with `action = { shell = "curl -s https://example.com/health" }`
- **THEN** the routines engine SHALL execute the shell command on schedule and log the output

### Requirement: Webhook-triggered routines
The routines engine SHALL support webhook triggers that fire when the gateway receives a matching webhook request.

#### Scenario: Webhook triggers SOP
- **WHEN** a routine defines `trigger = { webhook = "/hooks/deploy" }` and the gateway receives a POST to that path
- **THEN** the routines engine SHALL execute the configured action with the webhook payload available as context

### Requirement: Channel-pattern-triggered routines
The routines engine SHALL support channel message pattern matching as triggers, firing when an inbound message matches the configured pattern.

#### Scenario: Pattern match triggers action
- **WHEN** a routine defines `trigger = { channel = "telegram", pattern = "^!deploy" }` and a Telegram message matching that pattern arrives
- **THEN** the routines engine SHALL execute the configured action before normal message processing
