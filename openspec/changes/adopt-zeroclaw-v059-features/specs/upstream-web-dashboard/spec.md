## ADDED Requirements

### Requirement: Upstream React dashboard replaces sid-dashboard
The system SHALL use the upstream ZeroClaw React 19 web dashboard embedded in the gateway binary, replacing the custom Python `sid-dashboard` service.

#### Scenario: Dashboard accessible via gateway port
- **WHEN** a user navigates to `http://<host>:18789/` in a browser
- **THEN** the upstream React dashboard SHALL be served with full functionality (chat, memory, cron, config, cost, logs, tools, diagnostics, integrations, canvas, pairing)

#### Scenario: sid-dashboard service removed
- **WHEN** the NixOS configuration is deployed
- **THEN** no `sid-dashboard` systemd service SHALL exist, no port 8080 SHALL be opened, and no `dashboard.*` module options SHALL be available

### Requirement: sid-dashboard package and source removed
The `sid-dashboard` flake package definition and `dashboard/` source directory SHALL be removed from the repository.

#### Scenario: Flake packages do not include sid-dashboard
- **WHEN** `nix flake show` is run
- **THEN** the output SHALL NOT include a `sid-dashboard` package

#### Scenario: Dashboard directory removed
- **WHEN** the repository is checked
- **THEN** the `dashboard/` directory SHALL NOT exist
