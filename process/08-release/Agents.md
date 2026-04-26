# Agents: Release

## Release Agent

- Build the Android APK.
- Install the APK on the target phone.
- Record version, build number, and commit SHA.
- Use `flutter devices` to confirm the current wireless-debugging device ID before installing debug builds.

## Documentation Agent

- Write release notes and setup instructions.
- Document PC bridge prerequisites.

## Verification Agent

- Verify the installed app completes the end-to-end workflow.
- Confirm notification delivery after installation.
- Confirm progress display and supported locale behavior for releases that change Android UI text.

## Handoff

This phase is complete when the app is installed on the Xperia 1 III and the release issue records successful end-to-end verification.
