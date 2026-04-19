#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DEST="/mnt/c/Users/velunae/Desktop/mvp-vpn"
DEST="${1:-${WINDOW_F:-$DEFAULT_DEST}}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "The script directory is not inside a git repository."
  exit 1
fi

REPO_ROOT="$SCRIPT_DIR"
cd "$REPO_ROOT"

mkdir -p "$DEST"

copied=0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue

  case "$file" in
    hiddify-core/*) continue ;;
    build/*) continue ;;
    .dart_tool/*) continue ;;
    .idea/*) continue ;;
  esac

  mkdir -p "$DEST/$(dirname "$file")"
  cp "$file" "$DEST/$file"
  printf 'copied: %s\n' "$file"
  copied=$((copied + 1))
done < <(git -C "$REPO_ROOT" ls-files -m -o --exclude-standard)

for generated in \
  lib/gen/translations.g.dart \
  lib/gen/translations_*.g.dart \
  lib/core/localization/locale_preferences.g.dart
do
  for file in $generated; do
    [ -f "$file" ] || continue
    mkdir -p "$DEST/$(dirname "$file")"
    cp "$file" "$DEST/$file"
    printf 'copied: %s\n' "$file"
    copied=$((copied + 1))
  done
done

printf '\nDone. Copied %d file(s) to %s\n' "$copied" "$DEST"
