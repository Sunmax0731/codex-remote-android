import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { buildCompletionMessage } from "./completionMessage.js";

initializeApp();

const terminalStatuses = new Set(["completed", "failed"]);
const notificationChannelId = "remote_codex_completion";

export const notifyCommandCompletion = onDocumentUpdated(
  {
    document: "users/{userId}/sessions/{sessionId}/commands/{commandId}",
    region: "asia-northeast1",
  },
  async (event) => {
    const change = event.data;
    if (!change) {
      return;
    }

    const before = change.before.data();
    const after = change.after.data();

    const status = String(after.status ?? "");
    if (!terminalStatuses.has(status) || before.status === after.status || after.notificationSentAt) {
      return;
    }

    const { userId, sessionId, commandId } = event.params;
    const firestore = getFirestore();
    const devices = await firestore.collection(`users/${userId}/devices`).get();
    const tokens = devices.docs
      .map((device) => device.data().fcmToken)
      .filter((token): token is string => typeof token === "string" && token.length > 0);

    if (tokens.length === 0) {
      logger.info("No FCM tokens found for completed command.", { userId, sessionId, commandId });
      return;
    }

    const message = buildCompletionMessage(status, after, sessionId, commandId);
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: message.title,
        body: message.body,
      },
      android: {
        notification: {
          channelId: notificationChannelId,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      data: {
        type: "commandCompletion",
        userId,
        sessionId,
        commandId,
        status,
      },
    });

    await change.after.ref.update({
      notificationSentAt: Timestamp.now(),
      notificationSuccessCount: response.successCount,
      notificationFailureCount: response.failureCount,
      notificationLastError: firstErrorCode(response.responses) ?? FieldValue.delete(),
    });

    logger.info("Sent command completion notification.", {
      userId,
      sessionId,
      commandId,
      status,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);

function firstErrorCode(responses: Array<{ error?: { code?: string } }>): string | null {
  const failed = responses.find((response) => response.error?.code);
  return failed?.error?.code ?? null;
}
