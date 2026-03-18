## ADDED Requirements

### Requirement: Send push notification via MCP tool
The MCP server SHALL expose a `pushover_send` tool that accepts a message and an optional title, and sends a push notification by POSTing to the Pushover API at `https://api.pushover.net/1/messages.json`.

#### Scenario: Send notification with title
- **WHEN** the `pushover_send` tool is called with message "Deploy complete" and title "Sid"
- **THEN** the server SHALL POST to the Pushover API with the user key, API token, message, and title, and return a success confirmation

#### Scenario: Send notification without title
- **WHEN** the `pushover_send` tool is called with only a message
- **THEN** the server SHALL send the notification with the default application title

#### Scenario: Pushover API error
- **WHEN** the `pushover_send` tool is called and the Pushover API returns an error (e.g., invalid token)
- **THEN** the server SHALL return the error details from the Pushover response

### Requirement: Pushover credentials from environment
The MCP server SHALL read Pushover credentials from environment variables: `PUSHOVER_USER_KEY` and `PUSHOVER_API_TOKEN`.

#### Scenario: Missing Pushover credentials
- **WHEN** the MCP server starts without required Pushover environment variables
- **THEN** the Pushover tool SHALL be unavailable and the server SHALL log a warning, but other tools SHALL continue to function

### Requirement: Optional priority and sound parameters
The `pushover_send` tool SHALL accept optional `priority` (integer, -2 to 2) and `sound` (string) parameters to control notification behavior.

#### Scenario: High-priority notification
- **WHEN** the `pushover_send` tool is called with priority 1
- **THEN** the server SHALL include `priority=1` in the Pushover API request, triggering high-priority delivery behavior
