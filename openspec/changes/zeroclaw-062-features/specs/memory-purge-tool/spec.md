## ADDED Requirements

### Requirement: memory-purge tool registration
The `memory_purge` tool SHALL be registered in the gateway configuration, making it available to the agent for memory cleanup operations.

#### Scenario: Tool available to agent
- **WHEN** ZeroClaw starts with the memory-purge tool registered in config
- **THEN** the agent SHALL be able to invoke `memory_purge` during conversations

### Requirement: Memory cleanup capability
The `memory_purge` tool SHALL allow the agent to remove stale, duplicate, or irrelevant memories from the memory backend.

#### Scenario: Purge by query
- **WHEN** the agent calls `memory_purge` with a query or filter criteria
- **THEN** matching memories SHALL be removed from the SQLite memory backend and the tool SHALL return the count of purged entries

#### Scenario: Purge confirmation
- **WHEN** the agent calls `memory_purge`
- **THEN** the tool SHALL return a summary of what was purged (count and categories) for the agent to report to the user
