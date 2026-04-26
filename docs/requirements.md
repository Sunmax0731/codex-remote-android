# Requirements Definition

## Background

The user wants to use an Android phone to send development instructions to Codex running on a home PC inside VS Code. The PC performs the actual work. The phone is a remote command and result surface.

## Functional Requirements

### FR-001 Start Session

The Android app must allow the user to create a new remote Codex session.

Acceptance criteria:

- The user can create a session from the app.
- The session is persisted in the cloud relay.
- The PC bridge can discover the new session.

### FR-002 Select Existing Session

The Android app must allow the user to select an existing session.

Acceptance criteria:

- The app lists sessions owned by the authenticated user.
- The app shows enough metadata to distinguish sessions, such as title, last updated time, and status.
- Selecting a session opens its command/result view.

### FR-003 Send Text Instruction

The Android app must allow the user to send text to the selected session.

Acceptance criteria:

- The user can enter text and submit it.
- The command is queued for the PC bridge.
- Duplicate submit is prevented while a command is pending.

### FR-004 Show Final Result

The Android app must show the final result after the PC finishes processing.

Acceptance criteria:

- Intermediate progress does not need to be displayed.
- The app shows the final response text.
- The app shows failure state if the PC bridge reports an error.

### FR-005 Completion Push Notification

The phone must receive a push notification after processing completes.

Acceptance criteria:

- Completion creates an FCM notification.
- Tapping the notification opens the related session.
- Failure completion can also notify the user.

### FR-006 PC Online Assumption

The system may assume the PC is powered on for the MVP.

Acceptance criteria:

- If the PC bridge is offline, commands remain queued.
- The app clearly shows queued or waiting status.

### FR-007 VS Code Running Assumption and Optional Startup

The system may assume VS Code is running for the MVP. A later enhancement may start VS Code from a PC-side service.

Acceptance criteria:

- MVP can connect to Codex through the PC-side bridge while VS Code is running.
- Optional enhancement is tracked separately: PC bridge service starts `code.cmd` when VS Code is not running.

### FR-008 Xperia 1 III Support

The Android app must run on Xperia 1 III.

Acceptance criteria:

- Android minimum SDK and target SDK support Xperia 1 III.
- Layout works on 21:9 portrait display.
- APK can be installed and launched on the device.

### FR-009 WiFi and Cellular Connectivity

The app must work over WiFi and cellular.

Acceptance criteria:

- Core communication uses an internet-accessible relay.
- No inbound home router port forwarding is required.
- Direct LAN mode may be added later but is not required for MVP.

## Non-Functional Requirements

### NFR-001 Security

- Only authenticated devices can access sessions.
- Commands are scoped to the authenticated user.
- PC bridge must not expose arbitrary unauthenticated execution.
- Secrets must not be committed to the repository.

### NFR-002 Reliability

- Commands must survive temporary phone disconnects.
- PC bridge should retry transient relay failures.
- Command status must be explicit: queued, running, completed, failed, canceled.

### NFR-003 Privacy

- Session text and final results may contain source code or private project details.
- Data retention policy must be documented before public release.

### NFR-004 Maintainability

- Android app, cloud data model, and PC bridge must have clear interfaces.
- Integration tests should cover the command lifecycle.

## Out of Scope for MVP

- Streaming intermediate Codex output to the phone.
- Editing files directly from the phone.
- Wake-on-LAN from cellular network.
- Multi-user team collaboration.
- Marketplace publication.

