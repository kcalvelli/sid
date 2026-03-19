## ADDED Requirements

### Requirement: List cron jobs via MCP tool
The MCP server SHALL expose a `cron_list` tool that retrieves all scheduled cron jobs by calling the ZeroClaw gateway's `GET /api/cron` endpoint.

#### Scenario: List existing cron jobs
- **WHEN** the `cron_list` tool is called
- **THEN** the server SHALL GET `{ZEROCLAW_GATEWAY_URL}/api/cron` and return the list of scheduled jobs with their IDs, schedules, and descriptions

#### Scenario: No cron jobs exist
- **WHEN** the `cron_list` tool is called and no jobs are scheduled
- **THEN** the server SHALL return an empty list or a message indicating no jobs are scheduled

### Requirement: Add cron job via MCP tool
The MCP server SHALL expose a `cron_add` tool that accepts a cron schedule expression, a message/prompt, and an optional description, and creates a new scheduled job by calling the ZeroClaw gateway's `POST /api/cron` endpoint.

#### Scenario: Add a recurring job
- **WHEN** the `cron_add` tool is called with schedule "0 9 * * *", message "Good morning check-in", and description "Daily morning greeting"
- **THEN** the server SHALL POST to `{ZEROCLAW_GATEWAY_URL}/api/cron` with the job payload and return the created job's ID and details

#### Scenario: Invalid cron expression
- **WHEN** the `cron_add` tool is called with an invalid schedule expression
- **THEN** the server SHALL forward the gateway's validation error and return a descriptive error message

### Requirement: Remove cron job via MCP tool
The MCP server SHALL expose a `cron_remove` tool that accepts a job ID and deletes the scheduled job by calling the ZeroClaw gateway's `DELETE /api/cron/{id}` endpoint.

#### Scenario: Remove an existing job
- **WHEN** the `cron_remove` tool is called with a valid job ID
- **THEN** the server SHALL DELETE `{ZEROCLAW_GATEWAY_URL}/api/cron/{id}` and return a success confirmation

#### Scenario: Remove a nonexistent job
- **WHEN** the `cron_remove` tool is called with an ID that does not exist
- **THEN** the server SHALL forward the gateway's error response and return an appropriate message

### Requirement: Run cron job immediately via MCP tool
The MCP server SHALL expose a `cron_run` tool that accepts a job ID and triggers immediate execution by calling the ZeroClaw gateway's `POST /api/cron/{id}/run` endpoint.

#### Scenario: Trigger immediate execution
- **WHEN** the `cron_run` tool is called with a valid job ID
- **THEN** the server SHALL POST to `{ZEROCLAW_GATEWAY_URL}/api/cron/{id}/run` and return the execution result

### Requirement: Bearer token authentication for cron endpoints
All cron tool calls to the gateway SHALL include an `Authorization: Bearer {ZEROCLAW_GATEWAY_TOKEN}` header.

#### Scenario: Authenticated cron request
- **WHEN** any cron tool makes a request to the gateway
- **THEN** the request SHALL include the `Authorization: Bearer {token}` header from `ZEROCLAW_GATEWAY_TOKEN`
