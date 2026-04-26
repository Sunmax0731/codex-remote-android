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
    dangerNotice:
      "Never scan or share service account JSON, private keys, or Admin SDK credentials.",
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
    dangerNotice:
      "service account JSON、秘密鍵、Admin SDK認証情報をQR化したり共有したりしないでください。",
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
    dangerNotice:
      "不要扫描或共享 service account JSON、私钥或 Admin SDK 凭据。",
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
const serviceAccountFile = document.querySelector("#serviceAccountFile");
const serviceAccountStatus = document.querySelector("#serviceAccountStatus");
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
});

googleServicesText.addEventListener("input", () => {
  const value = googleServicesText.value.trim();
  setStatus(
    googleServicesStatus,
    value ? t("googleServicesReady") : t("notLoaded"),
    false,
  );
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
  qrBox.replaceChildren(document.createTextNode(t("qrOutput")));
  setStatus(localStatus, t("inputsCleared"), false);
  setStatus(googleServicesStatus, t("notLoaded"), false);
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

function t(key, ...args) {
  const value = messages[currentLanguage][key] ?? messages.en[key] ?? key;
  return typeof value === "function" ? value(...args) : value;
}
