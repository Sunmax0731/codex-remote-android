import type { BridgeConfig, CommandClaim, CommandRepository, RemoteCommand } from "./types.js";

export class FirestoreRelayRepository implements CommandRepository {
  private readonly config: BridgeConfig;

  constructor(config: BridgeConfig) {
    this.config = config;
  }

  async claimNextQueuedCommand(
    _pcBridgeId: string,
    _now: Date,
    _claimTtlSeconds: number,
  ): Promise<RemoteCommand | null> {
    throw this.notConfiguredError();
  }

  async markCompleted(_claim: CommandClaim, _resultText: string, _now: Date): Promise<void> {
    throw this.notConfiguredError();
  }

  async markFailed(_claim: CommandClaim, _errorText: string, _now: Date): Promise<void> {
    throw this.notConfiguredError();
  }

  async updateHeartbeat(_pcBridgeId: string, _now: Date): Promise<void> {
    throw this.notConfiguredError();
  }

  private notConfiguredError(): Error {
    const missing = [
      this.config.firebaseProjectId ? null : "firebaseProjectId",
      this.config.serviceAccountPath ? null : "serviceAccountPath",
    ].filter((value): value is string => value !== null);

    const suffix = missing.length > 0 ? ` Missing config: ${missing.join(", ")}.` : "";
    return new Error(`Firestore relay adapter is not implemented yet.${suffix}`);
  }
}
