import { FirestoreRelayRepository } from "./firestoreRelayRepository.js";
import { LocalRelayRepository } from "./localRelayRepository.js";
import type { BridgeConfig, CommandRepository } from "./types.js";

export function createCommandRepository(config: BridgeConfig): CommandRepository {
  if (config.relayMode === "firestore") {
    return new FirestoreRelayRepository(config);
  }

  return new LocalRelayRepository(config.localRelayPath);
}
