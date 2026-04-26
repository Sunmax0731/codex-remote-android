part of '../../main.dart';

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
