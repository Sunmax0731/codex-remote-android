const storageKey = "codexRemoteSetup.v1";

const appName = document.querySelector("#appName");
const packageName = document.querySelector("#packageName");
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

loadLocalState();

googleServicesFile.addEventListener("change", async () => {
  const file = googleServicesFile.files?.[0];
  if (!file) return;
  googleServicesText.value = await file.text();
  setStatus(googleServicesStatus, `Loaded ${file.name}.`, false);
});

googleServicesText.addEventListener("input", () => {
  const value = googleServicesText.value.trim();
  setStatus(
    googleServicesStatus,
    value ? "google-services.json text is ready." : "Not loaded.",
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
        ? `${file.name} looks like a service account file. Keep it local; it will not be included in the QR.`
        : `${file.name} was loaded, but it does not look like a service account JSON.`,
      !hasPrivateKey,
    );
  } catch (error) {
    setStatus(serviceAccountStatus, `Invalid JSON: ${error.message}`, true);
  }
});

generateQr.addEventListener("click", async () => {
  setStatus(qrStatus, "Generating QR...", false);
  qrBox.replaceChildren(document.createTextNode("Generating..."));
  payloadList.replaceChildren();

  try {
    const response = await fetch("/api/firebase-setup-qr", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        googleServicesJson: googleServicesText.value,
        packageName: packageName.value,
      }),
    });
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error ?? "QR generation failed.");
    }

    const image = document.createElement("img");
    image.src = result.qrDataUrl;
    image.alt = "Firebase setup QR";
    qrBox.replaceChildren(image);
    renderPayload(result.payload);
    setStatus(
      qrStatus,
      "QR generated. Scan it from the Android Firebase setup screen.",
      false,
    );
  } catch (error) {
    qrBox.replaceChildren(document.createTextNode("QR output"));
    setStatus(qrStatus, error.message, true);
  }
});

saveLocal.addEventListener("click", () => {
  localStorage.setItem(
    storageKey,
    JSON.stringify({
      appName: appName.value,
      packageName: packageName.value,
      googleServicesText: googleServicesText.value,
    }),
  );
  setStatus(localStatus, "Inputs saved in this browser.", false);
});

clearLocal.addEventListener("click", () => {
  localStorage.removeItem(storageKey);
  googleServicesText.value = "";
  setStatus(localStatus, "Local inputs cleared.", false);
  setStatus(googleServicesStatus, "Not loaded.", false);
});

function loadLocalState() {
  const raw = localStorage.getItem(storageKey);
  if (!raw) return;

  try {
    const state = JSON.parse(raw);
    if (typeof state.appName === "string") appName.value = state.appName;
    if (typeof state.packageName === "string") {
      packageName.value = state.packageName;
    }
    if (typeof state.googleServicesText === "string") {
      googleServicesText.value = state.googleServicesText;
      setStatus(googleServicesStatus, "Restored google-services.json text.", false);
    }
    setStatus(localStatus, "Inputs restored from this browser.", false);
  } catch {
    localStorage.removeItem(storageKey);
  }
}

function renderPayload(payload) {
  const rows = [
    ["schema", payload.schema],
    ["projectId", payload.projectId],
    ["apiKey", maskValue(payload.apiKey)],
    ["appId", payload.appId],
    ["messagingSenderId", payload.messagingSenderId],
    ["storageBucket", payload.storageBucket ?? ""],
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
