import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const defaultPcBridgeId = 'home-main-pc';
const defaultCodexModel = 'gpt-5.4';
const defaultCodexSandbox = 'workspace-write';
const codexModelOptions = [
  'gpt-5.5',
  'gpt-5.4',
  'gpt-5.4-mini',
  'gpt-5.3-codex',
  'gpt-5.3-codex-spark',
  'gpt-5.2',
];
const codexSandboxOptions = [
  'read-only',
  'workspace-write',
  'danger-full-access',
];
const cliOptionHelpItems = [
  CliOptionHelp(
    name: 'Model',
    location: 'New Session / CLI defaults',
    description: 'セッションで使用するCodexモデルを選びます。',
  ),
  CliOptionHelp(
    name: 'Profile',
    location: 'New Session / CLI defaults',
    description: 'PC側のCodex設定にある名前付きprofileを使用します。',
  ),
  CliOptionHelp(
    name: 'Sandbox',
    location: 'CLI defaults',
    description: 'CodexがPC上のファイルへどこまでアクセスできるかを制御します。',
  ),
  CliOptionHelp(
    name: 'Bypass sandbox',
    location: 'CLI defaults',
    description: 'PCブリッジでsandbox制限を迂回してCodexを実行します。',
  ),
  CliOptionHelp(
    name: '--config key=value',
    location: 'Advanced / future',
    description: '1回の実行だけCodex設定値を上書きします。',
  ),
  CliOptionHelp(
    name: '--enable / --disable',
    location: 'Advanced / future',
    description: 'Codexの機能フラグを有効化または無効化します。',
  ),
  CliOptionHelp(
    name: '--image',
    location: 'Advanced / future',
    description: '画像を使う依頼で、入力画像のパスを追加します。',
  ),
  CliOptionHelp(
    name: '--oss',
    location: 'Advanced / future',
    description: '設定済みの場合にローカルOSS providerモードを使います。',
  ),
  CliOptionHelp(
    name: '--local-provider',
    location: 'Advanced / future',
    description: 'OSSモードで使うローカルproviderを選びます。',
  ),
  CliOptionHelp(
    name: '--full-auto',
    location: 'Advanced / future',
    description: '確認を減らして自動実行寄りで進めます。',
  ),
  CliOptionHelp(
    name: '--add-dir',
    location: 'Advanced / future',
    description: 'Codexセッションに追加の作業ディレクトリを渡します。',
  ),
  CliOptionHelp(
    name: '--skip-git-repo-check',
    location: 'Advanced / future',
    description: '対象がGitリポジトリでなくても実行できるようにします。',
  ),
  CliOptionHelp(
    name: '--ephemeral',
    location: 'Advanced / future',
    description: '後から再開するためのセッション状態を保存せずに開始します。',
  ),
  CliOptionHelp(
    name: '--ignore-user-config',
    location: 'Advanced / future',
    description: 'PCユーザー単位のCodex設定を無視します。',
  ),
  CliOptionHelp(
    name: '--ignore-rules',
    location: 'Advanced / future',
    description: 'リポジトリまたはユーザーの指示ファイルを無視します。',
  ),
  CliOptionHelp(
    name: '--output-schema',
    location: 'Advanced / future',
    description: 'JSON schemaに沿った出力を要求します。',
  ),
  CliOptionHelp(
    name: '--json',
    location: 'PC bridge internal',
    description: 'PCブリッジが扱いやすい機械可読イベントを出力します。',
  ),
];
const androidDeviceId = 'android-app';
const notificationChannelId = 'remote_codex_completion';
const notificationChannelName = 'RemoteCodex completion';
final appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(
    RemoteCodexApp(
      bootstrap: bootstrapRemoteCodex(),
      sessionRepository: FirestoreSessionRepository(),
    ),
  );
}

Future<AppBootstrap> bootstrapRemoteCodex() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  final credential = await FirebaseAuth.instance.signInAnonymously();
  final uid = credential.user?.uid;

  if (uid == null || uid.isEmpty) {
    throw StateError('Anonymous sign-in did not return a user uid.');
  }

  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'defaultPcBridgeId': defaultPcBridgeId,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastSignedInAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final notificationState = await NotificationService().registerDevice(
    uid: uid,
    firestore: firestore,
  );

  return AppBootstrap(
    uid: uid,
    pcBridgeId: defaultPcBridgeId,
    notificationState: notificationState,
  );
}

class AppBootstrap {
  const AppBootstrap({
    required this.uid,
    required this.pcBridgeId,
    required this.notificationState,
  });

  final String uid;
  final String pcBridgeId;
  final NotificationState notificationState;
}

class NotificationState {
  const NotificationState({
    required this.permissionStatus,
    required this.hasToken,
  });

  final String permissionStatus;
  final bool hasToken;
}

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _messageHandlersRegistered = false;
  AppBootstrap? _bootstrap;
  SessionRepository? _sessionRepository;
  String? _pendingSessionId;

  Future<NotificationState> registerDevice({
    required String uid,
    required FirebaseFirestore firestore,
  }) async {
    await _initializeLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    final token = await messaging.getToken();

    await _storeToken(
      firestore: firestore,
      uid: uid,
      token: token,
      permissionStatus: settings.authorizationStatus.name,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _storeToken(
        firestore: firestore,
        uid: uid,
        token: newToken,
        permissionStatus: settings.authorizationStatus.name,
      );
    });

    _registerMessageHandlers();

    return NotificationState(
      permissionStatus: settings.authorizationStatus.name,
      hasToken: token != null && token.isNotEmpty,
    );
  }

  void attachNavigation({
    required AppBootstrap bootstrap,
    required SessionRepository sessionRepository,
  }) {
    _bootstrap = bootstrap;
    _sessionRepository = sessionRepository;

    final pendingSessionId = _pendingSessionId;
    if (pendingSessionId != null) {
      _pendingSessionId = null;
      scheduleMicrotask(() => _openSession(pendingSessionId));
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_initialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final sessionId = sessionIdFromPayload(response.payload);
        if (sessionId != null) {
          _openSession(sessionId);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description:
          'Notifications for completed or failed remote Codex commands.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _registerMessageHandlers() {
    if (_messageHandlersRegistered) {
      return;
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final sessionId = sessionIdFromMessageData(message.data);
      if (sessionId != null) {
        _openSession(sessionId);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      final sessionId = message == null
          ? null
          : sessionIdFromMessageData(message.data);
      if (sessionId != null) {
        _openSession(sessionId);
      }
    });

    _messageHandlersRegistered = true;
  }

  Future<void> _storeToken({
    required FirebaseFirestore firestore,
    required String uid,
    required String? token,
    required String permissionStatus,
  }) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(androidDeviceId)
        .set({
          'deviceId': androidDeviceId,
          'platform': 'android',
          'fcmToken': token,
          'notificationPermission': permissionStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'RemoteCodex';
    final body = notification?.body ?? 'Remote processing finished.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription:
            'Notifications for completed or failed remote Codex commands.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: notificationPayloadFromMessageData(message.data),
    );
  }

  void _openSession(String sessionId) {
    final navigator = appNavigatorKey.currentState;
    final bootstrap = _bootstrap;
    final sessionRepository = _sessionRepository;

    if (navigator == null || bootstrap == null || sessionRepository == null) {
      _pendingSessionId = sessionId;
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailPage(
          bootstrap: bootstrap,
          session: SessionSummary(
            id: sessionId,
            title: 'Session $sessionId',
            status: 'unknown',
          ),
          sessionRepository: sessionRepository,
        ),
      ),
    );
  }
}

String notificationPayloadFromMessageData(Map<String, dynamic> data) {
  return jsonEncode({
    'sessionId': data['sessionId'],
    'commandId': data['commandId'],
    'status': data['status'],
  });
}

String? sessionIdFromPayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return nonEmptyString(decoded['sessionId']);
    }
  } on FormatException {
    return payload.trim();
  }

  return null;
}

String? sessionIdFromMessageData(Map<String, dynamic> data) {
  return nonEmptyString(data['sessionId']);
}

String? nonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.title,
    required this.status,
    this.codexOptions,
    this.lastResultPreview,
    this.lastErrorPreview,
  });

  final String id;
  final String title;
  final String status;
  final SessionCreateOptions? codexOptions;
  final String? lastResultPreview;
  final String? lastErrorPreview;
}

class CommandSummary {
  const CommandSummary({
    required this.id,
    required this.text,
    required this.status,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.progressText,
    this.progressUpdatedAt,
    this.resultText,
    this.errorText,
  });

  final String id;
  final String text;
  final String status;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? progressText;
  final DateTime? progressUpdatedAt;
  final String? resultText;
  final String? errorText;
}

class PcBridgeStatus {
  const PcBridgeStatus({
    this.lastSeenAt,
    this.lastQueueCheckedAt,
    this.lastHealthCheckRequestedAt,
    this.lastHealthCheckRespondedAt,
    this.lastHealthCheckStatus,
    this.status,
  });

  final DateTime? lastSeenAt;
  final DateTime? lastQueueCheckedAt;
  final DateTime? lastHealthCheckRequestedAt;
  final DateTime? lastHealthCheckRespondedAt;
  final String? lastHealthCheckStatus;
  final String? status;
}

class SessionCreateOptions {
  const SessionCreateOptions({
    required this.codexModel,
    required this.codexSandbox,
    required this.codexBypassSandbox,
    this.codexProfile,
  });

  final String codexModel;
  final String codexSandbox;
  final bool codexBypassSandbox;
  final String? codexProfile;
}

const defaultSessionCreateOptions = SessionCreateOptions(
  codexModel: defaultCodexModel,
  codexSandbox: defaultCodexSandbox,
  codexBypassSandbox: false,
);

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
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return SessionSummary(
              id: doc.id,
              title: (data['title'] as String?)?.trim().isNotEmpty == true
                  ? data['title'] as String
                  : 'Untitled session',
              status: data['status'] as String? ?? 'idle',
              codexOptions: sessionOptionsFromData(data),
              lastResultPreview: data['lastResultPreview'] as String?,
              lastErrorPreview: data['lastErrorPreview'] as String?,
            );
          }).toList(),
        );
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
        .set(sessionOptionsToData(options), SetOptions(merge: true));
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
  );
}

Map<String, Object> sessionOptionsToData(SessionCreateOptions options) {
  return {
    'codexModel': options.codexModel,
    'codexSandbox': options.codexSandbox,
    'codexBypassSandbox': options.codexBypassSandbox,
    if (options.codexProfile != null) 'codexProfile': options.codexProfile!,
  };
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

class RemoteCodexApp extends StatelessWidget {
  const RemoteCodexApp({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final Future<AppBootstrap> bootstrap;
  final SessionRepository sessionRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'RemoteCodex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: StartupView(
        bootstrap: bootstrap,
        sessionRepository: sessionRepository,
      ),
    );
  }
}

class StartupView extends StatelessWidget {
  const StartupView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final Future<AppBootstrap> bootstrap;
  final SessionRepository sessionRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBootstrap>(
      future: bootstrap,
      builder: (context, snapshot) {
        final Widget body;

        if (snapshot.connectionState != ConnectionState.done) {
          body = const _StartupMessage(
            title: 'Signing in',
            message: 'Preparing secure relay access.',
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          body = _StartupMessage(
            title: 'Startup failed',
            message: snapshot.error.toString(),
            child: const Icon(Icons.error_outline, size: 36),
          );
        } else {
          body = SessionListView(
            bootstrap: snapshot.requireData,
            sessionRepository: sessionRepository,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('RemoteCodex')),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

class SessionListView extends StatefulWidget {
  const SessionListView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;

  @override
  State<SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends State<SessionListView> {
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    NotificationService().attachNavigation(
      bootstrap: widget.bootstrap,
      sessionRepository: widget.sessionRepository,
    );
  }

  Future<void> createSession() async {
    if (isCreating) {
      return;
    }

    setState(() => isCreating = true);
    SessionCreateOptions defaults;
    try {
      defaults = await widget.sessionRepository.loadCliDefaults(
        widget.bootstrap.uid,
      );
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }

    if (!mounted) {
      return;
    }

    final options = await showSessionOptionsDialog(
      context,
      title: 'New session',
      initialOptions: defaults,
      primaryLabel: 'Create',
      showExecutionDefaults: false,
    );
    if (options == null) {
      return;
    }

    setState(() => isCreating = true);
    try {
      final session = await widget.sessionRepository.createSession(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        options: options,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(
            bootstrap: widget.bootstrap,
            session: session,
            sessionRepository: widget.sessionRepository,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionSummary>>(
      stream: widget.sessionRepository.watchSessions(widget.bootstrap.uid),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <SessionSummary>[];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _ConnectionSummary(
                        bootstrap: widget.bootstrap,
                        sessionRepository: widget.sessionRepository,
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: _StartupMessage(
                        title: 'Session load failed',
                        message: snapshot.error.toString(),
                        child: const Icon(Icons.error_outline, size: 36),
                      ),
                    )
                  else if (sessions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySessions(),
                    )
                  else
                    SliverList.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return _SessionTile(
                          session: sessions[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SessionDetailPage(
                                  bootstrap: widget.bootstrap,
                                  session: sessions[index],
                                  sessionRepository: widget.sessionRepository,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            showSessionOptionsSummaryDialog(
                              context,
                              sessions[index],
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: isCreating ? null : createSession,
                icon: isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(isCreating ? 'Creating' : 'New session'),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<SessionCreateOptions?> showSessionOptionsDialog(
  BuildContext context, {
  required String title,
  required SessionCreateOptions initialOptions,
  required String primaryLabel,
  required bool showExecutionDefaults,
}) {
  final profileController = TextEditingController(
    text: initialOptions.codexProfile ?? '',
  );
  var model = codexModelOptions.contains(initialOptions.codexModel)
      ? initialOptions.codexModel
      : defaultCodexModel;
  var sandbox = codexSandboxOptions.contains(initialOptions.codexSandbox)
      ? initialOptions.codexSandbox
      : defaultCodexSandbox;
  var bypassSandbox = initialOptions.codexBypassSandbox;

  return showDialog<SessionCreateOptions>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: model,
                    decoration: const InputDecoration(labelText: 'Model'),
                    items: [
                      for (final option in codexModelOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => model = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: profileController,
                    decoration: const InputDecoration(
                      labelText: 'Profile',
                      hintText: 'Optional config profile',
                    ),
                  ),
                  if (showExecutionDefaults) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sandbox,
                      decoration: const InputDecoration(labelText: 'Sandbox'),
                      items: [
                        for (final option in codexSandboxOptions)
                          DropdownMenuItem(value: option, child: Text(option)),
                      ],
                      onChanged: bypassSandbox
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => sandbox = value);
                              }
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bypass sandbox'),
                      subtitle: const Text('Overrides the sandbox selection'),
                      value: bypassSandbox,
                      onChanged: (value) {
                        setDialogState(() => bypassSandbox = value);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sandbox and bypass use CLI defaults.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => showCliOptionHelpDialog(context),
                child: const Text('Help'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final profile = profileController.text.trim();
                  Navigator.of(context).pop(
                    SessionCreateOptions(
                      codexModel: model,
                      codexSandbox: sandbox,
                      codexBypassSandbox: bypassSandbox,
                      codexProfile: profile.isEmpty ? null : profile,
                    ),
                  );
                },
                child: Text(primaryLabel),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(() {
    profileController.dispose();
  });
}

Future<void> showCliOptionHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('CLI option help'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: cliOptionHelpItems.length,
          separatorBuilder: (context, index) => const Divider(height: 18),
          itemBuilder: (context, index) {
            final option = cliOptionHelpItems[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text('表示場所: ${option.location}'),
                const SizedBox(height: 2),
                Text(option.description),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class CliOptionHelp {
  const CliOptionHelp({
    required this.name,
    required this.location,
    required this.description,
  });

  final String name;
  final String location;
  final String description;
}

Future<void> showSessionOptionsSummaryDialog(
  BuildContext context,
  SessionSummary session,
) {
  final options = session.codexOptions ?? defaultSessionCreateOptions;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(session.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Model: ${options.codexModel}'),
          const SizedBox(height: 6),
          Text('Sandbox: ${options.codexSandbox}'),
          const SizedBox(height: 6),
          Text('Bypass sandbox: ${options.codexBypassSandbox ? 'on' : 'off'}'),
          const SizedBox(height: 6),
          Text('Profile: ${options.codexProfile ?? 'None'}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _ConnectionSummary extends StatefulWidget {
  const _ConnectionSummary({
    required this.bootstrap,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;

  @override
  State<_ConnectionSummary> createState() => _ConnectionSummaryState();
}

class _ConnectionSummaryState extends State<_ConnectionSummary> {
  bool isCheckingBridge = false;
  bool isOpeningDefaults = false;
  String? checkError;

  Future<void> requestHealthCheck() async {
    setState(() {
      isCheckingBridge = true;
      checkError = null;
    });

    try {
      await widget.sessionRepository.requestPcBridgeHealthCheck(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
      );
    } catch (error) {
      checkError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          isCheckingBridge = false;
        });
      }
    }
  }

  Future<void> openCliDefaults() async {
    if (isOpeningDefaults) {
      return;
    }

    setState(() => isOpeningDefaults = true);
    SessionCreateOptions defaults;
    try {
      defaults = await widget.sessionRepository.loadCliDefaults(
        widget.bootstrap.uid,
      );
    } finally {
      if (mounted) {
        setState(() => isOpeningDefaults = false);
      }
    }

    if (!mounted) {
      return;
    }

    final updated = await showSessionOptionsDialog(
      context,
      title: 'CLI defaults',
      initialOptions: defaults,
      primaryLabel: 'Save',
      showExecutionDefaults: true,
    );

    if (updated == null) {
      return;
    }

    await widget.sessionRepository.saveCliDefaults(
      widget.bootstrap.uid,
      updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PcBridgeStatus>(
      stream: widget.sessionRepository.watchPcBridgeStatus(
        widget.bootstrap.uid,
        widget.bootstrap.pcBridgeId,
      ),
      builder: (context, snapshot) {
        final bridge = snapshot.data ?? const PcBridgeStatus();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected as anonymous user',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'PC bridge: ${widget.bootstrap.pcBridgeId}${bridge.status == null ? '' : ' (${bridge.status})'}',
                ),
                const SizedBox(height: 4),
                Text('Last heartbeat: ${formatDateTime(bridge.lastSeenAt)}'),
                const SizedBox(height: 4),
                Text(
                  'Last queue check: ${formatDateTime(bridge.lastQueueCheckedAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Last manual check: ${formatDateTime(bridge.lastHealthCheckRequestedAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Last response: ${formatDateTime(bridge.lastHealthCheckRespondedAt)}${bridge.lastHealthCheckStatus == null ? '' : ' (${bridge.lastHealthCheckStatus})'}',
                ),
                if (checkError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    checkError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: isCheckingBridge ? null : requestHealthCheck,
                        icon: isCheckingBridge
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sensors),
                        label: Text(
                          isCheckingBridge ? 'Checking' : 'Check PC now',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: isOpeningDefaults ? null : openCliDefaults,
                        icon: isOpeningDefaults
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.tune),
                        label: Text(
                          isOpeningDefaults ? 'Loading' : 'CLI defaults',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showCliOptionHelpDialog(context),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('CLI option help'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notifications: ${widget.bootstrap.notificationState.permissionStatus}',
                ),
                const SizedBox(height: 4),
                SelectableText('UID: ${widget.bootstrap.uid}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

String formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not seen yet';
  }

  final local = value.toLocal();
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes <= 0) {
    return '${seconds}s';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours <= 0) {
    return '${minutes}m ${seconds}s';
  }

  return '${hours}h ${remainingMinutes}m ${seconds}s';
}

class SessionDrawer extends StatelessWidget {
  const SessionDrawer({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
    required this.currentSessionId,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;
  final String currentSessionId;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<List<SessionSummary>>(
          stream: sessionRepository.watchSessions(bootstrap.uid),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <SessionSummary>[];

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  title: Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text('${sessions.length} session(s)'),
                ),
                const Divider(height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const ListTile(title: Text('Loading sessions...'))
                else if (snapshot.hasError)
                  ListTile(
                    title: const Text('Session load failed'),
                    subtitle: Text(snapshot.error.toString()),
                  )
                else if (sessions.isEmpty)
                  const ListTile(title: Text('No sessions yet'))
                else
                  for (final session in sessions)
                    ListTile(
                      selected: session.id == currentSessionId,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(session.status),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (session.id == currentSessionId) {
                          return;
                        }
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => SessionDetailPage(
                              bootstrap: bootstrap,
                              session: session,
                              sessionRepository: sessionRepository,
                            ),
                          ),
                        );
                      },
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onLongPress,
  });

  final SessionSummary session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        session.lastErrorPreview ?? session.lastResultPreview ?? session.status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          title: Text(session.title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({
    super.key,
    required this.bootstrap,
    required this.session,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionSummary session;
  final SessionRepository sessionRepository;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> sendCommand() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) {
      return;
    }

    setState(() => isSending = true);
    try {
      await widget.sessionRepository.createCommand(
        uid: widget.bootstrap.uid,
        sessionId: widget.session.id,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        text: text,
      );
      controller.clear();
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      drawer: SessionDrawer(
        bootstrap: widget.bootstrap,
        sessionRepository: widget.sessionRepository,
        currentSessionId: widget.session.id,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<CommandSummary>>(
                stream: widget.sessionRepository.watchCommands(
                  widget.bootstrap.uid,
                  widget.session.id,
                ),
                builder: (context, snapshot) {
                  final commands = snapshot.data ?? const <CommandSummary>[];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _StartupMessage(
                      title: 'Command load failed',
                      message: snapshot.error.toString(),
                      child: const Icon(Icons.error_outline, size: 36),
                    );
                  }

                  if (commands.isEmpty) {
                    return const _NoCommands();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: commands.length,
                    itemBuilder: (context, index) =>
                        _CommandTile(command: commands[index]),
                  );
                },
              ),
            ),
            _CommandComposer(
              controller: controller,
              isSending: isSending,
              onSend: sendCommand,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandTile extends StatefulWidget {
  const _CommandTile({required this.command});

  final CommandSummary command;

  @override
  State<_CommandTile> createState() => _CommandTileState();
}

class _CommandTileState extends State<_CommandTile> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    updateTimer();
  }

  @override
  void didUpdateWidget(covariant _CommandTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.command.status != widget.command.status ||
        oldWidget.command.completedAt != widget.command.completedAt ||
        oldWidget.command.createdAt != widget.command.createdAt) {
      updateTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void updateTimer() {
    timer?.cancel();
    if (isTerminalStatus(widget.command.status) ||
        widget.command.createdAt == null) {
      timer = null;
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final command = widget.command;
    final status = command.status;
    final detail =
        command.errorText ??
        command.resultText ??
        command.progressText ??
        'Waiting for final result.';
    final elapsed = commandElapsed(command);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    command.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(status)),
              ],
            ),
            if (elapsed != null) ...[
              const SizedBox(height: 6),
              Text(
                'Elapsed: ${formatDuration(elapsed)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (command.progressUpdatedAt != null &&
                !isTerminalStatus(status)) ...[
              const SizedBox(height: 6),
              Text(
                'Last progress: ${formatDateTime(command.progressUpdatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            SelectableText(detail),
          ],
        ),
      ),
    );
  }
}

bool isTerminalStatus(String status) {
  return status == 'completed' || status == 'failed' || status == 'canceled';
}

Duration? commandElapsed(CommandSummary command) {
  final started = command.createdAt;
  if (started == null) {
    return null;
  }

  final ended = command.completedAt;
  final end = ended ?? DateTime.now();
  final elapsed = end.difference(started);

  if (elapsed.isNegative) {
    return Duration.zero;
  }

  return elapsed;
}

class _CommandComposer extends StatelessWidget {
  const _CommandComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Instruction',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              tooltip: 'Send',
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCommands extends StatelessWidget {
  const _NoCommands();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 40),
            const SizedBox(height: 16),
            Text(
              'No commands yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 40),
            const SizedBox(height: 16),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
