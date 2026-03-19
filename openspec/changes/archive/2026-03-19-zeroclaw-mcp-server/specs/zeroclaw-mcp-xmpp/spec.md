## ADDED Requirements

### Requirement: Send XMPP message via MCP tool
The MCP server SHALL expose an `xmpp_send` tool that accepts a recipient JID and a message body, connects to the XMPP server, and sends the message.

#### Scenario: Send message to a MUC room
- **WHEN** the `xmpp_send` tool is called with recipient "room@conference.chat.example.net" and message "Hello everyone"
- **THEN** the server SHALL connect to the XMPP server using configured credentials, send the message to the specified MUC room, and return a success confirmation

#### Scenario: Send message to a user
- **WHEN** the `xmpp_send` tool is called with recipient "user@chat.example.net" and message "Direct message"
- **THEN** the server SHALL connect and send a direct message to the specified JID

#### Scenario: XMPP connection failure
- **WHEN** the `xmpp_send` tool is called and the XMPP server is unreachable
- **THEN** the server SHALL return an error message indicating the connection failed

### Requirement: XMPP credentials from environment
The MCP server SHALL read XMPP connection details from environment variables: `XMPP_JID`, `XMPP_PASSWORD`, `XMPP_HOST`, and `XMPP_PORT`.

#### Scenario: Missing XMPP credentials
- **WHEN** the MCP server starts without required XMPP environment variables
- **THEN** the XMPP tool SHALL be unavailable and the server SHALL log a warning, but other tools SHALL continue to function

### Requirement: Connect-per-invocation model
The MCP server SHALL establish a new XMPP connection for each send operation and disconnect after delivery, rather than maintaining a persistent connection.

#### Scenario: Sequential sends
- **WHEN** the `xmpp_send` tool is called twice in succession
- **THEN** each call SHALL independently connect, send, and disconnect
