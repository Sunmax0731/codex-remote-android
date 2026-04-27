# Skill: QA

## Steps

1. Run Android unit and widget tests.
2. Run PC bridge tests.
3. Run Firebase emulator tests where applicable.
4. Execute one full command cycle from phone to PC and back.
5. Repeat over cellular network.
6. Verify push notification behavior.
7. Verify device-language behavior for Japanese, English, Chinese, Korean, and English fallback where practical.
8. Verify attachment input and result image output flows where applicable.
9. File issues for defects instead of hiding them in notes.

## Android Regression Notes

- Run `flutter analyze` and `flutter test` from `app/`.
- For localization-related widget tests, set test platform locales explicitly to avoid host-locale drift.
- Avoid unbounded `pumpAndSettle()` for stream-backed screens when app-level localization delegates are active; use bounded frame pumps unless the test specifically needs route/dialog animations to settle.
- For Xperia wireless debugging, confirm the current device ID with `flutter devices`; the port can change after reconnect or device reboot.
- For result image regression, verify Firestore `resultAttachments`, Storage `/results/` object existence, Android thumbnail rendering, tap preview, and long-press save.
- If a result thumbnail is missing, inspect Firestore metadata first, then Storage object, Storage Rules, app loader error, and PC bridge watcher freshness.

## Validation

- Test evidence is attached to the release issue.
- Known defects are either fixed or explicitly accepted.
- The release checklist in `docs/release-plan.md` is complete.
- Locale support evidence records at least the tested language and fallback behavior.
