## ADDED Requirements

### Requirement: Log export systemd service runs as root
The system SHALL provide a `sid-log-export.service` oneshot systemd unit that runs as root. The service SHALL collect the last 24 hours of priority 0-4 system logs from journalctl, filter for kernel, thermald, smartd, and failed unit entries, and write the output to `/var/lib/sid/.local/share/sid/watchdog.log`. The file SHALL be chowned to `sid:sid` after writing.

#### Scenario: Log file is written with system logs
- **WHEN** `systemctl start sid-log-export` is executed
- **THEN** `/var/lib/sid/.local/share/sid/watchdog.log` exists containing filtered journal entries from the last 24 hours, owned by `sid:sid`

#### Scenario: Log file contains only relevant entries
- **WHEN** the watchdog.log is read
- **THEN** it contains only priority 0-4 entries matching kernel, thermald, smartd, or failed unit patterns

### Requirement: Log export timer fires periodically
The system SHALL provide a `sid-log-export.timer` that triggers the log export service on boot (5 min delay) and every 15 minutes thereafter.

#### Scenario: Timer activates on schedule
- **WHEN** the system has been running for 20 minutes
- **THEN** the `sid-log-export.service` has run at least once

#### Scenario: Timer is enabled by default
- **WHEN** the NixOS configuration is activated
- **THEN** `sid-log-export.timer` is enabled and started

### Requirement: Log directory created by activation script
The NixOS activation script SHALL create `/var/lib/sid/.local/share/sid/` owned by `sid:sid` so the log export service has a target directory.

#### Scenario: Log directory exists before first timer run
- **WHEN** the NixOS activation script completes
- **THEN** `/var/lib/sid/.local/share/sid/` exists with owner `sid:sid`
