## ADDED Requirements

### Requirement: Tauri desktop app evaluation
The upstream ZeroClaw Tauri desktop app SHALL be evaluated for build feasibility and value-add over the existing web canvas UI.

#### Scenario: Build attempt
- **WHEN** the Tauri app from upstream ZeroClaw `apps/tauri` is built using the Sid project's Nix toolchain
- **THEN** the build result (success/failure), required dependencies, and any patches needed SHALL be documented

#### Scenario: Value assessment
- **WHEN** the Tauri app builds successfully
- **THEN** it SHALL be compared against the web canvas UI on: native OS integration, performance, notification support, and offline capability

### Requirement: Evaluation findings documented
The evaluation SHALL produce a written assessment with a recommendation on whether to include the Tauri desktop app in the Sid deployment.

#### Scenario: Findings recorded
- **WHEN** the evaluation is complete
- **THEN** a document SHALL record: build status, feature comparison vs web canvas, maintenance burden, and go/no-go recommendation
