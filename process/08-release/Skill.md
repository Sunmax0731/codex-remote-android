# Skill: Release

## 目的

AndroidアプリをRelease APKとしてビルドし、対象端末へインストールできる状態まで進める。

## 手順

1. Release blockerのIssueがすべてクローズされていることを確認する。
2. versionとbuild numberを確認し、必要があれば更新する。
3. APKをビルドする。
4. `flutter devices` または `adb devices -l` で現在のワイヤレスデバッグdevice idを確認する。
5. debug releaseの場合は `flutter install -d <device-id> --debug`、release APKの場合は `adb install` でXperia 1 IIIへインストールする。
6. Release smoke testを実施する。
   - セッションを作成または選択する。
   - 指示を送信する。
   - PCブリッジが指示を処理する。
   - bridgeが進捗を返す場合、running中の進捗概要が表示される。
   - 最終結果が表示される。
   - 完了通知が届く。
7. UIテキストを変更したReleaseでは、対応言語の表示をスポット確認する。
   - 日本語
   - 英語
   - 中国語
   - 韓国語
   - 可能であれば未対応言語の英語フォールバック
8. Release commitにtagを付ける。
9. 必要に応じてAPK付きのGitHub Releaseを公開する。

## 検証

- APKがスマホにインストールされている。
- end-to-endコマンドサイクルが完了する。
- 完了通知が届く。
- 対応言語の表示を確認済み、または理由付きで明示的に延期している。
- Release notesにセットアップ要件と既知制限が含まれている。

## 注意点

- ワイヤレスデバッグのdevice idとポートは変わるため、インストール直前に必ず確認する。
- 端末がofflineの場合は、ADB server再起動やスマホ側のワイヤレスデバッグ再接続を試す。
- 正式なストア公開にはdebug signing configでは不十分。Google Play公開時は専用署名鍵を用意する。
