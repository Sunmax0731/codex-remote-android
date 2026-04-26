import type { BridgeConfig, CodexInvoker, CommandRepository } from "./types.js";

export type ProcessNextCommandInput = {
  config: BridgeConfig;
  repository: CommandRepository;
  invoker: CodexInvoker;
  now?: Date;
};

export type ProcessNextCommandResult =
  | {
      kind: "none";
    }
  | {
      kind: "processed";
      commandId: string;
      status: "completed" | "failed";
    };

export async function processNextCommand(input: ProcessNextCommandInput): Promise<ProcessNextCommandResult> {
  const now = input.now ?? new Date();

  const command = await input.repository.claimNextQueuedCommand(
    input.config.pcBridgeId,
    now,
    input.config.claimTtlSeconds,
  );

  if (!command) {
    return { kind: "none" };
  }

  const claim = {
    userId: command.userId,
    sessionId: command.sessionId,
    commandId: command.commandId,
  };

  const result = await input.invoker.invoke({
    command,
    workspacePath: input.config.workspacePath,
    onProgress: (progressText, progressAt) =>
      input.repository.updateProgress(claim, progressText, progressAt, input.config.claimTtlSeconds),
  });

  const completedAt = new Date();

  if (result.kind === "success") {
    await input.repository.markCompleted(claim, result.resultText, completedAt);
    return {
      kind: "processed",
      commandId: command.commandId,
      status: "completed",
    };
  }

  await input.repository.markFailed(claim, result.errorText, completedAt);
  return {
    kind: "processed",
    commandId: command.commandId,
    status: "failed",
  };
}
