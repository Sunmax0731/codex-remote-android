part of '../../main.dart';

abstract class FirebaseConfigStore {
  Future<FirebaseClientConfig?> load();

  Future<bool> loadBundledConfigEnabled();

  Future<void> save(FirebaseClientConfig config);

  Future<void> saveBundledConfig();

  Future<void> clear();
}

class SharedPreferencesFirebaseConfigStore implements FirebaseConfigStore {
  const SharedPreferencesFirebaseConfigStore();

  static const _configKey = 'remote_codex.firebase_client_config.v1';
  static const _bundledConfigKey =
      'remote_codex.firebase_bundled_config_enabled.v1';

  @override
  Future<FirebaseClientConfig?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_configKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return FirebaseClientConfig.fromJson(decoded);
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  @override
  Future<bool> loadBundledConfigEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_bundledConfigKey) ?? false;
  }

  @override
  Future<void> save(FirebaseClientConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_configKey, jsonEncode(config.toJson()));
    await preferences.remove(_bundledConfigKey);
  }

  @override
  Future<void> saveBundledConfig() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_configKey);
    await preferences.setBool(_bundledConfigKey, true);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_configKey);
    await preferences.remove(_bundledConfigKey);
  }
}
