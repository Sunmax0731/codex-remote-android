import 'package:flutter_test/flutter_test.dart';
import 'package:remote_codex/main.dart';

void main() {
  testWidgets('shows anonymous auth ready state', (tester) async {
    await tester.pumpWidget(
      RemoteCodexApp(
        bootstrap: Future<AppBootstrap>.value(
          const AppBootstrap(uid: 'test-uid', pcBridgeId: defaultPcBridgeId),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RemoteCodex'), findsWidgets);
    expect(find.text('Anonymous sign-in is ready.'), findsOneWidget);
    expect(find.text('home-main-pc'), findsOneWidget);
    expect(find.text('test-uid'), findsOneWidget);
  });
}
