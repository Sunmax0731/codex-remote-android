import { redactSensitiveText } from "./redaction.js";
import type {
  AttachmentDownloader,
  BridgeConfig,
  CodexInvocationResult,
  CodexInvoker,
  CommandRepository,
  ResultAttachmentPublisher,
} from "./types.js";

export type ProcessNextCommandInput = {
  config: BridgeConfig;
  repository: CommandRepository;
  invoker: CodexInvoker;
  attachmentDownloader?: AttachmentDownloader;
  resultAttachmentPublisher?: ResultAttachmentPublisher;
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

  const prepared = await (input.attachmentDownloader?.prepare(command) ?? {
    command,
    async cleanup() {},
  });

  let result: CodexInvocationResult;
  try {
    result = await input.invoker.invoke({
      command: prepared.command,
      workspacePath: input.config.workspacePath,
      onProgress: (progressText, progressAt) =>
        input.repository.updateProgress(
          claim,
          redactSensitiveText(progressText),
          progressAt,
          input.config.claimTtlSeconds,
        ),
    });
  } finally {
    await prepared.cleanup();
  }

  const completedAt = new Date();

  if (result.kind === "success") {
    const resultText = redactSensitiveText(result.resultText);
    const resultAttachments =
      (await input.resultAttachmentPublisher?.publish(prepared.command, resultText)) ?? [];
    await input.repository.markCompleted(claim, resultText, completedAt, resultAttachments);
    return {
      kind: "processed",
      commandId: command.commandId,
      status: "completed",
    };
  }

  await input.repository.markFailed(claim, redactSensitiveText(result.errorText), completedAt);
  return {
    kind: "processed",
    commandId: command.commandId,
    status: "failed",
  };
}
