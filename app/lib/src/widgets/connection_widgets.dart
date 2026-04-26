part of '../../main.dart';

class _ConnectionSummary extends StatefulWidget {
  const _ConnectionSummary({
    required this.bootstrap,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;

  @override
  State<_ConnectionSummary> createState() => _ConnectionSummaryState();
}

class _ConnectionSummaryState extends State<_ConnectionSummary> {
  Future<void> openConnectionSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ConnectionSettingsSheet(
        bootstrap: widget.bootstrap,
        sessionRepository: widget.sessionRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StreamBuilder<PcBridgeStatus>(
      stream: widget.sessionRepository.watchPcBridgeStatus(
        widget.bootstrap.uid,
        widget.bootstrap.pcBridgeId,
      ),
      builder: (context, snapshot) {
        final bridge = snapshot.data ?? const PcBridgeStatus();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                const Icon(Icons.computer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('pcBridge'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.bootstrap.pcBridgeId}${bridge.status == null ? '' : ' (${bridge.status})'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${l10n.t('lastHeartbeat')}: ${formatDateTime(context, bridge.lastSeenAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: openConnectionSettings,
                  tooltip: l10n.t('settings'),
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionSettingsSheet extends StatefulWidget {
  const _ConnectionSettingsSheet({
    required this.bootstrap,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;

  @override
  State<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState extends State<_ConnectionSettingsSheet> {
  bool isCheckingBridge = false;
  bool isOpeningDefaults = false;
  String? checkError;

  Future<void> requestHealthCheck() async {
    setState(() {
      isCheckingBridge = true;
      checkError = null;
    });

    try {
      await widget.sessionRepository.requestPcBridgeHealthCheck(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
      );
    } catch (error) {
      checkError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          isCheckingBridge = false;
        });
      }
    }
  }

  Future<void> openCliDefaults() async {
    if (isOpeningDefaults) {
      return;
    }

    setState(() => isOpeningDefaults = true);
    SessionCreateOptions defaults;
    try {
      defaults = await widget.sessionRepository.loadCliDefaults(
        widget.bootstrap.uid,
      );
    } finally {
      if (mounted) {
        setState(() => isOpeningDefaults = false);
      }
    }

    if (!mounted) {
      return;
    }

    final updated = await showSessionOptionsDialog(
      context,
      title: context.l10n.t('cliDefaults'),
      initialOptions: defaults,
      primaryLabel: context.l10n.t('save'),
      showExecutionDefaults: true,
    );

    if (updated == null) {
      return;
    }

    await widget.sessionRepository.saveCliDefaults(
      widget.bootstrap.uid,
      updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: StreamBuilder<PcBridgeStatus>(
        stream: widget.sessionRepository.watchPcBridgeStatus(
          widget.bootstrap.uid,
          widget.bootstrap.pcBridgeId,
        ),
        builder: (context, snapshot) {
          final bridge = snapshot.data ?? const PcBridgeStatus();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('connectionSettings'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('connectedAnonymous'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.t('pcBridge')}: ${widget.bootstrap.pcBridgeId}${bridge.status == null ? '' : ' (${bridge.status})'}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('lastHeartbeat')}: ${formatDateTime(context, bridge.lastSeenAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('lastQueueCheck')}: ${formatDateTime(context, bridge.lastQueueCheckedAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('lastManualCheck')}: ${formatDateTime(context, bridge.lastHealthCheckRequestedAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('lastResponse')}: ${formatDateTime(context, bridge.lastHealthCheckRespondedAt)}${bridge.lastHealthCheckStatus == null ? '' : ' (${bridge.lastHealthCheckStatus})'}',
                ),
                if (checkError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    checkError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: isCheckingBridge ? null : requestHealthCheck,
                        icon: isCheckingBridge
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sensors),
                        label: Text(
                          isCheckingBridge
                              ? l10n.t('checking')
                              : l10n.t('checkPcNow'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: isOpeningDefaults ? null : openCliDefaults,
                        icon: isOpeningDefaults
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.tune),
                        label: Text(
                          isOpeningDefaults
                              ? l10n.t('loading')
                              : l10n.t('cliDefaults'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.t('notifications')}: ${widget.bootstrap.notificationState.permissionStatus}',
                ),
                const SizedBox(height: 4),
                SelectableText('UID: ${widget.bootstrap.uid}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

String formatDateTime(BuildContext context, DateTime? value) {
  if (value == null) {
    return context.l10n.t('notSeenYet');
  }

  final local = value.toLocal();
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes <= 0) {
    return '${seconds}s';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours <= 0) {
    return '${minutes}m ${seconds}s';
  }

  return '${hours}h ${remainingMinutes}m ${seconds}s';
}
