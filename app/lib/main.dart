import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const defaultPcBridgeId = 'home-main-pc';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RemoteCodexApp(bootstrap: bootstrapRemoteCodex()));
}

Future<AppBootstrap> bootstrapRemoteCodex() async {
  await Firebase.initializeApp();

  final credential = await FirebaseAuth.instance.signInAnonymously();
  final uid = credential.user?.uid;

  if (uid == null || uid.isEmpty) {
    throw StateError('Anonymous sign-in did not return a user uid.');
  }

  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'uid': uid,
    'defaultPcBridgeId': defaultPcBridgeId,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastSignedInAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  return AppBootstrap(uid: uid, pcBridgeId: defaultPcBridgeId);
}

class AppBootstrap {
  const AppBootstrap({required this.uid, required this.pcBridgeId});

  final String uid;
  final String pcBridgeId;
}

class RemoteCodexApp extends StatelessWidget {
  const RemoteCodexApp({super.key, required this.bootstrap});

  final Future<AppBootstrap> bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemoteCodex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: StartupView(bootstrap: bootstrap),
    );
  }
}

class StartupView extends StatelessWidget {
  const StartupView({super.key, required this.bootstrap});

  final Future<AppBootstrap> bootstrap;

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
          body = _ReadyView(bootstrap: snapshot.requireData);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('RemoteCodex')),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 40),
            const SizedBox(height: 20),
            Text(
              'RemoteCodex',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Anonymous sign-in is ready.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'PC bridge', value: bootstrap.pcBridgeId),
            const SizedBox(height: 12),
            _InfoRow(label: 'User uid', value: bootstrap.uid),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(value),
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
