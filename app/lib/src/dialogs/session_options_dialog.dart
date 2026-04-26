part of '../../main.dart';

Future<SessionCreateOptions?> showSessionOptionsDialog(
  BuildContext context, {
  required String title,
  required SessionCreateOptions initialOptions,
  required String primaryLabel,
  required bool showExecutionDefaults,
}) {
  final dialogContext = context;
  final l10n = context.l10n;
  final profileController = TextEditingController(
    text: initialOptions.codexProfile ?? '',
  );
  final configOverridesController = TextEditingController(
    text: linesText(initialOptions.codexConfigOverrides),
  );
  final enableFeaturesController = TextEditingController(
    text: linesText(initialOptions.codexEnableFeatures),
  );
  final disableFeaturesController = TextEditingController(
    text: linesText(initialOptions.codexDisableFeatures),
  );
  final imagesController = TextEditingController(
    text: linesText(initialOptions.codexImages),
  );
  final addDirsController = TextEditingController(
    text: linesText(initialOptions.codexAddDirs),
  );
  final outputSchemaController = TextEditingController(
    text: initialOptions.codexOutputSchema ?? '',
  );
  var model = codexModelOptions.contains(initialOptions.codexModel)
      ? initialOptions.codexModel
      : defaultCodexModel;
  var sandbox = codexSandboxOptions.contains(initialOptions.codexSandbox)
      ? initialOptions.codexSandbox
      : defaultCodexSandbox;
  var bypassSandbox = initialOptions.codexBypassSandbox;
  var useOss = initialOptions.codexOss;
  var localProvider = initialOptions.codexLocalProvider ?? '';
  var fullAuto = initialOptions.codexFullAuto;
  var skipGitRepoCheck = initialOptions.codexSkipGitRepoCheck;
  var ephemeral = initialOptions.codexEphemeral;
  var ignoreUserConfig = initialOptions.codexIgnoreUserConfig;
  var ignoreRules = initialOptions.codexIgnoreRules;
  var jsonOutput = initialOptions.codexJson;

  void dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> pickImageFiles(StateSetter setDialogState) async {
    dismissKeyboard();
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) {
      return;
    }

    final selectedPaths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    if (selectedPaths.isEmpty) {
      return;
    }

    final merged = [...lines(imagesController.text), ...selectedPaths];
    setDialogState(() {
      imagesController.text = linesText(merged);
    });
  }

  return showDialog<SessionCreateOptions>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: model,
                    decoration: optionInputDecoration(
                      context,
                      label: l10n.t('model'),
                      helpName: 'Model',
                    ),
                    items: [
                      for (final option in codexModelOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => model = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: profileController,
                    decoration: optionInputDecoration(
                      context,
                      label: l10n.t('profile'),
                      hint: l10n.t('optionalConfigProfile'),
                      helpName: 'Profile',
                    ),
                  ),
                  if (showExecutionDefaults) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sandbox,
                      decoration: optionInputDecoration(
                        context,
                        label: l10n.t('sandbox'),
                        helpName: 'Sandbox',
                      ),
                      items: [
                        for (final option in codexSandboxOptions)
                          DropdownMenuItem(value: option, child: Text(option)),
                      ],
                      onChanged: bypassSandbox
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => sandbox = value);
                              }
                            },
                    ),
                    _OptionSwitchTile(
                      title: l10n.t('bypassSandbox'),
                      subtitle: l10n.t('bypassSandboxSubtitle'),
                      helpName: 'Bypass sandbox',
                      value: bypassSandbox,
                      onChanged: (value) {
                        setDialogState(() => bypassSandbox = value);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.t('sandboxUsesDefaults'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l10n.t('advancedCliOptions')),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      _MultiLineOptionField(
                        controller: configOverridesController,
                        label: '--config key=value',
                        hint: 'model="gpt-5.5"',
                        helpName: '--config key=value',
                      ),
                      _MultiLineOptionField(
                        controller: enableFeaturesController,
                        label: '--enable',
                        hint: 'feature-name',
                        helpName: '--enable / --disable',
                      ),
                      _MultiLineOptionField(
                        controller: disableFeaturesController,
                        label: '--disable',
                        hint: 'feature-name',
                        helpName: '--enable / --disable',
                      ),
                      _ImageOptionField(
                        controller: imagesController,
                        onPick: () => pickImageFiles(setDialogState),
                      ),
                      _OptionSwitchTile(
                        title: '--oss',
                        helpName: '--oss',
                        value: useOss,
                        onChanged: (value) {
                          setDialogState(() => useOss = value);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: localProvider,
                        decoration: optionInputDecoration(
                          context,
                          label: '--local-provider',
                          helpName: '--local-provider',
                        ),
                        items: [
                          for (final option in codexLocalProviderOptions)
                            DropdownMenuItem(
                              value: option,
                              child: Text(
                                option.isEmpty
                                    ? l10n.t('defaultOption')
                                    : option,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => localProvider = value);
                          }
                        },
                      ),
                      _OptionSwitchTile(
                        title: '--full-auto',
                        helpName: '--full-auto',
                        value: fullAuto,
                        onChanged: bypassSandbox
                            ? null
                            : (value) {
                                setDialogState(() => fullAuto = value);
                              },
                      ),
                      _MultiLineOptionField(
                        controller: addDirsController,
                        label: '--add-dir',
                        hint: r'D:\another-workspace',
                        helpName: '--add-dir',
                      ),
                      _OptionSwitchTile(
                        title: '--skip-git-repo-check',
                        helpName: '--skip-git-repo-check',
                        value: skipGitRepoCheck,
                        onChanged: (value) {
                          setDialogState(() => skipGitRepoCheck = value);
                        },
                      ),
                      _OptionSwitchTile(
                        title: '--ephemeral',
                        helpName: '--ephemeral',
                        value: ephemeral,
                        onChanged: (value) {
                          setDialogState(() => ephemeral = value);
                        },
                      ),
                      _OptionSwitchTile(
                        title: '--ignore-user-config',
                        helpName: '--ignore-user-config',
                        value: ignoreUserConfig,
                        onChanged: (value) {
                          setDialogState(() => ignoreUserConfig = value);
                        },
                      ),
                      _OptionSwitchTile(
                        title: '--ignore-rules',
                        helpName: '--ignore-rules',
                        value: ignoreRules,
                        onChanged: (value) {
                          setDialogState(() => ignoreRules = value);
                        },
                      ),
                      TextField(
                        controller: outputSchemaController,
                        decoration: optionInputDecoration(
                          context,
                          label: '--output-schema',
                          hint: r'C:\path\schema.json',
                          helpName: '--output-schema',
                        ),
                      ),
                      _OptionSwitchTile(
                        title: '--json',
                        subtitle: l10n.t('bridgeReadsFinalOutput'),
                        helpName: '--json',
                        value: jsonOutput,
                        onChanged: (value) {
                          setDialogState(() => jsonOutput = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dismissKeyboard();
                  showCliOptionHelpDialog(dialogContext);
                },
                child: Text(l10n.t('help')),
              ),
              TextButton(
                onPressed: () {
                  dismissKeyboard();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.t('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  dismissKeyboard();
                  final profile = profileController.text.trim();
                  final outputSchema = outputSchemaController.text.trim();
                  Navigator.of(context).pop(
                    SessionCreateOptions(
                      codexModel: model,
                      codexSandbox: sandbox,
                      codexBypassSandbox: bypassSandbox,
                      codexProfile: profile.isEmpty ? null : profile,
                      codexConfigOverrides: lines(
                        configOverridesController.text,
                      ),
                      codexEnableFeatures: lines(enableFeaturesController.text),
                      codexDisableFeatures: lines(
                        disableFeaturesController.text,
                      ),
                      codexImages: lines(imagesController.text),
                      codexOss: useOss,
                      codexLocalProvider: localProvider.isEmpty
                          ? null
                          : localProvider,
                      codexFullAuto: fullAuto,
                      codexAddDirs: lines(addDirsController.text),
                      codexSkipGitRepoCheck: skipGitRepoCheck,
                      codexEphemeral: ephemeral,
                      codexIgnoreUserConfig: ignoreUserConfig,
                      codexIgnoreRules: ignoreRules,
                      codexOutputSchema: outputSchema.isEmpty
                          ? null
                          : outputSchema,
                      codexJson: jsonOutput,
                    ),
                  );
                },
                child: Text(primaryLabel),
              ),
            ],
          );
        },
      );
    },
  );
}

class _MultiLineOptionField extends StatelessWidget {
  const _MultiLineOptionField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helpName,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String helpName;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      decoration: optionInputDecoration(
        context,
        label: label,
        hint: hint,
        helpName: helpName,
      ),
    );
  }
}

class _ImageOptionField extends StatelessWidget {
  const _ImageOptionField({required this.controller, required this.onPick});

  final TextEditingController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _MultiLineOptionField(
            controller: controller,
            label: '--image',
            hint: r'C:\path\image.png',
            helpName: '--image',
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: context.l10n.t('selectImageFile'),
          onPressed: onPick,
          icon: const Icon(Icons.attach_file),
        ),
      ],
    );
  }
}

class _OptionSwitchTile extends StatelessWidget {
  const _OptionSwitchTile({
    required this.title,
    required this.helpName,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String helpName;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          _OptionHelpButton(helpName: helpName),
        ],
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _OptionHelpButton extends StatelessWidget {
  const _OptionHelpButton({required this.helpName});

  final String helpName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '${context.l10n.t('showHelpFor')} $helpName',
      onPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        showCliOptionHelpDialog(context, optionName: helpName);
      },
      icon: const Icon(Icons.help_outline),
    );
  }
}

InputDecoration optionInputDecoration(
  BuildContext context, {
  required String label,
  required String helpName,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: _OptionHelpButton(helpName: helpName),
  );
}

String linesText(List<String> values) => values.join('\n');

List<String> lines(String value) => value
    .split(RegExp(r'\r?\n'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

Future<void> showCliOptionHelpDialog(
  BuildContext context, {
  String? optionName,
}) {
  final items = optionName == null
      ? cliOptionHelpItems
      : cliOptionHelpItems
            .where((item) => item.name == optionName)
            .toList(growable: false);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(optionName ?? context.l10n.t('cliOptionHelp')),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? Text(context.l10n.t('noHelpAvailable'))
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final option = items[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${context.l10n.t('where')}: ${localizedOptionHelpLocation(context, option)}',
                      ),
                      const SizedBox(height: 6),
                      Text(localizedOptionHelpDescription(context, option)),
                      const SizedBox(height: 6),
                      Text('${context.l10n.t('example')}: ${option.example}'),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.t('close')),
        ),
      ],
    ),
  );
}

String localizedOptionHelpDescription(
  BuildContext context,
  CliOptionHelp option,
) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return cliOptionHelpDescriptions[languageCode]?[option.name] ??
      option.description;
}

String localizedOptionHelpLocation(BuildContext context, CliOptionHelp option) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return cliOptionHelpLocations[languageCode]?[option.location] ??
      option.location;
}

class CliOptionHelp {
  const CliOptionHelp({
    required this.name,
    required this.location,
    required this.description,
    required this.example,
  });

  final String name;
  final String location;
  final String description;
  final String example;
}

Future<void> showSessionOptionsSummaryDialog(
  BuildContext context,
  SessionSummary session,
) {
  final options = session.codexOptions ?? defaultSessionCreateOptions;
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(session.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.t('model')}: ${options.codexModel}'),
            const SizedBox(height: 6),
            Text('${l10n.t('sandbox')}: ${options.codexSandbox}'),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('bypassSandbox')}: ${options.codexBypassSandbox ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('profile')}: ${options.codexProfile ?? l10n.t('none')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('config')}: ${summaryList(context, options.codexConfigOverrides)}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('enable')}: ${summaryList(context, options.codexEnableFeatures)}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('disable')}: ${summaryList(context, options.codexDisableFeatures)}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('images')}: ${summaryList(context, options.codexImages)}',
            ),
            const SizedBox(height: 6),
            Text('OSS: ${options.codexOss ? l10n.t('on') : l10n.t('off')}'),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('localProvider')}: ${options.codexLocalProvider ?? l10n.t('defaultOption')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('fullAuto')}: ${options.codexFullAuto ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('addDirs')}: ${summaryList(context, options.codexAddDirs)}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('skipGitRepoCheck')}: ${options.codexSkipGitRepoCheck ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('ephemeral')}: ${options.codexEphemeral ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('ignoreUserConfig')}: ${options.codexIgnoreUserConfig ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('ignoreRules')}: ${options.codexIgnoreRules ? l10n.t('on') : l10n.t('off')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('outputSchema')}: ${options.codexOutputSchema ?? l10n.t('none')}',
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.t('jsonEvents')}: ${options.codexJson ? l10n.t('on') : l10n.t('off')}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('close')),
        ),
      ],
    ),
  );
}

String summaryList(BuildContext context, List<String> values) {
  if (values.isEmpty) {
    return context.l10n.t('none');
  }

  return values.join(', ');
}
