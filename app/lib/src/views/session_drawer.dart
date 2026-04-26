part of '../../main.dart';

class SessionDrawer extends StatelessWidget {
  const SessionDrawer({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
    required this.currentSessionId,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;
  final String currentSessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<List<SessionSummary>>(
          stream: sessionRepository.watchSessions(bootstrap.uid),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <SessionSummary>[];

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  title: Text(
                    l10n.t('sessions'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${sessions.length} ${l10n.t('sessionCount')}',
                  ),
                ),
                const Divider(height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  ListTile(title: Text(l10n.t('loadingSessions')))
                else if (snapshot.hasError)
                  ListTile(
                    title: Text(l10n.t('sessionLoadFailed')),
                    subtitle: Text(snapshot.error.toString()),
                  )
                else if (sessions.isEmpty)
                  ListTile(title: Text(l10n.t('noSessionsYet')))
                else
                  for (final session in sessions)
                    ListTile(
                      selected: session.id == currentSessionId,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(session.status),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (session.id == currentSessionId) {
                          return;
                        }
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => SessionDetailPage(
                              bootstrap: bootstrap,
                              session: session,
                              sessionRepository: sessionRepository,
                            ),
                          ),
                        );
                      },
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
