## ADDED Requirements

### Requirement: WebSocket subprotocol validation
The canvas WebSocket connection (patch 0016) SHALL be validated post-deploy to confirm RFC 6455 compliance — specifically that the server echoes the `Sec-WebSocket-Protocol` header in the 101 response.

#### Scenario: WebSocket handshake with subprotocol
- **WHEN** a client connects to the canvas WebSocket endpoint with `Sec-WebSocket-Protocol: canvas-v1`
- **THEN** the server's 101 response SHALL include `Sec-WebSocket-Protocol: canvas-v1`

#### Scenario: Canvas renders after WebSocket fix
- **WHEN** Sid calls `canvas_update` with HTML content after the patch 0016 fix is deployed
- **THEN** the dashboard canvas SHALL render the content in real-time without WebSocket connection failures

#### Scenario: Multiple canvas sessions
- **WHEN** multiple browser tabs connect to different canvas IDs simultaneously
- **THEN** each tab SHALL maintain an independent WebSocket connection and receive updates only for its canvas ID
