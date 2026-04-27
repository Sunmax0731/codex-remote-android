part of '../../main.dart';

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.title,
    required this.status,
    this.favorite = false,
    this.groupName,
    this.codexOptions,
    this.lastResultPreview,
    this.lastErrorPreview,
  });

  final String id;
  final String title;
  final String status;
  final bool favorite;
  final String? groupName;
  final SessionCreateOptions? codexOptions;
  final String? lastResultPreview;
  final String? lastErrorPreview;
}

class CommandSummary {
  const CommandSummary({
    required this.id,
    required this.text,
    required this.status,
    this.attachments = const <CommandAttachment>[],
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.progressText,
    this.progressUpdatedAt,
    this.resultText,
    this.errorText,
  });

  final String id;
  final String text;
  final String status;
  final List<CommandAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? progressText;
  final DateTime? progressUpdatedAt;
  final String? resultText;
  final String? errorText;
}

class PendingCommandAttachment {
  const PendingCommandAttachment({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    required this.kind,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final String kind;

  int get sizeBytes => bytes.lengthInBytes;
}

class CommandAttachment {
  const CommandAttachment({
    required this.id,
    required this.type,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.storagePath,
    required this.sha256,
  });

  final String id;
  final String type;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String storagePath;
  final String sha256;
}

class PcBridgeStatus {
  const PcBridgeStatus({
    this.lastSeenAt,
    this.lastQueueCheckedAt,
    this.lastHealthCheckRequestedAt,
    this.lastHealthCheckRespondedAt,
    this.lastHealthCheckStatus,
    this.status,
  });

  final DateTime? lastSeenAt;
  final DateTime? lastQueueCheckedAt;
  final DateTime? lastHealthCheckRequestedAt;
  final DateTime? lastHealthCheckRespondedAt;
  final String? lastHealthCheckStatus;
  final String? status;
}

class SessionCreateOptions {
  const SessionCreateOptions({
    required this.codexModel,
    required this.codexSandbox,
    required this.codexBypassSandbox,
    this.codexProfile,
    this.codexConfigOverrides = const <String>[],
    this.codexEnableFeatures = const <String>[],
    this.codexDisableFeatures = const <String>[],
    this.codexImages = const <String>[],
    this.codexOss = false,
    this.codexLocalProvider,
    this.codexFullAuto = false,
    this.codexAddDirs = const <String>[],
    this.codexSkipGitRepoCheck = false,
    this.codexEphemeral = false,
    this.codexIgnoreUserConfig = false,
    this.codexIgnoreRules = false,
    this.codexOutputSchema,
    this.codexJson = false,
  });

  final String codexModel;
  final String codexSandbox;
  final bool codexBypassSandbox;
  final String? codexProfile;
  final List<String> codexConfigOverrides;
  final List<String> codexEnableFeatures;
  final List<String> codexDisableFeatures;
  final List<String> codexImages;
  final bool codexOss;
  final String? codexLocalProvider;
  final bool codexFullAuto;
  final List<String> codexAddDirs;
  final bool codexSkipGitRepoCheck;
  final bool codexEphemeral;
  final bool codexIgnoreUserConfig;
  final bool codexIgnoreRules;
  final String? codexOutputSchema;
  final bool codexJson;
}

const defaultSessionCreateOptions = SessionCreateOptions(
  codexModel: defaultCodexModel,
  codexSandbox: defaultCodexSandbox,
  codexBypassSandbox: false,
);
