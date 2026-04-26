# Skill

Use this repository skill when developing the Codex Remote Android project.

## Operating Mode

1. Check open GitHub Issues and choose the highest-priority actionable issue.
2. Confirm the issue maps to one phase under `process/`.
3. Read that phase's `Agents.md` and `Skill.md`.
4. Implement only the scope needed for the selected issue.
5. Run the phase-specific validation.
6. Update documentation and issue status before moving to the next phase.

## Product Constraints

- Android app target: Xperia 1 III.
- Mobile network support is required; do not rely on LAN-only discovery for core workflows.
- PC is normally powered on.
- VS Code is normally running, but the design may include a PC-side service that can start VS Code later.
- Intermediate Codex progress is not required in the app.
- Completion must trigger a push notification.

## Preferred MVP Stack

- Flutter for Android UI.
- Firebase Authentication for user/device identity.
- Cloud Firestore for sessions, commands, and final results.
- Firebase Cloud Messaging for completion notification.
- PC bridge implemented as a small companion process first, with optional VS Code extension integration later.

