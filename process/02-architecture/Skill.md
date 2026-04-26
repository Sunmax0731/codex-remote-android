# Skill: Architecture

## Steps

1. Confirm the MVP relay architecture.
2. Specify session and command states.
3. Define Firestore paths and fields.
4. Define notification trigger ownership.
5. Write security rules requirements.
6. Document PC bridge startup behavior and VS Code assumptions.

## Validation

- Phone can work from cellular network.
- PC requires only outbound network access.
- No long-lived admin credential is stored in the Android app.
- Command lifecycle handles queued, running, completed, failed, and canceled states.

