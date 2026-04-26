import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import type { CommandClaim, CommandRepository, RemoteCommand } from "./types.js";

type RelayState = {
  users: Record<string, UserState>;
};

type UserState = {
  pcBridges?: Record<string, Record<string, unknown>>;
  sessions: Record<string, SessionState>;
};

type SessionState = {
  status?: string;
  targetPcBridgeId?: string;
  updatedAt?: string;
  lastCommandId?: string;
  lastResultPreview?: string;
  lastErrorPreview?: string;
  commands: Record<string, CommandState>;
};

type CommandState = Omit<RemoteCommand, "userId" | "sessionId" | "commandId">;

export class LocalRelayRepository implements CommandRepository {
  private readonly relayPath: string;

  constructor(relayPath: string) {
    this.relayPath = resolve(relayPath);
  }

  async claimNextQueuedCommand(pcBridgeId: string, now: Date, claimTtlSeconds: number): Promise<RemoteCommand | null> {
    const state = await this.readState();
    const nowIso = now.toISOString();
    const claimExpiresAt = new Date(now.getTime() + claimTtlSeconds * 1000).toISOString();

    for (const [userId, user] of Object.entries(state.users)) {
      for (const [sessionId, session] of Object.entries(user.sessions)) {
        for (const [commandId, command] of Object.entries(session.commands)) {
          if (!isClaimable(command, pcBridgeId, now)) {
            continue;
          }

          command.status = "running";
          command.claimedAt = nowIso;
          command.claimedByPcBridgeId = pcBridgeId;
          command.claimExpiresAt = claimExpiresAt;
          command.startedAt = nowIso;
          session.status = "running";
          session.updatedAt = nowIso;
          session.lastCommandId = commandId;

          await this.writeState(state);

          return toRemoteCommand(userId, sessionId, commandId, command);
        }
      }
    }

    return null;
  }

  async markCompleted(claim: CommandClaim, resultText: string, now: Date): Promise<void> {
    await this.updateClaimedCommand(claim, now, (session, command, nowIso) => {
      command.status = "completed";
      command.completedAt = nowIso;
      command.resultText = resultText;
      delete command.errorText;
      session.status = "completed";
      session.updatedAt = nowIso;
      session.lastResultPreview = preview(resultText);
      delete session.lastErrorPreview;
    });
  }

  async markFailed(claim: CommandClaim, errorText: string, now: Date): Promise<void> {
    await this.updateClaimedCommand(claim, now, (session, command, nowIso) => {
      command.status = "failed";
      command.completedAt = nowIso;
      command.errorText = errorText;
      delete command.resultText;
      session.status = "failed";
      session.updatedAt = nowIso;
      session.lastErrorPreview = preview(errorText);
    });
  }

  async updateHeartbeat(pcBridgeId: string, now: Date): Promise<void> {
    const state = await this.readState();

    for (const user of Object.values(state.users)) {
      const bridge = user.pcBridges?.[pcBridgeId];
      if (bridge) {
        bridge.lastSeenAt = now.toISOString();
        bridge.status = "active";
      }
    }

    await this.writeState(state);
  }

  private async updateClaimedCommand(
    claim: CommandClaim,
    now: Date,
    update: (session: SessionState, command: CommandState, nowIso: string) => void,
  ): Promise<void> {
    const state = await this.readState();
    const session = state.users[claim.userId]?.sessions[claim.sessionId];
    const command = session?.commands[claim.commandId];

    if (!session || !command) {
      throw new Error(`Command not found: ${claim.userId}/${claim.sessionId}/${claim.commandId}`);
    }

    update(session, command, now.toISOString());
    await this.writeState(state);
  }

  private async readState(): Promise<RelayState> {
    try {
      const text = await readFile(this.relayPath, "utf8");
      return JSON.parse(text) as RelayState;
    } catch (error) {
      if (isNodeError(error) && error.code === "ENOENT") {
        return { users: {} };
      }

      throw error;
    }
  }

  private async writeState(state: RelayState): Promise<void> {
    await mkdir(dirname(this.relayPath), { recursive: true });
    await writeFile(this.relayPath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
  }
}

function isClaimable(command: CommandState, pcBridgeId: string, now: Date): boolean {
  if (command.targetPcBridgeId !== pcBridgeId) {
    return false;
  }

  if (command.status === "queued") {
    return true;
  }

  if (command.status !== "running" || !command.claimExpiresAt) {
    return false;
  }

  const claimExpiresAt = Date.parse(command.claimExpiresAt);
  return Number.isFinite(claimExpiresAt) && claimExpiresAt <= now.getTime();
}

function toRemoteCommand(userId: string, sessionId: string, commandId: string, command: CommandState): RemoteCommand {
  return {
    userId,
    sessionId,
    commandId,
    ...command,
  };
}

function preview(value: string): string {
  return value.length <= 120 ? value : `${value.slice(0, 117)}...`;
}

function isNodeError(error: unknown): error is NodeJS.ErrnoException {
  return error instanceof Error && "code" in error;
}
