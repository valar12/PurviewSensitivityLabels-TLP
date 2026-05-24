# Changelog

## v1.2.0 - 2026-05-24

### Added
- Dry-run drift detection via `-DryRun` and CI-gating via `-FailOnDrift`.
- Structured execution report output `TlpLabelExecutionReport.json`.
- Configuration governance metadata: `ConfigVersion`, `Owner`, `LastReviewed`, `ChangeTicket`.
- Additional config schema checks for required fields and allowed enum values.
- Prerequisite command checks through `Test-TlpPrerequisites`.
- Retry wrapper `Invoke-WithRetry` for transient label command failures.

### Changed
- Expanded validation coverage to include priority/comment/tooltip and container controls.

## v1.1.0 - 2026-05-24

### Added
- `TlpLabelConfig.json` as the primary source of customizations for defaults, label metadata, encryption, container controls, and validation expectations.
- `Get-TlpConfiguration` helper to validate and load JSON configuration.

### Changed
- Main script now supports `-ConfigurationPath` and applies labels from JSON instead of static inline values.

## v1.0.0 - 2026-05-24

### Added
- Modular helper library `TlpLabelModule.ps1` to separate session/connect, label mutation, and validation responsibilities.
- Formal release baseline for TLP 2.0 Purview label automation.

### Changed
- Main script now orchestrates module functions rather than carrying all logic inline.
- Retained fail-fast behavior and post-apply validation checks for critical encryption/header properties.
