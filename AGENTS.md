# NotchHub AIエージェントへの指針 (AGENTS.md)

このファイルは、NotchHub リポジトリでコードを操作する AI エージェント（Claude Code, Copilot, Cursor など）へのルールおよび指針を提供する。

NotchHub は **Mac のノッチを活用した共有・一時保管ハブ**（Swift / SwiftUI + AppKit による macOS 常駐ネイティブアプリ）である。AI アシスタント管理アプリではない。詳細は [`docs/要件定義.md`](docs/要件定義.md) と [`docs/サービスコンセプト.md`](docs/サービスコンセプト.md) を参照。

## 必須ルール

### レイヤー境界を越えない（最重要）
依存方向は **`View → ViewModel → Service → Repository/Platform（protocol）`**、Model（`Core/Models`）は最内層で外部依存なし（[`docs/アーキテクチャ.md`](docs/アーキテクチャ.md)）。

- **View / ViewModel から SQLite・OS API を直接呼んではいけない。** 必ず Service 経由でアクセスする
- **Service は Repository / Platform の protocol にのみ依存する。** 具体実装を直接 import しない
- **DI の組み立ては `App/Composition/`（Composition Root）でのみ行う**

### OS API は Platform 層に隠蔽する
NSSharingService / EventKit / Accessibility / File System Events / Local Socket / AppleScript などの OS API は **必ず `Platform/` の protocol の裏に隠す**。本番実装と Stub 実装をペアで用意し、テスト・プレビュー・権限未付与時に Stub へ差し替えられるようにする。

### 永続化規約
- ファイル / フォルダは **コピーせず BookmarkData（Security Scoped Bookmark）で参照保持** する。元ファイル削除時は Shelf から自動除去する
- SQLite アクセスは `Repositories/` に集約。スキーマ変更は **バージョン管理されたマイグレーション**（`user_version`）で前方向きに適用する（[`docs/リポジトリ層設計規約.md`](docs/リポジトリ層設計規約.md)）

### 権限の扱い
- **権限（Files & Folders / Calendar / Accessibility / Notifications / Automation）は必要になった時点で要求する。初回に一括要求しない**
- `userId` のようなサーバー概念は存在しない。NotchHub はローカル完結アプリである

### ノッチ UI の鉄則
- 通常時はノッチに同化し、展開トリガーは **「ドラッグ接近 / クリック / AI 承認待ち」のみ**。Hover・カーソル接近で展開してはいけない
- 最小状態は優先度順に **常に 1 状態のみ** 表示する
- Drop 時のみ処理を実行する（誤操作防止：Dead Zone・強調・Toast・Undo）

## 作業ルール

### 要件定義・実装計画
依頼された場合は、最初に論点を洗い出してユーザーに質問しながらクリアにし、マークダウンでドキュメントを作成する。

### ドキュメント管理
- 設計ドキュメントは `docs/` 配下に Markdown で作成する
- 既存の設計ドキュメント（要件定義 / アーキテクチャ / 各規約）と矛盾しないよう、変更時は関連ドキュメントも更新する

### Push 前の必須チェック
本リポジトリは Swift Package Manager 構成を採用している（理由・詳細は [`docs/開発環境.md`](docs/開発環境.md)）。`git push` する前に `make verify` を実行し、全てパスすることを確認する（[`docs/品質チェック・テスト規約.md`](docs/品質チェック・テスト規約.md)）。`make verify` は以下を順に実行する:

1. `swiftformat --lint .` — フォーマット検証
2. `./scripts/swiftlint.sh --strict` — 静的解析
3. `swift build` — ビルド・型チェック（警告ゼロ）
4. `./scripts/swift-test.sh` — テスト（swift-testing）

いずれかが失敗した場合は修正してから push する。`!`（force unwrap）・`try!`・`as!` は原則禁止。

## 開発コマンド

SPM 構成のため `swift` ツールチェーンで操作する（詳細 [`docs/開発環境.md`](docs/開発環境.md)）。

```sh
# ビルド
make build            # swift build

# テスト
make test             # ./scripts/swift-test.sh
swift test --filter MigrationRunnerTests   # 特定 Suite のみ

# フォーマット適用 / 検証
make format           # swiftformat .
swiftformat --lint .

# 静的解析
make lint             # ./scripts/swiftlint.sh --strict

# 一括検証（push 前）
make verify
```

## アーキテクチャ

**設計思想**: 機能（Feature）単位モジュール分割 + MVVM + Service + Repository レイヤード

**技術スタック**: Swift / SwiftUI / AppKit / SQLite / EventKit / NSSharingService / Accessibility API / Security Scoped Bookmark / Local Socket / AppleScript

## ディレクトリ構造

```text
Sources/NotchHub/
├── App/            # エントリ・メニューバー・ノッチウィンドウ・Composition Root
├── Core/           # 共通: Models / Extensions / Utilities / DI
├── Features/       # 機能モジュール（Notch / Shelf / AirDrop / Share / AIMonitor / Calendar / Media）
│   └── */          # Views（SwiftUI） + ViewModels
├── Services/       # ビジネスロジック（protocol + 実装）
├── Repositories/   # 永続化（protocol + 実装 + Stub）
├── Platform/       # OS 統合（protocol + 実装 + Stub）
└── Resources/      # アセット・Info.plist・entitlements
```

## 参照ドキュメント

- [`docs/要件定義.md`](docs/要件定義.md) — 機能要件（全24章）
- [`docs/サービスコンセプト.md`](docs/サービスコンセプト.md) — プロダクトの位置付け
- [`docs/アーキテクチャ.md`](docs/アーキテクチャ.md) — レイヤー構造・依存方向
- [`docs/フロントエンドアーキテクチャ.md`](docs/フロントエンドアーキテクチャ.md) / [`docs/フロントエンド規約.md`](docs/フロントエンド規約.md) — UI（SwiftUI）方針・規約
- [`docs/リポジトリ層設計規約.md`](docs/リポジトリ層設計規約.md) — 永続化（SQLite / BookmarkData）
- [`docs/インフラストラクチャ規約.md`](docs/インフラストラクチャ規約.md) — ビルド・署名・配布・権限
- [`docs/スタイルガイド.md`](docs/スタイルガイド.md) — Swift / SwiftUI コーディング規約
- [`docs/テストガイドライン.md`](docs/テストガイドライン.md) / [`docs/品質チェック・テスト規約.md`](docs/品質チェック・テスト規約.md) — テスト・品質
- [`docs/実装計画.md`](docs/実装計画.md) — フェーズ別実装計画
