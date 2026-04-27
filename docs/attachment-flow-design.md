# Session attachment flow design

Issue #104の設計メモ。セッション開始時のPCローカル画像指定と、セッション途中でスマホから添付するファイルを分けて扱う。

## 方針

- セッション途中の添付は `commands/{commandId}` に紐づける。
- スマホ上のファイルはFirebase Storageへアップロードし、PCブリッジがclaim後にローカル一時領域へdownloadする。
- 画像はCodex CLIの `--image` に渡す。
- 汎用ファイルはPCブリッジがdownloadしたattachment directoryを `--add-dir` に渡し、promptへローカル参照path一覧を追記する。
- PCブリッジはdownload済みattachmentをrepository直下へ勝手に配置しない。workspaceへコピーする操作は、別の明示UI/設定が入るまで行わない。
- 既存の `codexImages` は、PCローカルpathを利用者が明示入力する初期prompt向け互換フィールドとして残す。

## Data model

`commands/{commandId}` に `attachments` 配列を追加する。

```json
{
  "text": "添付を見て要約してください",
  "status": "queued",
  "attachments": [
    {
      "attachmentId": "att_01",
      "kind": "image",
      "fileName": "photo.png",
      "mimeType": "image/png",
      "sizeBytes": 123456,
      "storagePath": "users/<uid>/sessions/<sessionId>/commands/<commandId>/attachments/att_01/photo.png",
      "sha256": "<optional-client-hash>",
      "disposition": "codexImage",
      "createdAt": "<server timestamp>",
      "expiresAt": "<timestamp>"
    }
  ]
}
```

`kind`:

- `image`: `image/*`。PCブリッジがdownload後に `--image <localPath>` として渡す。
- `file`: 画像以外。PCブリッジがdownload directoryを `--add-dir <attachmentDir>` として渡し、promptへ参照pathを追記する。

`disposition`:

- `codexImage`: Codex CLI `--image` に渡す。
- `promptReference`: promptへlocal pathを追記する。
- `addDirReference`: attachment directoryを `--add-dir` に渡す。

## Storage path

Firebase Storage path:

```text
users/{userId}/sessions/{sessionId}/commands/{commandId}/attachments/{attachmentId}/{safeFileName}
```

Rules方針:

- Android userは `request.auth.uid == userId` のpathだけupload/read/deleteできる。
- file size上限を設定する。
- MIME type allowlistを設定する。
- PCブリッジはAdmin SDK credentialでdownloadするため、Storage RulesではなくIAMとservice account key管理で保護する。

## Android flow

1. command作成画面で画像またはファイルを選ぶ。
2. file size、MIME type、件数をclient側で事前検査する。
3. command document IDを先に確保する。
4. Firebase Storageへuploadする。
5. upload完了後、`commands/{commandId}` を `queued` として作成し、`attachments` metadataを含める。
6. upload失敗時はcommandを作成しない。作成済みmetadataとStorage objectがずれた場合はcleanup対象にする。

## PC bridge flow

1. queued commandをclaimする。
2. `attachments` metadataを検証する。
3. Storage objectを `.local/attachments/{userId}/{sessionId}/{commandId}/{attachmentId}/` へdownloadする。
4. `sha256` がある場合はdownload後に照合する。
5. `kind=image` は `codexImages` と合流し、`--image` に渡す。
6. `kind=file` はattachment directoryを `--add-dir` に渡し、prompt末尾へ参照path一覧を追加する。
7. command完了後、local attachment cacheを削除する。失敗時も次回起動時に古いcacheをcleanupする。

## Security and limits

- MVP初期値は1 commandあたり最大5 files、合計25MBを目安にする。
- 拡張子ではなくMIME typeと実体検査を優先する。
- executable、script、archiveは初期実装では禁止する。
- attachment名はsanitizeし、path traversalを拒否する。
- promptへ貼るpathはPCローカルpathであり、Firestoreや通知payloadへ保存しない。
- result/error/progressにはattachment内容全文を保存しない。
- Storage objectは短期保持とし、削除UIまたはcleanup jobを別Issueで扱う。

## 実装Issue分割

1. Android/Firebase: Storage upload、metadata作成、Storage Rules、client side validation。
2. PC bridge: Storage download、local cache、`--image` / `--add-dir` 連携、cleanup。
3. QA/docs: attachment size/MIME/security test、E2E smoke、利用者向け説明。

Wake-on-LANやPC電源投入は別テーマとして残し、この設計には含めない。
