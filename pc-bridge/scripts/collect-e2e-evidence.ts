import { readFile } from "node:fs/promises";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { Timestamp, getFirestore, type DocumentData } from "firebase-admin/firestore";
import { loadBridgeConfig } from "../src/lib/config.js";
import { redactSensitiveText } from "../src/lib/redaction.js";

type Args = {
  configPath: string;
  uid?: string;
  sessionId?: string;
  commandId?: string;
};

const args = parseArgs(process.argv.slice(2));
const config = await loadBridgeConfig(args.configPath);
const userId = args.uid ?? config.ownerUserId;

if (!userId) {
  throw new Error("Pass --uid or set ownerUserId in config.local.json.");
}

if (!config.firebaseProjectId || !config.serviceAccountPath) {
  throw new Error("Firestore evidence requires firebaseProjectId and serviceAccountPath in config.local.json.");
}

const serviceAccount = JSON.parse(await readFile(config.serviceAccountPath, "utf8")) as object;
const appName = `codex-remote-e2e-${config.pcBridgeId}`;
const app = getApps().find((candidate) => candidate.name === appName) ??
  initializeApp(
    {
      credential: cert(serviceAccount),
      projectId: config.firebaseProjectId,
    },
    appName,
  );
const firestore = getFirestore(app);

const sessionDoc = args.sessionId
  ? await firestore.doc(`users/${userId}/sessions/${args.sessionId}`).get()
  : await latestDoc(`users/${userId}/sessions`, "updatedAt");

const commandDoc = sessionDoc?.exists
  ? args.commandId
    ? await sessionDoc.ref.collection("commands").doc(args.commandId).get()
    : await latestDoc(`${sessionDoc.ref.path}/commands`, "createdAt")
  : undefined;

const bridgeDoc = await firestore.doc(`users/${userId}/pcBridges/${config.pcBridgeId}`).get();

const evidence = {
  generatedAt: new Date().toISOString(),
  firebase: {
    projectId: maskProjectId(config.firebaseProjectId),
    userId: maskId(userId),
    pcBridgeId: maskId(config.pcBridgeId),
  },
  pcBridge: bridgeDoc.exists ? summarizeBridge(bridgeDoc.data()) : { exists: false },
  session: sessionDoc?.exists ? summarizeSession(sessionDoc.id, sessionDoc.data()) : { exists: false },
  command: commandDoc?.exists ? summarizeCommand(commandDoc.id, commandDoc.data()) : { exists: false },
};

console.log(JSON.stringify(evidence, null, 2));

async function latestDoc(collectionPath: string, orderByField: string) {
  const snapshot = await firestore.collection(collectionPath).orderBy(orderByField, "desc").limit(1).get();
  return snapshot.docs[0];
}

function summarizeBridge(data: DocumentData | undefined) {
  return {
    exists: true,
    status: optionalString(data?.status),
    displayName: optionalString(data?.displayName),
    workspaceName: optionalString(data?.workspaceName),
    lastSeenAt: timestampToIso(data?.lastSeenAt),
    lastQueueCheckedAt: timestampToIso(data?.lastQueueCheckedAt),
    lastHealthCheckRequestedAt: timestampToIso(data?.lastHealthCheckRequestedAt),
    lastHealthCheckRespondedAt: timestampToIso(data?.lastHealthCheckRespondedAt),
    lastHealthCheckStatus: optionalString(data?.lastHealthCheckStatus),
  };
}

function summarizeSession(id: string, data: DocumentData | undefined) {
  return {
    id,
    title: redact(data?.title),
    status: optionalString(data?.status),
    updatedAt: timestampToIso(data?.updatedAt),
    lastCommandId: optionalString(data?.lastCommandId),
    lastResultPreview: redact(data?.lastResultPreview),
    lastErrorPreview: redact(data?.lastErrorPreview),
  };
}

function summarizeCommand(id: string, data: DocumentData | undefined) {
  return {
    exists: true,
    id,
    text: redact(data?.text),
    status: optionalString(data?.status),
    targetPcBridgeId: maskId(optionalString(data?.targetPcBridgeId)),
    claimedByPcBridgeId: maskId(optionalString(data?.claimedByPcBridgeId)),
    createdAt: timestampToIso(data?.createdAt),
    startedAt: timestampToIso(data?.startedAt),
    completedAt: timestampToIso(data?.completedAt),
    notificationSentAt: timestampToIso(data?.notificationSentAt),
    notificationSuccessCount: numberOrNull(data?.notificationSuccessCount),
    notificationFailureCount: numberOrNull(data?.notificationFailureCount),
    notificationLastError: redact(data?.notificationLastError),
    resultPreview: preview(redact(data?.resultText)),
    errorPreview: preview(redact(data?.errorText)),
  };
}

function parseArgs(values: string[]): Args {
  const result: Args = {
    configPath: process.env.CODEX_REMOTE_BRIDGE_CONFIG ?? "config.local.json",
  };

  for (let index = 0; index < values.length; index += 1) {
    const value = values[index];
    const next = values[index + 1];
    if (value === "--config" && next) {
      result.configPath = next;
      index += 1;
    } else if (value === "--uid" && next) {
      result.uid = next;
      index += 1;
    } else if (value === "--session-id" && next) {
      result.sessionId = next;
      index += 1;
    } else if (value === "--command-id" && next) {
      result.commandId = next;
      index += 1;
    }
  }

  return result;
}

function timestampToIso(value: unknown): string | undefined {
  if (value instanceof Timestamp) {
    return value.toDate().toISOString();
  }

  if (typeof value === "string" && value.trim().length > 0) {
    return value;
  }

  return undefined;
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function numberOrNull(value: unknown): number | null {
  return typeof value === "number" ? value : null;
}

function redact(value: unknown): string | undefined {
  return typeof value === "string" ? redactSensitiveText(value) : undefined;
}

function preview(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  return value.length <= 240 ? value : `${value.slice(0, 237)}...`;
}

function maskId(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }

  return value.length <= 8 ? "***" : `${value.slice(0, 4)}...${value.slice(-4)}`;
}

function maskProjectId(value: string): string {
  const [prefix] = value.split("-");
  return `${prefix}-***`;
}
