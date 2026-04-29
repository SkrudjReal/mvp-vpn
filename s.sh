#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DEST="/mnt/c/Users/velunae/Desktop/mvp-vpn"
DEST="${1:-${WINDOW_F:-$DEFAULT_DEST}}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"
mkdir -p "$DEST"

should_skip() {
  case "$1" in
    ./.git/*|./.dart_tool/*|./build/*|./hiddify-core/*|./.idea/*|./.sentry-native/*) return 0 ;;
    ./.git|./.dart_tool|./build|./hiddify-core|./.idea|./.sentry-native) return 0 ;;
  esac
  return 1
}

copied=0

while IFS= read -r -d '' src; do
  should_skip "$src" && continue

  rel="${src#./}"
  dst="$DEST/$rel"

  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
  printf 'copied: %s\n' "$rel"
  copied=$((copied + 1))
done < <(
  find . \
    \( -path './.git' -o -path './.dart_tool' -o -path './build' -o -path './hiddify-core' -o -path './.idea' -o -path './.sentry-native' \) -prune \
    -o -type f -print0
)

printf '\nDone. Copied %d file(s) to %s\n' "$copied" "$DEST"
