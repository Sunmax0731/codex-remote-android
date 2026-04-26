# Architecture

## System Overview

The system has three main parts:

- Android app: session list, command input, final result display, notification handling.
- Cloud relay: authentication, command queue, session/result storage, notification trigger.
- PC bridge: watches for queued commands, sends them to Codex on the home PC, writes final results.

## MVP Communication Pattern

Use Firebase as the relay.

```text
1. Android app authenticates the user.
2. Android app creates or selects a session.
3. Android app writes a command document to Firestore.
4. PC bridge listens for queued command documents for the same user/device.
5. PC bridge runs the command through local Codex/VS Code integration.
6. PC bridge writes final result and status to Firestore.
7. Cloud Function or PC bridge sends an FCM completion notification.
8. Android app opens the completed session and displays the final result.
```

## Firestore Draft Model

```text
users/{userId}
users/{userId}/devices/{deviceId}
users/{userId}/sessions/{sessionId}
users/{userId}/sessions/{sessionId}/commands/{commandId}
```

Session fields:

- `title`
- `status`
- `createdAt`
- `updatedAt`
- `lastCommandId`
- `lastResultPreview`

Command fields:

- `text`
- `status`: queued, running, completed, failed, canceled
- `createdAt`
- `startedAt`
- `completedAt`
- `resultText`
- `errorText`
- `pcBridgeId`

## PC Bridge Options

### MVP: Companion Process

A small Windows process runs on the home PC and communicates with Firebase. It can be implemented in Node.js, .NET, or Dart.

Benefits:

- Can run even if VS Code is not yet open.
- Can later start `code.cmd` if needed.
- Easier to test outside VS Code.

Tradeoffs:

- Needs local setup and credentials.
- Codex/VS Code integration must be carefully controlled.

### Later: VS Code Extension

A VS Code extension can provide better integration with workspace state and UI.

Benefits:

- Directly aware of the active workspace.
- Can surface session status inside VS Code.

Tradeoffs:

- If VS Code is closed, the extension cannot run.

## Notification Strategy

Preferred MVP:

- Store the phone FCM token under the authenticated user's device document.
- When command status becomes completed or failed, send a notification through Firebase Cloud Functions.

Fallback:

- PC bridge sends notification through FCM after writing the result.

Cloud Functions are preferred because they avoid putting broader notification credentials on the home PC.

## Network Strategy

The phone never connects directly to the home PC for MVP. Both phone and PC connect outbound to Firebase. This satisfies WiFi and cellular access without router configuration.

## Security Model

- Firebase Auth identifies the app user.
- Firestore Security Rules restrict reads/writes to the owner.
- PC bridge uses a scoped service credential or device pairing token.
- Commands are plain text instructions, not raw shell commands.
- PC bridge validates command ownership and session state before execution.

## Open Design Decisions

- Exact Codex invocation mechanism from the PC bridge.
- Whether PC bridge is Node.js, .NET, or Dart.
- Whether result text should be encrypted client-side before storing in Firestore.
- Retention period for session logs.

