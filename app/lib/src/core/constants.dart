part of '../../main.dart';

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
