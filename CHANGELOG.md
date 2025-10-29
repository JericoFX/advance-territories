# Changelog

## Unreleased
### Added
- Documented the territory state request flow and mermaid sequence diagram in `docs/request-flow.md`.
- Linked the main README to the new request flow documentation.
### Changed
- Reduced text UI flicker in territory zones by caching the last rendered message and only refreshing when values change.
- Reused the new territory creation logic for dynamically-added zones, including blip updates, to keep ox_lib callbacks consistent.
### Fixed
- Prevented duplicate capture point handlers and removed outdated network calls when adding territories at runtime.
- Added missing locale strings for capture notifications so player-facing messages render correctly.
