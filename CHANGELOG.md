# Changelog

## 2.0.1

- Fix the handoff that could end on the desktop after a restart or when the client had no visible window. Send an explicit Launch Services open/reopen request instead of only activating a cached process.
- Keep Moonrise alive until the target process is frontmost with a visible normal window. Retry up to three times, report failure after 15 seconds, and stop treating an activation request as proof of success.
- Add bounded local diagnostic logging (no chat content) and native fixture integration tests for cold launch, missing windows, terminated clients, and missing applications.
- Existing restart Shortcuts continue to work without changing their three actions.

## 2.0

Initial 14-second cinematic sequence, three persistent palettes, Universal macOS app, browser demo and manual Shortcuts setup guide.
