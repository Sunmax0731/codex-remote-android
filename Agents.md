# Agents

This repository is organized as an issue-driven development project. Each phase has a local `Agents.md` that defines the agent responsibilities for that phase.

## Global Rules

- Work from the current GitHub Issues before implementing.
- Keep security-sensitive decisions explicit.
- Prefer Firebase relay communication for the MVP so WiFi and cellular both work without router port forwarding.
- Treat the PC bridge and Android app as separate deliverables with an integration contract between them.
- Do not expose arbitrary shell execution from the Android app.
- Validate on a real Android device or emulator before release; Xperia 1 III is the target physical device.

## Phase Order

1. Requirements definition
2. Architecture and threat model
3. Repository and environment setup
4. PC bridge implementation
5. Android app implementation
6. Push notification integration
7. End-to-end QA
8. Android release and installation

