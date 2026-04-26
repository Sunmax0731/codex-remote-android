# release APK作成手順

この文書は、Codex Remote Androidを自分以外の利用者へ配布するためのAPK作成手順をまとめる。

## 方針

- 配布APKのpackage名は `com.sunmax.remotecodex` に固定する。
- debug署名APKは配布用途に使わない。
- release APKはローカルPC上の署名鍵で署名する。
- 署名鍵、key password、`key.properties` はGitに含めない。
- Google Play公開は現時点の対象外とし、まずは内部配布用APKを対象にする。

## version更新

Flutterのversionは [app/pubspec.yaml](../app/pubspec.yaml) の `version` で管理する。

例:

```yaml
version: 1.0.1+2
```

- `1.0.1`: 利用者向けのversionName
- `2`: AndroidのversionCode

配布前には、前回配布版より `versionCode` を必ず増やす。

## 署名鍵を作成する

署名鍵はGit管理外の安全な場所に保存する。例では `D:\secure` を使う。

```powershell
New-Item -ItemType Directory -Force -Path D:\secure
keytool -genkeypair `
  -v `
  -keystore D:\secure\codex-remote-upload-keystore.jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload
```

入力したstore password、key password、alias、keystoreの場所は再配布や更新に必要になる。紛失すると同じ署名の更新APKを作れなくなるため、Git以外の安全な方法で保管する。

## key.propertiesを作成する

[app/android/key.properties.example](../app/android/key.properties.example) をコピーして `app/android/key.properties` を作成する。

```powershell
Copy-Item app\android\key.properties.example app\android\key.properties
```

内容を自分の署名鍵に合わせて編集する。

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=D:\\secure\\codex-remote-upload-keystore.jks
```

`app/android/key.properties` は `.gitignore` で除外されている。コミットしない。

## release APKをビルドする

事前に `app/android/app/google-services.json` が存在し、Firebase Androidアプリのpackage名が `com.sunmax.remotecodex` で登録されていることを確認する。

```powershell
cd app
flutter clean
flutter pub get
flutter build apk --release
```

出力先:

```text
app/build/app/outputs/flutter-apk/app-release.apk
```

`key.properties` がない状態では、releaseビルドは失敗する。配布用APKを作成する前に必ず署名鍵を用意する。

## APKを確認する

インストール前に、APKの存在と更新時刻を確認する。

```powershell
Get-Item app\build\app\outputs\flutter-apk\app-release.apk |
  Select-Object FullName,Length,LastWriteTime
```

署名状態を確認する。

```powershell
$apksigner = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Recurse -Filter apksigner.bat |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName
& $apksigner verify --verbose app\build\app\outputs\flutter-apk\app-release.apk
```

`Verified using v2 scheme (APK Signature Scheme v2): true` のように署名検証が成功することを確認する。

実機へインストールして、最低限次を確認する。

```powershell
adb install -r app\build\app\outputs\flutter-apk\app-release.apk
```

確認項目:

- アプリ名が `RemoteCodex` と表示される。
- Firebase setup QRを読み取れる。
- 匿名認証が成功する。
- PCブリッジのheartbeatが表示される。
- セッション作成から完了または失敗表示まで確認できる。
- 完了通知が届く。

## リリースノート項目

APK配布時には次を記載する。

- versionName / versionCode
- 配布日
- APKファイル名
- 対象package名: `com.sunmax.remotecodex`
- 主な変更点
- 既知の制限
- セットアップに必要なもの
  - Firebaseプロジェクト
  - PCブリッジ
  - Node.js / npm
  - Codex CLI
- 秘密情報の注意
  - service account JSONを共有しない
  - `key.properties` と署名鍵を共有しない
  - GitHub Issueやログにtokenを貼らない

## 判断が必要な項目

次は配布者の判断が必要。

- 署名鍵の正式な保管場所
- APKを配布する場所
  - GitHub Release
  - 個別共有
  - 社内/限定配布ストレージ
- 配布対象端末とAndroid versionの範囲
- 初回配布version
- Google Play公開を将来対象にするか
