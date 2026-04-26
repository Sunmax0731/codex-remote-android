# Agents: PC Bridge

## Bridge Implementation Agent

- Implement command polling or listening.
- Invoke the local Codex workflow.
- Write final result and status back to the relay.

## VS Code Integration Agent

- Define how the bridge detects VS Code.
- Define later support for launching VS Code with `code.cmd`.
- Ensure workspace selection is explicit.

## Security Agent

- Prevent arbitrary unauthenticated remote command execution.
- Ensure bridge credentials are local-only and ignored by Git.

## Handoff

This phase is complete when a queued command can be processed on the PC and a final result is written to the relay.

