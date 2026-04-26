part of '../../main.dart';

class SessionListView extends StatefulWidget {
  const SessionListView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
    this.firebaseConfigStore,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;
  final FirebaseConfigStore? firebaseConfigStore;

  @override
  State<SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends State<SessionListView> {
  final TextEditingController searchController = TextEditingController();
  bool isCreating = false;
  String? selectedGroup;

  @override
  void initState() {
    super.initState();
    NotificationService().attachNavigation(
      bootstrap: widget.bootstrap,
      sessionRepository: widget.sessionRepository,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<SessionSummary> filteredSessions(List<SessionSummary> sessions) {
    final query = searchController.text.trim().toLowerCase();
    return sessions
        .where((session) {
          final matchesSearch =
              query.isEmpty || session.title.toLowerCase().contains(query);
          final matchesGroup =
              selectedGroup == null ||
              sessionGroupKey(session) == selectedGroup;
          return matchesSearch && matchesGroup;
        })
        .toList(growable: false);
  }

  Future<void> openSessionActions(
    SessionSummary session,
    List<SessionSummary> sessions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(context.l10n.t('renameSession')),
              onTap: () async {
                Navigator.of(context).pop();
                await renameSession(session);
              },
            ),
            ListTile(
              leading: Icon(session.favorite ? Icons.star : Icons.star_border),
              title: Text(
                context.l10n.t(
                  session.favorite ? 'removeFavorite' : 'favorite',
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.sessionRepository.updateSessionFavorite(
                  uid: widget.bootstrap.uid,
                  sessionId: session.id,
                  favorite: !session.favorite,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(context.l10n.t('changeGroup')),
              onTap: () async {
                Navigator.of(context).pop();
                await changeSessionGroup(session, sessionGroups(sessions));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.t('cliOptionHelp')),
              onTap: () {
                Navigator.of(context).pop();
                showSessionOptionsSummaryDialog(context, session);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.l10n.t('deleteSession'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await confirmDeleteSession(session);
              },
            ),
          ],
        ),
      ),
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

  Future<void> changeSessionGroup(
    SessionSummary session,
    List<String> groups,
  ) async {
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

  Future<void> confirmDeleteSession(SessionSummary session) async {
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
  }

  Future<void> createSession() async {
    if (isCreating) {
      return;
    }

    setState(() => isCreating = true);
    SessionCreateOptions defaults;
    try {
      defaults = await widget.sessionRepository.loadCliDefaults(
        widget.bootstrap.uid,
      );
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }

    if (!mounted) {
      return;
    }

    final options = await showSessionOptionsDialog(
      context,
      title: context.l10n.t('newSession'),
      initialOptions: defaults,
      primaryLabel: context.l10n.t('create'),
      showExecutionDefaults: false,
    );
    if (options == null) {
      return;
    }

    setState(() => isCreating = true);
    try {
      final session = await widget.sessionRepository.createSession(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        options: options,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(
            bootstrap: widget.bootstrap,
            session: session,
            sessionRepository: widget.sessionRepository,
          ),
        ),
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
        final visibleSessions = filteredSessions(sessions);
        final groups = sessionGroups(sessions);

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
                      child: _ConnectionSummary(
                        bootstrap: widget.bootstrap,
                        sessionRepository: widget.sessionRepository,
                        firebaseConfigStore: widget.firebaseConfigStore,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              labelText: context.l10n.t('searchSessions'),
                              border: const OutlineInputBorder(),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(context.l10n.t('allGroups')),
                                    selected: selectedGroup == null,
                                    onSelected: (_) =>
                                        setState(() => selectedGroup = null),
                                  ),
                                ),
                                for (final group in groups)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        group.isEmpty
                                            ? context.l10n.t('ungrouped')
                                            : group,
                                      ),
                                      selected: selectedGroup == group,
                                      onSelected: (_) =>
                                          setState(() => selectedGroup = group),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: _StartupMessage(
                        title: context.l10n.t('sessionLoadFailed'),
                        message: snapshot.error.toString(),
                        child: const Icon(Icons.error_outline, size: 36),
                      ),
                    )
                  else if (sessions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySessions(),
                    )
                  else if (visibleSessions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySessions(messageKey: 'noMatchingSessions'),
                    )
                  else
                    SliverList.builder(
                      itemCount: visibleSessions.length,
                      itemBuilder: (context, index) {
                        final session = visibleSessions[index];
                        return _SessionTile(
                          session: session,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SessionDetailPage(
                                  bootstrap: widget.bootstrap,
                                  session: session,
                                  sessionRepository: widget.sessionRepository,
                                ),
                              ),
                            );
                          },
                          onLongPress: () =>
                              openSessionActions(session, sessions),
                          onMore: () => openSessionActions(session, sessions),
                        );
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
                label: Text(
                  isCreating
                      ? context.l10n.t('creating')
                      : context.l10n.t('newSession'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
