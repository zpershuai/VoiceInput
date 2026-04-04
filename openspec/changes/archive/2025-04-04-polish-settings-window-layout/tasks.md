## 1. Settings Window Layout

- [x] 1.1 Inspect `SettingsWindow.swift` layout constants and identify the current top inset, section spacing, and footer button positioning that cause excessive whitespace and clipping
- [x] 1.2 Adjust the Settings window geometry and vertical spacing so the `General` section starts closer to the top and sections maintain a clean, compact rhythm
- [x] 1.3 Update the bottom action area so `Test` and `Save` are fully visible and remain aligned with the rest of the form without introducing a larger redesign

## 2. Status Menu Consistency

- [x] 2.1 Update the status bar menu construction in `AppDelegate.swift` so `Settings...` is rendered without a leading icon while keeping its existing action and shortcut

## 3. Manual Verification

- [x] 3.1 Launch the app and verify the Settings window opens with improved top spacing and intact section readability
- [x] 3.2 Verify the `Test` and `Save` buttons are fully visible and clickable in the default window size
- [x] 3.3 Verify the status bar menu shows `Settings...` without an icon and that `Language`, `Settings...`, and `Quit` remain visually consistent
