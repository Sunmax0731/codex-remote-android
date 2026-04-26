part of '../../main.dart';

class _CommandTile extends StatefulWidget {
  const _CommandTile({required this.command});

  final CommandSummary command;

  @override
  State<_CommandTile> createState() => _CommandTileState();
}

class _CommandTileState extends State<_CommandTile> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    updateTimer();
  }

  @override
  void didUpdateWidget(covariant _CommandTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.command.status != widget.command.status ||
        oldWidget.command.completedAt != widget.command.completedAt ||
        oldWidget.command.createdAt != widget.command.createdAt) {
      updateTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void updateTimer() {
    timer?.cancel();
    if (isTerminalStatus(widget.command.status) ||
        widget.command.createdAt == null) {
      timer = null;
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final command = widget.command;
    final status = command.status;
    final detail =
        command.errorText ??
        command.resultText ??
        command.progressText ??
        l10n.t('waitingFinalResult');
    final elapsed = commandElapsed(command);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    command.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(status)),
              ],
            ),
            if (elapsed != null) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.t('elapsed')}: ${formatDuration(elapsed)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (command.progressUpdatedAt != null &&
                !isTerminalStatus(status)) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.t('lastProgress')}: ${formatDateTime(context, command.progressUpdatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            SelectableText(detail),
          ],
        ),
      ),
    );
  }
}

bool isTerminalStatus(String status) {
  return status == 'completed' || status == 'failed' || status == 'canceled';
}

Duration? commandElapsed(CommandSummary command) {
  final started = command.createdAt;
  if (started == null) {
    return null;
  }

  final ended = command.completedAt;
  final end = ended ?? DateTime.now();
  final elapsed = end.difference(started);

  if (elapsed.isNegative) {
    return Duration.zero;
  }

  return elapsed;
}

class _CommandComposer extends StatelessWidget {
  const _CommandComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: l10n.t('instruction'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              tooltip: l10n.t('send'),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCommands extends StatelessWidget {
  const _NoCommands();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 40),
            const SizedBox(height: 16),
            Text(
              context.l10n.t('noCommandsYet'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions({this.messageKey = 'noSessionsYet'});

  final String messageKey;

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
            Text(
              context.l10n.t(messageKey),
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
