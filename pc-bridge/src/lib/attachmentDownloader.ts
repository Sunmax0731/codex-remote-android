import { createHash } from "node:crypto";
import { mkdir, readFile, rm, stat } from "node:fs/promises";
import { dirname, resolve, sep } from "node:path";
import { cert, getApp, getApps, initializeApp, type App } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import type {
  AttachmentDownloader,
  BridgeConfig,
  CommandAttachment,
  PreparedCommandAttachments,
  RemoteCommand,
} from "./types.js";

const maxAttachmentBytes = 25 * 1024 * 1024;
const allowedContentTypes = new Set([
  "application/json",
  "application/pdf",
  "application/x-yaml",
  "image/gif",
  "image/jpeg",
  "image/png",
  "image/webp",
  "text/markdown",
  "text/plain",
]);

export function createAttachmentDownloader(config: BridgeConfig): AttachmentDownloader {
  if (config.relayMode === "firestore") {
    return new FirebaseStorageAttachmentDownloader(config);
  }

  return new NoopAttachmentDownloader();
}

class NoopAttachmentDownloader implements AttachmentDownloader {
  async prepare(command: RemoteCommand): Promise<PreparedCommandAttachments> {
    if ((command.attachments ?? []).length > 0) {
      throw new Error("Command attachments require firestore relay mode.");
    }

    return {
      command,
      async cleanup() {},
    };
  }
}

class FirebaseStorageAttachmentDownloader implements AttachmentDownloader {
  private readonly config: BridgeConfig;
  private appPromise: Promise<App> | null = null;

  constructor(config: BridgeConfig) {
    this.config = config;
  }

  async prepare(command: RemoteCommand): Promise<PreparedCommandAttachments> {
    const attachments = command.attachments ?? [];
    if (attachments.length === 0) {
      return {
        command,
        async cleanup() {},
      };
    }

    const app = await this.getApp();
    const bucketName = this.config.firebaseStorageBucket ?? defaultStorageBucket(this.config);
    const bucket = getStorage(app).bucket(bucketName);
    const commandCacheRoot = attachmentCommandRoot(this.config, command);
    const imagePaths: string[] = [];
    const addDirs = new Set(command.codexAddDirs ?? []);
    const promptLines: string[] = [];

    try {
      for (const attachment of attachments) {
        validateAttachment(command, attachment);
        const targetDirectory = attachmentDirectory(commandCacheRoot, attachment);
        const targetPath = resolve(targetDirectory, attachment.fileName);
        assertInside(targetPath, commandCacheRoot);
        await mkdir(dirname(targetPath), { recursive: true });

        const file = bucket.file(attachment.storagePath);
        const [metadata] = await file.getMetadata();
        const remoteSize = Number(metadata.size ?? 0);
        if (!Number.isFinite(remoteSize) || remoteSize <= 0 || remoteSize > maxAttachmentBytes) {
          throw new Error(`Attachment size is invalid: ${attachment.fileName}`);
        }
        if (metadata.contentType && metadata.contentType !== attachment.contentType) {
          throw new Error(`Attachment content type changed: ${attachment.fileName}`);
        }

        await file.download({ destination: targetPath });
        await verifyDownloadedAttachment(attachment, targetPath);

        if (attachment.type === "image") {
          imagePaths.push(targetPath);
          promptLines.push(`- ${attachment.fileName}: ${targetPath} (image)`);
        } else {
          addDirs.add(targetDirectory);
          promptLines.push(`- ${attachment.fileName}: ${targetPath}`);
        }
      }

      const commandWithAttachments: RemoteCommand = {
        ...command,
        text: promptLines.length > 0 ? `${command.text.trim()}\n\nAttached files:\n${promptLines.join("\n")}`.trim() : command.text,
        codexImages: [...(command.codexImages ?? []), ...imagePaths],
        codexAddDirs: [...addDirs],
      };

      return {
        command: commandWithAttachments,
        cleanup: async () => {
          await rm(commandCacheRoot, { recursive: true, force: true });
        },
      };
    } catch (error) {
      await rm(commandCacheRoot, { recursive: true, force: true });
      throw error;
    }
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
      throw new Error(`Attachment downloader is not configured. Missing config: ${missing.join(", ")}.`);
    }

    const appName = `codex-remote-attachments-${this.config.pcBridgeId}`;
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

function defaultStorageBucket(config: BridgeConfig): string {
  if (!config.firebaseProjectId) {
    throw new Error("firebaseStorageBucket is required when firebaseProjectId is not configured.");
  }
  return `${config.firebaseProjectId}.firebasestorage.app`;
}

function validateAttachment(command: RemoteCommand, attachment: CommandAttachment): void {
  if (!/^att_[A-Za-z0-9_-]+$/.test(attachment.id)) {
    throw new Error(`Attachment id is invalid: ${attachment.id}`);
  }
  if (attachment.type !== "image" && attachment.type !== "file") {
    throw new Error(`Attachment type is invalid: ${attachment.fileName}`);
  }
  if (!/^[^/\\]{1,160}$/.test(attachment.fileName)) {
    throw new Error(`Attachment file name is invalid: ${attachment.fileName}`);
  }
  if (!allowedContentTypes.has(attachment.contentType)) {
    throw new Error(`Attachment content type is not allowed: ${attachment.fileName}`);
  }
  if (!Number.isInteger(attachment.sizeBytes) || attachment.sizeBytes <= 0 || attachment.sizeBytes > maxAttachmentBytes) {
    throw new Error(`Attachment size is invalid: ${attachment.fileName}`);
  }
  if (!/^[a-f0-9]{64}$/.test(attachment.sha256)) {
    throw new Error(`Attachment hash is invalid: ${attachment.fileName}`);
  }

  const expectedPrefix =
    `users/${command.userId}/sessions/${command.sessionId}/commands/${command.commandId}` +
    `/attachments/${attachment.id}/`;
  const expectedPath = `${expectedPrefix}${attachment.fileName}`;
  if (attachment.storagePath !== expectedPath) {
    throw new Error(`Attachment storage path is invalid: ${attachment.fileName}`);
  }
}

function attachmentCommandRoot(config: BridgeConfig, command: RemoteCommand): string {
  return resolve(config.attachmentCachePath, command.userId, command.sessionId, command.commandId);
}

function attachmentDirectory(commandCacheRoot: string, attachment: CommandAttachment): string {
  return resolve(commandCacheRoot, attachment.id);
}

async function verifyDownloadedAttachment(attachment: CommandAttachment, targetPath: string): Promise<void> {
  const fileStat = await stat(targetPath);
  if (fileStat.size !== attachment.sizeBytes) {
    throw new Error(`Attachment downloaded size mismatch: ${attachment.fileName}`);
  }

  const digest = createHash("sha256").update(await readFile(targetPath)).digest("hex");
  if (digest !== attachment.sha256) {
    throw new Error(`Attachment downloaded hash mismatch: ${attachment.fileName}`);
  }
}

function assertInside(targetPath: string, rootPath: string): void {
  const normalizedRoot = rootPath.endsWith(sep) ? rootPath : `${rootPath}${sep}`;
  if (targetPath !== rootPath && !targetPath.startsWith(normalizedRoot)) {
    throw new Error(`Attachment path escapes cache root: ${targetPath}`);
  }
}
