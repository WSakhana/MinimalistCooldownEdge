# Changelog

## [1.8] - 2026-01-27
### Fixed
- **Glider Compatibility:** Fixed an issue where enabling the "Global" category would incorrectly attach cooldown styles to the **Glider** addon's speedometer.
- **Hardcoded Blacklist:** Implemented a blacklist system in `Core.lua`. The addon now immediately ignores frames containing specific keywords (currently "Glider") during the detection scan. This prevents interference with incompatible addons and reduces CPU usage by skipping them entirely.

## [1.7] - 2026-01-26
### Optimization
- **Critical Performance Boost (Caching):** Implemented a smart caching system in `Core.lua`. The addon now remembers the category of a cooldown frame after the first scan. This changes the complexity from O(N) to O(1) for subsequent updates, drastically reducing CPU usage during heavy combat or in crowded raids.
- **Garbage Collection:** Used weak tables for the cache to ensure memory is properly released when frames are hidden or destroyed.

## [1.6] - 2026-01-26
### Added
- **Smart Reload Logic:** The options panel now automatically detects when "Global" settings (like Scan Depth) change or when a category is disabled. A popup will appear prompting for a UI Reload, which is required to fully revert styles or update deep scan rules.

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
- **Major Refactor:** Completely rewrote the hooking mechanism to avoid "Taint" errors. The addon now targets generic `CooldownFrame` events instead of invasive `ActionButton` hooks.
- Implemented `C_Timer.After` execution delays (0-frame delay) to ensure style application never interferes with Blizzard's Secure Execution Path.
- Enhanced compatibility with **Bartender4** and other addons using `LibActionButton-1.0`.
- Replaced unsafe `ActionBarController_UpdateAll` calls with a custom, non-tainting manual refresh method.

### Fixed
- Resolved critical `ADDON_ACTION_BLOCKED` errors that were breaking Stance/Shape-shift bars.
- Fixed `attempt to compare a secret value` Lua errors caused by modifying secure action buttons during updates.
- Fixed a crash when attempting to open the Options Panel (`/mce`) while in combat; the command now checks for `InCombatLockdown()` properly.

## [1.3] - 2026-01-26
### Changed
- Updated version to 1.3 in .toc and GUI.
- Improved event-driven initialization and hook logic in `Core.lua` for better compatibility and reliability.
- Replaced bulk cooldown apply with robust hooks for `CooldownFrame_Set`, `CooldownFrame_SetTimer`, and `ActionButton_UpdateCooldown`.
- GUI now uses a `RefreshVisuals()` helper for immediate updates when settings change.

## [1.2] - 2026-01-25
### Added
- Configuration system with SavedVariables support (`Config.lua`)
  - Persistent settings across game sessions via `MinimalistCooldownEdgeDB`
  - Default configuration with deep copy for missing values
- In-game GUI options panel (`GUI.lua`)
  - Font customization (dropdown with 7 font options)
  - Font size slider (8-36)
  - Font style options (Outline, Thick Outline, Monochrome, None)
  - Text color picker with opacity support
  - Edge enable/disable toggle
  - Edge scale slider (0.5-2.0)
  - Reset to defaults button
  - Reload UI button
- Slash commands: `/mce` and `/minimalistcooldownedge`
- Support for all action bar types (MultiBar1-7)

### Changed
- Refactored `Core.lua` to use configuration system
  - Replaced hardcoded values with dynamic config retrieval
  - Separated apply logic into `ApplyCustomStyle()` function
  - Added `ApplyAllCooldowns()` function for bulk updates
  - Proper event-driven initialization with `ADDON_LOADED` and `PLAYER_LOGIN`
- Updated `.toc` file structure
  - Added `SavedVariables: MinimalistCooldownEdgeDB`
  - Added `Config.lua` and `GUI.lua` to file list
  - Version bumped to 1.2

### Fixed
- Settings now apply to all visible cooldowns on load
- Edge settings now properly toggleable

## [1.1] - 2026-01-25
### Changed
- Translated all code comments and print messages to English.
- Updated `.toc` metadata:
  - Added colored title for better visibility in the addon list.
  - Added an icon texture.
- Improved Cooldown Text styling:
  - Now sets custom font, size, and color for cooldown timers using `GetRegions`.
  - Ensures native cooldown numbers are shown via `SetHideCountdownNumbers(false)`.

## [1.0] - 2025-01-25
### Added
- Initial release.
- Custom texture for cooldown edges (`EdgeTexture`).
- Customized swipe color (`SwipeColor`).
- "Bling" effect enabled for finished cooldowns.
- Basic hooks for `ActionButton_UpdateCooldown` and `CooldownFrame_SetDrawEdge`.