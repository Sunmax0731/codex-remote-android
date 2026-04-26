import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import qrcode from "qrcode";

type GoogleServicesJson = {
  project_info?: {
    project_number?: string;
    project_id?: string;
    storage_bucket?: string;
  };
  client?: Array<{
    client_info?: {
      mobilesdk_app_id?: string;
      android_client_info?: {
        package_name?: string;
      };
    };
    api_key?: Array<{
      current_key?: string;
    }>;
  }>;
};

type CliOptions = {
  googleServicesPath: string;
  packageName?: string;
  outPath?: string;
  showPayload: boolean;
};

const firebaseClientQrSchema = "codex-remote.firebase-client.v1";

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const googleServicesText = stripBom(
    await readFile(resolve(options.googleServicesPath), "utf8"),
  );
  const googleServices = JSON.parse(googleServicesText) as GoogleServicesJson;

  const payload = buildPayload(googleServices, options.packageName);
  const payloadText = JSON.stringify(payload);
  const terminalQr = await qrcode.toString(payloadText, {
    type: "terminal",
    errorCorrectionLevel: "M",
  });

  console.log(terminalQr);
  console.log("Scan this QR from the Android Firebase setup screen.");
  console.log("Included fields: projectId, apiKey, appId, messagingSenderId, storageBucket.");
  console.log("Not included: service account JSON, Admin SDK credentials.");

  if (options.outPath) {
    await qrcode.toFile(resolve(options.outPath), payloadText, {
      errorCorrectionLevel: "M",
      margin: 2,
      width: 640,
    });
    console.log(`PNG written to ${options.outPath}`);
  }

  if (options.showPayload) {
    console.log(payloadText);
  }
}

function buildPayload(googleServices: GoogleServicesJson, packageName?: string): Record<string, string> {
  const projectInfo = googleServices.project_info;
  const client = selectClient(googleServices.client ?? [], packageName);
  const projectId = required(projectInfo?.project_id, "project_info.project_id");
  const messagingSenderId = required(
    projectInfo?.project_number,
    "project_info.project_number",
  );
  const appId = required(
    client.client_info?.mobilesdk_app_id,
    "client.client_info.mobilesdk_app_id",
  );
  const apiKey = required(client.api_key?.[0]?.current_key, "client.api_key[0].current_key");
  const storageBucket = projectInfo?.storage_bucket?.trim();

  return {
    schema: firebaseClientQrSchema,
    projectId,
    apiKey,
    appId,
    messagingSenderId,
    ...(storageBucket ? { storageBucket } : {}),
  };
}

function selectClient(
  clients: NonNullable<GoogleServicesJson["client"]>,
  packageName?: string,
): NonNullable<GoogleServicesJson["client"]>[number] {
  if (clients.length === 0) {
    throw new Error("google-services.json does not contain any client entries.");
  }

  if (!packageName) {
    return clients[0]!;
  }

  const found = clients.find(
    (client) =>
      client.client_info?.android_client_info?.package_name === packageName,
  );
  if (!found) {
    throw new Error(`No Android client found for package name: ${packageName}`);
  }

  return found;
}

function required(value: string | undefined, field: string): string {
  const trimmed = value?.trim();
  if (!trimmed) {
    throw new Error(`Missing required google-services.json field: ${field}`);
  }

  return trimmed;
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

function stripBom(value: string): string {
  return value.charCodeAt(0) === 0xfeff ? value.slice(1) : value;
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
