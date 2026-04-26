part of '../../main.dart';

class FirebaseSetupView extends StatefulWidget {
  const FirebaseSetupView({
    super.key,
    required this.onConfigured,
    required this.onUseBundledConfig,
  });

  final Future<void> Function(FirebaseClientConfig? config) onConfigured;
  final Future<void> Function() onUseBundledConfig;

  @override
  State<FirebaseSetupView> createState() => _FirebaseSetupViewState();
}

class _FirebaseSetupViewState extends State<FirebaseSetupView> {
  final projectIdController = TextEditingController();
  final apiKeyController = TextEditingController();
  final appIdController = TextEditingController();
  final messagingSenderIdController = TextEditingController();
  final authDomainController = TextEditingController();
  final storageBucketController = TextEditingController();
  bool isSaving = false;
  String? errorText;

  @override
  void dispose() {
    projectIdController.dispose();
    apiKeyController.dispose();
    appIdController.dispose();
    messagingSenderIdController.dispose();
    authDomainController.dispose();
    storageBucketController.dispose();
    super.dispose();
  }

  Future<void> saveRuntimeConfig() async {
    final config = FirebaseClientConfigDraft(
      projectId: projectIdController.text,
      apiKey: apiKeyController.text,
      appId: appIdController.text,
      messagingSenderId: messagingSenderIdController.text,
      authDomain: authDomainController.text,
      storageBucket: storageBucketController.text,
    ).validate();

    if (config == null) {
      setState(() {
        errorText = 'Project ID, API key, app ID, and sender ID are required.';
      });
      return;
    }

    await start(config);
  }

  Future<void> start(FirebaseClientConfig? config) async {
    setState(() {
      isSaving = true;
      errorText = null;
    });

    try {
      await widget.onConfigured(config);
    } catch (error) {
      if (mounted) {
        setState(() {
          isSaving = false;
          errorText = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('RemoteCodex')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Firebase setup', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Enter the Firebase web or Android client values for your own project. Do not paste service account JSON or Admin SDK credentials here.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _SetupTextField(
              controller: projectIdController,
              label: 'Project ID',
              hintText: 'my-firebase-project',
            ),
            _SetupTextField(
              controller: apiKeyController,
              label: 'API key',
              hintText: 'AIza...',
            ),
            _SetupTextField(
              controller: appIdController,
              label: 'App ID',
              hintText: '1:1234567890:android:abcdef',
            ),
            _SetupTextField(
              controller: messagingSenderIdController,
              label: 'Messaging sender ID',
              keyboardType: TextInputType.number,
            ),
            _SetupTextField(
              controller: authDomainController,
              label: 'Auth domain (optional)',
              hintText: 'my-firebase-project.firebaseapp.com',
            ),
            _SetupTextField(
              controller: storageBucketController,
              label: 'Storage bucket (optional)',
              hintText: 'my-firebase-project.appspot.com',
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : saveRuntimeConfig,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_done),
              label: const Text('Save and connect'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isSaving ? null : widget.onUseBundledConfig,
              icon: const Icon(Icons.phone_android),
              label: const Text('Use bundled Firebase config'),
            ),
            const SizedBox(height: 16),
            Text(
              'The bundled option is for developer builds that already include google-services.json. Runtime setup is required for APK-only distribution to another Firebase project.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupTextField extends StatelessWidget {
  const _SetupTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
