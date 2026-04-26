# Skill: Android App

## Steps

1. Create Flutter app under `app/`.
2. Add Firebase initialization.
3. Implement sign-in or device pairing.
4. Implement session list.
5. Implement session creation.
6. Implement session detail with command composer.
7. Implement final result display.
8. Add loading, queued, running, completed, and failed states.
9. Keep device-language localization current for Japanese, English, Chinese, and Korean.
10. When adding user-facing text, add it to the app localization table and keep technical identifiers such as CLI options and status values unchanged.

## Localization Notes

- The app follows the phone locale through Flutter localization delegates.
- Supported MVP languages are `ja`, `en`, `zh`, and `ko`; unsupported locales fall back to English.
- CLI option names, model names, sandbox values, API names, file paths, and Firestore status values remain untranslated.
- Option help shown from settings must be localized when the explanatory text is user-facing.
- Current implementation uses a lightweight in-app string table in `app/lib/main.dart`; do not introduce ARB migration inside unrelated Issues.

## Flutter Test Notes

- Widget tests that expect English should set `localeTestValue` and `localesTestValue` to `Locale('en')`.
- Add at least one non-English widget test when localization behavior changes.
- Avoid broad `pumpAndSettle()` after stream updates when localization delegates or long-lived animations are present. Prefer a bounded helper such as `pump(); pump(Duration(milliseconds: 300));`.
- Fake repositories using broadcast streams should replay the latest value so tests do not miss events emitted near subscription startup.

## Validation

- App launches on Android.
- Layout fits Xperia 1 III portrait screen.
- Session list reads only the authenticated user's sessions.
- Duplicate command submission is prevented while pending.
- Device locale changes select supported app text automatically, with English fallback.
- `flutter analyze` and `flutter test` pass after localization changes.
