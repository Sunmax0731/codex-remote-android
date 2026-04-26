# Agents: Architecture

## Architect Agent

- Define the Android app, cloud relay, and PC bridge boundaries.
- Own data model, command lifecycle, and integration contracts.

## Security Agent

- Review authentication, authorization, secret storage, and command execution boundaries.
- Reject designs that expose unauthenticated remote execution.

## Operations Agent

- Define how the PC bridge is installed, configured, started, and monitored.

## Handoff

This phase is complete when `docs/architecture.md` defines the MVP stack, data model, network model, and unresolved design decisions.

