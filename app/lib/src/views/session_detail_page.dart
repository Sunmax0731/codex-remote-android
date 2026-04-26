part of '../../main.dart';

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({
    super.key,
    required this.bootstrap,
    required this.session,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionSummary session;
  final SessionRepository sessionRepository;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> sendCommand() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) {
      return;
    }

    setState(() => isSending = true);
    try {
      await widget.sessionRepository.createCommand(
        uid: widget.bootstrap.uid,
        sessionId: widget.session.id,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        text: text,
      );
      controller.clear();
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  SessionSummary currentSessionFrom(List<SessionSummary> sessions) {
    return sessions.firstWhere(
      (session) => session.id == widget.session.id,
      orElse: () => widget.session,
    );
  }

  Future<void> renameSession(SessionSummary session) async {
    final title = await showTextValueDialog(
      context,
      title: context.l10n.t('renameSession'),
      label: context.l10n.t('sessionName'),
      initialValue: session.title,
    );
    if (title == null) {
      return;
    }

    await widget.sessionRepository.renameSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      title: title,
    );
  }

  Future<void> updateGroup(SessionSummary session, List<String> groups) async {
    final groupName = await showGroupValueDialog(
      context,
      title: context.l10n.t('changeGroup'),
      label: context.l10n.t('groupName'),
      initialValue: session.groupName ?? '',
      groups: groups,
    );
    if (groupName == null) {
      return;
    }

    await widget.sessionRepository.updateSessionGroup(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      groupName: groupName,
    );
  }

  Future<void> deleteSession(SessionSummary session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteSession')),
        content: Text(context.l10n.t('deleteSessionQuestion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.sessionRepository.deleteSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionSummary>>(
      stream: widget.sessionRepository.watchSessions(widget.bootstrap.uid),
      builder: (context, sessionSnapshot) {
        final currentSession = currentSessionFrom(
          sessionSnapshot.data ?? const <SessionSummary>[],
        );
        final groups = sessionGroups(
          sessionSnapshot.data ?? const <SessionSummary>[],
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(currentSession.title),
            actions: [
              IconButton(
                onPressed: () => widget.sessionRepository.updateSessionFavorite(
                  uid: widget.bootstrap.uid,
                  sessionId: currentSession.id,
                  favorite: !currentSession.favorite,
                ),
                tooltip: context.l10n.t(
                  currentSession.favorite ? 'removeFavorite' : 'favorite',
                ),
                icon: Icon(
                  currentSession.favorite ? Icons.star : Icons.star_border,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.t('more'),
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      renameSession(currentSession);
                    case 'group':
                      updateGroup(currentSession, groups);
                    case 'delete':
                      deleteSession(currentSession);
                    case 'options':
                      showSessionOptionsSummaryDialog(context, currentSession);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(context.l10n.t('renameSession')),
                  ),
                  PopupMenuItem(
                    value: 'group',
                    child: Text(context.l10n.t('changeGroup')),
                  ),
                  PopupMenuItem(
                    value: 'options',
                    child: Text(context.l10n.t('cliOptionHelp')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.t('deleteSession')),
                  ),
                ],
              ),
            ],
          ),
          drawer: SessionDrawer(
            bootstrap: widget.bootstrap,
            sessionRepository: widget.sessionRepository,
            currentSessionId: currentSession.id,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<CommandSummary>>(
                    stream: widget.sessionRepository.watchCommands(
                      widget.bootstrap.uid,
                      currentSession.id,
                    ),
                    builder: (context, snapshot) {
                      final commands =
                          snapshot.data ?? const <CommandSummary>[];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _StartupMessage(
                          title: context.l10n.t('commandLoadFailed'),
                          message: snapshot.error.toString(),
                          child: const Icon(Icons.error_outline, size: 36),
                        );
                      }

                      if (commands.isEmpty) {
                        return const _NoCommands();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: commands.length,
                        itemBuilder: (context, index) =>
                            _CommandTile(command: commands[index]),
                      );
                    },
                  ),
                ),
                _CommandComposer(
                  controller: controller,
                  isSending: isSending,
                  onSend: sendCommand,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
