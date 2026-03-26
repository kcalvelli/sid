## ADDED Requirements

### Requirement: Report template engine as standalone tool
The system SHALL expose a `report_template` tool that renders structured reports from templates, usable by SOPs and agents.

#### Scenario: Morning briefing uses report template
- **WHEN** the morning-briefing SOP invokes `report_template` with a template name and data
- **THEN** the tool renders a formatted report using the template and returns the result

#### Scenario: Tool available in tool registry
- **WHEN** the ZeroClaw tool registry is loaded
- **THEN** `report_template` is listed as an available tool
