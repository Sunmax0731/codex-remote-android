import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import {
  buildFirebaseSetupPayload,
  firebaseSetupPayloadToTerminalQr,
  parseGoogleServicesJson,
  writeFirebaseSetupQrPng,
} from "../src/lib/firebaseSetupQr.js";

type CliOptions = {
  googleServicesPath: string;
  packageName?: string;
  outPath?: string;
  showPayload: boolean;
};

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const googleServices = parseGoogleServicesJson(
    await readFile(resolve(options.googleServicesPath), "utf8"),
  );

  const payload = buildFirebaseSetupPayload(
    googleServices,
    options.packageName,
  );
  const terminalQr = await firebaseSetupPayloadToTerminalQr(payload);

  console.log(terminalQr);
  console.log("Scan this QR from the Android Firebase setup screen.");
  console.log(
    "Included fields: projectId, apiKey, appId, messagingSenderId, storageBucket.",
  );
  console.log("Not included: service account JSON, Admin SDK credentials.");

  if (options.outPath) {
    await writeFirebaseSetupQrPng(payload, resolve(options.outPath));
    console.log(`PNG written to ${options.outPath}`);
  }

  if (options.showPayload) {
    console.log(JSON.stringify(payload));
  }
}

function parseArgs(args: string[]): CliOptions {
  let googleServicesPath = "../app/android/app/google-services.json";
  let packageName: string | undefined;
  let outPath: string | undefined;
  let showPayload = false;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    switch (arg) {
      case "--google-services":
        googleServicesPath = requiredArg(args, ++index, arg);
        break;
      case "--package":
        packageName = requiredArg(args, ++index, arg);
        break;
      case "--out":
        outPath = requiredArg(args, ++index, arg);
        break;
      case "--show-payload":
        showPayload = true;
        break;
      case "--help":
      case "-h":
        printHelp();
        process.exit(0);
      default:
        throw new Error(`Unknown option: ${arg}`);
    }
  }

  return {
    googleServicesPath,
    packageName,
    outPath,
    showPayload,
  };
}

function requiredArg(args: string[], index: number, option: string): string {
  const value = args[index];
  if (!value || value.startsWith("--")) {
    throw new Error(`${option} requires a value.`);
  }
  return value;
}

function printHelp(): void {
  console.log(`Usage: npm run qr:firebase -- [options]

Options:
  --google-services <path>  Path to google-services.json.
                            Default: ../app/android/app/google-services.json
  --package <name>          Android package name to select when multiple clients exist.
  --out <path>              Also write the QR code as a PNG file.
  --show-payload            Print the JSON payload after the QR code.
`);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
