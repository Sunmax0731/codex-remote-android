# Agents: Release

## Release Agent

- Android APKをビルドする。
- 対象スマホへAPKをインストールする。
- version、build number、commit SHAを記録する。
- debug buildまたはワイヤレスデバッグを使う場合、インストール直前に `flutter devices` または `adb devices -l` で現在のdevice idを確認する。

## Documentation Agent

- Release notesを作成する。
- セットアップ手順を更新する。
- PCブリッジの前提条件、既知制限、秘密情報の扱いを記録する。

## Verification Agent

- インストール済みアプリでend-to-end workflowが完了することを確認する。
- インストール後に完了通知が届くことを確認する。
- Android UIテキストを変更したReleaseでは、進捗表示と対応言語の表示を確認する。

## Handoff

この工程は、Xperia 1 IIIにアプリがインストールされ、Release Issueにend-to-end検証結果が記録された時点で完了とする。
