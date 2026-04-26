# Skill: PC Bridge

## Steps

1. Choose bridge runtime.
2. Implement device pairing or bridge registration.
3. Listen for queued command documents.
4. Mark a command `running` before execution.
5. Send text to the local Codex workflow.
6. Capture final result.
7. Mark the command `completed` or `failed`.
8. Log local diagnostics without leaking secrets.

## Validation

- A test queued command transitions to `running`.
- A successful command transitions to `completed`.
- A failing command transitions to `failed` with useful error text.
- The bridge does not execute commands for another user.

