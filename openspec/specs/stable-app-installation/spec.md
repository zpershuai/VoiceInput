# Stable App Installation

## Purpose

Ensure that VoiceInput installations to `/Applications` maintain a stable app identity for macOS Accessibility trust persistence. When the app is reinstalled during development cycles, existing Accessibility permissions should remain valid without requiring users to delete and re-add the app in System Settings.

## Requirements

### Requirement: Supported `/Applications` installs preserve app identity
The system SHALL provide a supported installation path for `/Applications/VoiceInput.app` that preserves a stable app identity across normal rebuild and reinstall cycles used for Accessibility-enabled runs.

#### Scenario: Reinstall over an existing trusted app
- **WHEN** the developer rebuilds VoiceInput and reinstalls it to `/Applications/VoiceInput.app` using the supported install flow
- **THEN** the installed app SHALL keep the same bundle identifier
- **AND** the install flow SHALL use the configured stable signing identity required by that flow
- **AND** the install flow SHALL replace the target bundle in a controlled way suitable for macOS app bundles

### Requirement: Unsupported installs are surfaced clearly
The system SHALL surface when an install flow cannot guarantee stable Accessibility trust persistence.

#### Scenario: Stable signing identity is unavailable
- **WHEN** the developer runs the supported install flow without the required stable signing identity configuration
- **THEN** the install flow SHALL fail fast or emit a clear warning before installation completes
- **AND** it SHALL state that Accessibility permission persistence across reinstalls is not guaranteed for that build

### Requirement: Install diagnostics are available
The system SHALL log or print the identity details needed to diagnose repeated Accessibility reauthorization after installation.

#### Scenario: Install completes
- **WHEN** the supported install flow finishes
- **THEN** it SHALL report the app bundle path being installed
- **AND** it SHALL report the bundle identifier
- **AND** it SHALL report the signing mode or identity used for that install
