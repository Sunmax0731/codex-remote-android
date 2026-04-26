import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.platformDispatcher.localeTestValue = const Locale('en');
    binding.platformDispatcher.localesTestValue = const [Locale('en')];
  });

  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
    binding.platformDispatcher.clearLocalesTestValue();
  });

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
    await pumpFrames(tester);

    expect(find.text('Connected as anonymous user'), findsOneWidget);
    expect(find.text('PC bridge: home-main-pc (active)'), findsOneWidget);
    expect(find.text('Check PC now'), findsOneWidget);
    expect(find.text('CLI defaults'), findsOneWidget);
    expect(find.text('CLI option help'), findsNothing);
    expect(find.text('UID: test-uid'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('uses Japanese strings when device locale is Japanese', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('ja');
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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
    await pumpFrames(tester);

    expect(find.text('匿名ユーザーで接続中'), findsOneWidget);
    expect(find.text('セッションはまだありません'), findsOneWidget);
    expect(find.text('新規セッション'), findsOneWidget);
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

  test('serializes advanced CLI options for Firestore', () {
    const options = SessionCreateOptions(
      codexModel: 'gpt-5.5',
      codexSandbox: 'workspace-write',
      codexBypassSandbox: false,
      codexConfigOverrides: ['model="gpt-5.5"'],
      codexEnableFeatures: ['feature-a'],
      codexDisableFeatures: ['feature-b'],
      codexImages: [r'C:\tmp\image.png'],
      codexOss: true,
      codexLocalProvider: 'ollama',
      codexFullAuto: true,
      codexAddDirs: [r'D:\work'],
      codexSkipGitRepoCheck: true,
      codexEphemeral: true,
      codexIgnoreUserConfig: true,
      codexIgnoreRules: true,
      codexOutputSchema: r'C:\tmp\schema.json',
      codexJson: true,
    );

    final data = sessionOptionsToData(options);
    final parsed = sessionOptionsFromData(data);

    expect(data['codexConfigOverrides'], ['model="gpt-5.5"']);
    expect(data['codexEnableFeatures'], ['feature-a']);
    expect(data['codexDisableFeatures'], ['feature-b']);
    expect(data['codexImages'], [r'C:\tmp\image.png']);
    expect(data['codexOss'], true);
    expect(data['codexLocalProvider'], 'ollama');
    expect(data['codexFullAuto'], true);
    expect(data['codexAddDirs'], [r'D:\work']);
    expect(data['codexSkipGitRepoCheck'], true);
    expect(data['codexEphemeral'], true);
    expect(data['codexIgnoreUserConfig'], true);
    expect(data['codexIgnoreRules'], true);
    expect(data['codexOutputSchema'], r'C:\tmp\schema.json');
    expect(data['codexJson'], true);
    expect(parsed?.codexConfigOverrides, ['model="gpt-5.5"']);
    expect(parsed?.codexLocalProvider, 'ollama');
    expect(parsed?.codexJson, true);
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
    await pumpFrames(tester);

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
    await pumpFrames(tester);

    await tester.tap(find.text('CLI defaults'));
    await pumpFrames(tester);
    expect(find.text('Sandbox'), findsOneWidget);
    expect(find.text('Bypass sandbox'), findsOneWidget);
    await tester.tap(find.text('Advanced CLI options'));
    await pumpFrames(tester);
    expect(find.byTooltip('Select image file'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(repository.savedDefaultsCount, 1);
  });

  testWidgets('cancels settings dialog while text field is focused', (
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
    await pumpFrames(tester);

    await tester.tap(find.text('CLI defaults'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField).first, 'focused-profile');
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(repository.savedDefaultsCount, 0);
  });

  testWidgets('shows option help from the settings dialog', (tester) async {
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
    await pumpFrames(tester);

    await tester.tap(find.text('CLI defaults'));
    await pumpFrames(tester);
    await tester.tap(find.byTooltip('Show help for Model'));
    await pumpFrames(tester);

    expect(find.text('Example: gpt-5.5'), findsOneWidget);
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
          codexConfigOverrides: ['model="gpt-5.4-mini"'],
          codexEnableFeatures: ['feature-a'],
          codexJson: true,
        ),
      ),
    ]);
    await pumpFrames(tester);

    await tester.longPress(find.text('Session 1'));
    await pumpFrames(tester);
    await tester.tap(find.text('CLI option help'));
    await pumpFrames(tester);

    expect(find.text('Model: gpt-5.4-mini'), findsOneWidget);
    expect(find.text('Sandbox: read-only'), findsOneWidget);
    expect(find.text('Config: model="gpt-5.4-mini"'), findsOneWidget);
    expect(find.text('Enable: feature-a'), findsOneWidget);
    expect(find.text('JSON events: on'), findsOneWidget);
  });

  testWidgets('filters sessions by title and group', (tester) async {
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
        title: 'Billing fix',
        status: 'idle',
        groupName: 'Work',
      ),
      SessionSummary(
        id: 'session-2',
        title: 'Game notes',
        status: 'idle',
        groupName: 'Personal',
      ),
    ]);
    await pumpFrames(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search sessions'),
      'billing',
    );
    await pumpFrames(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('Billing fix'), findsOneWidget);
    expect(find.text('Game notes'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search sessions'),
      '',
    );
    await pumpFrames(tester);
    await tester.tap(find.text('Personal'));
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('Billing fix'), findsNothing);
    expect(find.text('Game notes'), findsOneWidget);
  });

  testWidgets('edits favorite group and deletion from session actions', (
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
    repository.emit(const [
      SessionSummary(id: 'session-1', title: 'Session 1', status: 'idle'),
    ]);
    await pumpFrames(tester);

    await tester.longPress(find.text('Session 1'));
    await pumpFrames(tester);
    await tester.tap(find.text('Rename session'));
    await pumpFrames(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Session name'),
      'Renamed',
    );
    await tester.tap(find.text('Save'));
    await pumpFrames(tester);
    expect(repository.renamedSessionTitle, 'Renamed');

    await tester.longPress(find.text('Session 1'));
    await pumpFrames(tester);
    await tester.tap(find.text('Favorite'));
    await pumpFrames(tester);
    expect(repository.updatedFavorite, true);

    await tester.longPress(find.text('Session 1'));
    await pumpFrames(tester);
    await tester.tap(find.text('Change group'));
    await pumpFrames(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'Work',
    );
    await tester.tap(find.text('Save'));
    await pumpFrames(tester);
    expect(repository.updatedGroupName, 'Work');

    await tester.longPress(find.text('Session 1'));
    await pumpFrames(tester);
    await tester.tap(find.text('Delete session'));
    await pumpFrames(tester);
    await tester.tap(find.text('Delete'));
    await pumpFrames(tester);
    expect(repository.deletedSessionCount, 1);
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
    expect(find.widgetWithText(TextField, 'Instruction'), findsOneWidget);
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
    await pumpFrames(tester);

    await tester.tap(find.text('Session 1'));
    await tester.pump();
    repository.emitCommands('session-1', const <CommandSummary>[]);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No commands yet'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Instruction'),
      'Summarize the repo',
    );
    await tester.tap(find.byTooltip('Send'));
    await pumpFrames(tester);

    expect(repository.createdCommandText, 'Summarize the repo');
    expect(find.text('Summarize the repo'), findsOneWidget);
    expect(find.text('queued'), findsOneWidget);
  });
}

Future<void> pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class FakeSessionRepository implements SessionRepository {
  final StreamController<List<SessionSummary>> controller =
      StreamController<List<SessionSummary>>.broadcast();
  final Map<String, StreamController<List<CommandSummary>>> commandControllers =
      {};
  List<SessionSummary>? latestSessions;
  final Map<String, List<CommandSummary>> latestCommands = {};
  int createdSessionCount = 0;
  int healthCheckCount = 0;
  int savedDefaultsCount = 0;
  int deletedSessionCount = 0;
  String? createdCommandText;
  String? renamedSessionTitle;
  bool? updatedFavorite;
  String? updatedGroupName;
  SessionCreateOptions? createdSessionOptions;
  SessionCreateOptions cliDefaults = defaultSessionCreateOptions;

  void emit(List<SessionSummary> sessions) {
    latestSessions = sessions;
    controller.add(sessions);
  }

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) async* {
    final latest = latestSessions;
    if (latest != null) {
      yield latest;
    }
    yield* controller.stream;
  }

  @override
  Stream<List<CommandSummary>> watchCommands(
    String uid,
    String sessionId,
  ) async* {
    final latest = latestCommands[sessionId];
    if (latest != null) {
      yield latest;
    }
    yield* commandControllers
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
    latestCommands[sessionId] = commands;
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
  Future<void> renameSession({
    required String uid,
    required String sessionId,
    required String title,
  }) async {
    renamedSessionTitle = title;
  }

  @override
  Future<void> updateSessionFavorite({
    required String uid,
    required String sessionId,
    required bool favorite,
  }) async {
    updatedFavorite = favorite;
  }

  @override
  Future<void> updateSessionGroup({
    required String uid,
    required String sessionId,
    required String? groupName,
  }) async {
    updatedGroupName = groupName;
  }

  @override
  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    deletedSessionCount++;
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
