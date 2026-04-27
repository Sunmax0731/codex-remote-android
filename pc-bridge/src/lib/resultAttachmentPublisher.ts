import { createHash } from "node:crypto";
import { basename, extname, isAbsolute, resolve } from "node:path";
import { readFile, stat } from "node:fs/promises";
import { cert, getApp, getApps, initializeApp, type App } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import type { BridgeConfig, CommandResultAttachment, RemoteCommand, ResultAttachmentPublisher } from "./types.js";

const maxResultAttachmentBytes = 25 * 1024 * 1024;
const imageContentTypes = new Map([
  [".gif", "image/gif"],
  [".jpeg", "image/jpeg"],
  [".jpg", "image/jpeg"],
  [".png", "image/png"],
  [".webp", "image/webp"],
]);

export function createResultAttachmentPublisher(config: BridgeConfig): ResultAttachmentPublisher {
  if (config.relayMode === "firestore") {
    return new FirebaseStorageResultAttachmentPublisher(config);
  }

  return new NoopResultAttachmentPublisher();
}

class NoopResultAttachmentPublisher implements ResultAttachmentPublisher {
  async publish(): Promise<CommandResultAttachment[]> {
    return [];
  }
}

class FirebaseStorageResultAttachmentPublisher implements ResultAttachmentPublisher {
  private appPromise: Promise<App> | null = null;

  constructor(private readonly config: BridgeConfig) {}

  async publish(command: RemoteCommand, resultText: string): Promise<CommandResultAttachment[]> {
    const paths = await resultImagePaths(resultText, this.config.workspacePath);
    if (paths.length === 0) {
      return [];
    }

    const app = await this.getApp();
    const bucketName = this.config.firebaseStorageBucket ?? defaultStorageBucket(this.config);
    const bucket = getStorage(app).bucket(bucketName);
    const uploaded: CommandResultAttachment[] = [];

    for (let index = 0; index < paths.length; index += 1) {
      const path = paths[index]!;
      const bytes = await readFile(path);
      const digest = createHash("sha256").update(bytes).digest("hex");
      const fileName = safeResultFileName(basename(path));
      const contentType = imageContentTypes.get(extname(path).toLowerCase())!;
      const id = `result_${index}_${digest.slice(0, 12)}`;
      const storagePath =
        `users/${command.userId}/sessions/${command.sessionId}/commands/${command.commandId}` +
        `/results/${id}/${fileName}`;

      await bucket.file(storagePath).save(bytes, {
        metadata: {
          contentType,
          metadata: {
            commandId: command.commandId,
            sha256: digest,
          },
        },
      });

      uploaded.push({
        id,
        type: "image",
        fileName,
        contentType,
        sizeBytes: bytes.length,
        storagePath,
        sha256: digest,
      });
    }

    return uploaded;
  }

  private async getApp(): Promise<App> {
    if (this.appPromise) {
      return this.appPromise;
    }

    this.appPromise = this.initializeApp();
    return this.appPromise;
  }

  private async initializeApp(): Promise<App> {
    const missing = [
      this.config.firebaseProjectId ? null : "firebaseProjectId",
      this.config.serviceAccountPath ? null : "serviceAccountPath",
    ].filter((value): value is string => value !== null);

    if (missing.length > 0) {
      throw new Error(`Result attachment publisher is not configured. Missing config: ${missing.join(", ")}.`);
    }

    const appName = `codex-remote-results-${this.config.pcBridgeId}`;
    const existing = getApps().find((app) => app.name === appName);
    if (existing) {
      return getApp(appName);
    }

    const serviceAccount = JSON.parse(await readFile(this.config.serviceAccountPath!, "utf8")) as object;
    return initializeApp(
      {
        credential: cert(serviceAccount),
        projectId: this.config.firebaseProjectId,
        storageBucket: this.config.firebaseStorageBucket ?? defaultStorageBucket(this.config),
      },
      appName,
    );
  }
}

export async function resultImagePaths(resultText: string, workspacePath: string): Promise<string[]> {
  const paths = new Set<string>();
  const markdownImage = /!\[[^\]]*]\(([^)\r\n]+)\)/g;
  let match: RegExpExecArray | null;

  while ((match = markdownImage.exec(resultText)) !== null) {
    const rawPath = normalizeImageReference(match[1]!);
    if (!rawPath || isRemoteReference(rawPath)) {
      continue;
    }

    const candidate = isAbsolute(rawPath) ? resolve(rawPath) : resolve(workspacePath, rawPath);
    if (await isReadableImage(candidate)) {
      paths.add(candidate);
    }
  }

  return [...paths];
}

function normalizeImageReference(value: string): string {
  return value.trim().replace(/^['"]|['"]$/g, "");
}

function isRemoteReference(value: string): boolean {
  return /^(https?:|data:|gs:)/i.test(value);
}

async function isReadableImage(path: string): Promise<boolean> {
  const contentType = imageContentTypes.get(extname(path).toLowerCase());
  if (!contentType) {
    return false;
  }

  try {
    const fileStat = await stat(path);
    return fileStat.isFile() && fileStat.size > 0 && fileStat.size <= maxResultAttachmentBytes;
  } catch {
    return false;
  }
}

function safeResultFileName(value: string): string {
  const sanitized = value
    .trim()
    .replaceAll(/[\\/:*?"<>|]/g, "_")
    .replaceAll(/\s+/g, "_")
    .replaceAll("..", "_");

  return sanitized.length > 0 ? sanitized : "result-image";
}

function defaultStorageBucket(config: BridgeConfig): string {
  if (!config.firebaseProjectId) {
    throw new Error("firebaseStorageBucket is required when firebaseProjectId is not configured.");
  }
  return `${config.firebaseProjectId}.firebasestorage.app`;
}
