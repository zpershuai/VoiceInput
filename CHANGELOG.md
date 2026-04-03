# Changelog

## 2026-04-03

- Added startup Accessibility permission checks before initializing the global Fn-key monitor.
- Added a blocking permission dialog with localized Chinese and English copy, direct System Settings navigation, and automatic polling for granted permission.
- Delayed event-monitor startup until Accessibility permission is available, then started it automatically once granted.
