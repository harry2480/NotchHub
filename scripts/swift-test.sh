#!/usr/bin/env bash
#
# Runs `swift test`, adding the framework search path / rpath needed to locate
# swift-testing when only the Command Line Tools (no full Xcode) are installed.
# Under a full Xcode toolchain `swift test` finds Testing natively, so no extra
# flags are added. Any arguments are forwarded to `swift test`.
set -euo pipefail

cd "$(dirname "$0")/.."

developer_dir="$(xcode-select -p 2>/dev/null || true)"
extra=()

if [[ "$developer_dir" == *CommandLineTools* ]]; then
    frameworks="$developer_dir/Library/Developer/Frameworks"
    interop="$developer_dir/Library/Developer/usr/lib"
    if [[ -d "$frameworks/Testing.framework" ]]; then
        extra=(
            -Xswiftc -F -Xswiftc "$frameworks"
            -Xlinker -F -Xlinker "$frameworks"
            -Xlinker -rpath -Xlinker "$frameworks"
            -Xlinker -rpath -Xlinker "$interop"
        )
    fi
fi

exec swift test "${extra[@]}" "$@"
