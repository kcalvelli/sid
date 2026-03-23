## ADDED Requirements

### Requirement: canvas_update MCP tool
The zeroclaw-mcp server SHALL expose a `canvas_update` tool that pushes an HTML frame to the ZeroClaw dashboard canvas.

#### Scenario: Push HTML to default canvas
- **WHEN** Sid calls `canvas_update(html="<div>...</div>")`
- **THEN** the MCP server SHALL POST the HTML content to the gateway's canvas endpoint and the dashboard SHALL render it in real-time

#### Scenario: Push to named canvas
- **WHEN** Sid calls `canvas_update(html="...", canvas_id="weather")`
- **THEN** the frame SHALL be pushed to the specified canvas ID, allowing multiple independent canvas views

#### Scenario: Clear canvas
- **WHEN** Sid calls `canvas_update(html="", canvas_id="weather")`
- **THEN** the specified canvas SHALL be cleared

### Requirement: canvas_update supports iterative rendering
Sid SHALL be able to call `canvas_update` multiple times in succession to iterate on visual output during a conversation.

#### Scenario: Iterative design feedback
- **WHEN** Sid pushes a frame, user gives feedback, Sid pushes an updated frame
- **THEN** each push SHALL replace the previous frame on the same canvas_id with no accumulation
