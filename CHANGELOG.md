# Changelog

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
