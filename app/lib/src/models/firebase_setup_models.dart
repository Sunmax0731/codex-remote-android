part of '../../main.dart';

class FirebaseClientConfig {
  const FirebaseClientConfig({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    this.authDomain,
    this.storageBucket,
  });

  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String? authDomain;
  final String? storageBucket;

  FirebaseOptions toFirebaseOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }

  Map<String, String> toJson() {
    final data = {
      'projectId': projectId,
      'apiKey': apiKey,
      'appId': appId,
      'messagingSenderId': messagingSenderId,
    };
    final authDomainValue = authDomain;
    final storageBucketValue = storageBucket;
    if (authDomainValue != null) {
      data['authDomain'] = authDomainValue;
    }
    if (storageBucketValue != null) {
      data['storageBucket'] = storageBucketValue;
    }
    return data;
  }

  static FirebaseClientConfig? fromJson(Map<String, dynamic> json) {
    final projectId = nonEmptyString(json['projectId']);
    final apiKey = nonEmptyString(json['apiKey']);
    final appId = nonEmptyString(json['appId']);
    final messagingSenderId = nonEmptyString(json['messagingSenderId']);

    if (projectId == null ||
        apiKey == null ||
        appId == null ||
        messagingSenderId == null) {
      return null;
    }

    return FirebaseClientConfig(
      projectId: projectId,
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      authDomain: nonEmptyString(json['authDomain']),
      storageBucket: nonEmptyString(json['storageBucket']),
    );
  }
}

class FirebaseClientConfigDraft {
  const FirebaseClientConfigDraft({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    this.authDomain,
    this.storageBucket,
  });

  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String? authDomain;
  final String? storageBucket;

  FirebaseClientConfig? validate() {
    final projectIdValue = projectId.trim();
    final apiKeyValue = apiKey.trim();
    final appIdValue = appId.trim();
    final messagingSenderIdValue = messagingSenderId.trim();
    final authDomainValue = authDomain?.trim();
    final storageBucketValue = storageBucket?.trim();

    if (projectIdValue.isEmpty ||
        apiKeyValue.isEmpty ||
        appIdValue.isEmpty ||
        messagingSenderIdValue.isEmpty) {
      return null;
    }

    return FirebaseClientConfig(
      projectId: projectIdValue,
      apiKey: apiKeyValue,
      appId: appIdValue,
      messagingSenderId: messagingSenderIdValue,
      authDomain: authDomainValue == null || authDomainValue.isEmpty
          ? null
          : authDomainValue,
      storageBucket: storageBucketValue == null || storageBucketValue.isEmpty
          ? null
          : storageBucketValue,
    );
  }
}
