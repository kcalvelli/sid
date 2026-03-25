## ADDED Requirements

### Requirement: Haiku worker delegate agent
The system SHALL configure a `worker` delegate agent using Anthropic native provider with Claude Haiku 4.5 for structured task execution.

#### Scenario: Worker executes with ZeroClaw tools
- **WHEN** a swarm or SOP dispatches to the worker agent
- **THEN** the worker SHALL have access to ZeroClaw's full tool registry (shell, web_fetch, email, memory, mcp_gateway, cron, xmpp) via native tool calling

#### Scenario: Worker uses minimal persona
- **WHEN** the worker agent is invoked
- **THEN** its system prompt SHALL be a brief operational directive without personality ("You are a task executor. Execute the requested task precisely. Return structured results.")

### Requirement: Sonnet researcher delegate agent
The system SHALL configure a `researcher` delegate agent using Anthropic native provider with Claude Sonnet 4.6 for tasks requiring judgment.

#### Scenario: Researcher used for memory writes
- **WHEN** a task involves writing to persistent state (workspace files, memory store)
- **THEN** the researcher agent SHALL be used instead of the worker agent

#### Scenario: Researcher used for user-facing content
- **WHEN** a task produces content delivered directly to the user (briefing emails)
- **THEN** the researcher agent SHALL be used with a Sid-lite system prompt (stripped-down persona for voice consistency)

### Requirement: Delegate agents use Anthropic API key
Both delegate agents SHALL authenticate via the Anthropic API key (not the subscription/OAuth token used by claude-code).

#### Scenario: API key configured via agenix
- **WHEN** the NixOS module deploys
- **THEN** the Anthropic API key SHALL be available in the ZeroClaw environment and referenced in delegate agent config
