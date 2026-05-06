#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DEST="/mnt/c/Users/velunae/Desktop/mvp-vpn"
DEST="${1:-${WINDOW_F:-$DEFAULT_DEST}}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"
mkdir -p "$DEST"

should_skip() {
  case "$1" in
    *.tsbuildinfo) return 0 ;;
    ./.git/*|./.dart_tool/*|./build/*|./dist/*|./hiddify-core/*|./.idea/*|./.sentry-native/*|./noda-web/data/*|*/node_modules/*|*/dist/*) return 0 ;;
    ./.git|./.dart_tool|./build|./dist|./hiddify-core|./.idea|./.sentry-native|./noda-web/data|*/node_modules|*/dist) return 0 ;;
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
    \( -path './.git' -o -path './.dart_tool' -o -path './build' -o -path './dist' -o -path './hiddify-core' -o -path './.idea' -o -path './.sentry-native' -o -path './noda-web/data' -o -path '*/node_modules' -o -path '*/dist' \) -prune \
    -o -type f -print0
)

printf '\nDone. Copied %d file(s) to %s\n' "$copied" "$DEST"
