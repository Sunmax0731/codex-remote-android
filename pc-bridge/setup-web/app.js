const storageKey = "codexRemoteSetup.v1";
const fixedAppName = "RemoteCodex";
const fixedPackageName = "com.sunmax.remotecodex";

const messages = {
  en: {
    appTitle: "Codex Remote Setup",
    appSubtitle:
      "Prepare Firebase, register local setup files, and generate the Android setup QR.",
    languageLabel: "Language",
    cloudLinksTitle: "Cloud Links",
    cloudLinksSubtitle:
      "Open the services needed for project creation and deployment.",
    firebaseConsoleDesc: "Create the project and register the Android app.",
    gcpConsoleDesc: "Check billing, APIs, IAM, and service accounts.",
    functionsApiDesc: "Enable APIs required by Firebase Functions.",
    firebaseCliDesc: "Install and authenticate the Firebase CLI.",
    procedureTitle: "Procedure",
    procedureSubtitle: "Follow these steps before scanning the QR on Android.",
    step1: "Create a dedicated Firebase project.",
    step2: "Enable Authentication and Anonymous sign-in.",
    step3: "Create Firestore Database.",
    step4: "Register Android app package: com.sunmax.remotecodex.",
    step5Prefix: "Download",
    step6: "Create a PC bridge service account JSON and keep it local only.",
    step7: "Generate the QR and scan it from the Android setup screen.",
    step8: "Deploy Firestore rules, indexes, and Functions when needed.",
    appNameLabel: "App name",
    packageNameLabel: "Android package name",
    fixedAppInfoTitle: "Distributed APK settings",
    jsonRegistrationTitle: "JSON Registration",
    jsonRegistrationSubtitle:
      "Use client config for the QR. Keep admin credentials on the PC side only.",
    googleServicesDesc:
      "This file is parsed to generate the Android QR payload.",
    googleServicesPlaceholder: "Paste google-services.json here",
    serviceAccountTitle: "Service account JSON",
    serviceAccountDesc:
      "This is checked locally for setup progress. It is not sent to the QR endpoint.",
    serviceAccountPathLabel: "Service account JSON path for config.local.json",
    dangerNotice:
      "Never scan or share service account JSON, private keys, or Admin SDK credentials.",
    configHelperTitle: "config.local.json Helper",
    configHelperSubtitle:
      "Generate a PC bridge config template without embedding service account JSON or QR secrets.",
    pcBridgeIdLabel: "PC bridge ID",
    displayNameLabel: "Display name",
    workspaceNameLabel: "Workspace name",
    workspacePathLabel: "Workspace path",
    configSecretNotice:
      "The generated template contains project IDs and local paths, but not API keys, private keys, or service account JSON contents.",
    copyConfig: "Copy config template",
    configWaiting: "Load google-services.json to generate a config template.",
    configReady: "config.local.json template is ready.",
    configCopied: "config.local.json template copied.",
    configCopyFailed: "Copy failed. Select the text and copy it manually.",
    bridgeOpsTitle: "PC Bridge Operations",
    bridgeOpsSubtitle:
      "Check config.local.json, watcher state, scheduled startup, and redacted logs from this local setup UI.",
    refreshBridgeStatus: "Refresh status",
    startBridge: "Start watcher",
    registerBridgeTask: "Register on-login task",
    bridgeConfigStatusTitle: "Config status",
    bridgeProcessStatusTitle: "Process status",
    bridgeLogTitle: "Latest redacted watcher log",
    bridgeLogEmpty: "No log loaded.",
    bridgeOpsReady: "Ready.",
    bridgeStatusLoading: "Checking PC bridge status...",
    bridgeStartRequested: "Watcher start was requested. Refresh status after a few seconds.",
    bridgeTaskRegistered: "On-login task registration completed.",
    bridgeActionFailed: (message) => `PC bridge action failed: ${message}`,
    statusYes: "yes",
    statusNo: "no",
    googleServicesPackageOk: "Android package matches com.sunmax.remotecodex.",
    googleServicesPackageMissing:
      "Android package com.sunmax.remotecodex was not found.",
    googleServicesRequiredOk:
      "Required Firebase client fields are present.",
    googleServicesRequiredMissing: (fields) =>
      `Missing required Firebase fields: ${fields}.`,
    googleServicesNoAdminSecrets:
      "No service account private key was detected in this QR input.",
    googleServicesHasAdminSecrets:
      "This looks like Admin SDK or service account JSON. Do not use it for the QR.",
    qrBoundaryTitle: "QR payload boundary",
    qrIncludes:
      "QR includes: projectId, apiKey, appId, messagingSenderId, storageBucket.",
    qrExcludes:
      "QR excludes: service account JSON, private_key, client_email, local paths, config.local.json.",
    qrGeneratorTitle: "QR Generator",
    qrGeneratorSubtitle:
      "Generate the Android setup QR for the distributed APK.",
    generateQr: "Generate QR",
    saveLocal: "Save inputs locally",
    clearLocal: "Clear local inputs",
    qrOutput: "QR output",
    ready: "Ready.",
    localStatusEmpty: "No local setup saved.",
    notLoaded: "Not loaded.",
    notRegistered: "Not registered.",
    loadedFile: (name) => `Loaded ${name}.`,
    googleServicesReady: "google-services.json text is ready.",
    serviceAccountLooksValid: (name) =>
      `${name} looks like a service account file. Keep it local; it will not be included in the QR.`,
    serviceAccountLooksInvalid: (name) =>
      `${name} was loaded, but it does not look like a service account JSON.`,
    invalidJson: (message) => `Invalid JSON: ${message}`,
    generatingQr: "Generating QR...",
    qrGeneratingBox: "Generating...",
    qrGenerated:
      "QR generated. Scan it from the Android Firebase setup screen.",
    qrFailed: "QR generation failed.",
    inputsSaved: "Inputs saved in this browser.",
    inputsCleared: "Local inputs cleared.",
    googleServicesRestored: "Restored google-services.json text.",
    inputsRestored: "Inputs restored from this browser.",
    payloadFields: {
      schema: "schema",
      projectId: "projectId",
      apiKey: "apiKey",
      appId: "appId",
      messagingSenderId: "messagingSenderId",
      storageBucket: "storageBucket",
    },
  },
  ja: {
    appTitle: "Codex Remote セットアップ",
    appSubtitle:
      "Firebaseの準備、ローカル設定ファイルの確認、AndroidセットアップQRの生成を行います。",
    languageLabel: "表示言語",
    cloudLinksTitle: "クラウドリンク",
    cloudLinksSubtitle: "プロジェクト作成とデプロイに必要なサービスを開きます。",
    firebaseConsoleDesc: "プロジェクト作成とAndroidアプリ登録を行います。",
    gcpConsoleDesc: "課金、API、IAM、サービスアカウントを確認します。",
    functionsApiDesc: "Firebase Functionsに必要なAPIを有効化します。",
    firebaseCliDesc: "Firebase CLIの導入と認証手順を確認します。",
    procedureTitle: "手順",
    procedureSubtitle: "AndroidでQRを読み取る前に、この順番で準備します。",
    step1: "専用のFirebaseプロジェクトを作成する。",
    step2: "Authenticationで匿名ログインを有効化する。",
    step3: "Firestore Databaseを作成する。",
    step4: "Androidアプリのpackageを登録する: com.sunmax.remotecodex",
    step5Prefix: "次のファイルをダウンロードする:",
    step6: "PCブリッジ用service account JSONを作成し、PC上だけで保管する。",
    step7: "QRを生成し、Androidのセットアップ画面から読み取る。",
    step8: "必要に応じてFirestore Rules、Indexes、Functionsをデプロイする。",
    appNameLabel: "アプリ名",
    packageNameLabel: "Android package名",
    fixedAppInfoTitle: "配布APKの固定設定",
    jsonRegistrationTitle: "JSON登録",
    jsonRegistrationSubtitle:
      "QRにはクライアント設定だけを使います。管理者認証情報はPC側だけで扱います。",
    googleServicesDesc:
      "Android用QR payloadを生成するためにこのファイルを解析します。",
    googleServicesPlaceholder: "google-services.jsonを貼り付け",
    serviceAccountTitle: "Service account JSON",
    serviceAccountDesc:
      "セットアップ状況確認のためブラウザ内で確認します。QR生成APIには送信しません。",
    serviceAccountPathLabel: "config.local.jsonに書くservice account JSONのパス",
    dangerNotice:
      "service account JSON、秘密鍵、Admin SDK認証情報をQR化したり共有したりしないでください。",
    configHelperTitle: "config.local.json補助",
    configHelperSubtitle:
      "service account JSONやQR用の秘密値を埋め込まずに、PCブリッジ設定の雛形を生成します。",
    pcBridgeIdLabel: "PCブリッジID",
    displayNameLabel: "表示名",
    workspaceNameLabel: "ワークスペース名",
    workspacePathLabel: "ワークスペースパス",
    configSecretNotice:
      "生成される雛形にはproject IDとローカルパスを含みますが、API key、秘密鍵、service account JSON本文は含みません。",
    copyConfig: "設定雛形をコピー",
    configWaiting: "google-services.jsonを読み込むと設定雛形を生成できます。",
    configReady: "config.local.jsonの雛形を生成しました。",
    configCopied: "config.local.jsonの雛形をコピーしました。",
    configCopyFailed: "コピーに失敗しました。テキストを選択して手動でコピーしてください。",
    bridgeOpsTitle: "PCブリッジ運用",
    bridgeOpsSubtitle:
      "このローカルセットアップUIからconfig.local.json、watcher状態、常駐化、redaction済みログを確認します。",
    refreshBridgeStatus: "状態を更新",
    startBridge: "watcherを起動",
    registerBridgeTask: "ログオン時タスクを登録",
    bridgeConfigStatusTitle: "設定状態",
    bridgeProcessStatusTitle: "プロセス状態",
    bridgeLogTitle: "最新のredaction済みwatcherログ",
    bridgeLogEmpty: "ログはまだ読み込まれていません。",
    bridgeOpsReady: "準備完了。",
    bridgeStatusLoading: "PCブリッジ状態を確認中...",
    bridgeStartRequested: "watcher起動を要求しました。数秒後に状態を更新してください。",
    bridgeTaskRegistered: "ログオン時タスクの登録が完了しました。",
    bridgeActionFailed: (message) => `PCブリッジ操作に失敗しました: ${message}`,
    statusYes: "はい",
    statusNo: "いいえ",
    googleServicesPackageOk: "Android packageがcom.sunmax.remotecodexと一致しています。",
    googleServicesPackageMissing:
      "Android package com.sunmax.remotecodex が見つかりません。",
    googleServicesRequiredOk: "必要なFirebaseクライアント項目があります。",
    googleServicesRequiredMissing: (fields) =>
      `不足しているFirebase項目: ${fields}`,
    googleServicesNoAdminSecrets:
      "QR入力内にservice account秘密鍵は見つかりません。",
    googleServicesHasAdminSecrets:
      "Admin SDKまたはservice account JSONのようです。QRには使わないでください。",
    qrIncludes:
      "QRに含める項目: projectId, apiKey, appId, messagingSenderId, storageBucket。",
    qrExcludes:
      "QRに含めない項目: service account JSON, private_key, client_email, local path, config.local.json。",
    qrGeneratorTitle: "QR生成",
    qrGeneratorSubtitle: "配布APK向けのAndroidセットアップQRを生成します。",
    generateQr: "QRを生成",
    saveLocal: "入力をローカル保存",
    clearLocal: "ローカル入力をクリア",
    qrOutput: "QR出力",
    ready: "準備完了。",
    localStatusEmpty: "ローカル保存されたセットアップ情報はありません。",
    notLoaded: "未読み込み。",
    notRegistered: "未登録。",
    loadedFile: (name) => `${name}を読み込みました。`,
    googleServicesReady: "google-services.jsonの内容を利用できます。",
    serviceAccountLooksValid: (name) =>
      `${name}はservice accountファイルのようです。PC内だけで保管し、QRには含めません。`,
    serviceAccountLooksInvalid: (name) =>
      `${name}を読み込みましたが、service account JSONではないようです。`,
    invalidJson: (message) => `JSONが不正です: ${message}`,
    generatingQr: "QRを生成中...",
    qrGeneratingBox: "生成中...",
    qrGenerated: "QRを生成しました。AndroidのFirebaseセットアップ画面で読み取ってください。",
    qrFailed: "QR生成に失敗しました。",
    inputsSaved: "このブラウザに入力を保存しました。",
    inputsCleared: "ローカル入力をクリアしました。",
    googleServicesRestored: "google-services.jsonの内容を復元しました。",
    inputsRestored: "このブラウザから入力を復元しました。",
    payloadFields: {
      schema: "schema",
      projectId: "projectId",
      apiKey: "API key",
      appId: "app ID",
      messagingSenderId: "messaging sender ID",
      storageBucket: "storage bucket",
    },
  },
  zh: {
    appTitle: "Codex Remote 设置",
    appSubtitle: "准备 Firebase、登记本地设置文件，并生成 Android 设置二维码。",
    languageLabel: "语言",
    cloudLinksTitle: "云服务链接",
    cloudLinksSubtitle: "打开创建项目和部署所需的服务。",
    firebaseConsoleDesc: "创建项目并注册 Android 应用。",
    gcpConsoleDesc: "检查结算、API、IAM 和服务账号。",
    functionsApiDesc: "启用 Firebase Functions 所需的 API。",
    firebaseCliDesc: "安装 Firebase CLI 并完成认证。",
    procedureTitle: "步骤",
    procedureSubtitle: "在 Android 上扫描二维码前，请按以下步骤准备。",
    step1: "创建专用的 Firebase 项目。",
    step2: "启用 Authentication 和匿名登录。",
    step3: "创建 Firestore Database。",
    step4: "注册 Android 应用 package：com.sunmax.remotecodex",
    step5Prefix: "下载文件:",
    step6: "创建 PC 桥接用 service account JSON，并只保存在本机。",
    step7: "生成二维码，并从 Android 设置画面扫描。",
    step8: "按需部署 Firestore rules、indexes 和 Functions。",
    appNameLabel: "应用名称",
    packageNameLabel: "Android package 名称",
    fixedAppInfoTitle: "分发 APK 的固定设置",
    jsonRegistrationTitle: "JSON 登记",
    jsonRegistrationSubtitle:
      "二维码只使用客户端配置。管理员凭据只在 PC 侧处理。",
    googleServicesDesc: "解析此文件以生成 Android 二维码 payload。",
    googleServicesPlaceholder: "在此粘贴 google-services.json",
    serviceAccountTitle: "Service account JSON",
    serviceAccountDesc:
      "仅在浏览器内用于检查设置进度，不会发送到二维码生成接口。",
    serviceAccountPathLabel: "写入 config.local.json 的 service account JSON 路径",
    dangerNotice:
      "不要扫描或共享 service account JSON、私钥或 Admin SDK 凭据。",
    configHelperTitle: "config.local.json 辅助",
    configHelperSubtitle:
      "生成 PC 桥接设置模板，不嵌入 service account JSON 或二维码机密。",
    pcBridgeIdLabel: "PC bridge ID",
    displayNameLabel: "显示名称",
    workspaceNameLabel: "工作区名称",
    workspacePathLabel: "工作区路径",
    configSecretNotice:
      "生成的模板包含 project ID 和本地路径，但不包含 API key、私钥或 service account JSON 内容。",
    copyConfig: "复制设置模板",
    configWaiting: "加载 google-services.json 后可生成设置模板。",
    configReady: "config.local.json 模板已准备好。",
    configCopied: "config.local.json 模板已复制。",
    configCopyFailed: "复制失败。请选中文本后手动复制。",
    bridgeOpsTitle: "PC 桥接运行",
    bridgeOpsSubtitle:
      "从本地设置 UI 检查 config.local.json、watcher 状态、常驻启动和已脱敏日志。",
    refreshBridgeStatus: "刷新状态",
    startBridge: "启动 watcher",
    registerBridgeTask: "登记登录时任务",
    bridgeConfigStatusTitle: "设置状态",
    bridgeProcessStatusTitle: "进程状态",
    bridgeLogTitle: "最新脱敏 watcher 日志",
    bridgeLogEmpty: "尚未加载日志。",
    bridgeOpsReady: "就绪。",
    bridgeStatusLoading: "正在检查 PC 桥接状态...",
    bridgeStartRequested: "已请求启动 watcher。请几秒后刷新状态。",
    bridgeTaskRegistered: "登录时任务登记已完成。",
    bridgeActionFailed: (message) => `PC 桥接操作失败: ${message}`,
    statusYes: "是",
    statusNo: "否",
    googleServicesPackageOk: "Android package 与 com.sunmax.remotecodex 一致。",
    googleServicesPackageMissing:
      "未找到 Android package com.sunmax.remotecodex。",
    googleServicesRequiredOk: "必要的 Firebase 客户端字段已存在。",
    googleServicesRequiredMissing: (fields) =>
      `缺少 Firebase 字段: ${fields}`,
    googleServicesNoAdminSecrets:
      "二维码输入中未检测到 service account 私钥。",
    googleServicesHasAdminSecrets:
      "这看起来像 Admin SDK 或 service account JSON。不要用于二维码。",
    qrIncludes:
      "二维码包含: projectId, apiKey, appId, messagingSenderId, storageBucket。",
    qrExcludes:
      "二维码不包含: service account JSON, private_key, client_email, local path, config.local.json。",
    qrGeneratorTitle: "二维码生成",
    qrGeneratorSubtitle: "为分发 APK 生成 Android 设置二维码。",
    generateQr: "生成二维码",
    saveLocal: "保存到本地",
    clearLocal: "清除本地输入",
    qrOutput: "二维码输出",
    ready: "就绪。",
    localStatusEmpty: "没有保存的本地设置。",
    notLoaded: "未加载。",
    notRegistered: "未登记。",
    loadedFile: (name) => `已加载 ${name}。`,
    googleServicesReady: "google-services.json 文本已准备好。",
    serviceAccountLooksValid: (name) =>
      `${name} 看起来是 service account 文件。请保存在本机，且不会包含在二维码中。`,
    serviceAccountLooksInvalid: (name) =>
      `${name} 已加载，但看起来不是 service account JSON。`,
    invalidJson: (message) => `JSON 无效: ${message}`,
    generatingQr: "正在生成二维码...",
    qrGeneratingBox: "生成中...",
    qrGenerated: "二维码已生成。请在 Android Firebase 设置画面扫描。",
    qrFailed: "二维码生成失败。",
    inputsSaved: "输入已保存在当前浏览器中。",
    inputsCleared: "本地输入已清除。",
    googleServicesRestored: "已恢复 google-services.json 文本。",
    inputsRestored: "已从当前浏览器恢复输入。",
    payloadFields: {
      schema: "schema",
      projectId: "projectId",
      apiKey: "API key",
      appId: "app ID",
      messagingSenderId: "messaging sender ID",
      storageBucket: "storage bucket",
    },
  },
};

const languageSelect = document.querySelector("#languageSelect");
const localStatus = document.querySelector("#localStatus");
const googleServicesFile = document.querySelector("#googleServicesFile");
const googleServicesText = document.querySelector("#googleServicesText");
const googleServicesStatus = document.querySelector("#googleServicesStatus");
const googleServicesChecks = document.querySelector("#googleServicesChecks");
const serviceAccountFile = document.querySelector("#serviceAccountFile");
const serviceAccountStatus = document.querySelector("#serviceAccountStatus");
const serviceAccountPath = document.querySelector("#serviceAccountPath");
const pcBridgeId = document.querySelector("#pcBridgeId");
const displayName = document.querySelector("#displayName");
const workspaceName = document.querySelector("#workspaceName");
const workspacePath = document.querySelector("#workspacePath");
const configPreview = document.querySelector("#configPreview");
const copyConfig = document.querySelector("#copyConfig");
const configStatus = document.querySelector("#configStatus");
const refreshBridgeStatus = document.querySelector("#refreshBridgeStatus");
const startBridge = document.querySelector("#startBridge");
const registerBridgeTask = document.querySelector("#registerBridgeTask");
const bridgeConfigStatus = document.querySelector("#bridgeConfigStatus");
const bridgeProcessStatus = document.querySelector("#bridgeProcessStatus");
const bridgeLogTail = document.querySelector("#bridgeLogTail");
const bridgeOpsStatus = document.querySelector("#bridgeOpsStatus");
const generateQr = document.querySelector("#generateQr");
const saveLocal = document.querySelector("#saveLocal");
const clearLocal = document.querySelector("#clearLocal");
const qrBox = document.querySelector("#qrBox");
const payloadList = document.querySelector("#payloadList");
const qrStatus = document.querySelector("#qrStatus");

let currentLanguage = detectInitialLanguage();
let lastPayload = null;

languageSelect.value = currentLanguage;
applyLanguage();
loadLocalState();
refreshPcBridgeStatus();

languageSelect.addEventListener("change", () => {
  currentLanguage = languageSelect.value;
  saveLocalState();
  applyLanguage();
  if (lastPayload) {
    renderPayload(lastPayload);
  }
});

googleServicesFile.addEventListener("change", async () => {
  const file = googleServicesFile.files?.[0];
  if (!file) return;
  googleServicesText.value = await file.text();
  setStatus(googleServicesStatus, t("loadedFile", file.name), false);
  validateSetupInputs();
  updateConfigPreview();
});

googleServicesText.addEventListener("input", () => {
  const value = googleServicesText.value.trim();
  setStatus(
    googleServicesStatus,
    value ? t("googleServicesReady") : t("notLoaded"),
    false,
  );
  validateSetupInputs();
  updateConfigPreview();
});

serviceAccountFile.addEventListener("change", async () => {
  const file = serviceAccountFile.files?.[0];
  if (!file) return;

  try {
    const parsed = JSON.parse(await file.text());
    const hasPrivateKey =
      typeof parsed.private_key === "string" &&
      typeof parsed.client_email === "string";
    setStatus(
      serviceAccountStatus,
      hasPrivateKey
        ? t("serviceAccountLooksValid", file.name)
        : t("serviceAccountLooksInvalid", file.name),
      !hasPrivateKey,
    );
  } catch (error) {
    setStatus(serviceAccountStatus, t("invalidJson", error.message), true);
  }
  updateConfigPreview();
});

for (const input of [
  serviceAccountPath,
  pcBridgeId,
  displayName,
  workspaceName,
  workspacePath,
]) {
  input.addEventListener("input", () => {
    saveLocalState();
    updateConfigPreview();
  });
}

copyConfig.addEventListener("click", async () => {
  if (!configPreview.value.trim()) {
    setStatus(configStatus, t("configWaiting"), true);
    return;
  }

  try {
    await navigator.clipboard.writeText(configPreview.value);
    setStatus(configStatus, t("configCopied"), false);
  } catch {
    configPreview.select();
    setStatus(configStatus, t("configCopyFailed"), true);
  }
});

refreshBridgeStatus.addEventListener("click", () => {
  refreshPcBridgeStatus();
});

startBridge.addEventListener("click", async () => {
  await postBridgeAction("/api/pc-bridge/start", t("bridgeStartRequested"));
});

registerBridgeTask.addEventListener("click", async () => {
  await postBridgeAction(
    "/api/pc-bridge/register-task",
    t("bridgeTaskRegistered"),
  );
});

generateQr.addEventListener("click", async () => {
  setStatus(qrStatus, t("generatingQr"), false);
  qrBox.replaceChildren(document.createTextNode(t("qrGeneratingBox")));
  payloadList.replaceChildren();

  try {
    const response = await fetch("/api/firebase-setup-qr", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        googleServicesJson: googleServicesText.value,
        packageName: fixedPackageName,
      }),
    });
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error ?? t("qrFailed"));
    }

    const image = document.createElement("img");
    image.src = result.qrDataUrl;
    image.alt = "Firebase setup QR";
    qrBox.replaceChildren(image);
    lastPayload = result.payload;
    renderPayload(result.payload);
    updateConfigPreview(result.payload);
    setStatus(qrStatus, t("qrGenerated"), false);
  } catch (error) {
    qrBox.replaceChildren(document.createTextNode(t("qrOutput")));
    setStatus(qrStatus, error.message, true);
  }
});

saveLocal.addEventListener("click", () => {
  saveLocalState();
  setStatus(localStatus, t("inputsSaved"), false);
});

clearLocal.addEventListener("click", () => {
  localStorage.removeItem(storageKey);
  googleServicesText.value = "";
  lastPayload = null;
  payloadList.replaceChildren();
  googleServicesChecks.replaceChildren();
  configPreview.value = "";
  qrBox.replaceChildren(document.createTextNode(t("qrOutput")));
  setStatus(localStatus, t("inputsCleared"), false);
  setStatus(googleServicesStatus, t("notLoaded"), false);
  setStatus(configStatus, t("configWaiting"), false);
  setStatus(qrStatus, t("ready"), false);
});

function loadLocalState() {
  const raw = localStorage.getItem(storageKey);
  if (!raw) return;

  try {
    const state = JSON.parse(raw);
    if (typeof state.language === "string" && messages[state.language]) {
      currentLanguage = state.language;
      languageSelect.value = currentLanguage;
      applyLanguage();
    }
    if (typeof state.googleServicesText === "string") {
      googleServicesText.value = state.googleServicesText;
      setStatus(googleServicesStatus, t("googleServicesRestored"), false);
    }
    for (const [key, element] of Object.entries({
      serviceAccountPath,
      pcBridgeId,
      displayName,
      workspaceName,
      workspacePath,
    })) {
      if (typeof state[key] === "string") {
        element.value = state[key];
      }
    }
    validateSetupInputs();
    updateConfigPreview();
    setStatus(localStatus, t("inputsRestored"), false);
  } catch {
    localStorage.removeItem(storageKey);
  }
}

function saveLocalState() {
  localStorage.setItem(
    storageKey,
    JSON.stringify({
      language: currentLanguage,
      appName: fixedAppName,
      packageName: fixedPackageName,
      googleServicesText: googleServicesText.value,
      serviceAccountPath: serviceAccountPath.value,
      pcBridgeId: pcBridgeId.value,
      displayName: displayName.value,
      workspaceName: workspaceName.value,
      workspacePath: workspacePath.value,
    }),
  );
}

function applyLanguage() {
  document.documentElement.lang = currentLanguage;
  for (const element of document.querySelectorAll("[data-i18n]")) {
    element.textContent = t(element.dataset.i18n);
  }
  for (const element of document.querySelectorAll("[data-i18n-placeholder]")) {
    element.placeholder = t(element.dataset.i18nPlaceholder);
  }
  if (!googleServicesText.value.trim()) {
    setStatus(googleServicesStatus, t("notLoaded"), false);
  }
  if (!serviceAccountFile.files?.length) {
    setStatus(serviceAccountStatus, t("notRegistered"), false);
  }
}

function detectInitialLanguage() {
  const raw = localStorage.getItem(storageKey);
  if (raw) {
    try {
      const state = JSON.parse(raw);
      if (typeof state.language === "string" && messages[state.language]) {
        return state.language;
      }
    } catch {
      localStorage.removeItem(storageKey);
    }
  }

  const browserLanguage = navigator.language.toLowerCase();
  if (browserLanguage.startsWith("ja")) return "ja";
  if (browserLanguage.startsWith("zh")) return "zh";
  return "en";
}

async function refreshPcBridgeStatus() {
  setStatus(bridgeOpsStatus, t("bridgeStatusLoading"), false);
  try {
    const response = await fetch("/api/pc-bridge/status", {
      headers: { Accept: "application/json" },
    });
    const report = await response.json();
    if (!response.ok) {
      throw new Error(report.error ?? response.statusText);
    }

    renderStatusList(bridgeConfigStatus, {
      path: report.config?.path,
      exists: yesNo(report.config?.exists),
      valid: yesNo(report.config?.valid),
      classification: report.config?.classification,
      relayMode: report.config?.relayMode,
      codexMode: report.config?.codexMode,
      pcBridgeId: report.config?.pcBridgeId,
      firebaseProjectId: report.config?.firebaseProjectId,
      serviceAccountConfigured: yesNo(report.config?.serviceAccountConfigured),
      serviceAccountPathExists: yesNo(report.config?.serviceAccountPathExists),
      workspaceConfigured: yesNo(report.config?.workspaceConfigured),
      error: report.config?.error,
    });

    renderStatusList(bridgeProcessStatus, {
      supported: yesNo(report.process?.supported),
      running: yesNo(report.process?.running),
      matches: Array.isArray(report.process?.matches)
        ? String(report.process.matches.length)
        : undefined,
      error: report.process?.error,
    });

    if (report.logs?.found) {
      bridgeLogTail.textContent =
        `# ${report.logs.file} (${report.logs.updatedAt})\n` +
        (report.logs.redactedTail ?? "");
    } else {
      bridgeLogTail.textContent = t("bridgeLogEmpty");
    }

    setStatus(bridgeOpsStatus, t("ready"), false);
  } catch (error) {
    setStatus(
      bridgeOpsStatus,
      t("bridgeActionFailed", error instanceof Error ? error.message : String(error)),
      true,
    );
  }
}

async function postBridgeAction(url, successMessage) {
  setStatus(bridgeOpsStatus, t("bridgeStatusLoading"), false);
  try {
    const response = await fetch(url, { method: "POST" });
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.stderr || result.error || response.statusText);
    }
    setStatus(bridgeOpsStatus, successMessage, false);
    await refreshPcBridgeStatus();
  } catch (error) {
    setStatus(
      bridgeOpsStatus,
      t("bridgeActionFailed", error instanceof Error ? error.message : String(error)),
      true,
    );
  }
}

function renderStatusList(container, entries) {
  container.replaceChildren();
  for (const [key, value] of Object.entries(entries)) {
    if (value === undefined || value === null || value === "") {
      continue;
    }

    const term = document.createElement("dt");
    term.textContent = key;
    const description = document.createElement("dd");
    description.textContent = String(value);
    container.append(term, description);
  }
}

function yesNo(value) {
  if (typeof value !== "boolean") {
    return undefined;
  }

  return value ? t("statusYes") : t("statusNo");
}

function validateSetupInputs() {
  googleServicesChecks.replaceChildren();
  const text = googleServicesText.value.trim();
  if (!text) {
    return;
  }

  try {
    const parsed = JSON.parse(stripBom(text));
    const payload = extractPayloadFromGoogleServices(parsed, fixedPackageName);
    const containsAdminSecrets =
      typeof parsed.private_key === "string" ||
      typeof parsed.client_email === "string" ||
      typeof parsed.client_x509_cert_url === "string";

    addCheck(t("googleServicesRequiredOk"), true);
    addCheck(
      payload.packageName === fixedPackageName
        ? t("googleServicesPackageOk")
        : t("googleServicesPackageMissing"),
      payload.packageName === fixedPackageName,
    );
    addCheck(
      containsAdminSecrets
        ? t("googleServicesHasAdminSecrets")
        : t("googleServicesNoAdminSecrets"),
      !containsAdminSecrets,
    );
    addCheck(t("qrIncludes"), true);
    addCheck(t("qrExcludes"), true);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    addCheck(t("googleServicesRequiredMissing", message), false);
  }
}

function updateConfigPreview(payload = lastPayload) {
  const resolvedPayload =
    payload ?? tryExtractPayloadFromText(googleServicesText.value);
  if (!resolvedPayload) {
    configPreview.value = "";
    setStatus(configStatus, t("configWaiting"), false);
    return;
  }

  const template = {
    pcBridgeId: nonEmpty(pcBridgeId.value) ?? "home-main-pc",
    displayName: nonEmpty(displayName.value) ?? "Home PC",
    workspaceName: nonEmpty(workspaceName.value) ?? "codex-remote-android",
    workspacePath: nonEmpty(workspacePath.value) ?? "<absolute workspace path>",
    ownerUserId: "<paste Android UID after first app start>",
    firebaseProjectId: resolvedPayload.projectId,
    serviceAccountPath:
      nonEmpty(serviceAccountPath.value) ??
      "<absolute service account JSON path>",
    relayMode: "firestore",
    localRelayPath: ".local/relay-state.json",
    claimTtlSeconds: 300,
    pollIntervalSeconds: 5,
    heartbeatIntervalSeconds: 300,
    maxCommandsPerTick: 5,
    codexMode: "cli",
    codexCommandPath: "codex.cmd",
    codexSandbox: "workspace-write",
    codexBypassSandbox: false,
    codexTimeoutSeconds: 900,
  };

  configPreview.value = JSON.stringify(template, null, 2);
  setStatus(configStatus, t("configReady"), false);
}

function tryExtractPayloadFromText(text) {
  const trimmed = text.trim();
  if (!trimmed) {
    return null;
  }

  try {
    return extractPayloadFromGoogleServices(JSON.parse(stripBom(trimmed)), fixedPackageName);
  } catch {
    return null;
  }
}

function extractPayloadFromGoogleServices(googleServices, packageName) {
  const projectInfo = googleServices.project_info ?? {};
  const clients = Array.isArray(googleServices.client)
    ? googleServices.client
    : [];
  const client = clients.find(
    (entry) =>
      entry?.client_info?.android_client_info?.package_name === packageName,
  );
  if (!client) {
    throw new Error("client_info.android_client_info.package_name");
  }

  return {
    schema: "codex-remote.firebase-client.v1",
    projectId: requiredValue(projectInfo.project_id, "project_info.project_id"),
    apiKey: requiredValue(
      client.api_key?.[0]?.current_key,
      "client.api_key[0].current_key",
    ),
    appId: requiredValue(
      client.client_info?.mobilesdk_app_id,
      "client.client_info.mobilesdk_app_id",
    ),
    messagingSenderId: requiredValue(
      projectInfo.project_number,
      "project_info.project_number",
    ),
    storageBucket: nonEmpty(projectInfo.storage_bucket),
    packageName,
  };
}

function requiredValue(value, field) {
  const resolved = nonEmpty(value);
  if (!resolved) {
    throw new Error(field);
  }

  return resolved;
}

function nonEmpty(value) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function addCheck(message, passed) {
  const item = document.createElement("li");
  item.textContent = message;
  item.className = passed ? "passed" : "failed";
  googleServicesChecks.append(item);
}

function renderPayload(payload) {
  const labels = messages[currentLanguage].payloadFields;
  const rows = [
    [labels.schema, payload.schema],
    [labels.projectId, payload.projectId],
    [labels.apiKey, maskValue(payload.apiKey)],
    [labels.appId, payload.appId],
    [labels.messagingSenderId, payload.messagingSenderId],
    [labels.storageBucket, payload.storageBucket ?? ""],
  ];

  payloadList.replaceChildren();
  for (const [name, value] of rows) {
    const term = document.createElement("dt");
    term.textContent = name;
    const description = document.createElement("dd");
    description.textContent = value || "-";
    payloadList.append(term, description);
  }
}

function maskValue(value) {
  if (typeof value !== "string" || value.length < 10) return value ?? "";
  return `${value.slice(0, 6)}...${value.slice(-4)}`;
}

function setStatus(element, message, isError) {
  element.textContent = message;
  element.classList.toggle("error", isError);
}

function stripBom(value) {
  return value.charCodeAt(0) === 0xfeff ? value.slice(1) : value;
}

function t(key, ...args) {
  const value = messages[currentLanguage][key] ?? messages.en[key] ?? key;
  return typeof value === "function" ? value(...args) : value;
}
