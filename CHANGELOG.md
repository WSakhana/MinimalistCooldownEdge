# Changelog

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
