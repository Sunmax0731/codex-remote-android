import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import type { BridgeConfig, CodexInvocation, CodexInvocationResult, CodexInvoker } from "./types.js";

export function createCodexInvoker(_config: BridgeConfig): CodexInvoker {
  if (_config.codexMode === "cli") {
    return new CliCodexInvoker(_config);
  }

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

export class CliCodexInvoker implements CodexInvoker {
  private readonly config: BridgeConfig;

  constructor(config: BridgeConfig) {
    this.config = config;
  }

  async invoke(input: CodexInvocation): Promise<CodexInvocationResult> {
    const prompt = input.command.text.trim();

    if (prompt.length === 0) {
      return {
        kind: "failure",
        errorText: "空の指示は処理できません。",
      };
    }

    const tempRoot = await mkdtemp(join(tmpdir(), "codex-remote-cli-"));
    const outputPath = join(tempRoot, "last-message.txt");

    try {
      const result = await runCodexExec({
        commandPath: this.config.codexCommandPath,
        model: this.config.codexModel,
        workspacePath: this.config.workspacePath,
        sandbox: this.config.codexSandbox,
        timeoutSeconds: this.config.codexTimeoutSeconds,
        outputPath,
        prompt,
      });

      if (result.exitCode !== 0) {
        return {
          kind: "failure",
          errorText: cliErrorText(result, `Codex CLI failed with exit code ${result.exitCode}.`),
        };
      }

      const output = await readFile(outputPath, "utf8").catch(() => "");
      const finalMessage = output.trim();

      if (!finalMessage) {
        return {
          kind: "failure",
          errorText: cliErrorText(result, "Codex CLI completed without a final message."),
        };
      }

      return {
        kind: "success",
        resultText: finalMessage,
      };
    } finally {
      await rm(tempRoot, { recursive: true, force: true });
    }
  }
}

type RunCodexExecInput = {
  commandPath: string;
  model?: string;
  workspacePath: string;
  sandbox: string;
  timeoutSeconds: number;
  outputPath: string;
  prompt: string;
};

type RunCodexExecResult = {
  exitCode: number | null;
  stdout: string;
  stderr: string;
};

function runCodexExec(input: RunCodexExecInput): Promise<RunCodexExecResult> {
  const codexArgs = [
    "exec",
    "--cd",
    input.workspacePath,
    "--sandbox",
    input.sandbox,
    "--output-last-message",
    input.outputPath,
    "-",
  ];

  if (input.model) {
    codexArgs.splice(1, 0, "-m", input.model);
  }

  return new Promise((resolve) => {
    const launch = resolveLaunchCommand(input.commandPath, codexArgs);
    let child;

    try {
      child = spawn(launch.command, launch.args, {
        cwd: input.workspacePath,
        shell: false,
        windowsHide: true,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (error: unknown) {
      resolve({
        exitCode: 1,
        stdout: "",
        stderr: error instanceof Error ? error.message : String(error),
      });
      return;
    }

    let stdout = "";
    let stderr = "";
    let settled = false;

    const timeout = setTimeout(() => {
      if (!settled) {
        child.kill();
        stderr += `Codex CLI timed out after ${input.timeoutSeconds} seconds.`;
      }
    }, input.timeoutSeconds * 1000);

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    child.stdout.on("data", (chunk: string) => {
      stdout += chunk;
    });

    child.stderr.on("data", (chunk: string) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      settled = true;
      clearTimeout(timeout);
      resolve({
        exitCode: 1,
        stdout,
        stderr: stderr + error.message,
      });
    });

    child.on("close", (exitCode) => {
      settled = true;
      clearTimeout(timeout);
      resolve({
        exitCode,
        stdout,
        stderr,
      });
    });

    child.stdin.end(input.prompt, "utf8");
  });
}

function resolveLaunchCommand(commandPath: string, args: string[]): { command: string; args: string[] } {
  if (process.platform === "win32" && /\.(cmd|bat)$/i.test(commandPath)) {
    return {
      command: "cmd.exe",
      args: ["/d", "/s", "/c", commandPath, ...args],
    };
  }

  return {
    command: commandPath,
    args,
  };
}

function cliErrorText(result: RunCodexExecResult, fallback: string): string {
  const stderr = result.stderr.trim();
  const stdout = result.stdout.trim();
  const detail = [stderr, stdout].filter((value) => value.length > 0).join("\n\n");

  if (!detail) {
    return fallback;
  }

  return `${fallback}\n\n${detail}`;
}
