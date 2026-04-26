export type RelayMode = "local" | "firestore";

export type BridgeConfig = {
  pcBridgeId: string;
  displayName: string;
  workspaceName: string;
  workspacePath: string;
  firebaseProjectId?: string;
  serviceAccountPath?: string;
  relayMode: RelayMode;
  localRelayPath: string;
  claimTtlSeconds: number;
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
  markCompleted(claim: CommandClaim, resultText: string, now: Date): Promise<void>;
  markFailed(claim: CommandClaim, errorText: string, now: Date): Promise<void>;
  updateHeartbeat(pcBridgeId: string, now: Date): Promise<void>;
};

export type CodexInvocation = {
  command: RemoteCommand;
  workspacePath: string;
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
