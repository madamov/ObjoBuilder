#!/usr/bin/env bash
set -euo pipefail

BASE_PAGE="https://objo.dev/download"
DOWNLOAD_BASE="https://downloads.objo.dev/releases"

VERSION=$(
  curl -fsSL "$BASE_PAGE" |
  grep -oE 'Latest version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' |
  head -n1 |
  sed -E 's/Latest version:[[:space:]]*//'
)

if [[ -z "$VERSION" ]]; then
  echo "Could not detect latest version" >&2
  exit 1
fi

echo "Latest version: $VERSION"

mkdir -p downloads

MAC_FILE="Objo-Studio-${VERSION}-macOS-arm64.dmg"
WIN_FILE="Objo-Studio-${VERSION}-win-x64.msix"
LINUX_FILE="Objo-Studio-${VERSION}-linux-x64.tar.gz"

curl -fL \
  "${DOWNLOAD_BASE}/${VERSION}/${MAC_FILE}" \
  -o "downloads/${MAC_FILE}"

curl -fL \
  "${DOWNLOAD_BASE}/${VERSION}/${WIN_FILE}" \
  -o "downloads/${WIN_FILE}"

curl -fL \
  "${DOWNLOAD_BASE}/${VERSION}/${LINUX_FILE}" \
  -o "downloads/${LINUX_FILE}"

echo "Downloaded:"
echo "downloads/${MAC_FILE}"
echo "downloads/${WIN_FILE}"
echo "downloads/${LINUX_FILE}"
