part of '../../main.dart';

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
