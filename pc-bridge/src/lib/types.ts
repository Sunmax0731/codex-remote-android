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
  serviceAccountPath?: string;
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
  resultText?: string;
  errorText?: string;
  notificationSentAt?: string;
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
