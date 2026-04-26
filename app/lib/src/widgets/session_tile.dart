part of '../../main.dart';

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
  });

  final SessionSummary session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        session.lastErrorPreview ?? session.lastResultPreview ?? session.status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          leading: Icon(
            session.favorite ? Icons.star : Icons.forum_outlined,
            color: session.favorite
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(session.title),
          subtitle: Text(
            [
              if (session.groupName != null) session.groupName!,
              subtitle,
            ].join(' / '),
          ),
          trailing: IconButton(
            onPressed: onMore,
            tooltip: context.l10n.t('more'),
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ),
    );
  }
}
