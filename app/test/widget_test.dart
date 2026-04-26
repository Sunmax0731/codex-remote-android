import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  testWidgets('shows startup ready state after Firebase initialization', (tester) async {
    await tester.pumpWidget(RemoteCodexApp(firebaseInitialization: Future<FirebaseApp>.value(FakeFirebaseApp())));
    await tester.pump();

    expect(find.text('RemoteCodex'), findsWidgets);
    expect(find.text('Firebase is ready. Session features are next.'), findsOneWidget);
  });
}

class FakeFirebaseApp implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      );

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
