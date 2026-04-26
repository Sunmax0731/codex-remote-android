import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const defaultPcBridgeId = 'home-main-pc';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final firestore = FirebaseFirestore.instance;
  runApp(
    RemoteCodexApp(
      bootstrap: bootstrapRemoteCodex(firestore),
      sessionRepository: FirestoreSessionRepository(firestore),
    ),
  );
}

Future<AppBootstrap> bootstrapRemoteCodex(FirebaseFirestore firestore) async {
  await Firebase.initializeApp();

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

  return AppBootstrap(uid: uid, pcBridgeId: defaultPcBridgeId);
}

class AppBootstrap {
  const AppBootstrap({required this.uid, required this.pcBridgeId});

  final String uid;
  final String pcBridgeId;
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.title,
    required this.status,
    this.lastResultPreview,
    this.lastErrorPreview,
  });

  final String id;
  final String title;
  final String status;
  final String? lastResultPreview;
  final String? lastErrorPreview;
}

abstract class SessionRepository {
  Stream<List<SessionSummary>> watchSessions(String uid);
  Future<void> createSession({required String uid, required String pcBridgeId});
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return SessionSummary(
                id: doc.id,
                title: (data['title'] as String?)?.trim().isNotEmpty == true ? data['title'] as String : 'Untitled session',
                status: data['status'] as String? ?? 'idle',
                lastResultPreview: data['lastResultPreview'] as String?,
                lastErrorPreview: data['lastErrorPreview'] as String?,
              );
            }).toList());
  }

  @override
  Future<void> createSession({required String uid, required String pcBridgeId}) async {
    final now = DateTime.now();
    final title = 'Session ${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';

    await firestore.collection('users').doc(uid).collection('sessions').add({
      'title': title,
      'status': 'idle',
      'targetPcBridgeId': pcBridgeId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

String two(int value) => value.toString().padLeft(2, '0');

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

  Future<void> createSession() async {
    if (isCreating) {
      return;
    }

    setState(() => isCreating = true);
    try {
      await widget.sessionRepository.createSession(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
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
                      child: _ConnectionSummary(bootstrap: widget.bootstrap),
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
                        return _SessionTile(session: sessions[index]);
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

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
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
            Text('Connected as anonymous user', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('PC bridge: ${bootstrap.pcBridgeId}'),
            const SizedBox(height: 4),
            SelectableText('UID: ${bootstrap.uid}'),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final subtitle = session.lastErrorPreview ?? session.lastResultPreview ?? session.status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: ListTile(
          title: Text(session.title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
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
            Text('No sessions yet', style: Theme.of(context).textTheme.titleLarge),
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
