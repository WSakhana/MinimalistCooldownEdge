# Changelog

## [1.5] - 2026-01-26
### Added
- **Category-Based Styling:** Introduced independent configuration profiles. You can now set distinct styles (Font, Size, Edge Scale) for:
  - Action Bars (Spells)
  - Nameplates
  - Unit Frames
  - Global/Others (Items, Bags, Auras)
- **Deep Scan Heuristic:** Implemented a robust parent-detection algorithm in `Core.lua` that scans up to 20 levels of hierarchy. This ensures proper detection of cooldowns inside complex addon structures (e.g., Plater, ElvUI, VuhDo).

### Changed
- **GUI Overhaul:** Added a "Select Category" dropdown to the options panel, allowing real-time switching between configuration profiles.
- **Optimization:** Added a CPU-efficient "Fast Return" check for standard Blizzard Buff/Debuff buttons to bypass deep scanning and save performance.
- Merged "Auras" configuration into the "Global/Others" category for a streamlined user experience.
- Refactored `Config.lua` to support nested tables for category-specific SavedVariables.

### Fixed
- Fixed an issue where styles failed to apply to nested frames (specifically Nameplates and UnitFrames) because the addon could not identify the parent container.

## [1.4] - 2026-01-26
### Changed
- **Major Refactor:** Completely rewrote the hooking mechanism to avoid "Taint" errors. [cite_start]The addon now targets generic `CooldownFrame` events instead of invasive `ActionButton` hooks. [cite: 1]
- [cite_start]Implemented `C_Timer.After` execution delays (0-frame delay) to ensure style application never interferes with Blizzard's Secure Execution Path. [cite: 1]
- [cite_start]Enhanced compatibility with **Bartender4** and other addons using `LibActionButton-1.0`. [cite: 1]
- [cite_start]Replaced unsafe `ActionBarController_UpdateAll` calls with a custom, non-tainting manual refresh method. [cite: 1]

### Fixed
- [cite_start]Resolved critical `ADDON_ACTION_BLOCKED` errors that were breaking Stance/Shape-shift bars. [cite: 1]
- [cite_start]Fixed `attempt to compare a secret value` Lua errors caused by modifying secure action buttons during updates. [cite: 1]
- [cite_start]Fixed a crash when attempting to open the Options Panel (`/mce`) while in combat; the command now checks for `InCombatLockdown()` properly. [cite: 1]

## [1.3] - 2026-01-26
### Changed
- [cite_start]Updated version to 1.3 in .toc and GUI. [cite: 1]
- [cite_start]Improved event-driven initialization and hook logic in `Core.lua` for better compatibility and reliability. [cite: 1]
- [cite_start]Replaced bulk cooldown apply with robust hooks for `CooldownFrame_Set`, `CooldownFrame_SetTimer`, and `ActionButton_UpdateCooldown`. [cite: 1]
- [cite_start]GUI now uses a `RefreshVisuals()` helper for immediate updates when settings change. [cite: 1]

## [1.2] - 2026-01-25
### Added
- [cite_start]Configuration system with SavedVariables support (`Config.lua`) [cite: 1]
  - [cite_start]Persistent settings across game sessions via `MinimalistCooldownEdgeDB` [cite: 1]
  - [cite_start]Default configuration with deep copy for missing values [cite: 1]
- [cite_start]In-game GUI options panel (`GUI.lua`) [cite: 1]
  - [cite_start]Font customization (dropdown with 7 font options) [cite: 1]
  - [cite_start]Font size slider (8-36) [cite: 1]
  - [cite_start]Font style options (Outline, Thick Outline, Monochrome, None) [cite: 1]
  - [cite_start]Text color picker with opacity support [cite: 1]
  - [cite_start]Edge enable/disable toggle [cite: 1]
  - [cite_start]Edge scale slider (0.5-2.0) [cite: 1]
  - [cite_start]Reset to defaults button [cite: 1]
  - [cite_start]Reload UI button [cite: 1]
- [cite_start]Slash commands: `/mce` and `/minimalistcooldownedge` [cite: 1]
- [cite_start]Support for all action bar types (MultiBar1-7) [cite: 1]

### Changed
- [cite_start]Refactored `Core.lua` to use configuration system [cite: 1]
  - [cite_start]Replaced hardcoded values with dynamic config retrieval [cite: 1]
  - [cite_start]Separated apply logic into `ApplyCustomStyle()` function [cite: 1]
  - [cite_start]Added `ApplyAllCooldowns()` function for bulk updates [cite: 1]
  - [cite_start]Proper event-driven initialization with `ADDON_LOADED` and `PLAYER_LOGIN` [cite: 1]
- [cite_start]Updated `.toc` file structure [cite: 1]
  - [cite_start]Added `SavedVariables: MinimalistCooldownEdgeDB` [cite: 1]
  - [cite_start]Added `Config.lua` and `GUI.lua` to file list [cite: 1]
  - [cite_start]Version bumped to 1.2 [cite: 1]

### Fixed
- [cite_start]Settings now apply to all visible cooldowns on load [cite: 1]
- [cite_start]Edge settings now properly toggleable [cite: 1]

## [1.1] - 2026-01-25
### Changed
- [cite_start]Translated all code comments and print messages to English. [cite: 1]
- [cite_start]Updated `.toc` metadata: [cite: 1]
  - [cite_start]Added colored title for better visibility in the addon list. [cite: 1]
  - [cite_start]Added an icon texture. [cite: 1]
- [cite_start]Improved Cooldown Text styling: [cite: 1]
  - [cite_start]Now sets custom font, size, and color for cooldown timers using `GetRegions`. [cite: 1]
  - [cite_start]Ensures native cooldown numbers are shown via `SetHideCountdownNumbers(false)`. [cite: 1]

## [1.0] - 2025-01-25
### Added
- [cite_start]Initial release. [cite: 1]
- [cite_start]Custom texture for cooldown edges (`EdgeTexture`). [cite: 1]
- [cite_start]Customized swipe color (`SwipeColor`). [cite: 1]
- [cite_start]"Bling" effect enabled for finished cooldowns. [cite: 1]
- [cite_start]Basic hooks for `ActionButton_UpdateCooldown` and `CooldownFrame_SetDrawEdge`. [cite: 1]