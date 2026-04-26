# Agents: Android App

## Flutter UI Agent

- Build session list, session detail, command composer, and result display.
- Optimize layout for Xperia 1 III portrait display.
- Keep all user-facing text routed through the app localization layer.
- Preserve technical labels such as CLI flags, model IDs, status values, and file paths as literal text.

## State Management Agent

- Keep authentication, session state, command state, and notification navigation predictable.
- Ensure stream-backed screens render stable empty, queued, running, completed, and failed states in widget tests.

## Android Platform Agent

- Configure package name, permissions, notification channel, and release build settings.
- Verify debug APK installation on the wireless-debugging Xperia target when UI behavior changes materially.

## Localization Agent

- Maintain Japanese, English, Chinese, and Korean app strings.
- Confirm unsupported locales fall back to English.
- Add or update widget tests for any locale-sensitive behavior.
- Keep settings option help localized while leaving CLI option names unchanged.

## Handoff

This phase is complete when the app can authenticate, list sessions, create a session, send a command, display progress and the final result, and render supported device languages correctly.
