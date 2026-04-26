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

- `app/`: Flutter Android project generated for package `com.sunmax.remotecodex`. Startup initializes Firebase, signs in anonymously, shows sessions, and can queue text commands for the PC bridge.
- `pc-bridge/`: Node.js/TypeScript bridge with local relay and Firestore relay support. Current local config can reach Firebase in `stub` mode.
- `firebase/`: Firebase relay scaffold linked to project `remotecodex-c52ae`, with Firestore rules and command query index.
- `docs/development-setup.md`: Local toolchain status, wireless debugging workflow, and Firebase/Flutter setup handoff.

## Current Phase

Phase 5 Android app MVP is in progress. Flutter scaffold, Firebase initialization, anonymous-auth baseline, session list/create, command submission/result display, and Xperia 1 III wireless debug launch are in place.

## Documents

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Development Setup](docs/development-setup.md)
- [Release Plan](docs/release-plan.md)
- [Phase Workflows](process/README.md)

## Release Definition

Release is complete when a signed or debug Android APK can be installed on the Xperia 1 III, the app can send a command to the home PC, Codex processing runs on the PC, the final result is visible in the app, and a completion push notification is delivered.
