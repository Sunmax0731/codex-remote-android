part of '../../main.dart';

abstract class SessionRepository {
  Stream<List<SessionSummary>> watchSessions(String uid);
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId);
  Stream<PcBridgeStatus> watchPcBridgeStatus(String uid, String pcBridgeId);
  Future<SessionCreateOptions> loadCliDefaults(String uid);
  Future<void> saveCliDefaults(String uid, SessionCreateOptions options);
  Future<void> requestPcBridgeHealthCheck({
    required String uid,
    required String pcBridgeId,
  });
  Future<SessionSummary> createSession({
    required String uid,
    required String pcBridgeId,
    required SessionCreateOptions options,
  });
  Future<void> renameSession({
    required String uid,
    required String sessionId,
    required String title,
  });
  Future<void> updateSessionFavorite({
    required String uid,
    required String sessionId,
    required bool favorite,
  });
  Future<void> updateSessionGroup({
    required String uid,
    required String sessionId,
    required String? groupName,
  });
  Future<void> deleteSession({required String uid, required String sessionId});
  Future<void> createCommand({
    required String uid,
    required String sessionId,
    required String pcBridgeId,
    required String text,
  });
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository([FirebaseFirestore? firestore])
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .where((doc) {
                return doc.data()['deletedAt'] == null;
              })
              .map((doc) {
                final data = doc.data();
                return SessionSummary(
                  id: doc.id,
                  title: (data['title'] as String?)?.trim().isNotEmpty == true
                      ? data['title'] as String
                      : 'Untitled session',
                  status: data['status'] as String? ?? 'idle',
                  favorite: data['favorite'] as bool? ?? false,
                  groupName: optionString(data['groupName']),
                  codexOptions: sessionOptionsFromData(data),
                  lastResultPreview: data['lastResultPreview'] as String?,
                  lastErrorPreview: data['lastErrorPreview'] as String?,
                );
              })
              .toList();
          sessions.sort((a, b) {
            if (a.favorite != b.favorite) {
              return a.favorite ? -1 : 1;
            }
            return 0;
          });
          return sessions;
        });
  }

  @override
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('commands')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return CommandSummary(
              id: doc.id,
              text: data['text'] as String? ?? '',
              status: data['status'] as String? ?? 'queued',
              createdAt: timestampToDateTime(data['createdAt']),
              startedAt: timestampToDateTime(data['startedAt']),
              completedAt: timestampToDateTime(data['completedAt']),
              progressText: data['progressText'] as String?,
              progressUpdatedAt: timestampToDateTime(data['progressUpdatedAt']),
              resultText: data['resultText'] as String?,
              errorText: data['errorText'] as String?,
            );
          }).toList(),
        );
  }

  @override
  Stream<PcBridgeStatus> watchPcBridgeStatus(String uid, String pcBridgeId) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('pcBridges')
        .doc(pcBridgeId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return PcBridgeStatus(
            lastSeenAt: timestampToDateTime(data?['lastSeenAt']),
            lastQueueCheckedAt: timestampToDateTime(
              data?['lastQueueCheckedAt'],
            ),
            lastHealthCheckRequestedAt: timestampToDateTime(
              data?['lastHealthCheckRequestedAt'],
            ),
            lastHealthCheckRespondedAt: timestampToDateTime(
              data?['lastHealthCheckRespondedAt'],
            ),
            lastHealthCheckStatus: data?['lastHealthCheckStatus'] as String?,
            status: data?['status'] as String?,
          );
        });
  }

  @override
  Future<SessionCreateOptions> loadCliDefaults(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('cliDefaults')
        .get();

    return sessionOptionsFromData(snapshot.data()) ??
        defaultSessionCreateOptions;
  }

  @override
  Future<void> saveCliDefaults(String uid, SessionCreateOptions options) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('cliDefaults')
        .set(sessionOptionsToData(options));
  }

  @override
  Future<void> requestPcBridgeHealthCheck({
    required String uid,
    required String pcBridgeId,
  }) async {
    final bridgeRef = firestore
        .collection('users')
        .doc(uid)
        .collection('pcBridges')
        .doc(pcBridgeId);
    final healthCheckRef = bridgeRef.collection('healthChecks').doc();
    final batch = firestore.batch();

    batch.set(healthCheckRef, {
      'status': 'requested',
      'targetPcBridgeId': pcBridgeId,
      'createdByDeviceId': androidDeviceId,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    batch.set(bridgeRef, {
      'pcBridgeId': pcBridgeId,
      'lastHealthCheckRequestedAt': FieldValue.serverTimestamp(),
      'lastHealthCheckStatus': 'requested',
    }, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<SessionSummary> createSession({
    required String uid,
    required String pcBridgeId,
    required SessionCreateOptions options,
  }) async {
    final now = DateTime.now();
    final title =
        'Session ${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';

    final ref = await firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .add({
          'title': title,
          'status': 'idle',
          'targetPcBridgeId': pcBridgeId,
          ...sessionOptionsToData(options),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    return SessionSummary(
      id: ref.id,
      title: title,
      status: 'idle',
      codexOptions: options,
    );
  }

  @override
  Future<void> renameSession({
    required String uid,
    required String sessionId,
    required String title,
  }) async {
    await sessionDocument(uid, sessionId).update({
      'title': title.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSessionFavorite({
    required String uid,
    required String sessionId,
    required bool favorite,
  }) async {
    await sessionDocument(
      uid,
      sessionId,
    ).update({'favorite': favorite, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updateSessionGroup({
    required String uid,
    required String sessionId,
    required String? groupName,
  }) async {
    final trimmed = groupName?.trim();
    await sessionDocument(uid, sessionId).update({
      if (trimmed == null || trimmed.isEmpty)
        'groupName': FieldValue.delete()
      else
        'groupName': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    await sessionDocument(uid, sessionId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createCommand({
    required String uid,
    required String sessionId,
    required String pcBridgeId,
    required String text,
  }) async {
    final sessionRef = firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
    final commandRef = sessionRef.collection('commands').doc();
    final batch = firestore.batch();

    batch.set(commandRef, {
      'text': text,
      'status': 'queued',
      'targetPcBridgeId': pcBridgeId,
      'createdByDeviceId': 'android-app',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(sessionRef, {
      'status': 'queued',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastCommandId': commandRef.id,
      'lastCommandPreview': preview(text),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> sessionDocument(
    String uid,
    String sessionId,
  ) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
  }
}

SessionCreateOptions? sessionOptionsFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }

  return SessionCreateOptions(
    codexModel: optionString(data['codexModel']) ?? defaultCodexModel,
    codexSandbox: normalizedSandbox(data['codexSandbox']),
    codexBypassSandbox: data['codexBypassSandbox'] as bool? ?? false,
    codexProfile: optionString(data['codexProfile']),
    codexConfigOverrides: stringList(data['codexConfigOverrides']),
    codexEnableFeatures: stringList(data['codexEnableFeatures']),
    codexDisableFeatures: stringList(data['codexDisableFeatures']),
    codexImages: stringList(data['codexImages']),
    codexOss: data['codexOss'] as bool? ?? false,
    codexLocalProvider: normalizedLocalProvider(data['codexLocalProvider']),
    codexFullAuto: data['codexFullAuto'] as bool? ?? false,
    codexAddDirs: stringList(data['codexAddDirs']),
    codexSkipGitRepoCheck: data['codexSkipGitRepoCheck'] as bool? ?? false,
    codexEphemeral: data['codexEphemeral'] as bool? ?? false,
    codexIgnoreUserConfig: data['codexIgnoreUserConfig'] as bool? ?? false,
    codexIgnoreRules: data['codexIgnoreRules'] as bool? ?? false,
    codexOutputSchema: optionString(data['codexOutputSchema']),
    codexJson: data['codexJson'] as bool? ?? false,
  );
}

Map<String, Object> sessionOptionsToData(SessionCreateOptions options) {
  return {
    'codexModel': options.codexModel,
    'codexSandbox': options.codexSandbox,
    'codexBypassSandbox': options.codexBypassSandbox,
    if (options.codexProfile != null) 'codexProfile': options.codexProfile!,
    if (options.codexConfigOverrides.isNotEmpty)
      'codexConfigOverrides': options.codexConfigOverrides,
    if (options.codexEnableFeatures.isNotEmpty)
      'codexEnableFeatures': options.codexEnableFeatures,
    if (options.codexDisableFeatures.isNotEmpty)
      'codexDisableFeatures': options.codexDisableFeatures,
    if (options.codexImages.isNotEmpty) 'codexImages': options.codexImages,
    'codexOss': options.codexOss,
    if (options.codexLocalProvider != null)
      'codexLocalProvider': options.codexLocalProvider!,
    'codexFullAuto': options.codexFullAuto,
    if (options.codexAddDirs.isNotEmpty) 'codexAddDirs': options.codexAddDirs,
    'codexSkipGitRepoCheck': options.codexSkipGitRepoCheck,
    'codexEphemeral': options.codexEphemeral,
    'codexIgnoreUserConfig': options.codexIgnoreUserConfig,
    'codexIgnoreRules': options.codexIgnoreRules,
    if (options.codexOutputSchema != null)
      'codexOutputSchema': options.codexOutputSchema!,
    'codexJson': options.codexJson,
  };
}

List<String> stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }

  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String? optionString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String normalizedSandbox(Object? value) {
  if (value is String && codexSandboxOptions.contains(value)) {
    return value;
  }

  return defaultCodexSandbox;
}

String? normalizedLocalProvider(Object? value) {
  final provider = optionString(value);
  if (provider == null || !codexLocalProviderOptions.contains(provider)) {
    return null;
  }

  return provider;
}

String two(int value) => value.toString().padLeft(2, '0');

DateTime? timestampToDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }

  return null;
}

String preview(String value) {
  final trimmed = value.trim();
  return trimmed.length <= 120 ? trimmed : '${trimmed.substring(0, 117)}...';
}
