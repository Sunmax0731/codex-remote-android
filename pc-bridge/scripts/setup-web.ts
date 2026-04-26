import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  buildFirebaseSetupPayload,
  firebaseSetupPayloadToDataUrl,
  parseGoogleServicesJson,
} from "../src/lib/firebaseSetupQr.js";

type GenerateRequest = {
  googleServicesJson?: string;
  packageName?: string;
};

const currentDir = fileURLToPath(new URL(".", import.meta.url));
const rootDir = resolve(currentDir, "..", "..");
const publicDir = join(rootDir, "setup-web");
const port = Number(process.env.CODEX_REMOTE_SETUP_PORT ?? 8787);

const contentTypes: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
};

const server = createServer(async (request, response) => {
  try {
    if (request.method === "POST" && request.url === "/api/firebase-setup-qr") {
      await handleGenerateQr(request, response);
      return;
    }

    if (request.method === "GET") {
      await serveStatic(request, response);
      return;
    }

    sendJson(response, 405, { error: "Method not allowed." });
  } catch (error) {
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Codex Remote setup UI: http://127.0.0.1:${port}`);
});

async function handleGenerateQr(
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  const body = (await readRequestBody(request)).trim();
  if (!body) {
    sendJson(response, 400, { error: "Request body is empty." });
    return;
  }

  const data = JSON.parse(body) as GenerateRequest;
  if (!data.googleServicesJson?.trim()) {
    sendJson(response, 400, { error: "google-services.json is required." });
    return;
  }

  const googleServices = parseGoogleServicesJson(data.googleServicesJson);
  const payload = buildFirebaseSetupPayload(
    googleServices,
    data.packageName?.trim() || undefined,
  );
  const qrDataUrl = await firebaseSetupPayloadToDataUrl(payload);

  sendJson(response, 200, { payload, qrDataUrl });
}

async function serveStatic(
  request: IncomingMessage,
  response: ServerResponse,
): Promise<void> {
  const requestUrl = new URL(request.url ?? "/", `http://127.0.0.1:${port}`);
  const pathname = requestUrl.pathname === "/" ? "/index.html" : requestUrl.pathname;
  const filePath = normalize(join(publicDir, decodeURIComponent(pathname)));

  if (!filePath.startsWith(publicDir)) {
    sendText(response, 403, "Forbidden");
    return;
  }

  try {
    const content = await readFile(filePath);
    response.writeHead(200, {
      "Content-Type": contentTypes[extname(filePath)] ?? "application/octet-stream",
      "Cache-Control": "no-store",
    });
    response.end(content);
  } catch {
    sendText(response, 404, "Not found");
  }
}

async function readRequestBody(request: IncomingMessage): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    if (Buffer.concat(chunks).byteLength > 2_000_000) {
      throw new Error("Request body is too large.");
    }
  }
  return Buffer.concat(chunks).toString("utf8");
}

function sendJson(
  response: ServerResponse,
  statusCode: number,
  body: unknown,
): void {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(JSON.stringify(body));
}

function sendText(
  response: ServerResponse,
  statusCode: number,
  body: string,
): void {
  response.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(body);
}
