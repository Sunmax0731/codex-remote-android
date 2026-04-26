# Agents: Push Notifications

## Notification Agent

- Configure Firebase Cloud Messaging.
- Register and refresh device tokens.
- Handle notification tap routing to the correct session.

## Cloud Function Agent

- Trigger notifications when command status changes to completed or failed.
- Keep notification payload minimal and safe.

## QA Agent

- Verify foreground, background, and terminated app notification behavior.

## Handoff

This phase is complete when the phone receives a completion notification and opens the related session from the notification.

