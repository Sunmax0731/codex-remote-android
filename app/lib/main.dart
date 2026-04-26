import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RemoteCodexApp(firebaseInitialization: Firebase.initializeApp()));
}

class RemoteCodexApp extends StatelessWidget {
  const RemoteCodexApp({super.key, required this.firebaseInitialization});

  final Future<FirebaseApp> firebaseInitialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemoteCodex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: FirebaseStartupView(firebaseInitialization: firebaseInitialization),
    );
  }
}

class FirebaseStartupView extends StatelessWidget {
  const FirebaseStartupView({super.key, required this.firebaseInitialization});

  final Future<FirebaseApp> firebaseInitialization;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: firebaseInitialization,
      builder: (context, snapshot) {
        final Widget body;

        if (snapshot.connectionState != ConnectionState.done) {
          body = const _StartupMessage(
            title: 'Initializing Firebase',
            message: 'Preparing secure relay access.',
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          body = _StartupMessage(
            title: 'Firebase setup failed',
            message: snapshot.error.toString(),
            child: const Icon(Icons.error_outline, size: 36),
          );
        } else {
          body = const _StartupMessage(
            title: 'RemoteCodex',
            message: 'Firebase is ready. Session features are next.',
            child: Icon(Icons.check_circle_outline, size: 36),
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
