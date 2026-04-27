export type RelayMode = "local" | "firestore";

export type CodexMode = "stub" | "cli";

export type CodexSandbox = "read-only" | "workspace-write" | "danger-full-access";

export type BridgeConfig = {
  pcBridgeId: string;
  displayName: string;
  workspaceName: string;
  workspacePath: string;
  ownerUserId?: string;
  firebaseProjectId?: string;
  firebaseStorageBucket?: string;
  serviceAccountPath?: string;
  attachmentCachePath: string;
  relayMode: RelayMode;
  localRelayPath: string;
  claimTtlSeconds: number;
  pollIntervalSeconds: number;
  heartbeatIntervalSeconds: number;
  maxCommandsPerTick: number;
  codexMode: CodexMode;
  codexCommandPath: string;
  codexModel?: string;
  codexBypassSandbox: boolean;
  codexSandbox: CodexSandbox;
  codexTimeoutSeconds: number;
  codexProgressIntervalSeconds: number;
};

export type CommandStatus = "queued" | "running" | "completed" | "failed" | "canceled";

export type RemoteCommand = {
  userId: string;
  sessionId: string;
  commandId: string;
  text: string;
  status: CommandStatus;
  targetPcBridgeId: string;
  createdByDeviceId?: string;
  createdAt: string;
  claimedAt?: string;
  claimedByPcBridgeId?: string;
  claimExpiresAt?: string;
  startedAt?: string;
  completedAt?: string;
  progressText?: string;
  progressUpdatedAt?: string;
  codexModel?: string;
  codexSandbox?: CodexSandbox;
  codexBypassSandbox?: boolean;
  codexProfile?: string;
  codexConfigOverrides?: string[];
  codexEnableFeatures?: string[];
  codexDisableFeatures?: string[];
  codexImages?: string[];
  codexOss?: boolean;
  codexLocalProvider?: string;
  codexFullAuto?: boolean;
  codexAddDirs?: string[];
  codexSkipGitRepoCheck?: boolean;
  codexEphemeral?: boolean;
  codexIgnoreUserConfig?: boolean;
  codexIgnoreRules?: boolean;
  codexOutputSchema?: string;
  codexJson?: boolean;
  resultText?: string;
  errorText?: string;
  notificationSentAt?: string;
  attachments?: CommandAttachment[];
};

export type CommandAttachment = {
  id: string;
  type: "image" | "file";
  fileName: string;
  contentType: string;
  sizeBytes: number;
  storagePath: string;
  sha256: string;
};

export type CommandClaim = {
  userId: string;
  sessionId: string;
  commandId: string;
};

export type CommandRepository = {
  claimNextQueuedCommand(pcBridgeId: string, now: Date, claimTtlSeconds: number): Promise<RemoteCommand | null>;
  updateProgress(claim: CommandClaim, progressText: string, now: Date, claimTtlSeconds: number): Promise<void>;
  markCompleted(claim: CommandClaim, resultText: string, now: Date): Promise<void>;
  markFailed(claim: CommandClaim, errorText: string, now: Date): Promise<void>;
  updateHeartbeat(pcBridgeId: string, now: Date): Promise<void>;
  updateQueueCheck(pcBridgeId: string, now: Date): Promise<void>;
  respondPendingHealthChecks(pcBridgeId: string, now: Date): Promise<number>;
};

export type CodexInvocation = {
  command: RemoteCommand;
  workspacePath: string;
  onProgress?: (progressText: string, now: Date) => Promise<void>;
};

export type CodexInvocationResult =
  | {
      kind: "success";
      resultText: string;
    }
  | {
      kind: "failure";
      errorText: string;
    };

export type CodexInvoker = {
  invoke(input: CodexInvocation): Promise<CodexInvocationResult>;
};

export type PreparedCommandAttachments = {
  command: RemoteCommand;
  cleanup(): Promise<void>;
};

export type AttachmentDownloader = {
  prepare(command: RemoteCommand): Promise<PreparedCommandAttachments>;
};
