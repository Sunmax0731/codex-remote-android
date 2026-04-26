# Codex Remote Android

Android app and PC-side bridge for sending instructions from a phone to Codex running on a home PC.

## Goal

Build a Flutter Android app that can:

- Start a new remote Codex session.
- Choose per-session Codex CLI options when starting a session and keep stable execution options in app defaults.
- Select an existing remote Codex session.
- Send text instructions to a selected session.
- Show only the final result in the app.
- Notify the phone with a push notification when remote processing completes.
- Work from both WiFi and cellular networks while the home PC is online.
- Automatically follow the phone language for Japanese, English, Chinese, and Korean.
- Target Xperia 1 III and equivalent Android devices.

## Proposed Architecture

The MVP should use a cloud relay instead of direct phone-to-PC networking:

```text
Android app -> Firebase Auth/Firestore -> PC bridge -> VS Code/Codex
Android app <- Firestore final result <- PC bridge <- VS Code/Codex
Android app <- Firebase Cloud Messaging completion notification
```

This avoids opening inbound ports on the home network and allows cellular access.

## Current Setup Status

- `app/`: Flutter Android project generated for package `com.sunmax.remotecodex`. Startup initializes Firebase, signs in anonymously, stores FCM tokens, shows sessions, stores CLI option defaults, lets new sessions choose Codex CLI model/profile values and advanced CLI options, exposes per-option help inside the settings dialog, supports image file selection for `--image`, shows session options on long press, queues text commands for the PC bridge, shows running progress logs, can request an on-demand PC bridge health check, routes notification taps to the target session, follows the phone language for Japanese/English/Chinese/Korean, and uses the custom RemoteCodex launcher icon.
- `pc-bridge/`: Node.js/TypeScript bridge with local relay and Firestore relay support. Current local config can run `codexMode: cli` with a fixed Codex model, reflect session-level Codex CLI options into `codex exec`, return 1-minute progress logs while Codex CLI is running, respond to on-demand health checks, follow Android anonymous UID changes for bridge status, and `start:watch` can keep polling queued commands. Windows batch files under `pc-bridge/scripts/` can run the watcher in the background or register it with Task Scheduler.
- `firebase/`: Firebase relay scaffold linked to project `remotecodex-c52ae`, with Firestore rules, command query index, and a Cloud Function that sends FCM completion notifications.
- `docs/development-setup.md`: Local toolchain status, wireless debugging workflow, and Firebase/Flutter setup handoff.

## Current Phase

Phase 6 push notification integration is technically complete. Android FCM setup, device token storage, notification tap routing, and the Cloud Functions completion notification trigger are implemented. `notifyCommandCompletion` is deployed to `asia-northeast1` and has sent a completion notification successfully in Firebase-side validation.

Pre-QA work is in progress before Phase 7. The PC bridge can run Codex CLI with an explicit local `codexBypassSandbox` opt-in when VS Code shell parity is needed for commands such as `gh issue list`, and the Android app shows session navigation, bridge timing status, and 1-minute running progress logs.

## Documents

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Development Setup](docs/development-setup.md)
- [Release Plan](docs/release-plan.md)
- [Phase Workflows](process/README.md)

## Release Definition

Release is complete when a signed or debug Android APK can be installed on the Xperia 1 III, the app can send a command to the home PC, Codex processing runs on the PC, the final result is visible in the app, and a completion push notification is delivered.
