## ADDED Requirements

### Requirement: Collapsible thinking/reasoning UI
The web channel SHALL render thinking/reasoning blocks in a collapsible UI element, allowing users to expand or collapse intermediate reasoning.

#### Scenario: Thinking blocks collapsed by default
- **WHEN** a response includes thinking/reasoning content in the web channel
- **THEN** the thinking content is rendered in a collapsed state with a toggle to expand

### Requirement: Markdown rendering in web chat
The web channel SHALL render markdown formatting in chat messages, including headers, lists, code blocks, and inline formatting.

#### Scenario: Code block rendered with syntax highlighting
- **WHEN** a response contains a fenced code block in the web channel
- **THEN** the code block is rendered with appropriate formatting and syntax highlighting

### Requirement: Responsive mobile sidebar
The web channel SHALL include a responsive sidebar with a hamburger toggle for mobile viewports.

#### Scenario: Sidebar collapses on mobile
- **WHEN** the web channel is viewed on a viewport narrower than 768px
- **THEN** the sidebar is hidden and a hamburger menu icon is displayed to toggle it
