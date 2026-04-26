import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  testWidgets('shows empty session list after anonymous auth baseline', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(permissionStatus: 'authorized', hasToken: true),
          ),
        ),
        sessionRepository: repository,
      ),
    );
    await tester.pump();
    repository.emit(const <SessionSummary>[]);
    await tester.pump();

    expect(find.text('Connected as anonymous user'), findsOneWidget);
    expect(find.text('PC bridge: home-main-pc'), findsOneWidget);
    expect(find.text('UID: test-uid'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('creates a session from the floating action button', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(permissionStatus: 'authorized', hasToken: true),
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

    expect(repository.createdSessionCount, 1);
    expect(find.text('Session 1'), findsOneWidget);
  });

  testWidgets('opens session detail and sends a command', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(
            uid: 'test-uid',
            pcBridgeId: defaultPcBridgeId,
            notificationState: NotificationState(permissionStatus: 'authorized', hasToken: true),
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
  final StreamController<List<SessionSummary>> controller = StreamController<List<SessionSummary>>.broadcast();
  final Map<String, StreamController<List<CommandSummary>>> commandControllers = {};
  int createdSessionCount = 0;
  String? createdCommandText;

  void emit(List<SessionSummary> sessions) {
    controller.add(sessions);
  }

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) => controller.stream;

  @override
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId) {
    return commandControllers.putIfAbsent(
      sessionId,
      () => StreamController<List<CommandSummary>>.broadcast(),
    ).stream;
  }

  void emitCommands(String sessionId, List<CommandSummary> commands) {
    commandControllers.putIfAbsent(
      sessionId,
      () => StreamController<List<CommandSummary>>.broadcast(),
    ).add(commands);
  }

  @override
  Future<void> createSession({required String uid, required String pcBridgeId}) async {
    createdSessionCount++;
    controller.add([
      SessionSummary(
        id: 'session-$createdSessionCount',
        title: 'Session $createdSessionCount',
        status: 'idle',
      ),
    ]);
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
      CommandSummary(
        id: 'command-1',
        text: text,
        status: 'queued',
      ),
    ]);
  }
}
