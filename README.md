# NotchHub

**Mac のノッチを活用した「共有」と「一時保管」の常駐アプリ**（Swift / SwiftUI + AppKit のネイティブ macOS アプリ）。

ファイルをノッチへドラッグするだけで AirDrop / Share Sheet を即起動し、「あとで使う・あとで送る」を Shelf に一時保管できます。補助機能として AI CLI モニター・カレンダー・メディア操作を備えます。

> 詳細な仕様は [`docs/要件定義.md`](docs/要件定義.md) と [`docs/サービスコンセプト.md`](docs/サービスコンセプト.md) を参照してください。

## 主な機能

| 機能 | 概要 |
|---|---|
| **AirDrop 高速化** | ノッチへドラッグ → AirDrop 共有 UI を即起動（履歴を保存、送信先は保存しない） |
| **Shelf（一時保管）** | ファイル/フォルダ/テキスト/URL/Markdown を参照保持で保管・全文検索 |
| Share Sheet | `NSSharingServicePicker` で Mail / Messages / Notes / Reminders などへ共有 |
| Screenshot Auto Import | スクリーンショットを自動で Shelf に追加（ON/OFF） |
| AI CLI Monitor | Claude Code / Codex / Antigravity のセッション・承認待ちを表示し Approve/Deny/Stop |
| Calendar | EventKit で Next / Today を表示（過去は非表示、クリックで Calendar.app） |
| Media | Apple Music / Spotify の再生情報表示と Play/Pause/Next/Previous |

中核は **「AirDrop + Shelf」**、AI Monitor・Calendar・Media は補助機能という位置づけです。

## 動作環境

- macOS 14+（将来の機能方針は macOS 15+ を基準に検討）
- Apple Silicon / Intel

## アーキテクチャ

**機能（Feature）単位モジュール + MVVM + Service + Repository** のレイヤード構成。

```text
依存方向: View → ViewModel → Service → Repository / Platform（protocol）
          Model（Core/Models）は最内層・外部依存なし
```

OS API（NSSharingService / EventKit / Accessibility / Local Socket / AppleScript / Security Scoped Bookmark）はすべて `Platform/` の protocol の裏に隠蔽し、本番実装と Stub をペアで用意しています。詳細は [`docs/アーキテクチャ.md`](docs/アーキテクチャ.md)。

### ディレクトリ構成

```text
Sources/NotchHub/
├── App/            # エントリ・メニューバー・ノッチウィンドウ・Composition Root
├── Core/           # Models / Theme / Components / Utilities
├── Features/       # Notch / Shelf / AIMonitor / Calendar / Media / Settings
├── Services/       # ビジネスロジック（protocol + 実装）
├── Repositories/   # 永続化（protocol + SQLite + Stub）
├── Platform/       # OS 統合（protocol + 実装 + Stub）
└── Resources/      # Info.plist・entitlements（バンドル化時に適用）
Tests/NotchHubTests/  # swift-testing（ソース構造を mirror）
```

## 開発

本リポジトリは **Swift Package Manager 構成**（full Xcode 不要、Command Line Tools でも可）。理由と詳細は [`docs/開発環境.md`](docs/開発環境.md)。

```sh
make build     # swift build
make test      # swift-testing 実行
make format    # swiftformat .
make lint      # swiftlint --strict
make verify    # format(lint) → lint → build → test（push 前に実行）
```

- テストは XCTest ではなく **swift-testing**（`import Testing`）を使用。
- CI（[`.github/workflows/ci.yml`](.github/workflows/ci.yml)）は PR / push で `make verify` 相当を実行します。

## ドキュメント

- [`docs/要件定義.md`](docs/要件定義.md) — 機能要件（全24章）
- [`docs/アーキテクチャ.md`](docs/アーキテクチャ.md) — レイヤー構造・依存方向
- [`docs/フロントエンドアーキテクチャ.md`](docs/フロントエンドアーキテクチャ.md) / [`docs/フロントエンド規約.md`](docs/フロントエンド規約.md) — UI（SwiftUI）方針
- [`docs/リポジトリ層設計規約.md`](docs/リポジトリ層設計規約.md) — 永続化（SQLite / BookmarkData）
- [`docs/インフラストラクチャ規約.md`](docs/インフラストラクチャ規約.md) — ビルド・署名・配布・権限
- [`docs/スタイルガイド.md`](docs/スタイルガイド.md) — コーディング規約
- [`docs/テストガイドライン.md`](docs/テストガイドライン.md) / [`docs/品質チェック・テスト規約.md`](docs/品質チェック・テスト規約.md) — テスト・品質
- [`docs/実装計画.md`](docs/実装計画.md) — フェーズ別実装計画
- [`AGENTS.md`](AGENTS.md) — AI エージェント向けの開発指針

## ライセンス

[LICENSE](LICENSE) を参照。
