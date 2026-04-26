# Skill: Release

## Steps

1. Confirm all release-blocking issues are closed.
2. Update version and build number.
3. Build APK.
4. Install APK on Xperia 1 III with `adb install`.
5. Run the release smoke test:
   - create or select session
   - send command
   - PC bridge processes command
   - final result appears
   - push notification arrives
6. Tag the release commit.
7. Publish GitHub Release with APK if appropriate.

## Validation

- APK is installed on the phone.
- End-to-end command cycle passes.
- Notification arrives after completion.
- Release notes include setup and known limitations.

