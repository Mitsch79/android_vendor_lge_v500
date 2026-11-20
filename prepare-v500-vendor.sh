#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tree=$(realpath "${1:-.}")
test -f "$tree/device/lge/v500/BoardConfig.mk"
bash "$here/prepare-mesa23.sh" "$tree"
for patch in mesa23-prime-mmap mesa23-android-display-fd mesa23-freedreno-cache-build-id; do
    if ! git -C "$tree/external/mesa3d-v500" apply --reverse --check "$here/$patch.patch" 2>/dev/null; then
        git -C "$tree/external/mesa3d-v500" apply "$here/$patch.patch"
    fi
done
