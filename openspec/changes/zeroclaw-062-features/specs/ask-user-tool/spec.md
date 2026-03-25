## ADDED Requirements

### Requirement: ask-user tool registration
The `ask_user` tool SHALL be registered in the gateway configuration, making it available to the agent for interactive user prompting.

#### Scenario: Tool available to agent
- **WHEN** ZeroClaw starts with the ask-user tool registered in config
- **THEN** the agent SHALL be able to invoke `ask_user` during conversations and SOP execution

### Requirement: Cross-channel user prompting
The `ask_user` tool SHALL send a prompt to the user and wait for a response, working across any active channel (Telegram, XMPP, CLI, email).

#### Scenario: Prompt via originating channel
- **WHEN** the agent calls `ask_user` with a question during a Telegram conversation
- **THEN** the prompt SHALL be sent to the user via Telegram and the tool SHALL return the user's response

#### Scenario: Prompt during autonomous SOP execution
- **WHEN** the agent calls `ask_user` during an autonomously-executing SOP (no active conversation)
- **THEN** the prompt SHALL be sent via the configured default notification channel and the tool SHALL wait for a response

#### Scenario: Timeout on no response
- **WHEN** the user does not respond within the configured timeout
- **THEN** the tool SHALL return a timeout indicator so the agent can decide how to proceed
