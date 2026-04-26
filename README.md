# Codex Remote Android

Android app and PC-side bridge for sending instructions from a phone to Codex running on a home PC.

## Goal

Build a Flutter Android app that can:

- Start a new remote Codex session.
- Select an existing remote Codex session.
- Send text instructions to a selected session.
- Show only the final result in the app.
- Notify the phone with a push notification when remote processing completes.
- Work from both WiFi and cellular networks while the home PC is online.
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

- `app/`: Flutter app placeholder. Flutter SDK is not installed on PATH yet.
- `pc-bridge/`: Node.js/TypeScript scaffold for the Windows PC bridge.
- `firebase/`: Firebase relay scaffold for Firestore, Functions, and Emulators.
- `docs/development-setup.md`: Local toolchain status and setup handoff.

## Documents

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Development Setup](docs/development-setup.md)
- [Release Plan](docs/release-plan.md)
- [Phase Workflows](process/README.md)

## Release Definition

Release is complete when a signed or debug Android APK can be installed on the Xperia 1 III, the app can send a command to the home PC, Codex processing runs on the PC, the final result is visible in the app, and a completion push notification is delivered.
