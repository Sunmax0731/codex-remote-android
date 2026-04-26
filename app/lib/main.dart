import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const defaultPcBridgeId = 'home-main-pc';
const defaultCodexModel = 'gpt-5.4';
const defaultCodexSandbox = 'workspace-write';
const codexModelOptions = [
  'gpt-5.5',
  'gpt-5.4',
  'gpt-5.4-mini',
  'gpt-5.3-codex',
  'gpt-5.3-codex-spark',
  'gpt-5.2',
];
const codexSandboxOptions = [
  'read-only',
  'workspace-write',
  'danger-full-access',
];
const codexLocalProviderOptions = ['', 'lmstudio', 'ollama'];
const cliOptionHelpItems = [
  CliOptionHelp(
    name: 'Model',
    location: 'New Session / CLI defaults',
    description: 'Selects the Codex model used for the session.',
    example: 'gpt-5.5',
  ),
  CliOptionHelp(
    name: 'Profile',
    location: 'New Session / CLI defaults',
    description: 'Uses a named profile from the PC-side Codex config.',
    example: 'work',
  ),
  CliOptionHelp(
    name: 'Sandbox',
    location: 'CLI defaults',
    description: 'Controls how much filesystem access Codex receives.',
    example: 'workspace-write',
  ),
  CliOptionHelp(
    name: 'Bypass sandbox',
    location: 'CLI defaults',
    description: 'Runs Codex with sandbox bypass enabled on the PC bridge.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--config key=value',
    location: 'Advanced',
    description: 'Overrides a Codex config value for one run.',
    example: 'model="gpt-5.5"',
  ),
  CliOptionHelp(
    name: '--enable / --disable',
    location: 'Advanced',
    description: 'Turns a named Codex feature flag on or off.',
    example: 'feature-name',
  ),
  CliOptionHelp(
    name: '--image',
    location: 'Advanced',
    description: 'Adds one or more image files to the initial prompt.',
    example: r'C:\path\image.png',
  ),
  CliOptionHelp(
    name: '--oss',
    location: 'Advanced',
    description: 'Uses open-source provider mode when configured.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--local-provider',
    location: 'Advanced',
    description: 'Selects the local provider used with OSS mode.',
    example: 'ollama',
  ),
  CliOptionHelp(
    name: '--full-auto',
    location: 'Advanced',
    description: 'Allows automated execution with fewer confirmations.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--add-dir',
    location: 'Advanced',
    description: 'Adds another working directory to the Codex session.',
    example: r'D:\another-workspace',
  ),
  CliOptionHelp(
    name: '--skip-git-repo-check',
    location: 'Advanced',
    description: 'Allows running even when the target is not a Git repo.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--ephemeral',
    location: 'Advanced',
    description: 'Starts without saving session state for later resume.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--ignore-user-config',
    location: 'Advanced',
    description: 'Ignores the PC user-level Codex configuration.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--ignore-rules',
    location: 'Advanced',
    description: 'Ignores repository or user instruction files.',
    example: 'on',
  ),
  CliOptionHelp(
    name: '--output-schema',
    location: 'Advanced',
    description: 'Requests output matching a JSON schema file.',
    example: r'C:\path\schema.json',
  ),
  CliOptionHelp(
    name: '--json',
    location: 'PC bridge internal',
    description: 'Streams machine-readable CLI events for the bridge.',
    example: 'on',
  ),
];
const cliOptionHelpDescriptions = {
  'ja': {
    'Model': 'セッションで使用するCodexモデルを選択します。',
    'Profile': 'PC側のCodex設定にある名前付きプロファイルを使用します。',
    'Sandbox': 'Codexがアクセスできるファイル範囲を制御します。',
    'Bypass sandbox': 'PCブリッジ上でサンドボックスの制限を回避して実行します。',
    '--config key=value': '1回の実行だけCodex設定値を上書きします。',
    '--enable / --disable': '指定したCodex機能フラグを有効または無効にします。',
    '--image': '初回プロンプトに画像ファイルを添付します。',
    '--oss': '設定済みの場合にOSSプロバイダーモードを使用します。',
    '--local-provider': 'OSSモードで使用するローカルプロバイダーを選択します。',
    '--full-auto': '確認を減らして自動実行を許可します。',
    '--add-dir': 'Codexセッションに追加の作業ディレクトリを渡します。',
    '--skip-git-repo-check': '対象がGitリポジトリでなくても実行を許可します。',
    '--ephemeral': '後で再開するためのセッション状態を保存せずに開始します。',
    '--ignore-user-config': 'PCユーザー単位のCodex設定を無視します。',
    '--ignore-rules': 'リポジトリまたはユーザーの指示ファイルを無視します。',
    '--output-schema': 'JSON schemaファイルに合う形式での出力を要求します。',
    '--json': 'PCブリッジが読み取る機械可読CLIイベントを出力します。',
  },
  'zh': {
    'Model': '选择此会话使用的Codex模型。',
    'Profile': '使用PC端Codex配置中的命名配置文件。',
    'Sandbox': '控制Codex可访问的文件范围。',
    'Bypass sandbox': '在PC桥接端绕过沙箱限制运行。',
    '--config key=value': '仅为本次运行覆盖Codex配置值。',
    '--enable / --disable': '启用或禁用指定的Codex功能标志。',
    '--image': '向初始提示附加一个或多个图片文件。',
    '--oss': '在已配置时使用开源提供方模式。',
    '--local-provider': '选择OSS模式使用的本地提供方。',
    '--full-auto': '减少确认并允许自动执行。',
    '--add-dir': '向Codex会话添加另一个工作目录。',
    '--skip-git-repo-check': '即使目标不是Git仓库也允许运行。',
    '--ephemeral': '启动时不保存用于以后恢复的会话状态。',
    '--ignore-user-config': '忽略PC用户级Codex配置。',
    '--ignore-rules': '忽略仓库或用户指令文件。',
    '--output-schema': '请求输出符合JSON schema文件。',
    '--json': '输出供PC桥接读取的机器可读CLI事件。',
  },
  'ko': {
    'Model': '세션에서 사용할 Codex 모델을 선택합니다.',
    'Profile': 'PC 쪽 Codex 설정의 이름 있는 프로필을 사용합니다.',
    'Sandbox': 'Codex가 접근할 수 있는 파일 범위를 제어합니다.',
    'Bypass sandbox': 'PC 브리지에서 샌드박스 제한을 우회해 실행합니다.',
    '--config key=value': '이번 실행에만 Codex 설정 값을 덮어씁니다.',
    '--enable / --disable': '지정한 Codex 기능 플래그를 켜거나 끕니다.',
    '--image': '초기 프롬프트에 이미지 파일을 첨부합니다.',
    '--oss': '설정된 경우 오픈소스 제공자 모드를 사용합니다.',
    '--local-provider': 'OSS 모드에서 사용할 로컬 제공자를 선택합니다.',
    '--full-auto': '확인을 줄이고 자동 실행을 허용합니다.',
    '--add-dir': 'Codex 세션에 추가 작업 디렉터리를 전달합니다.',
    '--skip-git-repo-check': '대상이 Git 저장소가 아니어도 실행을 허용합니다.',
    '--ephemeral': '나중에 재개할 세션 상태를 저장하지 않고 시작합니다.',
    '--ignore-user-config': 'PC 사용자 단위 Codex 설정을 무시합니다.',
    '--ignore-rules': '저장소 또는 사용자 지시 파일을 무시합니다.',
    '--output-schema': 'JSON schema 파일에 맞는 출력을 요청합니다.',
    '--json': 'PC 브리지가 읽을 수 있는 기계 판독 CLI 이벤트를 출력합니다.',
  },
};
const cliOptionHelpLocations = {
  'ja': {
    'New Session / CLI defaults': '新規セッション / CLI既定値',
    'CLI defaults': 'CLI既定値',
    'Advanced': '詳細',
    'PC bridge internal': 'PCブリッジ内部',
  },
  'zh': {
    'New Session / CLI defaults': '新会话 / CLI默认值',
    'CLI defaults': 'CLI默认值',
    'Advanced': '高级',
    'PC bridge internal': 'PC桥接内部',
  },
  'ko': {
    'New Session / CLI defaults': '새 세션 / CLI 기본값',
    'CLI defaults': 'CLI 기본값',
    'Advanced': '고급',
    'PC bridge internal': 'PC 브리지 내부',
  },
};
const androidDeviceId = 'android-app';
const notificationChannelId = 'remote_codex_completion';
const notificationChannelName = 'RemoteCodex completion';
final appNavigatorKey = GlobalKey<NavigatorState>();

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
  ];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  String get code {
    final languageCode = locale.languageCode.toLowerCase();
    if (_messages.containsKey(languageCode)) {
      return languageCode;
    }
    return 'en';
  }

  String t(String key) => _messages[code]?[key] ?? _messages['en']![key] ?? key;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

extension AppStringsContext on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}

const _messages = <String, Map<String, String>>{
  'en': {
    'signingIn': 'Signing in',
    'preparingRelay': 'Preparing secure relay access.',
    'startupFailed': 'Startup failed',
    'sessionLoadFailed': 'Session load failed',
    'commandLoadFailed': 'Command load failed',
    'newSession': 'New session',
    'create': 'Create',
    'creating': 'Creating',
    'connectedAnonymous': 'Connected as anonymous user',
    'pcBridge': 'PC bridge',
    'lastHeartbeat': 'Last heartbeat',
    'lastQueueCheck': 'Last queue check',
    'lastManualCheck': 'Last manual check',
    'lastResponse': 'Last response',
    'checkPcNow': 'Check PC now',
    'checking': 'Checking',
    'cliDefaults': 'CLI defaults',
    'loading': 'Loading',
    'notifications': 'Notifications',
    'settings': 'Settings',
    'connectionSettings': 'Connection settings',
    'notSeenYet': 'Not seen yet',
    'sessions': 'Sessions',
    'sessionCount': 'session(s)',
    'loadingSessions': 'Loading sessions...',
    'noSessionsYet': 'No sessions yet',
    'noMatchingSessions': 'No matching sessions',
    'noCommandsYet': 'No commands yet',
    'searchSessions': 'Search sessions',
    'allGroups': 'All groups',
    'ungrouped': 'Ungrouped',
    'favorites': 'Favorites',
    'favorite': 'Favorite',
    'removeFavorite': 'Remove favorite',
    'renameSession': 'Rename session',
    'sessionName': 'Session name',
    'group': 'Group',
    'groupName': 'Group name',
    'changeGroup': 'Change group',
    'deleteSession': 'Delete session',
    'deleteSessionQuestion': 'Delete this session from the app history?',
    'delete': 'Delete',
    'more': 'More',
    'waitingFinalResult': 'Waiting for final result.',
    'elapsed': 'Elapsed',
    'lastProgress': 'Last progress',
    'instruction': 'Instruction',
    'send': 'Send',
    'model': 'Model',
    'profile': 'Profile',
    'sandbox': 'Sandbox',
    'bypassSandbox': 'Bypass sandbox',
    'bypassSandboxSubtitle': 'Overrides the sandbox selection',
    'sandboxUsesDefaults': 'Sandbox and bypass use CLI defaults.',
    'advancedCliOptions': 'Advanced CLI options',
    'optionalConfigProfile': 'Optional config profile',
    'defaultOption': 'Default',
    'bridgeReadsFinalOutput': 'Bridge still reads final output from file',
    'help': 'Help',
    'cancel': 'Cancel',
    'save': 'Save',
    'close': 'Close',
    'selectImageFile': 'Select image file',
    'showHelpFor': 'Show help for',
    'cliOptionHelp': 'CLI option help',
    'noHelpAvailable': 'No help is available for this option.',
    'where': 'Where',
    'example': 'Example',
    'none': 'None',
    'on': 'on',
    'off': 'off',
    'config': 'Config',
    'enable': 'Enable',
    'disable': 'Disable',
    'images': 'Images',
    'oss': 'OSS',
    'localProvider': 'Local provider',
    'fullAuto': 'Full auto',
    'addDirs': 'Add dirs',
    'skipGitRepoCheck': 'Skip git repo check',
    'ephemeral': 'Ephemeral',
    'ignoreUserConfig': 'Ignore user config',
    'ignoreRules': 'Ignore rules',
    'outputSchema': 'Output schema',
    'jsonEvents': 'JSON events',
  },
  'ja': {
    'signingIn': 'サインイン中',
    'preparingRelay': '安全なリレー接続を準備しています。',
    'startupFailed': '起動に失敗しました',
    'sessionLoadFailed': 'セッションの読み込みに失敗しました',
    'commandLoadFailed': 'コマンドの読み込みに失敗しました',
    'newSession': '新規セッション',
    'create': '作成',
    'creating': '作成中',
    'connectedAnonymous': '匿名ユーザーで接続中',
    'pcBridge': 'PCブリッジ',
    'lastHeartbeat': '最終heartbeat',
    'lastQueueCheck': '最終queue確認',
    'lastManualCheck': '最終手動確認',
    'lastResponse': '最終応答',
    'checkPcNow': 'PCを確認',
    'checking': '確認中',
    'cliDefaults': 'CLI既定値',
    'loading': '読込中',
    'notifications': '通知',
    'settings': '設定',
    'connectionSettings': '接続設定',
    'notSeenYet': '未確認',
    'sessions': 'セッション',
    'sessionCount': '件',
    'loadingSessions': 'セッションを読み込み中...',
    'noSessionsYet': 'セッションはまだありません',
    'noMatchingSessions': '一致するセッションはありません',
    'noCommandsYet': 'コマンドはまだありません',
    'searchSessions': 'セッションを検索',
    'allGroups': 'すべてのグループ',
    'ungrouped': '未分類',
    'favorites': 'お気に入り',
    'favorite': 'お気に入り',
    'removeFavorite': 'お気に入りを解除',
    'renameSession': 'セッション名を変更',
    'sessionName': 'セッション名',
    'group': 'グループ',
    'groupName': 'グループ名',
    'changeGroup': 'グループを変更',
    'deleteSession': 'セッションを削除',
    'deleteSessionQuestion': 'このセッションをアプリの履歴から削除しますか？',
    'delete': '削除',
    'more': 'その他',
    'waitingFinalResult': '最終結果を待っています。',
    'elapsed': '経過時間',
    'lastProgress': '最終進捗',
    'instruction': '指示',
    'send': '送信',
    'model': 'モデル',
    'profile': 'プロファイル',
    'sandbox': 'サンドボックス',
    'bypassSandbox': 'サンドボックス迂回',
    'bypassSandboxSubtitle': 'サンドボックス選択より優先します',
    'sandboxUsesDefaults': 'サンドボックスと迂回設定はCLI既定値を使用します。',
    'advancedCliOptions': '詳細CLIオプション',
    'optionalConfigProfile': '任意のconfig profile',
    'defaultOption': '既定',
    'bridgeReadsFinalOutput': '最終出力は引き続きファイルから読み取ります',
    'help': 'ヘルプ',
    'cancel': 'キャンセル',
    'save': '保存',
    'close': '閉じる',
    'selectImageFile': '画像ファイルを選択',
    'showHelpFor': 'ヘルプを表示',
    'cliOptionHelp': 'CLIオプションヘルプ',
    'noHelpAvailable': 'この項目のヘルプはありません。',
    'where': '表示場所',
    'example': '入力例',
    'none': 'なし',
    'on': 'オン',
    'off': 'オフ',
    'config': 'Config',
    'enable': 'Enable',
    'disable': 'Disable',
    'images': '画像',
    'oss': 'OSS',
    'localProvider': 'ローカルprovider',
    'fullAuto': 'Full auto',
    'addDirs': '追加ディレクトリ',
    'skipGitRepoCheck': 'Git repo確認スキップ',
    'ephemeral': 'Ephemeral',
    'ignoreUserConfig': 'ユーザー設定を無視',
    'ignoreRules': 'ルールを無視',
    'outputSchema': '出力schema',
    'jsonEvents': 'JSONイベント',
  },
  'zh': {
    'signingIn': '正在登录',
    'preparingRelay': '正在准备安全中继访问。',
    'startupFailed': '启动失败',
    'sessionLoadFailed': '会话加载失败',
    'commandLoadFailed': '命令加载失败',
    'newSession': '新建会话',
    'create': '创建',
    'creating': '创建中',
    'connectedAnonymous': '已作为匿名用户连接',
    'pcBridge': 'PC 桥接',
    'lastHeartbeat': '上次心跳',
    'lastQueueCheck': '上次队列检查',
    'lastManualCheck': '上次手动检查',
    'lastResponse': '上次响应',
    'checkPcNow': '立即检查PC',
    'checking': '检查中',
    'cliDefaults': 'CLI 默认值',
    'loading': '加载中',
    'notifications': '通知',
    'settings': '设置',
    'connectionSettings': '连接设置',
    'notSeenYet': '尚未看到',
    'sessions': '会话',
    'sessionCount': '个会话',
    'loadingSessions': '正在加载会话...',
    'noSessionsYet': '还没有会话',
    'noMatchingSessions': '没有匹配的会话',
    'noCommandsYet': '还没有命令',
    'searchSessions': '搜索会话',
    'allGroups': '所有分组',
    'ungrouped': '未分组',
    'favorites': '收藏',
    'favorite': '收藏',
    'removeFavorite': '取消收藏',
    'renameSession': '重命名会话',
    'sessionName': '会话名称',
    'group': '分组',
    'groupName': '分组名称',
    'changeGroup': '更改分组',
    'deleteSession': '删除会话',
    'deleteSessionQuestion': '要从应用历史记录中删除此会话吗？',
    'delete': '删除',
    'more': '更多',
    'waitingFinalResult': '正在等待最终结果。',
    'elapsed': '已用时间',
    'lastProgress': '上次进度',
    'instruction': '指令',
    'send': '发送',
    'model': '模型',
    'profile': '配置文件',
    'sandbox': '沙盒',
    'bypassSandbox': '绕过沙盒',
    'bypassSandboxSubtitle': '覆盖沙盒选择',
    'sandboxUsesDefaults': '沙盒和绕过设置使用CLI默认值。',
    'advancedCliOptions': '高级CLI选项',
    'optionalConfigProfile': '可选配置profile',
    'defaultOption': '默认',
    'bridgeReadsFinalOutput': '桥接仍从文件读取最终输出',
    'help': '帮助',
    'cancel': '取消',
    'save': '保存',
    'close': '关闭',
    'selectImageFile': '选择图片文件',
    'showHelpFor': '显示帮助',
    'cliOptionHelp': 'CLI选项帮助',
    'noHelpAvailable': '此选项没有帮助。',
    'where': '位置',
    'example': '示例',
    'none': '无',
    'on': '开',
    'off': '关',
    'config': '配置',
    'enable': '启用',
    'disable': '禁用',
    'images': '图片',
    'oss': 'OSS',
    'localProvider': '本地provider',
    'fullAuto': '全自动',
    'addDirs': '追加目录',
    'skipGitRepoCheck': '跳过Git repo检查',
    'ephemeral': '临时会话',
    'ignoreUserConfig': '忽略用户配置',
    'ignoreRules': '忽略规则',
    'outputSchema': '输出schema',
    'jsonEvents': 'JSON事件',
  },
  'ko': {
    'signingIn': '로그인 중',
    'preparingRelay': '보안 릴레이 접속을 준비 중입니다.',
    'startupFailed': '시작 실패',
    'sessionLoadFailed': '세션 로드 실패',
    'commandLoadFailed': '명령 로드 실패',
    'newSession': '새 세션',
    'create': '생성',
    'creating': '생성 중',
    'connectedAnonymous': '익명 사용자로 연결됨',
    'pcBridge': 'PC 브리지',
    'lastHeartbeat': '마지막 heartbeat',
    'lastQueueCheck': '마지막 queue 확인',
    'lastManualCheck': '마지막 수동 확인',
    'lastResponse': '마지막 응답',
    'checkPcNow': 'PC 확인',
    'checking': '확인 중',
    'cliDefaults': 'CLI 기본값',
    'loading': '로딩 중',
    'notifications': '알림',
    'settings': '설정',
    'connectionSettings': '연결 설정',
    'notSeenYet': '아직 확인 안 됨',
    'sessions': '세션',
    'sessionCount': '개 세션',
    'loadingSessions': '세션 로딩 중...',
    'noSessionsYet': '아직 세션이 없습니다',
    'noMatchingSessions': '일치하는 세션이 없습니다',
    'noCommandsYet': '아직 명령이 없습니다',
    'searchSessions': '세션 검색',
    'allGroups': '모든 그룹',
    'ungrouped': '미분류',
    'favorites': '즐겨찾기',
    'favorite': '즐겨찾기',
    'removeFavorite': '즐겨찾기 해제',
    'renameSession': '세션 이름 변경',
    'sessionName': '세션 이름',
    'group': '그룹',
    'groupName': '그룹 이름',
    'changeGroup': '그룹 변경',
    'deleteSession': '세션 삭제',
    'deleteSessionQuestion': '앱 기록에서 이 세션을 삭제할까요?',
    'delete': '삭제',
    'more': '더보기',
    'waitingFinalResult': '최종 결과를 기다리는 중입니다.',
    'elapsed': '경과 시간',
    'lastProgress': '마지막 진행',
    'instruction': '지시',
    'send': '전송',
    'model': '모델',
    'profile': '프로필',
    'sandbox': '샌드박스',
    'bypassSandbox': '샌드박스 우회',
    'bypassSandboxSubtitle': '샌드박스 선택보다 우선합니다',
    'sandboxUsesDefaults': '샌드박스와 우회 설정은 CLI 기본값을 사용합니다.',
    'advancedCliOptions': '고급 CLI 옵션',
    'optionalConfigProfile': '선택적 config profile',
    'defaultOption': '기본값',
    'bridgeReadsFinalOutput': '최종 출력은 계속 파일에서 읽습니다',
    'help': '도움말',
    'cancel': '취소',
    'save': '저장',
    'close': '닫기',
    'selectImageFile': '이미지 파일 선택',
    'showHelpFor': '도움말 표시',
    'cliOptionHelp': 'CLI 옵션 도움말',
    'noHelpAvailable': '이 옵션에 대한 도움말이 없습니다.',
    'where': '위치',
    'example': '예시',
    'none': '없음',
    'on': '켜짐',
    'off': '꺼짐',
    'config': '설정',
    'enable': '활성화',
    'disable': '비활성화',
    'images': '이미지',
    'oss': 'OSS',
    'localProvider': '로컬 provider',
    'fullAuto': 'Full auto',
    'addDirs': '추가 디렉터리',
    'skipGitRepoCheck': 'Git repo 확인 건너뛰기',
    'ephemeral': '임시 세션',
    'ignoreUserConfig': '사용자 설정 무시',
    'ignoreRules': '규칙 무시',
    'outputSchema': '출력 schema',
    'jsonEvents': 'JSON 이벤트',
  },
};

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(
    RemoteCodexApp(
      bootstrap: bootstrapRemoteCodex(),
      sessionRepository: FirestoreSessionRepository(),
    ),
  );
}

Future<AppBootstrap> bootstrapRemoteCodex() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  final credential = await FirebaseAuth.instance.signInAnonymously();
  final uid = credential.user?.uid;

  if (uid == null || uid.isEmpty) {
    throw StateError('Anonymous sign-in did not return a user uid.');
  }

  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'defaultPcBridgeId': defaultPcBridgeId,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastSignedInAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final notificationState = await NotificationService().registerDevice(
    uid: uid,
    firestore: firestore,
  );

  return AppBootstrap(
    uid: uid,
    pcBridgeId: defaultPcBridgeId,
    notificationState: notificationState,
  );
}

class AppBootstrap {
  const AppBootstrap({
    required this.uid,
    required this.pcBridgeId,
    required this.notificationState,
  });

  final String uid;
  final String pcBridgeId;
  final NotificationState notificationState;
}

class NotificationState {
  const NotificationState({
    required this.permissionStatus,
    required this.hasToken,
  });

  final String permissionStatus;
  final bool hasToken;
}

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _messageHandlersRegistered = false;
  AppBootstrap? _bootstrap;
  SessionRepository? _sessionRepository;
  String? _pendingSessionId;

  Future<NotificationState> registerDevice({
    required String uid,
    required FirebaseFirestore firestore,
  }) async {
    await _initializeLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    final token = await messaging.getToken();

    await _storeToken(
      firestore: firestore,
      uid: uid,
      token: token,
      permissionStatus: settings.authorizationStatus.name,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _storeToken(
        firestore: firestore,
        uid: uid,
        token: newToken,
        permissionStatus: settings.authorizationStatus.name,
      );
    });

    _registerMessageHandlers();

    return NotificationState(
      permissionStatus: settings.authorizationStatus.name,
      hasToken: token != null && token.isNotEmpty,
    );
  }

  void attachNavigation({
    required AppBootstrap bootstrap,
    required SessionRepository sessionRepository,
  }) {
    _bootstrap = bootstrap;
    _sessionRepository = sessionRepository;

    final pendingSessionId = _pendingSessionId;
    if (pendingSessionId != null) {
      _pendingSessionId = null;
      scheduleMicrotask(() => _openSession(pendingSessionId));
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_initialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final sessionId = sessionIdFromPayload(response.payload);
        if (sessionId != null) {
          _openSession(sessionId);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description:
          'Notifications for completed or failed remote Codex commands.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _registerMessageHandlers() {
    if (_messageHandlersRegistered) {
      return;
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final sessionId = sessionIdFromMessageData(message.data);
      if (sessionId != null) {
        _openSession(sessionId);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      final sessionId = message == null
          ? null
          : sessionIdFromMessageData(message.data);
      if (sessionId != null) {
        _openSession(sessionId);
      }
    });

    _messageHandlersRegistered = true;
  }

  Future<void> _storeToken({
    required FirebaseFirestore firestore,
    required String uid,
    required String? token,
    required String permissionStatus,
  }) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(androidDeviceId)
        .set({
          'deviceId': androidDeviceId,
          'platform': 'android',
          'fcmToken': token,
          'notificationPermission': permissionStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'RemoteCodex';
    final body = notification?.body ?? 'Remote processing finished.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription:
            'Notifications for completed or failed remote Codex commands.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: notificationPayloadFromMessageData(message.data),
    );
  }

  void _openSession(String sessionId) {
    final navigator = appNavigatorKey.currentState;
    final bootstrap = _bootstrap;
    final sessionRepository = _sessionRepository;

    if (navigator == null || bootstrap == null || sessionRepository == null) {
      _pendingSessionId = sessionId;
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailPage(
          bootstrap: bootstrap,
          session: SessionSummary(
            id: sessionId,
            title: 'Session $sessionId',
            status: 'unknown',
          ),
          sessionRepository: sessionRepository,
        ),
      ),
    );
  }
}

String notificationPayloadFromMessageData(Map<String, dynamic> data) {
  return jsonEncode({
    'sessionId': data['sessionId'],
    'commandId': data['commandId'],
    'status': data['status'],
  });
}

String? sessionIdFromPayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return nonEmptyString(decoded['sessionId']);
    }
  } on FormatException {
    return payload.trim();
  }

  return null;
}

String? sessionIdFromMessageData(Map<String, dynamic> data) {
  return nonEmptyString(data['sessionId']);
}

String? nonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

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
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? progressText;
  final DateTime? progressUpdatedAt;
  final String? resultText;
  final String? errorText;
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

abstract class SessionRepository {
  Stream<List<SessionSummary>> watchSessions(String uid);
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId);
  Stream<PcBridgeStatus> watchPcBridgeStatus(String uid, String pcBridgeId);
  Future<SessionCreateOptions> loadCliDefaults(String uid);
  Future<void> saveCliDefaults(String uid, SessionCreateOptions options);
  Future<void> requestPcBridgeHealthCheck({
    required String uid,
    required String pcBridgeId,
  });
  Future<SessionSummary> createSession({
    required String uid,
    required String pcBridgeId,
    required SessionCreateOptions options,
  });
  Future<void> renameSession({
    required String uid,
    required String sessionId,
    required String title,
  });
  Future<void> updateSessionFavorite({
    required String uid,
    required String sessionId,
    required bool favorite,
  });
  Future<void> updateSessionGroup({
    required String uid,
    required String sessionId,
    required String? groupName,
  });
  Future<void> deleteSession({required String uid, required String sessionId});
  Future<void> createCommand({
    required String uid,
    required String sessionId,
    required String pcBridgeId,
    required String text,
  });
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository([FirebaseFirestore? firestore])
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<SessionSummary>> watchSessions(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .where((doc) {
                return doc.data()['deletedAt'] == null;
              })
              .map((doc) {
                final data = doc.data();
                return SessionSummary(
                  id: doc.id,
                  title: (data['title'] as String?)?.trim().isNotEmpty == true
                      ? data['title'] as String
                      : 'Untitled session',
                  status: data['status'] as String? ?? 'idle',
                  favorite: data['favorite'] as bool? ?? false,
                  groupName: optionString(data['groupName']),
                  codexOptions: sessionOptionsFromData(data),
                  lastResultPreview: data['lastResultPreview'] as String?,
                  lastErrorPreview: data['lastErrorPreview'] as String?,
                );
              })
              .toList();
          sessions.sort((a, b) {
            if (a.favorite != b.favorite) {
              return a.favorite ? -1 : 1;
            }
            return 0;
          });
          return sessions;
        });
  }

  @override
  Stream<List<CommandSummary>> watchCommands(String uid, String sessionId) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .collection('commands')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return CommandSummary(
              id: doc.id,
              text: data['text'] as String? ?? '',
              status: data['status'] as String? ?? 'queued',
              createdAt: timestampToDateTime(data['createdAt']),
              startedAt: timestampToDateTime(data['startedAt']),
              completedAt: timestampToDateTime(data['completedAt']),
              progressText: data['progressText'] as String?,
              progressUpdatedAt: timestampToDateTime(data['progressUpdatedAt']),
              resultText: data['resultText'] as String?,
              errorText: data['errorText'] as String?,
            );
          }).toList(),
        );
  }

  @override
  Stream<PcBridgeStatus> watchPcBridgeStatus(String uid, String pcBridgeId) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('pcBridges')
        .doc(pcBridgeId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return PcBridgeStatus(
            lastSeenAt: timestampToDateTime(data?['lastSeenAt']),
            lastQueueCheckedAt: timestampToDateTime(
              data?['lastQueueCheckedAt'],
            ),
            lastHealthCheckRequestedAt: timestampToDateTime(
              data?['lastHealthCheckRequestedAt'],
            ),
            lastHealthCheckRespondedAt: timestampToDateTime(
              data?['lastHealthCheckRespondedAt'],
            ),
            lastHealthCheckStatus: data?['lastHealthCheckStatus'] as String?,
            status: data?['status'] as String?,
          );
        });
  }

  @override
  Future<SessionCreateOptions> loadCliDefaults(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('cliDefaults')
        .get();

    return sessionOptionsFromData(snapshot.data()) ??
        defaultSessionCreateOptions;
  }

  @override
  Future<void> saveCliDefaults(String uid, SessionCreateOptions options) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('cliDefaults')
        .set(sessionOptionsToData(options));
  }

  @override
  Future<void> requestPcBridgeHealthCheck({
    required String uid,
    required String pcBridgeId,
  }) async {
    final bridgeRef = firestore
        .collection('users')
        .doc(uid)
        .collection('pcBridges')
        .doc(pcBridgeId);
    final healthCheckRef = bridgeRef.collection('healthChecks').doc();
    final batch = firestore.batch();

    batch.set(healthCheckRef, {
      'status': 'requested',
      'targetPcBridgeId': pcBridgeId,
      'createdByDeviceId': androidDeviceId,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    batch.set(bridgeRef, {
      'pcBridgeId': pcBridgeId,
      'lastHealthCheckRequestedAt': FieldValue.serverTimestamp(),
      'lastHealthCheckStatus': 'requested',
    }, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<SessionSummary> createSession({
    required String uid,
    required String pcBridgeId,
    required SessionCreateOptions options,
  }) async {
    final now = DateTime.now();
    final title =
        'Session ${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';

    final ref = await firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .add({
          'title': title,
          'status': 'idle',
          'targetPcBridgeId': pcBridgeId,
          ...sessionOptionsToData(options),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    return SessionSummary(
      id: ref.id,
      title: title,
      status: 'idle',
      codexOptions: options,
    );
  }

  @override
  Future<void> renameSession({
    required String uid,
    required String sessionId,
    required String title,
  }) async {
    await sessionDocument(uid, sessionId).update({
      'title': title.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSessionFavorite({
    required String uid,
    required String sessionId,
    required bool favorite,
  }) async {
    await sessionDocument(
      uid,
      sessionId,
    ).update({'favorite': favorite, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updateSessionGroup({
    required String uid,
    required String sessionId,
    required String? groupName,
  }) async {
    final trimmed = groupName?.trim();
    await sessionDocument(uid, sessionId).update({
      if (trimmed == null || trimmed.isEmpty)
        'groupName': FieldValue.delete()
      else
        'groupName': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    await sessionDocument(uid, sessionId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createCommand({
    required String uid,
    required String sessionId,
    required String pcBridgeId,
    required String text,
  }) async {
    final sessionRef = firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
    final commandRef = sessionRef.collection('commands').doc();
    final batch = firestore.batch();

    batch.set(commandRef, {
      'text': text,
      'status': 'queued',
      'targetPcBridgeId': pcBridgeId,
      'createdByDeviceId': 'android-app',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(sessionRef, {
      'status': 'queued',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastCommandId': commandRef.id,
      'lastCommandPreview': preview(text),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> sessionDocument(
    String uid,
    String sessionId,
  ) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);
  }
}

SessionCreateOptions? sessionOptionsFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }

  return SessionCreateOptions(
    codexModel: optionString(data['codexModel']) ?? defaultCodexModel,
    codexSandbox: normalizedSandbox(data['codexSandbox']),
    codexBypassSandbox: data['codexBypassSandbox'] as bool? ?? false,
    codexProfile: optionString(data['codexProfile']),
    codexConfigOverrides: stringList(data['codexConfigOverrides']),
    codexEnableFeatures: stringList(data['codexEnableFeatures']),
    codexDisableFeatures: stringList(data['codexDisableFeatures']),
    codexImages: stringList(data['codexImages']),
    codexOss: data['codexOss'] as bool? ?? false,
    codexLocalProvider: normalizedLocalProvider(data['codexLocalProvider']),
    codexFullAuto: data['codexFullAuto'] as bool? ?? false,
    codexAddDirs: stringList(data['codexAddDirs']),
    codexSkipGitRepoCheck: data['codexSkipGitRepoCheck'] as bool? ?? false,
    codexEphemeral: data['codexEphemeral'] as bool? ?? false,
    codexIgnoreUserConfig: data['codexIgnoreUserConfig'] as bool? ?? false,
    codexIgnoreRules: data['codexIgnoreRules'] as bool? ?? false,
    codexOutputSchema: optionString(data['codexOutputSchema']),
    codexJson: data['codexJson'] as bool? ?? false,
  );
}

Map<String, Object> sessionOptionsToData(SessionCreateOptions options) {
  return {
    'codexModel': options.codexModel,
    'codexSandbox': options.codexSandbox,
    'codexBypassSandbox': options.codexBypassSandbox,
    if (options.codexProfile != null) 'codexProfile': options.codexProfile!,
    if (options.codexConfigOverrides.isNotEmpty)
      'codexConfigOverrides': options.codexConfigOverrides,
    if (options.codexEnableFeatures.isNotEmpty)
      'codexEnableFeatures': options.codexEnableFeatures,
    if (options.codexDisableFeatures.isNotEmpty)
      'codexDisableFeatures': options.codexDisableFeatures,
    if (options.codexImages.isNotEmpty) 'codexImages': options.codexImages,
    'codexOss': options.codexOss,
    if (options.codexLocalProvider != null)
      'codexLocalProvider': options.codexLocalProvider!,
    'codexFullAuto': options.codexFullAuto,
    if (options.codexAddDirs.isNotEmpty) 'codexAddDirs': options.codexAddDirs,
    'codexSkipGitRepoCheck': options.codexSkipGitRepoCheck,
    'codexEphemeral': options.codexEphemeral,
    'codexIgnoreUserConfig': options.codexIgnoreUserConfig,
    'codexIgnoreRules': options.codexIgnoreRules,
    if (options.codexOutputSchema != null)
      'codexOutputSchema': options.codexOutputSchema!,
    'codexJson': options.codexJson,
  };
}

List<String> stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }

  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String? optionString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String normalizedSandbox(Object? value) {
  if (value is String && codexSandboxOptions.contains(value)) {
    return value;
  }

  return defaultCodexSandbox;
}

String? normalizedLocalProvider(Object? value) {
  final provider = optionString(value);
  if (provider == null || !codexLocalProviderOptions.contains(provider)) {
    return null;
  }

  return provider;
}

String two(int value) => value.toString().padLeft(2, '0');

DateTime? timestampToDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }

  return null;
}

String preview(String value) {
  final trimmed = value.trim();
  return trimmed.length <= 120 ? trimmed : '${trimmed.substring(0, 117)}...';
}

class RemoteCodexApp extends StatelessWidget {
  const RemoteCodexApp({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final Future<AppBootstrap> bootstrap;
  final SessionRepository sessionRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'RemoteCodex',
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: StartupView(
        bootstrap: bootstrap,
        sessionRepository: sessionRepository,
      ),
    );
  }
}

class StartupView extends StatelessWidget {
  const StartupView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final Future<AppBootstrap> bootstrap;
  final SessionRepository sessionRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBootstrap>(
      future: bootstrap,
      builder: (context, snapshot) {
        final Widget body;
        final l10n = context.l10n;

        if (snapshot.connectionState != ConnectionState.done) {
          body = _StartupMessage(
            title: l10n.t('signingIn'),
            message: l10n.t('preparingRelay'),
            child: const CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          body = _StartupMessage(
            title: l10n.t('startupFailed'),
            message: snapshot.error.toString(),
            child: const Icon(Icons.error_outline, size: 36),
          );
        } else {
          body = SessionListView(
            bootstrap: snapshot.requireData,
            sessionRepository: sessionRepository,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('RemoteCodex')),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

class SessionListView extends StatefulWidget {
  const SessionListView({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;

  @override
  State<SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends State<SessionListView> {
  final TextEditingController searchController = TextEditingController();
  bool isCreating = false;
  String? selectedGroup;

  @override
  void initState() {
    super.initState();
    NotificationService().attachNavigation(
      bootstrap: widget.bootstrap,
      sessionRepository: widget.sessionRepository,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<SessionSummary> filteredSessions(List<SessionSummary> sessions) {
    final query = searchController.text.trim().toLowerCase();
    return sessions
        .where((session) {
          final matchesSearch =
              query.isEmpty || session.title.toLowerCase().contains(query);
          final matchesGroup =
              selectedGroup == null ||
              sessionGroupKey(session) == selectedGroup;
          return matchesSearch && matchesGroup;
        })
        .toList(growable: false);
  }

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

  Future<void> openSessionActions(SessionSummary session) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(context.l10n.t('renameSession')),
              onTap: () async {
                Navigator.of(context).pop();
                await renameSession(session);
              },
            ),
            ListTile(
              leading: Icon(session.favorite ? Icons.star : Icons.star_border),
              title: Text(
                context.l10n.t(
                  session.favorite ? 'removeFavorite' : 'favorite',
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.sessionRepository.updateSessionFavorite(
                  uid: widget.bootstrap.uid,
                  sessionId: session.id,
                  favorite: !session.favorite,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(context.l10n.t('changeGroup')),
              onTap: () async {
                Navigator.of(context).pop();
                await changeSessionGroup(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.t('cliOptionHelp')),
              onTap: () {
                Navigator.of(context).pop();
                showSessionOptionsSummaryDialog(context, session);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.l10n.t('deleteSession'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await confirmDeleteSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> renameSession(SessionSummary session) async {
    final title = await showTextValueDialog(
      context,
      title: context.l10n.t('renameSession'),
      label: context.l10n.t('sessionName'),
      initialValue: session.title,
    );
    if (title == null) {
      return;
    }

    await widget.sessionRepository.renameSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      title: title,
    );
  }

  Future<void> changeSessionGroup(SessionSummary session) async {
    final groupName = await showTextValueDialog(
      context,
      title: context.l10n.t('changeGroup'),
      label: context.l10n.t('groupName'),
      initialValue: session.groupName ?? '',
    );
    if (groupName == null) {
      return;
    }

    await widget.sessionRepository.updateSessionGroup(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      groupName: groupName,
    );
  }

  Future<void> confirmDeleteSession(SessionSummary session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteSession')),
        content: Text(context.l10n.t('deleteSessionQuestion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.sessionRepository.deleteSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
    );
  }

  Future<void> createSession() async {
    if (isCreating) {
      return;
    }

    setState(() => isCreating = true);
    SessionCreateOptions defaults;
    try {
      defaults = await widget.sessionRepository.loadCliDefaults(
        widget.bootstrap.uid,
      );
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }

    if (!mounted) {
      return;
    }

    final options = await showSessionOptionsDialog(
      context,
      title: context.l10n.t('newSession'),
      initialOptions: defaults,
      primaryLabel: context.l10n.t('create'),
      showExecutionDefaults: false,
    );
    if (options == null) {
      return;
    }

    setState(() => isCreating = true);
    try {
      final session = await widget.sessionRepository.createSession(
        uid: widget.bootstrap.uid,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        options: options,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailPage(
            bootstrap: widget.bootstrap,
            session: session,
            sessionRepository: widget.sessionRepository,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionSummary>>(
      stream: widget.sessionRepository.watchSessions(widget.bootstrap.uid),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <SessionSummary>[];
        final visibleSessions = filteredSessions(sessions);
        final groups = sessionGroups(sessions);

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _ConnectionSummary(
                        bootstrap: widget.bootstrap,
                        sessionRepository: widget.sessionRepository,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              labelText: context.l10n.t('searchSessions'),
                              border: const OutlineInputBorder(),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(context.l10n.t('allGroups')),
                                    selected: selectedGroup == null,
                                    onSelected: (_) =>
                                        setState(() => selectedGroup = null),
                                  ),
                                ),
                                for (final group in groups)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        group.isEmpty
                                            ? context.l10n.t('ungrouped')
                                            : group,
                                      ),
                                      selected: selectedGroup == group,
                                      onSelected: (_) =>
                                          setState(() => selectedGroup = group),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: _StartupMessage(
                        title: context.l10n.t('sessionLoadFailed'),
                        message: snapshot.error.toString(),
                        child: const Icon(Icons.error_outline, size: 36),
                      ),
                    )
                  else if (sessions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySessions(),
                    )
                  else if (visibleSessions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySessions(messageKey: 'noMatchingSessions'),
                    )
                  else
                    SliverList.builder(
                      itemCount: visibleSessions.length,
                      itemBuilder: (context, index) {
                        final session = visibleSessions[index];
                        return _SessionTile(
                          session: session,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SessionDetailPage(
                                  bootstrap: widget.bootstrap,
                                  session: session,
                                  sessionRepository: widget.sessionRepository,
                                ),
                              ),
                            );
                          },
                          onLongPress: () => openSessionActions(session),
                          onMore: () => openSessionActions(session),
                        );
                      },
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: isCreating ? null : createSession,
                icon: isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  isCreating
                      ? context.l10n.t('creating')
                      : context.l10n.t('newSession'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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

String sessionGroupKey(SessionSummary session) => session.groupName ?? '';

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

class SessionDrawer extends StatelessWidget {
  const SessionDrawer({
    super.key,
    required this.bootstrap,
    required this.sessionRepository,
    required this.currentSessionId,
  });

  final AppBootstrap bootstrap;
  final SessionRepository sessionRepository;
  final String currentSessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<List<SessionSummary>>(
          stream: sessionRepository.watchSessions(bootstrap.uid),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <SessionSummary>[];

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  title: Text(
                    l10n.t('sessions'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${sessions.length} ${l10n.t('sessionCount')}',
                  ),
                ),
                const Divider(height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  ListTile(title: Text(l10n.t('loadingSessions')))
                else if (snapshot.hasError)
                  ListTile(
                    title: Text(l10n.t('sessionLoadFailed')),
                    subtitle: Text(snapshot.error.toString()),
                  )
                else if (sessions.isEmpty)
                  ListTile(title: Text(l10n.t('noSessionsYet')))
                else
                  for (final session in sessions)
                    ListTile(
                      selected: session.id == currentSessionId,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(session.status),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (session.id == currentSessionId) {
                          return;
                        }
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => SessionDetailPage(
                              bootstrap: bootstrap,
                              session: session,
                              sessionRepository: sessionRepository,
                            ),
                          ),
                        );
                      },
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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

class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({
    super.key,
    required this.bootstrap,
    required this.session,
    required this.sessionRepository,
  });

  final AppBootstrap bootstrap;
  final SessionSummary session;
  final SessionRepository sessionRepository;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final TextEditingController controller = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> sendCommand() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) {
      return;
    }

    setState(() => isSending = true);
    try {
      await widget.sessionRepository.createCommand(
        uid: widget.bootstrap.uid,
        sessionId: widget.session.id,
        pcBridgeId: widget.bootstrap.pcBridgeId,
        text: text,
      );
      controller.clear();
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  SessionSummary currentSessionFrom(List<SessionSummary> sessions) {
    return sessions.firstWhere(
      (session) => session.id == widget.session.id,
      orElse: () => widget.session,
    );
  }

  Future<void> renameSession(SessionSummary session) async {
    final title = await showTextValueDialog(
      context,
      title: context.l10n.t('renameSession'),
      label: context.l10n.t('sessionName'),
      initialValue: session.title,
    );
    if (title == null) {
      return;
    }

    await widget.sessionRepository.renameSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      title: title,
    );
  }

  Future<void> updateGroup(SessionSummary session) async {
    final groupName = await showTextValueDialog(
      context,
      title: context.l10n.t('changeGroup'),
      label: context.l10n.t('groupName'),
      initialValue: session.groupName ?? '',
    );
    if (groupName == null) {
      return;
    }

    await widget.sessionRepository.updateSessionGroup(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
      groupName: groupName,
    );
  }

  Future<void> deleteSession(SessionSummary session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteSession')),
        content: Text(context.l10n.t('deleteSessionQuestion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.sessionRepository.deleteSession(
      uid: widget.bootstrap.uid,
      sessionId: session.id,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionSummary>>(
      stream: widget.sessionRepository.watchSessions(widget.bootstrap.uid),
      builder: (context, sessionSnapshot) {
        final currentSession = currentSessionFrom(
          sessionSnapshot.data ?? const <SessionSummary>[],
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(currentSession.title),
            actions: [
              IconButton(
                onPressed: () => widget.sessionRepository.updateSessionFavorite(
                  uid: widget.bootstrap.uid,
                  sessionId: currentSession.id,
                  favorite: !currentSession.favorite,
                ),
                tooltip: context.l10n.t(
                  currentSession.favorite ? 'removeFavorite' : 'favorite',
                ),
                icon: Icon(
                  currentSession.favorite ? Icons.star : Icons.star_border,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.t('more'),
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      renameSession(currentSession);
                    case 'group':
                      updateGroup(currentSession);
                    case 'delete':
                      deleteSession(currentSession);
                    case 'options':
                      showSessionOptionsSummaryDialog(context, currentSession);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(context.l10n.t('renameSession')),
                  ),
                  PopupMenuItem(
                    value: 'group',
                    child: Text(context.l10n.t('changeGroup')),
                  ),
                  PopupMenuItem(
                    value: 'options',
                    child: Text(context.l10n.t('cliOptionHelp')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.t('deleteSession')),
                  ),
                ],
              ),
            ],
          ),
          drawer: SessionDrawer(
            bootstrap: widget.bootstrap,
            sessionRepository: widget.sessionRepository,
            currentSessionId: currentSession.id,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<CommandSummary>>(
                    stream: widget.sessionRepository.watchCommands(
                      widget.bootstrap.uid,
                      currentSession.id,
                    ),
                    builder: (context, snapshot) {
                      final commands =
                          snapshot.data ?? const <CommandSummary>[];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _StartupMessage(
                          title: context.l10n.t('commandLoadFailed'),
                          message: snapshot.error.toString(),
                          child: const Icon(Icons.error_outline, size: 36),
                        );
                      }

                      if (commands.isEmpty) {
                        return const _NoCommands();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: commands.length,
                        itemBuilder: (context, index) =>
                            _CommandTile(command: commands[index]),
                      );
                    },
                  ),
                ),
                _CommandComposer(
                  controller: controller,
                  isSending: isSending,
                  onSend: sendCommand,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
