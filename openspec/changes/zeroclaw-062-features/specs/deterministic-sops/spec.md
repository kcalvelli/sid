## ADDED Requirements

### Requirement: Deterministic execution mode
SOPs with `deterministic = true` in their definition SHALL execute step-by-step without LLM round-trips, following steps in strict sequence.

#### Scenario: Deterministic SOP executes without LLM
- **WHEN** a SOP with `deterministic = true` is triggered
- **THEN** the system SHALL execute each step in order using direct tool calls, without invoking the LLM to interpret or decide between steps

#### Scenario: Non-deterministic SOP unaffected
- **WHEN** a SOP without `deterministic = true` (or with `deterministic = false`) is triggered
- **THEN** the system SHALL execute it using the existing LLM-driven execution flow

### Requirement: Checkpoint steps for human approval
Deterministic SOPs SHALL support checkpoint steps that pause execution and require human approval before continuing.

#### Scenario: Checkpoint pauses execution
- **WHEN** a deterministic SOP reaches a step with `checkpoint = true`
- **THEN** execution SHALL pause and the system SHALL notify the user (via the originating channel or configured notification method) requesting approval to continue

#### Scenario: Checkpoint approved
- **WHEN** a user approves a checkpoint
- **THEN** execution SHALL resume from the next step

#### Scenario: Checkpoint rejected
- **WHEN** a user rejects a checkpoint
- **THEN** execution SHALL stop and the system SHALL log the rejection with the step name

### Requirement: Initial deterministic SOP candidate
The `stay-quiet` SOP SHALL be configured with `deterministic = true` as the initial test of deterministic execution mode.

#### Scenario: Stay-quiet runs deterministically
- **WHEN** the `stay-quiet` SOP is triggered
- **THEN** it SHALL execute its alert-checking steps deterministically without LLM round-trips
