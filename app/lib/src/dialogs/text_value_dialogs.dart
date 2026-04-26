part of '../../main.dart';

String sessionGroupKey(SessionSummary session) => session.groupName ?? '';

List<String> sessionGroups(List<SessionSummary> sessions) {
  final groups = sessions.map(sessionGroupKey).toSet().toList();
  groups.sort((a, b) {
    if (a == '') {
      return -1;
    }
    if (b == '') {
      return 1;
    }
    return a.compareTo(b);
  });
  return groups;
}

Future<String?> showTextValueDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
}) {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(context.l10n.t('save')),
        ),
      ],
    ),
  );
}

Future<String?> showGroupValueDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  required List<String> groups,
}) {
  final controller = TextEditingController(text: initialValue);
  final selectableGroups =
      groups.where((group) => group.trim().isNotEmpty).toSet().toList()..sort();
  String? selectedGroup = selectableGroups.contains(initialValue)
      ? initialValue
      : null;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectableGroups.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedGroup,
                decoration: InputDecoration(
                  labelText: context.l10n.t('group'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final group in selectableGroups)
                    DropdownMenuItem(value: group, child: Text(group)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => selectedGroup = value);
                  controller.text = value;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: selectableGroups.isEmpty,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final trimmed = value.trim();
                setState(() {
                  selectedGroup = selectableGroups.contains(trimmed)
                      ? trimmed
                      : null;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    ),
  );
}
