# Skill: Release

## Steps

1. Confirm all release-blocking issues are closed.
2. Update version and build number.
3. Build APK.
4. Confirm the wireless-debugging device ID with `flutter devices`.
5. Install APK on Xperia 1 III with `flutter install -d <device-id> --debug` for debug releases, or `adb install` for a signed APK artifact.
6. Run the release smoke test:
   - create or select session
   - send command
   - PC bridge processes command
   - running progress is visible when the bridge reports it
   - final result appears
   - push notification arrives
7. Spot-check supported locale behavior when UI text changed in the release:
   - Japanese
   - English
   - Chinese
   - Korean
   - English fallback for unsupported locales where practical
8. Tag the release commit.
9. Publish GitHub Release with APK if appropriate.

## Validation

- APK is installed on the phone.
- End-to-end command cycle passes.
- Notification arrives after completion.
- Supported locale behavior is either verified or explicitly deferred with a reason.
- Release notes include setup and known limitations.
