#!/usr/bin/env bash
#
# Quality gate for NotchHub (品質チェック・テスト規約.md).
# Runs the full verify pipeline; any failure aborts with a non-zero status.
#
# Note: the project uses a Swift Package Manager configuration, so the build /
# test steps use `swift build` / `swift test` rather than `xcodebuild`.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> SwiftFormat (lint)"
swiftformat --lint .

echo "==> SwiftLint"
./scripts/swiftlint.sh --strict

echo "==> Build"
swift build

echo "==> Test"
./scripts/swift-test.sh

echo "All checks passed."
