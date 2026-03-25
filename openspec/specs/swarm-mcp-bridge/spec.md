## ADDED Requirements

### Requirement: swarm_invoke MCP tool
The zeroclaw-mcp server SHALL expose a `swarm_invoke` tool that dispatches a prompt to a named ZeroClaw swarm and returns the result.

#### Scenario: Successful swarm dispatch
- **WHEN** Sid calls `swarm_invoke(swarm="briefing", prompt="Gather today's calendar and weather")`
- **THEN** the MCP server SHALL POST to the gateway's swarm endpoint, wait for completion, and return structured results including step outputs and any errors

#### Scenario: Swarm not found
- **WHEN** Sid calls `swarm_invoke` with a swarm name that doesn't exist in config
- **THEN** the tool SHALL return an error message naming the unknown swarm and listing available swarms

#### Scenario: Worker failure within swarm
- **WHEN** a worker agent within the swarm fails during execution
- **THEN** the tool SHALL return the error context (step name, tool that failed, error message) so Sid can report meaningfully to the user

### Requirement: swarm_invoke returns structured output
The `swarm_invoke` tool SHALL return results as structured data (JSON) including agent outputs, duration, and status, not raw prose.

#### Scenario: Sequential swarm completes
- **WHEN** a sequential swarm completes all agents
- **THEN** the result SHALL include each agent's output in order, total duration, and overall status (success/partial/failed)
