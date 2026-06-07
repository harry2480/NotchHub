#!/usr/bin/env bash
#
# Runs SwiftLint, pointing it at the Command Line Tools' SourceKit framework when
# a full Xcode is not installed (SwiftLint otherwise fails to dlopen
# sourcekitdInProc.framework). Under full Xcode this is a no-op. Arguments are
# forwarded to `swiftlint`.
set -euo pipefail

cd "$(dirname "$0")/.."

developer_dir="$(xcode-select -p 2>/dev/null || true)"

if [[ "$developer_dir" == *CommandLineTools* ]]; then
    lib_dir="$developer_dir/usr/lib"
    if [[ -d "$lib_dir/sourcekitdInProc.framework" ]]; then
        export DYLD_FRAMEWORK_PATH="$lib_dir${DYLD_FRAMEWORK_PATH:+:$DYLD_FRAMEWORK_PATH}"
    fi
fi

exec swiftlint "$@"
