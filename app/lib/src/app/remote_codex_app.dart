part of '../../main.dart';

class RemoteCodexApp extends StatelessWidget {
  const RemoteCodexApp({
    super.key,
    this.bootstrap,
    required this.sessionRepository,
    this.firebaseConfigStore,
  });

  final Future<AppBootstrap>? bootstrap;
  final SessionRepository sessionRepository;
  final FirebaseConfigStore? firebaseConfigStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'RemoteCodex',
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: bootstrap == null
          ? FirebaseSetupGate(
              firebaseConfigStore:
                  firebaseConfigStore ??
                  const SharedPreferencesFirebaseConfigStore(),
              sessionRepository: sessionRepository,
            )
          : StartupView(
              bootstrap: bootstrap!,
              sessionRepository: sessionRepository,
              firebaseConfigStore: firebaseConfigStore,
            ),
    );
  }
}

class FirebaseSetupGate extends StatefulWidget {
  const FirebaseSetupGate({
    super.key,
    required this.firebaseConfigStore,
    required this.sessionRepository,
  });

  final FirebaseConfigStore firebaseConfigStore;
  final SessionRepository sessionRepository;

  @override
  State<FirebaseSetupGate> createState() => _FirebaseSetupGateState();
}

class _FirebaseSetupGateState extends State<FirebaseSetupGate> {
  late Future<_SavedFirebaseSetup> _savedSetup;
  Future<AppBootstrap>? _bootstrap;

  @override
  void initState() {
    super.initState();
    _savedSetup = _loadSavedSetup();
  }

  Future<_SavedFirebaseSetup> _loadSavedSetup() async {
    final config = await widget.firebaseConfigStore.load();
    if (config != null) {
      return _SavedFirebaseSetup(config: config);
    }
    return _SavedFirebaseSetup(
      useBundledConfig: await widget.firebaseConfigStore
          .loadBundledConfigEnabled(),
    );
  }

  Future<void> startWithConfig(
    FirebaseClientConfig? config, {
    bool persistBundledConfig = false,
  }) async {
    if (config != null) {
      await widget.firebaseConfigStore.save(config);
    } else if (persistBundledConfig) {
      await widget.firebaseConfigStore.saveBundledConfig();
    }

    setState(() {
      _bootstrap = bootstrapRemoteCodex(config: config);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = _bootstrap;
    if (bootstrap != null) {
      return StartupView(
        bootstrap: bootstrap,
        sessionRepository: widget.sessionRepository,
        firebaseConfigStore: widget.firebaseConfigStore,
      );
    }

    return FutureBuilder<_SavedFirebaseSetup>(
      future: _savedSetup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('RemoteCodex')),
            body: const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final savedSetup = snapshot.data;
        if (savedSetup?.config != null ||
            savedSetup?.useBundledConfig == true) {
          scheduleMicrotask(() => startWithConfig(savedSetup?.config));
          return Scaffold(
            appBar: AppBar(title: const Text('RemoteCodex')),
            body: const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return FirebaseSetupView(
          onConfigured: startWithConfig,
          onUseBundledConfig: () =>
              startWithConfig(null, persistBundledConfig: true),
        );
      },
    );
  }
}

class _SavedFirebaseSetup {
  const _SavedFirebaseSetup({this.config, this.useBundledConfig = false});

  final FirebaseClientConfig? config;
  final bool useBundledConfig;
}

class StartupView extends StatelessWidget {
  const StartupView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
    this.firebaseConfigStore,
  });

  final Future<AppBootstrap> bootstrap;
  final SessionRepository sessionRepository;
  final FirebaseConfigStore? firebaseConfigStore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBootstrap>(
      future: bootstrap,
      builder: (context, snapshot) {
        final Widget body;
        final l10n = context.l10n;

        if (snapshot.connectionState != ConnectionState.done) {
          body = _StartupMessage(
            title: l10n.t('signingIn'),
            message: l10n.t('preparingRelay'),
            child: const CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          body = _StartupMessage(
            title: l10n.t('startupFailed'),
            message: snapshot.error.toString(),
            child: const Icon(Icons.error_outline, size: 36),
          );
        } else {
          body = SessionListView(
            bootstrap: snapshot.requireData,
            sessionRepository: sessionRepository,
            firebaseConfigStore: firebaseConfigStore,
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
