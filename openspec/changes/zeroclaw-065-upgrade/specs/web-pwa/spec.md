## MODIFIED Requirements

### Requirement: Web app manifest for installability
The web UI SHALL include a `manifest.json` served at `/_app/manifest.json`. The `npmDepsHash` SHALL be updated to match v0.6.5's `package-lock.json`. The PWA overlay (manifest, service worker, icons, registration module) SHALL continue to be injected via `postPatch` in the `zeroclaw-web` derivation.

#### Scenario: PWA overlay applied to v0.6.5 web source
- **WHEN** the `zeroclaw-web` derivation builds against v0.6.5
- **THEN** the PWA files SHALL be injected into the build and the resulting dist SHALL include `manifest.json`, `service-worker.js`, and icon files

#### Scenario: npmDepsHash matches v0.6.5
- **WHEN** the npm install phase runs
- **THEN** it SHALL succeed with the updated hash matching v0.6.5's dependency tree
