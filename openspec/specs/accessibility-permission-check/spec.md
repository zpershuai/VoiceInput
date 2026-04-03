# Accessibility Permission Check

## Purpose

Ensure VoiceInput has the necessary macOS Accessibility permissions to function correctly. The app requires Accessibility permissions to:
- Monitor global Fn key events for triggering voice input
- Inject transcribed text into other applications

This capability provides graceful handling when permissions are missing, guiding users through the permission grant process.

## Requirements

### Requirement: Detect missing Accessibility permissions at startup
The system SHALL check Accessibility permission status during application initialization before attempting to create the event tap.

#### Scenario: Permission already granted
- **WHEN** the application launches
- **AND** Accessibility permission has been previously granted
- **THEN** the application proceeds to start the GlobalEventMonitor normally
- **AND** no permission dialog is displayed

#### Scenario: Permission not granted
- **WHEN** the application launches
- **AND** Accessibility permission has not been granted
- **THEN** a blocking modal dialog SHALL be displayed
- **AND** the GlobalEventMonitor SHALL NOT attempt to create event tap

### Requirement: Display blocking permission dialog
The system SHALL display a modal dialog explaining the Accessibility permission requirement when permissions are missing.

#### Scenario: Dialog content
- **WHEN** the permission dialog is displayed
- **THEN** it SHALL include a title explaining the requirement
- **AND** it SHALL include descriptive text explaining why the permission is needed
- **AND** it SHALL include an "Open System Settings" button
- **AND** it SHALL include a "Quit" button

#### Scenario: Dialog matches app language
- **WHEN** the permission dialog is displayed
- **AND** the app language is set to Chinese
- **THEN** the dialog SHALL display Chinese text
- **WHEN** the app language is set to English
- **THEN** the dialog SHALL display English text

### Requirement: Navigate to System Settings
The system SHALL open System Settings to the Accessibility preferences when the user clicks "Open System Settings".

#### Scenario: Open System Settings
- **WHEN** the user clicks the "Open System Settings" button
- **THEN** the system SHALL open System Settings
- **AND** it SHALL navigate directly to Privacy & Security → Accessibility

### Requirement: Poll for permission changes
The system SHALL periodically check for permission status changes while the dialog is displayed.

#### Scenario: Permission granted while dialog visible
- **WHEN** the permission dialog is displayed
- **AND** the user grants Accessibility permission in System Settings
- **THEN** the system SHALL detect the permission change within 1 second
- **AND** the dialog SHALL automatically dismiss
- **AND** the GlobalEventMonitor SHALL start automatically

#### Scenario: Polling stops appropriately
- **WHEN** the permission is granted
- **THEN** polling SHALL stop
- **WHEN** the user clicks "Quit"
- **THEN** polling SHALL stop
- **AND** the application SHALL terminate

### Requirement: Provide permission check API
The system SHALL provide a programmatic API to check and request Accessibility permissions.

#### Scenario: Check permission status
- **WHEN** calling `GlobalEventMonitor.checkAccessibilityPermission()`
- **THEN** it SHALL return `true` if permission is granted
- **AND** it SHALL return `false` if permission is not granted

#### Scenario: Request permission
- **WHEN** calling `GlobalEventMonitor.requestAccessibilityPermission()`
- **THEN** it SHALL trigger the system permission prompt
- **AND** it SHALL return immediately (non-blocking)
