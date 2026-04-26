# Skill: Push Notifications

## Steps

1. Add FCM to the Android app.
2. Request notification permission on supported Android versions.
3. Store FCM token under the user's device document.
4. Add Cloud Function status-change trigger.
5. Send notification for completed and failed commands.
6. Implement notification tap deep link to session detail.

## Validation

- Notification arrives when app is foregrounded.
- Notification arrives when app is backgrounded.
- Notification tap opens the relevant session.
- Notification content does not leak sensitive command text by default.

