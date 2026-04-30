#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
CORE_DIR="$ROOT_DIR/hiddify-core/bin"
CORE_DYLIB="$CORE_DIR/hiddify-core.dylib"

if [[ -f "$CORE_DYLIB" ]]; then
  exit 0
fi

CORE_VERSION="$(sed -n 's/^core.version=//p' "$ROOT_DIR/dependencies.properties" | head -n 1)"
if [[ -z "$CORE_VERSION" ]]; then
  echo "error: core.version is missing in dependencies.properties" >&2
  exit 1
fi

CORE_BASE_URL="https://github.com/hiddify/hiddify-next-core/releases/download/draft"
if [[ "${CHANNEL:-dev}" == "prod" ]]; then
  CORE_BASE_URL="https://github.com/hiddify/hiddify-next-core/releases/download/v${CORE_VERSION}"
fi

ARCHIVE_URL="${HIDDIFY_CORE_MACOS_ARCHIVE_URL:-${CORE_BASE_URL}/hiddify-lib-macos.tar.gz}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$CORE_DIR"
echo "Downloading hiddify-core.dylib from $ARCHIVE_URL"
curl -fL "$ARCHIVE_URL" -o "$TMP_DIR/hiddify-lib-macos.tar.gz"
tar xzf "$TMP_DIR/hiddify-lib-macos.tar.gz" -C "$CORE_DIR"

if [[ ! -f "$CORE_DYLIB" ]]; then
  echo "error: hiddify-core.dylib was not extracted to $CORE_DYLIB" >&2
  exit 1
fi
