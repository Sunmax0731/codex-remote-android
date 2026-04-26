import type { BridgeConfig, CodexInvocation, CodexInvocationResult, CodexInvoker } from "./types.js";

export function createCodexInvoker(_config: BridgeConfig): CodexInvoker {
  return new SafeStubCodexInvoker();
}

export class SafeStubCodexInvoker implements CodexInvoker {
  async invoke(input: CodexInvocation): Promise<CodexInvocationResult> {
    const text = input.command.text.trim();

    if (text.length === 0) {
      return {
        kind: "failure",
        errorText: "空の指示は処理できません。",
      };
    }

    if (text.startsWith("/fail")) {
      return {
        kind: "failure",
        errorText: "検証用の失敗指示として処理しました。",
      };
    }

    return {
      kind: "success",
      resultText: [
        "PCブリッジが指示を受け取りました。",
        `workspace: ${input.workspacePath}`,
        `commandId: ${input.command.commandId}`,
      ].join("\n"),
    };
  }
}
