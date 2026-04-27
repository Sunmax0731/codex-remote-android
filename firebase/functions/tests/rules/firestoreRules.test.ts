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
  const { host, port } = emulatorHost();

  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host,
      port,
      rules: readFileSync(resolve("..", "firestore.rules"), "utf8"),
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

function emulatorHost(): { host: string; port: number } {
  const value = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:18080";
  const [host, portText] = value.split(":");
  const port = Number.parseInt(portText ?? "", 10);

  if (!host || !Number.isInteger(port)) {
    throw new Error(`Invalid FIRESTORE_EMULATOR_HOST: ${value}`);
  }

  return { host, port };
}
