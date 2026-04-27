part of '../../main.dart';

class _CommandTile extends StatefulWidget {
  const _CommandTile({required this.command});

  final CommandSummary command;

  @override
  State<_CommandTile> createState() => _CommandTileState();
}

class _CommandTileState extends State<_CommandTile> {
  Timer? timer;
  final Map<String, Future<Uint8List?>> imageLoaders =
      <String, Future<Uint8List?>>{};

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

  Future<Uint8List?> imageBytesFor(CommandAttachment attachment) {
    return imageLoaders.putIfAbsent(
      attachment.id,
      () => commandAttachmentImageLoader(attachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final command = widget.command;
    final status = command.status;
    final imageAttachments = command.attachments
        .where((attachment) => attachment.type == 'image')
        .toList(growable: false);
    final fileAttachments = command.attachments
        .where((attachment) => attachment.type != 'image')
        .toList(growable: false);
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
            if (imageAttachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final attachment in imageAttachments)
                    _CommandAttachmentImagePreview(
                      key: ValueKey(
                        'command-attachment-image-${command.id}-${attachment.id}',
                      ),
                      future: imageBytesFor(attachment),
                      fileName: attachment.fileName,
                    ),
                ],
              ),
            ],
            if (fileAttachments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final attachment in fileAttachments)
                    Chip(
                      avatar: const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 18,
                      ),
                      label: Text(attachment.fileName),
                    ),
                ],
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
            if (command.resultAttachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ResultImageStrip(attachments: command.resultAttachments),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultImageStrip extends StatelessWidget {
  const _ResultImageStrip({required this.attachments});

  final List<CommandResultAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final images = attachments
        .where((attachment) => attachment.contentType.startsWith('image/'))
        .toList(growable: false);
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final image in images) _ResultImageThumbnail(attachment: image),
      ],
    );
  }
}

class _ResultImageThumbnail extends StatefulWidget {
  const _ResultImageThumbnail({required this.attachment});

  final CommandResultAttachment attachment;

  @override
  State<_ResultImageThumbnail> createState() => _ResultImageThumbnailState();
}

class _ResultImageThumbnailState extends State<_ResultImageThumbnail> {
  late Future<Uint8List?> imageBytesFuture;

  @override
  void initState() {
    super.initState();
    imageBytesFuture = loadImageBytes();
  }

  @override
  void didUpdateWidget(covariant _ResultImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.storagePath != widget.attachment.storagePath) {
      imageBytesFuture = loadImageBytes();
    }
  }

  Future<Uint8List?> loadImageBytes() {
    return resultAttachmentImageLoader(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: imageBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        } else if (bytes == null || bytes.isEmpty) {
          child = Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        } else {
          child = Image.memory(bytes, fit: BoxFit.cover);
        }

        return Tooltip(
          message:
              '${widget.attachment.fileName} / ${formatAttachmentSize(widget.attachment.sizeBytes)}',
          child: GestureDetector(
            onTap: bytes == null || bytes.isEmpty
                ? null
                : () =>
                      showResultImageDialog(context, widget.attachment, bytes),
            onLongPress: bytes == null || bytes.isEmpty
                ? null
                : () => saveResultImage(context, widget.attachment, bytes),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 112,
                height: 112,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showResultImageDialog(
  BuildContext context,
  CommandResultAttachment attachment,
  Uint8List bytes,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.92,
            maxHeight: size.height * 0.82,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: context.l10n.t('close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> saveResultImage(
  BuildContext context,
  CommandResultAttachment attachment,
  Uint8List bytes,
) async {
  final l10n = context.l10n;
  try {
    final savedPath = await FilePicker.saveFile(
      dialogTitle: l10n.t('saveResultImage'),
      fileName: attachment.fileName,
      bytes: bytes,
      type: FileType.image,
    );
    if (!context.mounted || savedPath == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('resultImageSaved'))));
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.t('resultImageSaveFailed')}: $error')),
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
    required this.attachments,
    required this.isSending,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<PendingCommandAttachment> attachments;
  final bool isSending;
  final VoidCallback onAddAttachment;
  final ValueChanged<PendingCommandAttachment> onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imageAttachments = attachments
        .where((attachment) => attachment.kind == 'image')
        .toList(growable: false);
    final fileAttachments = attachments
        .where((attachment) => attachment.kind != 'image')
        .toList(growable: false);
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageAttachments.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final attachment in imageAttachments)
                            _PendingAttachmentImagePreview(
                              key: ValueKey(
                                'pending-attachment-image-${attachment.fileName}',
                              ),
                              attachment: attachment,
                              enabled: !isSending,
                              onDeleted: () => onRemoveAttachment(attachment),
                            ),
                        ],
                      ),
                    if (fileAttachments.isNotEmpty) ...[
                      if (imageAttachments.isNotEmpty)
                        const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final attachment in fileAttachments)
                            InputChip(
                              avatar: const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 18,
                              ),
                              label: Text(attachment.fileName),
                              tooltip:
                                  '${attachment.contentType} / ${formatAttachmentSize(attachment.sizeBytes)}',
                              onDeleted: isSending
                                  ? null
                                  : () => onRemoveAttachment(attachment),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: isSending ? null : onAddAttachment,
                  tooltip: l10n.t('attachFiles'),
                  icon: const Icon(Icons.attach_file),
                ),
                const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}

String formatAttachmentSize(int sizeBytes) {
  if (sizeBytes < 1024) {
    return '$sizeBytes B';
  }
  final kib = sizeBytes / 1024;
  if (kib < 1024) {
    return '${kib.toStringAsFixed(1)} KiB';
  }
  return '${(kib / 1024).toStringAsFixed(1)} MiB';
}

class _PendingAttachmentImagePreview extends StatelessWidget {
  const _PendingAttachmentImagePreview({
    super.key,
    required this.attachment,
    required this.enabled,
    required this.onDeleted,
  });

  final PendingCommandAttachment attachment;
  final bool enabled;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return _AttachmentPreviewCard(
      fileName: attachment.fileName,
      image: Image.memory(
        attachment.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
      trailing: IconButton(
        onPressed: enabled ? onDeleted : null,
        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        icon: const Icon(Icons.close, size: 18),
      ),
    );
  }
}

class _CommandAttachmentImagePreview extends StatelessWidget {
  const _CommandAttachmentImagePreview({
    super.key,
    required this.future,
    required this.fileName,
  });

  final Future<Uint8List?> future;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return _AttachmentPreviewCard(
            fileName: fileName,
            image: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _AttachmentPreviewCard(
            fileName: fileName,
            image: const Center(child: CircularProgressIndicator()),
          );
        }

        return _AttachmentPreviewCard(
          fileName: fileName,
          image: _AttachmentPreviewUnavailable(
            message: context.l10n.t('attachmentPreviewUnavailable'),
          ),
        );
      },
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  const _AttachmentPreviewCard({
    required this.fileName,
    required this.image,
    this.trailing,
  });

  final String fileName;
  final Widget image;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 104,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: image,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreviewUnavailable extends StatelessWidget {
  const _AttachmentPreviewUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, size: 28),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
