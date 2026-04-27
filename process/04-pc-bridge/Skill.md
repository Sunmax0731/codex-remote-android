# Skill: PC Bridge

## Steps

1. Choose bridge runtime.
2. Implement device pairing or bridge registration.
3. Listen for queued command documents.
4. Mark a command `running` before execution.
5. Send text to the local Codex workflow.
6. Capture final result.
7. Detect local Markdown image references in the final result, upload valid image files to Firebase Storage, and attach `resultAttachments` metadata.
8. Mark the command `completed` or `failed`.
9. Log local diagnostics without leaking secrets.

## Validation

- A test queued command transitions to `running`.
- A successful command transitions to `completed`.
- A failing command transitions to `failed` with useful error text.
- The bridge does not execute commands for another user.
- Result images are uploaded under `users/{userId}/sessions/{sessionId}/commands/{commandId}/results/...`.
- The command stores `resultAttachments` without exposing local PC paths.
- After TypeScript changes, rebuild and restart the long-running watcher before E2E verification.
