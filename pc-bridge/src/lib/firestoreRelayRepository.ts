import { readFile } from "node:fs/promises";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentSnapshot,
  type Firestore,
} from "firebase-admin/firestore";
import type { BridgeConfig, CommandClaim, CommandRepository, RemoteCommand } from "./types.js";

export class FirestoreRelayRepository implements CommandRepository {
  private readonly config: BridgeConfig;
  private firestorePromise: Promise<Firestore> | null = null;

  constructor(config: BridgeConfig) {
    this.config = config;
  }

  async claimNextQueuedCommand(
    pcBridgeId: string,
    now: Date,
    claimTtlSeconds: number,
  ): Promise<RemoteCommand | null> {
    const firestore = await this.getFirestore();
    const candidate = await this.findClaimCandidate(firestore, pcBridgeId, now);
    if (!candidate) {
      return null;
    }

    const nowTimestamp = Timestamp.fromDate(now);
    const claimExpiresAt = Timestamp.fromMillis(now.getTime() + claimTtlSeconds * 1000);

    return firestore.runTransaction(async (transaction) => {
      const current = await transaction.get(candidate.ref);

      if (!current.exists) {
        return null;
      }

      const data = current.data();
      if (!isClaimable(data, pcBridgeId, now)) {
        return null;
      }

      const ids = getCommandPathIds(current);
      const sessionRef = current.ref.parent.parent!;
      const session = await transaction.get(sessionRef);

      transaction.update(current.ref, {
        status: "running",
        claimedAt: nowTimestamp,
        claimedByPcBridgeId: pcBridgeId,
        claimExpiresAt,
        startedAt: nowTimestamp,
      });

      transaction.update(sessionRef, {
        status: "running",
        updatedAt: nowTimestamp,
        lastCommandId: ids.commandId,
      });

      return toRemoteCommand(ids.userId, ids.sessionId, ids.commandId, {
        ...data,
        ...sessionCodexOptions(session.data()),
        status: "running",
        claimedAt: now.toISOString(),
        claimedByPcBridgeId: pcBridgeId,
        claimExpiresAt: claimExpiresAt.toDate().toISOString(),
        startedAt: now.toISOString(),
      });
    });
  }

  private async findClaimCandidate(
    firestore: Firestore,
    pcBridgeId: string,
    now: Date,
  ): Promise<DocumentSnapshot<DocumentData> | null> {
    const queued = await firestore
      .collectionGroup("commands")
      .where("targetPcBridgeId", "==", pcBridgeId)
      .where("status", "==", "queued")
      .limit(1)
      .get();

    if (queued.docs[0]) {
      return queued.docs[0];
    }

    const running = await firestore
      .collectionGroup("commands")
      .where("targetPcBridgeId", "==", pcBridgeId)
      .where("status", "==", "running")
      .limit(10)
      .get();

    return running.docs.find((doc) => isExpiredRunning(doc.data(), now)) ?? null;
  }

  async markCompleted(claim: CommandClaim, resultText: string, now: Date): Promise<void> {
    const firestore = await this.getFirestore();
    const nowTimestamp = Timestamp.fromDate(now);
    const commandRef = commandDocument(firestore, claim);
    const sessionRef = commandRef.parent.parent!;

    await firestore.runTransaction(async (transaction) => {
      transaction.update(commandRef, {
        status: "completed",
        completedAt: nowTimestamp,
        resultText,
        errorText: FieldValue.delete(),
      });

      transaction.update(sessionRef, {
        status: "completed",
        updatedAt: nowTimestamp,
        lastResultPreview: preview(resultText),
        lastErrorPreview: FieldValue.delete(),
      });
    });
  }

  async updateProgress(
    claim: CommandClaim,
    progressText: string,
    now: Date,
    claimTtlSeconds: number,
  ): Promise<void> {
    const firestore = await this.getFirestore();
    const commandRef = commandDocument(firestore, claim);

    await commandRef.update({
      progressText,
      progressUpdatedAt: Timestamp.fromDate(now),
      claimExpiresAt: Timestamp.fromMillis(now.getTime() + claimTtlSeconds * 1000),
    });
  }

  async markFailed(claim: CommandClaim, errorText: string, now: Date): Promise<void> {
    const firestore = await this.getFirestore();
    const nowTimestamp = Timestamp.fromDate(now);
    const commandRef = commandDocument(firestore, claim);
    const sessionRef = commandRef.parent.parent!;

    await firestore.runTransaction(async (transaction) => {
      transaction.update(commandRef, {
        status: "failed",
        completedAt: nowTimestamp,
        errorText,
        resultText: FieldValue.delete(),
      });

      transaction.update(sessionRef, {
        status: "failed",
        updatedAt: nowTimestamp,
        lastErrorPreview: preview(errorText),
      });
    });
  }

  async updateHeartbeat(pcBridgeId: string, now: Date): Promise<void> {
    const firestore = await this.getFirestore();
    const userIds = await this.resolveBridgeUserIds(firestore, pcBridgeId);
    await Promise.all(userIds.map((userId) => firestore.doc(`users/${userId}/pcBridges/${pcBridgeId}`).set({
      pcBridgeId,
      displayName: this.config.displayName,
      workspaceName: this.config.workspaceName,
      lastSeenAt: Timestamp.fromDate(now),
      status: "active",
      version: "0.1.0",
    }, { merge: true })));
  }

  async updateQueueCheck(pcBridgeId: string, now: Date): Promise<void> {
    const firestore = await this.getFirestore();
    const userIds = await this.resolveBridgeUserIds(firestore, pcBridgeId);
    await Promise.all(userIds.map((userId) => firestore.doc(`users/${userId}/pcBridges/${pcBridgeId}`).set({
      pcBridgeId,
      displayName: this.config.displayName,
      workspaceName: this.config.workspaceName,
      lastQueueCheckedAt: Timestamp.fromDate(now),
      status: "active",
      version: "0.1.0",
    }, { merge: true })));
  }

  async respondPendingHealthChecks(pcBridgeId: string, now: Date): Promise<number> {
    const firestore = await this.getFirestore();
    const userIds = await this.resolveBridgeUserIds(firestore, pcBridgeId);

    const nowTimestamp = Timestamp.fromDate(now);
    let respondedCount = 0;

    for (const userId of userIds) {
      const healthChecks = await firestore
        .collection(`users/${userId}/pcBridges/${pcBridgeId}/healthChecks`)
        .where("status", "==", "requested")
        .limit(20)
        .get();

      for (const healthCheck of healthChecks.docs) {
        await firestore.runTransaction(async (transaction) => {
          const current = await transaction.get(healthCheck.ref);

          if (!current.exists || current.data()?.status !== "requested") {
            return;
          }

          if (current.data()?.targetPcBridgeId !== pcBridgeId) {
            return;
          }

          const bridgeRef = healthCheck.ref.parent.parent;
          if (!bridgeRef) {
            return;
          }

          transaction.update(healthCheck.ref, {
            status: "responded",
            respondedAt: nowTimestamp,
            respondingPcBridgeId: pcBridgeId,
            message: "PC bridge watcher responded.",
          });

          const requestedAt = current.data()?.requestedAt;
          const bridgeUpdate: Record<string, unknown> = {
            pcBridgeId,
            displayName: this.config.displayName,
            workspaceName: this.config.workspaceName,
            status: "active",
            version: "0.1.0",
            lastHealthCheckRespondedAt: nowTimestamp,
            lastHealthCheckStatus: "responded",
          };

          if (requestedAt) {
            bridgeUpdate.lastHealthCheckRequestedAt = requestedAt;
          }

          transaction.set(bridgeRef, bridgeUpdate, { merge: true });

          respondedCount += 1;
        });
      }
    }

    return respondedCount;
  }

  private async getFirestore(): Promise<Firestore> {
    if (this.firestorePromise) {
      return this.firestorePromise;
    }

    this.firestorePromise = this.initializeFirestore();
    return this.firestorePromise;
  }

  private async initializeFirestore(): Promise<Firestore> {
    const missing = [
      this.config.firebaseProjectId ? null : "firebaseProjectId",
      this.config.serviceAccountPath ? null : "serviceAccountPath",
    ].filter((value): value is string => value !== null);

    if (missing.length > 0) {
      throw new Error(`Firestore relay adapter is not configured. Missing config: ${missing.join(", ")}.`);
    }

    const serviceAccount = JSON.parse(await readFile(this.config.serviceAccountPath!, "utf8")) as object;
    const appName = `codex-remote-${this.config.pcBridgeId}`;
    const existing = getApps().find((app) => app.name === appName);
    const app =
      existing ??
      initializeApp(
        {
          credential: cert(serviceAccount),
          projectId: this.config.firebaseProjectId,
        },
        appName,
      );

    return getFirestore(app);
  }

  private async resolveBridgeUserIds(firestore: Firestore, pcBridgeId: string): Promise<string[]> {
    const userIds = new Set<string>();

    if (this.config.ownerUserId) {
      userIds.add(this.config.ownerUserId);
    }

    const users = await firestore
      .collection("users")
      .where("defaultPcBridgeId", "==", pcBridgeId)
      .limit(20)
      .get();

    for (const user of users.docs) {
      userIds.add(user.id);
    }

    return [...userIds];
  }
}

function commandDocument(firestore: Firestore, claim: CommandClaim) {
  return firestore.doc(`users/${claim.userId}/sessions/${claim.sessionId}/commands/${claim.commandId}`);
}

function getCommandPathIds(snapshot: DocumentSnapshot<DocumentData>): CommandClaim {
  const commandId = snapshot.id;
  const session = snapshot.ref.parent.parent;
  const user = session?.parent.parent;

  if (!session || !user) {
    throw new Error(`Unexpected command path: ${snapshot.ref.path}`);
  }

  return {
    userId: user.id,
    sessionId: session.id,
    commandId,
  };
}

function toRemoteCommand(
  userId: string,
  sessionId: string,
  commandId: string,
  data: DocumentData,
): RemoteCommand {
  return {
    userId,
    sessionId,
    commandId,
    text: String(data.text ?? ""),
    status: data.status,
    targetPcBridgeId: String(data.targetPcBridgeId ?? ""),
    createdByDeviceId: data.createdByDeviceId,
    createdAt: timestampToIso(data.createdAt),
    claimedAt: timestampToIso(data.claimedAt),
    claimedByPcBridgeId: data.claimedByPcBridgeId,
    claimExpiresAt: timestampToIso(data.claimExpiresAt),
    startedAt: timestampToIso(data.startedAt),
    completedAt: timestampToIso(data.completedAt),
    progressText: data.progressText,
    progressUpdatedAt: timestampToIso(data.progressUpdatedAt),
    codexModel: optionalString(data.codexModel),
    codexSandbox: isCodexSandbox(data.codexSandbox) ? data.codexSandbox : undefined,
    codexBypassSandbox: typeof data.codexBypassSandbox === "boolean" ? data.codexBypassSandbox : undefined,
    codexProfile: optionalString(data.codexProfile),
    resultText: data.resultText,
    errorText: data.errorText,
    notificationSentAt: timestampToIso(data.notificationSentAt),
  };
}

function sessionCodexOptions(data: DocumentData | undefined): Partial<RemoteCommand> {
  return {
    codexModel: optionalString(data?.codexModel),
    codexSandbox: isCodexSandbox(data?.codexSandbox) ? data?.codexSandbox : undefined,
    codexBypassSandbox: typeof data?.codexBypassSandbox === "boolean" ? data.codexBypassSandbox : undefined,
    codexProfile: optionalString(data?.codexProfile),
  };
}

function isClaimable(data: DocumentData | undefined, pcBridgeId: string, now: Date): boolean {
  if (!data || data.targetPcBridgeId !== pcBridgeId) {
    return false;
  }

  return data.status === "queued" || isExpiredRunning(data, now);
}

function isExpiredRunning(data: DocumentData, now: Date): boolean {
  if (data.status !== "running" || !(data.claimExpiresAt instanceof Timestamp)) {
    return false;
  }

  return data.claimExpiresAt.toMillis() <= now.getTime();
}

function timestampToIso(value: unknown): string {
  if (value instanceof Timestamp) {
    return value.toDate().toISOString();
  }

  if (typeof value === "string") {
    return value;
  }

  return "";
}

function preview(value: string): string {
  return value.length <= 120 ? value : `${value.slice(0, 117)}...`;
}

function optionalString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function isCodexSandbox(value: unknown): value is RemoteCommand["codexSandbox"] {
  return value === "read-only" || value === "workspace-write" || value === "danger-full-access";
}
