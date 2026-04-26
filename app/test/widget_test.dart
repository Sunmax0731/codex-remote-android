import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  testWidgets('shows empty session list after anonymous auth baseline', (tester) async {
    final repository = FakeSessionRepository();

    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(uid: 'test-uid', pcBridgeId: defaultPcBridgeId),
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
          const AppBootstrap(uid: 'test-uid', pcBridgeId: defaultPcBridgeId),
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
}

class FakeSessionRepository implements SessionRepository {
  final StreamController<List<SessionSummary>> controller = StreamController<List<SessionSummary>>.broadcast();
  int createdSessionCount = 0;

  void emit(List<SessionSummary> sessions) {
    controller.add(sessions);
  }

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) => controller.stream;

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
}
