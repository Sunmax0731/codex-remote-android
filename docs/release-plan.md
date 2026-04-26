# Release Plan

## Release Target

Installable Android app on Xperia 1 III.

The first release may be a debug APK or internal signed APK. Google Play publication is not required for MVP.

## Release Readiness Checklist

- Android app can authenticate.
- Android app can create a session.
- Android app can select a session.
- Android app can send a text command.
- PC bridge receives and processes the command.
- Final result is visible in the app.
- Running progress summary is visible when the PC bridge reports progress.
- Completion push notification is delivered.
- App follows the device language for Japanese, English, Chinese, and Korean, with English fallback for unsupported languages.
- App works over cellular network.
- App layout is usable on Xperia 1 III portrait display.
- Secrets are excluded from Git.
- Release notes describe setup requirements for the PC bridge.

## Installation Definition

Release is complete when:

1. APK is built.
2. APK is installed on the Xperia 1 III.
3. The installed app completes one end-to-end command cycle with the home PC.

## Post-MVP Release Candidates

- Start VS Code automatically from the PC bridge.
- Local LAN discovery mode.
- Command cancellation.
- Session search.
- Encrypted session payloads.
- Multiple PC bridge registration.
- ARB-based translation workflow or professional translation management.
