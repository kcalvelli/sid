## ADDED Requirements

### Requirement: llm-task tool registration
The `llm_task` tool SHALL be registered in the gateway configuration, making it available to the agent for lightweight sub-agent calls.

#### Scenario: Tool available to agent
- **WHEN** ZeroClaw starts with the llm-task tool registered in config
- **THEN** the agent SHALL be able to invoke `llm_task` during conversations

### Requirement: Structured JSON-only output
The `llm_task` tool SHALL accept a prompt and return structured JSON output, without requiring a full agent loop or tool access.

#### Scenario: JSON extraction task
- **WHEN** the agent calls `llm_task` with a prompt requesting structured data extraction
- **THEN** the tool SHALL return a JSON response from a lightweight LLM call without granting the sub-call access to tools

#### Scenario: Invalid JSON from sub-call
- **WHEN** the LLM sub-call produces output that is not valid JSON
- **THEN** the tool SHALL return an error indicating the response could not be parsed as JSON
