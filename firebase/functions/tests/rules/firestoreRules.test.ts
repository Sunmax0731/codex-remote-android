import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test, { after, before } from "node:test";
import assert from "node:assert/strict";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

const projectId = "codex-remote-rules-test";
let testEnv: RulesTestEnvironment;

before(async () => {
  const firestore = emulatorHost("FIRESTORE_EMULATOR_HOST", "127.0.0.1:18080");
  const storage = emulatorHost("FIREBASE_STORAGE_EMULATOR_HOST", "127.0.0.1:19199");

  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: firestore.host,
      port: firestore.port,
      rules: readFileSync(resolve("..", "firestore.rules"), "utf8"),
    },
    storage: {
      host: storage.host,
      port: storage.port,
      rules: readFileSync(resolve("..", "storage.rules"), "utf8"),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

test("owner can read own session and queued command", async () => {
  await testEnv.clearFirestore();
  await seedOwnSession();

  const db = testEnv.authenticatedContext("userA").firestore();

  await assertSucceeds(getDoc(doc(db, "users/userA/sessions/sessionA")));
  await assertSucceeds(getDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA")));
});

test("owner can create queued commands under own user", async () => {
  await testEnv.clearFirestore();
  const db = testEnv.authenticatedContext("userA").firestore();

  await assertSucceeds(
    setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), {
      text: "hello",
      status: "queued",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
    }),
  );
});

test("owner can create queued commands with valid attachments", async () => {
  await testEnv.clearFirestore();
  const db = testEnv.authenticatedContext("userA").firestore();

  await assertSucceeds(
    setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), {
      text: "inspect this file",
      status: "queued",
      targetPcBridgeId: "pc-a",
      createdByDeviceId: "android-app",
      attachments: [
        {
          id: "att_123_0",
          type: "image",
          fileName: "screen.png",
          contentType: "image/png",
          sizeBytes: 1024,
          storagePath:
            "users/userA/sessions/sessionA/commands/commandA/attachments/att_123_0/screen.png",
          sha256: "a".repeat(64),
        },
      ],
      createdAt: "2026-04-27T00:00:00.000Z",
    }),
  );
});

test("owner cannot create commands with invalid attachment metadata", async () => {
  await testEnv.clearFirestore();
  const db = testEnv.authenticatedContext("userA").firestore();

  await assertFails(
    setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), {
      text: "run this",
      status: "queued",
      targetPcBridgeId: "pc-a",
      attachments: [
        {
          id: "att_123_0",
          type: "file",
          fileName: "../script.ps1",
          contentType: "application/octet-stream",
          sizeBytes: 26 * 1024 * 1024,
          storagePath:
            "users/userA/sessions/sessionA/commands/other/attachments/att_123_0/script.ps1",
          sha256: "not-a-hash",
        },
      ],
      createdAt: "2026-04-27T00:00:00.000Z",
    }),
  );
});

test("owner cannot create non-queued commands from the client", async () => {
  await testEnv.clearFirestore();
  const db = testEnv.authenticatedContext("userA").firestore();

  await assertFails(
    setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), {
      text: "hello",
      status: "completed",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
    }),
  );
});

test("owner cannot update command after creation", async () => {
  await testEnv.clearFirestore();
  await seedOwnSession();
  const db = testEnv.authenticatedContext("userA").firestore();

  await assertFails(updateDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), { status: "canceled" }));
});

test("other users cannot read or write another user's data", async () => {
  await testEnv.clearFirestore();
  await seedOwnSession();
  const db = testEnv.authenticatedContext("userB").firestore();

  await assertFails(getDoc(doc(db, "users/userA/sessions/sessionA")));
  await assertFails(
    setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandB"), {
      text: "cross-user",
      status: "queued",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
    }),
  );
});

test("signed-out users cannot read user data", async () => {
  await testEnv.clearFirestore();
  await seedOwnSession();
  const db = testEnv.unauthenticatedContext().firestore();

  await assertFails(getDoc(doc(db, "users/userA/sessions/sessionA")));
});

test("owner can upload command attachments to own storage path", async () => {
  await testEnv.clearStorage();
  const storage = testEnv.authenticatedContext("userA").storage();

  await assertSucceeds(
    upload(
      storage
        .ref("users/userA/sessions/sessionA/commands/commandA/attachments/att_123_0/screen.png")
        .put(new Uint8Array([1, 2, 3]), { contentType: "image/png" }),
    ),
  );
});

test("storage rules reject cross-user and unsupported command attachments", async () => {
  await testEnv.clearStorage();
  const storage = testEnv.authenticatedContext("userB").storage();

  await assertFails(
    upload(
      storage
        .ref("users/userA/sessions/sessionA/commands/commandA/attachments/att_123_0/screen.png")
        .put(new Uint8Array([1, 2, 3]), { contentType: "image/png" }),
    ),
  );

  await assertFails(
    upload(
      storage
        .ref("users/userB/sessions/sessionA/commands/commandA/attachments/att_123_0/script.ps1")
        .put(new Uint8Array([1, 2, 3]), { contentType: "application/octet-stream" }),
    ),
  );
});

function upload(task: {
  then: (
    resolvePromise: (value: unknown) => void,
    rejectPromise: (reason?: unknown) => void,
  ) => unknown;
}): Promise<unknown> {
  return new Promise((resolvePromise, rejectPromise) => {
    task.then(resolvePromise, rejectPromise);
  });
}

async function seedOwnSession(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users/userA/sessions/sessionA"), {
      status: "queued",
      targetPcBridgeId: "pc-a",
    });
    await setDoc(doc(db, "users/userA/sessions/sessionA/commands/commandA"), {
      text: "hello",
      status: "queued",
      targetPcBridgeId: "pc-a",
      createdAt: "2026-04-27T00:00:00.000Z",
    });
  });
}

test("rules test environment is initialized", () => {
  assert.ok(testEnv);
});

function emulatorHost(envName: string, fallback: string): { host: string; port: number } {
  const value = process.env[envName] ?? fallback;
  const [host, portText] = value.split(":");
  const port = Number.parseInt(portText ?? "", 10);

  if (!host || !Number.isInteger(port)) {
    throw new Error(`Invalid ${envName}: ${value}`);
  }

  return { host, port };
}
