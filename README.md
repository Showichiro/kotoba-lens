# ことばレンズ

Chrome 内蔵のローカル LLM（Prompt API / Gemini Nano）がページ全体を先回りして理解し、3行要約と選択箇所の文脈解説を提供する Manifest V3 拡張です。ページの文章は外部サーバーへ送信しません。

## できること

- ページを開くと本文の3行要約を自動生成
- テキストを選択すると、ページ全体の文脈を踏まえて意味を解説
- 解説を「やさしく」「前提から」「具体例で」の3方向に再説明
- 要約と解説はChromeのUI言語に合わせて生成し、言語が異なる場合は自動で再生成
- URLと本文のハッシュを使い、直近の要約を端末内へキャッシュ
- すべてのAI処理を端末内で実行

## セットアップ

必要なもの:

- デスクトップ版 Chrome 138 以降
- Prompt API のハードウェア／ストレージ要件を満たす端末
- Node.js 20 以降

### ビルド済みファイルを使う

[Releases](https://github.com/Showichiro/kotoba-lens/releases/latest) から最新の `kotoba-lens-v*.zip` をダウンロードして展開し、Chrome の `chrome://extensions` でデベロッパーモードを有効にして「パッケージ化されていない拡張機能を読み込む」から展開先を選びます。

リリース前の最新版は [Actions の CI](https://github.com/Showichiro/kotoba-lens/actions/workflows/ci.yml) の成功した実行にある Artifacts からダウンロードできます（GitHubへのログインが必要です）。

### ソースからビルドする

```sh
npm install
npm run build
```

Chrome で `chrome://extensions` を開き、デベロッパーモードを有効にして「パッケージ化されていない拡張機能を読み込む」から `dist` を選びます。通常のWebページを開くと自動で要約処理が始まります。ツールバーの「ことばレンズ」を押すと3行要約を開閉できます。

初回実行時は Chrome がモデルをダウンロードするため、完了まで時間がかかることがあります。

## 開発

```sh
npm run check
npm run dev
```

`dev` はファイル変更を監視して `dist` を再生成します。変更後は `chrome://extensions` で拡張を再読み込みしてください。

## Feature Flag lifecycle PoC

このリポジトリには、Dart 3.10 で正式導入された Analyzer Plugin API を使い、Feature Flag の撤去期限を静的解析で強制する最小 PoC も含まれます。拡張機能が Flag の値をどこから取得するか（Remote Config など）には関与せず、コード上のライフサイクルメタデータだけを検査します。

### 設計

`feature_flag_annotation` はアプリが依存する軽量なアノテーション、`feature_flag_lifecycle_plugin` は開発時だけ利用する Analyzer Plugin です。Flag は enum value に宣言します。

```dart
enum FeatureFlag {
  @Flag(
    expiresAt: '2026-08-01',
    owner: 'checkout-team',
  )
  newCheckout,
}
```

`expiresAt` は UTC のカレンダー日（`YYYY-MM-DD`）として扱い、その日の間は有効、翌日から期限切れです。`owner` は任意の運用メタデータで、現在のルール判定には使いません。期限切れの場合は enum value に error severity の `expired_feature_flag` を報告するため、通常の `dart analyze` が非 0 で終了します。

Plugin は対象プロジェクトの `analysis_options.yaml` でローカルパスを指定して有効化します。

```yaml
plugins:
  feature_flag_lifecycle_plugin:
    path: ../../packages/feature_flag_lifecycle_plugin
```

### 実行と検証

Dart 3.11 以降を用意し（Plugin API 自体は Dart 3.10 で導入）、リポジトリルートで次を実行します。

```sh
./scripts/verify-feature-flags.sh
```

スクリプトはルールの単体テスト、期限内 fixture の解析成功、期限切れ fixture の解析失敗と診断コード／メッセージを順に検証します。個別にも確認できます。

```sh
cd fixtures/feature_flags_valid && dart pub get && dart analyze
cd fixtures/feature_flags_expired && dart pub get && dart analyze # exit 3
```

検証 fixture は日付に依存して不安定にならないよう、期限内を `2999-12-31`、期限切れを `2000-01-01` に固定しています。CI の `feature-flag-lifecycle` job も同じスクリプトを実行し、期待される解析失敗を捕捉するので main を常時赤くしません。

### 方式選定

- **採用:** Dart 公式の `analysis_server_plugin` / `analyzer` API。Dart 3.10 以降の `plugins` 設定で標準の `dart analyze` に診断を統合でき、IDE と CI が同じルールを利用できます。
- **不採用:** 旧 `analyzer_plugin` の protocol server を手動実装する方式。現在の公式エントリポイントと登録 API が利用できるため、古い API への依存や isolate protocol の独自実装は不要です。
- **不採用:** 独立した CLI でソースを正規表現検索する方式。Analyzer の AST を使う採用案に比べ、Dart 構文への追従性と `dart analyze` への統合で劣ります。

PoC の最小スコープとして、`Flag` という名前のアノテーション、リテラルの `expiresAt`、enum value を対象にしています。日付形式エラー、owner 必須化、型解決による同名アノテーション除外は将来のルール候補です。

配布用の ZIP は次のコマンドで `artifacts/` に生成できます。

```sh
npm run package
```

## リリースと Changelog

利用者に影響する変更には Changeset を追加します。

```sh
npm run changeset
```

`main` への反映後、Changesets Action がリリース PR を作成・更新します。この PR をマージすると `CHANGELOG.md` とバージョンを更新し、GitHub Release にインストール用 ZIP を添付します。変更の分類は SemVer に従い、修正は patch、後方互換性のある機能追加は minor、破壊的変更は major を選択してください。

## プライバシーと権限

外部 API、解析 SDK、ネットワーク通信はありません。権限は次の用途だけに使います。

- `http://*/*` / `https://*/*`: コンテンツスクリプトを実行し、開いているWebページの本文を端末内で解析
- `storage`: 生成済みの3行要約を端末内へ一時保存

本文そのものは保存・送信しません。要約キャッシュだけを最大20件、端末内に保持します。Chrome 内部ページや Chrome ウェブストアにはアクセスできません。

Chrome の組み込み AI の要件と API は [Prompt API 公式ドキュメント](https://developer.chrome.com/docs/ai/prompt-api) を参照してください。

## 現在の制限

- Chrome 内部ページ、Chrome ウェブストア、PDF ビューアー等では動作しません。
- 本文が短いページや、本文構造を取得できないページでは要約を作成しません。
- 約16,000文字までをページ文脈として取得します。長いページの選択解説では、全体要約・見出し・関連度の高い段落を組み合わせます。
- 1回のローカルAI処理が90秒を超えた場合は中断します。
- 初回実行時はモデルのダウンロードに時間がかかる場合があります。
- ローカルモデルがChromeのUI言語をサポートしていない場合、その言語では生成できません。

## License

[Apache License 2.0](LICENSE) © 2026 Showichiro
