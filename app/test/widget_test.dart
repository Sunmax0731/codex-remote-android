import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  test('parses notification routing payloads', () {
    final payload = notificationPayloadFromMessageData({
      'sessionId': 'session-1',
      'commandId': 'command-1',
      'status': 'completed',
    });

    expect(sessionIdFromPayload(payload), 'session-1');
    expect(sessionIdFromPayload('legacy-session'), 'legacy-session');
    expect(sessionIdFromPayload(''), isNull);
    expect(sessionIdFromMessageData({'sessionId': 'session-2'}), 'session-2');
  });

  testWidgets('shows empty session list after anonymous auth baseline', (
    tester,
  ) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pumpAndSettle();

    expect(find.text('Connected as anonymous user'), findsOneWidget);
    expect(find.text('PC bridge: home-main-pc (active)'), findsOneWidget);
    expect(find.text('Check PC now'), findsOneWidget);
    expect(find.text('CLI defaults'), findsOneWidget);
    expect(find.text('CLI option help'), findsOneWidget);
    expect(find.text('UID: test-uid'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  test('includes gpt-5.5 in model options', () {
    expect(codexModelOptions, contains('gpt-5.5'));
  });

  test('documents advanced CLI option meanings', () {
    final optionNames = cliOptionHelpItems.map((option) => option.name);

    expect(optionNames, contains('--config key=value'));
    expect(optionNames, contains('--add-dir'));
    expect(optionNames, contains('--json'));
  });

  testWidgets('requests a PC bridge health check from the status panel', (
    tester,
  ) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check PC now'));
    await tester.pump();

    expect(repository.healthCheckCount, 1);
  });

  testWidgets('saves CLI defaults from the status panel', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CLI defaults'));
    await tester.pumpAndSettle();
    expect(find.text('Sandbox'), findsOneWidget);
    expect(find.text('Bypass sandbox'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(repository.savedDefaultsCount, 1);
  });

  testWidgets('shows CLI option help from the status panel', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CLI option help'));
    await tester.pumpAndSettle();

    expect(find.text('CLI option help'), findsWidgets);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('shows session CLI options on long press', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const [
      SessionSummary(
        id: 'session-1',
        title: 'Session 1',
        status: 'idle',
        codexOptions: SessionCreateOptions(
          codexModel: 'gpt-5.4-mini',
          codexSandbox: 'read-only',
          codexBypassSandbox: false,
        ),
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Session 1'));
    await tester.pumpAndSettle();

    expect(find.text('Model: gpt-5.4-mini'), findsOneWidget);
    expect(find.text('Sandbox: read-only'), findsOneWidget);
  });

  testWidgets('creates a session from the floating action button', (
    tester,
  ) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pump();

    await tester.tap(find.text('New session'));
    await tester.pump();
    expect(find.text(defaultCodexModel), findsOneWidget);
    expect(find.text('Sandbox'), findsNothing);
    expect(find.text('Sandbox and bypass use CLI defaults.'), findsOneWidget);
    await tester.tap(find.text('Create'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.createdSessionCount, 1);
    expect(repository.createdSessionOptions?.codexModel, defaultCodexModel);
    expect(find.text('Session 1'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('opens session detail and sends a command', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(
              permissionStatus: 'authorized',
              hasToken: true,
            ),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const [
      SessionSummary(id: 'session-1', title: 'Session 1', status: 'idle'),
    ]);
    repository.emitCommands('session-1', const <CommandSummary>[]);
    await tester.pump();

    await tester.tap(find.text('Session 1'));
    await tester.pump();
    repository.emitCommands('session-1', const <CommandSummary>[]);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No commands yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Summarize the repo');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(repository.createdCommandText, 'Summarize the repo');
    expect(find.text('Summarize the repo'), findsOneWidget);
    expect(find.text('queued'), findsOneWidget);
  });
}

class FakeSessionRepository implements SessionRepository {
  final StreamController<List<SessionSummary>> controller =
      StreamController<List<SessionSummary>>.broadcast();
  final Map<String, StreamController<List<CommandSummary>>> commandControllers =
      {};
  int createdSessionCount = 0;
  int healthCheckCount = 0;
  int savedDefaultsCount = 0;
  String? createdCommandText;
  SessionCreateOptions? createdSessionOptions;
  SessionCreateOptions cliDefaults = defaultSessionCreateOptions;

  void emit(List<SessionSummary> sessions) {
    controller.add(sessions);
  }

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) => controller.stream;

  @override
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId) {
    return commandControllers
        .putIfAbsent(
          sessionId,
          () => StreamController<List<CommandSummary>>.broadcast(),
        )
        .stream;
  }

  @override
  Stream<PcBridgeStatus> watchPcBridgeStatus(String uid, String pcBridgeId) =>
      Stream.value(
        PcBridgeStatus(
          lastSeenAt: DateTime(2026, 4, 26, 12),
          lastQueueCheckedAt: DateTime(2026, 4, 26, 12, 1),
          lastHealthCheckRequestedAt: DateTime(2026, 4, 26, 12, 2),
          lastHealthCheckRespondedAt: DateTime(2026, 4, 26, 12, 2, 5),
          lastHealthCheckStatus: 'responded',
          status: 'active',
        ),
      );

  @override
  Future<void> requestPcBridgeHealthCheck({
    required String uid,
    required String pcBridgeId,
  }) async {
    healthCheckCount++;
  }

  @override
  Future<SessionCreateOptions> loadCliDefaults(String uid) async => cliDefaults;

  @override
  Future<void> saveCliDefaults(String uid, SessionCreateOptions options) async {
    savedDefaultsCount++;
    cliDefaults = options;
  }

  void emitCommands(String sessionId, List<CommandSummary> commands) {
    commandControllers
        .putIfAbsent(
          sessionId,
          () => StreamController<List<CommandSummary>>.broadcast(),
        )
        .add(commands);
  }

  @override
  Future<SessionSummary> createSession({
    required String uid,
    required String pcBridgeId,
    required SessionCreateOptions options,
  }) async {
    createdSessionCount++;
    createdSessionOptions = options;
    final session = SessionSummary(
      id: 'session-$createdSessionCount',
      title: 'Session $createdSessionCount',
      status: 'idle',
    );
    controller.add([session]);
    return session;
  }

  @override
  Future<void> createCommand({
    required String uid,
    required String sessionId,
    required String pcBridgeId,
    required String text,
  }) async {
    createdCommandText = text;
    emitCommands(sessionId, [
      CommandSummary(id: 'command-1', text: text, status: 'queued'),
    ]);
  }
}
