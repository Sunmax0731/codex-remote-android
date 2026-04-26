# Requirements Definition

## Background

The user wants to use an Android phone to send development instructions to Codex running on a home PC inside VS Code. The PC performs the actual work. The phone is a remote command and result surface.

## MVP Goal

The MVP is complete when an Android APK is installed on the user's Xperia 1 III and the user can complete this workflow:

1. Open the Android app.
2. Select or create a remote Codex session.
3. Send one text instruction from the phone.
4. The home PC receives the instruction and runs the Codex workflow.
5. The app shows the final result after processing completes.
6. The phone receives a completion push notification.

The MVP does not need full streaming terminal output, direct phone-to-PC networking, or Google Play publication. The current MVP may show periodic PC bridge progress summaries while Codex is running.

## Primary User

- A single developer who owns both the Android phone and the home PC.
- The developer uses the phone as a remote control surface for development work performed on the PC.
- The developer is expected to complete a one-time setup for the PC bridge.

## MVP Product Decisions

- The phone and PC communicate through an internet-accessible relay so both WiFi and cellular networks work.
- The home PC is assumed to be powered on.
- VS Code is assumed to be running for the first MVP.
- Starting VS Code from the PC bridge is a post-MVP enhancement unless it is cheap to add after the bridge exists.
- The Android app displays final results and may show periodic progress summaries while running; full intermediate Codex output streaming is intentionally omitted.
- One user and one primary PC are enough for MVP.
- MVP authentication uses a simple single-user pairing flow built on Firebase identity. Exact implementation is owned by the architecture phase.
- MVP targets one fixed PC workspace configured on the PC bridge. Multi-workspace selection is post-MVP.
- MVP may store command text and final result text in the cloud relay as plain text, protected by authentication and security rules. Client-side encryption is post-MVP unless the architecture phase finds a low-cost approach.
- The Android app should follow the device language automatically for Japanese, English, Chinese, and Korean. Unsupported languages fall back to English.

## Functional Requirements

### FR-001 Start Session

The Android app must allow the user to create a new remote Codex session.

Acceptance criteria:

- The user can create a session from the app.
- The session is persisted in the cloud relay.
- The PC bridge can discover the new session.
- The session receives a default title that the user can understand.

### FR-002 Select Existing Session

The Android app must allow the user to select an existing session.

Acceptance criteria:

- The app lists sessions owned by the authenticated user.
- The app shows enough metadata to distinguish sessions, such as title, last updated time, and status.
- Selecting a session opens its command/result view.
- Sessions not owned by the authenticated user are not visible.

### FR-003 Send Text Instruction

The Android app must allow the user to send text to the selected session.

Acceptance criteria:

- The user can enter text and submit it.
- The command is queued for the PC bridge.
- Duplicate submit is prevented while a command is pending.
- Empty commands cannot be submitted.
- The app records the command creation time.

### FR-004 Show Final Result

The Android app must show the final result after the PC finishes processing.

Acceptance criteria:

- The app can show periodic progress logs while a command is running.
- The app shows the final response text.
- The app shows failure state if the PC bridge reports an error.
- The app preserves the final result after app restart.

### FR-014 Device Language Localization

The Android app must automatically select its display language from the phone language settings.

Acceptance criteria:

- Japanese, English, Chinese, and Korean are supported.
- Unsupported phone languages fall back to English.
- Core session, command, PC bridge status, settings, and CLI option help labels are localized.
- CLI option names, model names, API names, file paths, and other technical identifiers remain unchanged.
- Widget tests cover at least one non-English locale.

### FR-005 Completion Push Notification

The phone must receive a push notification after processing completes.

Acceptance criteria:

- Completion creates an FCM notification.
- Tapping the notification opens the related session.
- Failure completion can also notify the user.
- Notification text does not include the full command or full result by default.

### FR-006 PC Online Assumption

The system may assume the PC is powered on for the MVP.

Acceptance criteria:

- If the PC bridge is offline, commands remain queued.
- The app clearly shows queued or waiting status.
- The app does not pretend that queued work has started until the PC bridge marks it running.

### FR-007 VS Code Running Assumption and Optional Startup

The system may assume VS Code is running for the MVP. A later enhancement may start VS Code from a PC-side service.

Acceptance criteria:

- MVP can connect to Codex through the PC-side bridge while VS Code is running.
- Optional enhancement is tracked separately: PC bridge service starts `code.cmd` when VS Code is not running.
- If VS Code/Codex cannot be reached, the command fails with a visible error state.

### FR-008 Xperia 1 III Support

The Android app must run on Xperia 1 III.

Acceptance criteria:

- Android minimum SDK and target SDK support Xperia 1 III.
- Layout works on 21:9 portrait display.
- APK can be installed and launched on the device.
- Text input, session list, and result display remain usable in portrait orientation.

### FR-009 WiFi and Cellular Connectivity

The app must work over WiFi and cellular.

Acceptance criteria:

- Core communication uses an internet-accessible relay.
- No inbound home router port forwarding is required.
- Direct LAN mode may be added later but is not required for MVP.

### FR-010 Device Pairing and Authentication

The system must prevent unknown phones or unknown PC bridges from accessing sessions.

Acceptance criteria:

- The Android app has an authenticated user or device identity.
- The PC bridge has a registered identity for the same user.
- The first MVP may use a simple single-user pairing flow.
- Pairing credentials are not stored in Git.

### FR-011 Workspace Targeting

The user must be able to understand which PC/workspace receives the command.

Acceptance criteria:

- The system records the target PC bridge for each command.
- The app shows at least one readable target name, such as the PC bridge name.
- If multi-workspace support is not implemented in MVP, the PC bridge configuration documents the fixed workspace it controls.

### FR-012 Command Lifecycle

Commands must have explicit lifecycle states.

Acceptance criteria:

- Supported states are queued, running, completed, failed, and canceled.
- The Android app displays queued, running, completed, and failed states.
- Canceled may be stored in the model even if command cancellation UI is post-MVP.
- The PC bridge writes started and completed timestamps where applicable.

### FR-013 Basic Setup Visibility

The app must make common setup failures understandable.

Acceptance criteria:

- If no PC bridge is registered, the app shows a setup-required state.
- If the PC bridge is registered but inactive, the app shows a waiting/offline state.
- If notification permission is missing, the app asks for or explains the permission.

## Non-Functional Requirements

### NFR-001 Security

- Only authenticated devices can access sessions.
- Commands are scoped to the authenticated user.
- PC bridge must not expose arbitrary unauthenticated execution.
- Secrets must not be committed to the repository.
- The PC bridge must treat mobile text as a Codex instruction, not as a raw shell command.
- Firestore Security Rules or equivalent relay permissions must be tested.

### NFR-002 Reliability

- Commands must survive temporary phone disconnects.
- PC bridge should retry transient relay failures.
- Command status must be explicit: queued, running, completed, failed, canceled.
- A command must not be processed twice by concurrent bridge instances.
- The app must recover session state after restart.

### NFR-003 Privacy

- Session text and final results may contain source code or private project details.
- Data retention policy must be documented before public release.
- Notification payloads should avoid sensitive content.
- Logs must avoid storing secrets.

### NFR-004 Maintainability

- Android app, cloud data model, and PC bridge must have clear interfaces.
- Integration tests should cover the command lifecycle.
- Phase-specific work should be tracked through GitHub Issues.

### NFR-005 Usability

- The app should be usable one-handed in portrait orientation.
- Long results must be scrollable.
- Submit controls must make pending/running state obvious.

### NFR-006 Observability

- PC bridge should produce local logs for setup and runtime diagnosis.
- Command failure errors should be actionable without exposing secrets.
- Release verification should record app version, build number, commit SHA, and target device.

## MVP Acceptance Scenario

Given:

- The Android app is installed on the Xperia 1 III.
- The phone has internet access through WiFi or cellular.
- The PC is powered on.
- VS Code and the PC bridge are running on the home PC.
- The phone and PC bridge are paired to the same user.

When:

1. The user opens the Android app.
2. The user creates or selects a session.
3. The user sends a text instruction.
4. The PC bridge receives and processes the instruction.

Then:

- The command moves from queued to running to completed, or failed on error.
- The final result or error is visible in the app.
- The phone receives a push notification after completion or failure.
- The workflow works without home router port forwarding.

## Requirement Traceability

| User request | Requirement coverage |
| --- | --- |
| Start session | FR-001 |
| Select existing session | FR-002 |
| Send text and show result | FR-003, FR-004 |
| Running progress logs and completion notification | FR-004, FR-005 |
| PC is powered on | FR-006 |
| VS Code is running | FR-007 |
| Possible later VS Code startup | FR-007, out of scope for MVP |
| Xperia 1 III support | FR-008 |
| WiFi and cellular | FR-009 |
| Safe phone and PC access | FR-010, NFR-001 |
| PC/workspace target clarity | FR-011 |
| Device language support | FR-014 |

## Out of Scope for MVP

- Streaming intermediate Codex output to the phone.
- Editing files directly from the phone.
- Wake-on-LAN from cellular network.
- Multi-user team collaboration.
- Marketplace publication.
- Google Play Store publication.
- Rich Codex session transcript browsing.
- Multi-PC routing beyond one registered primary PC.
- Full remote desktop or VS Code UI mirroring.
- Full professional translation management through ARB files or a translation service. The MVP may use a lightweight in-app string table.

## Architecture Follow-Up Decisions

These decisions should be settled before or during the architecture phase:

- Whether the pairing flow uses Firebase anonymous auth, email sign-in, or another Firebase-supported identity mechanism under the single-user pairing requirement.
- Whether the PC bridge is registered with a short-lived pairing code, a local configuration secret, or both.
- Exact Firestore Security Rules and tests for command/result access.
- Exact retention policy for command and result documents.
