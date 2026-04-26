import qrcode from "qrcode";

export type GoogleServicesJson = {
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

export type FirebaseSetupPayload = {
  schema: typeof firebaseClientQrSchema;
  projectId: string;
  apiKey: string;
  appId: string;
  messagingSenderId: string;
  storageBucket?: string;
};

export const firebaseClientQrSchema = "codex-remote.firebase-client.v1";

export function parseGoogleServicesJson(text: string): GoogleServicesJson {
  return JSON.parse(stripBom(text)) as GoogleServicesJson;
}

export function buildFirebaseSetupPayload(
  googleServices: GoogleServicesJson,
  packageName?: string,
): FirebaseSetupPayload {
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
  const apiKey = required(
    client.api_key?.[0]?.current_key,
    "client.api_key[0].current_key",
  );
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

export async function firebaseSetupPayloadToTerminalQr(
  payload: FirebaseSetupPayload,
): Promise<string> {
  return qrcode.toString(JSON.stringify(payload), {
    type: "terminal",
    errorCorrectionLevel: "M",
  });
}

export async function firebaseSetupPayloadToDataUrl(
  payload: FirebaseSetupPayload,
): Promise<string> {
  return qrcode.toDataURL(JSON.stringify(payload), {
    errorCorrectionLevel: "M",
    margin: 2,
    width: 640,
  });
}

export async function writeFirebaseSetupQrPng(
  payload: FirebaseSetupPayload,
  outPath: string,
): Promise<void> {
  await qrcode.toFile(outPath, JSON.stringify(payload), {
    errorCorrectionLevel: "M",
    margin: 2,
    width: 640,
  });
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

function stripBom(value: string): string {
  return value.charCodeAt(0) === 0xfeff ? value.slice(1) : value;
}
