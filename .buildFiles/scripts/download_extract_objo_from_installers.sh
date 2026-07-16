#!/usr/bin/env bash

# script was used to fetch Objo Studio for each platform, extract objo or objo.exe
# create 7z archive and later upload it to SFTP server

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

mkdir -p downloads extracted mac linux windows

MAC_FILE="Objo-Studio-${VERSION}-macOS-arm64.dmg"
LINUX_FILE="Objo-Studio-${VERSION}-linux-x64.tar.gz"
WIN_FILE="Objo-Studio-${VERSION}-win-x64.msix"

download_if_missing() {
    local url="$1"
    local file="$2"

    if [[ -f "$file" ]]; then
        echo "Using existing $(basename "$file")"
    else
        echo "Downloading $(basename "$file")..."
        curl -fL "$url" -o "$file"
    fi
}

download_if_missing \
    "${DOWNLOAD_BASE}/${VERSION}/${MAC_FILE}" \
    "downloads/${MAC_FILE}"

download_if_missing \
    "${DOWNLOAD_BASE}/${VERSION}/${LINUX_FILE}" \
    "downloads/${LINUX_FILE}"

download_if_missing \
    "${DOWNLOAD_BASE}/${VERSION}/${WIN_FILE}" \
    "downloads/${WIN_FILE}"

echo "Extracting macOS executable..."

if [[ -f "mac/objo" ]]; then
    echo "Using existing mac/objo"
else
    MOUNT_POINT=$(
        hdiutil attach "downloads/${MAC_FILE}" -nobrowse |
        awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}'
    )

    if [[ -z "$MOUNT_POINT" ]]; then
        echo "Could not determine DMG mount point" >&2
        exit 1
    fi

    echo "Mounted at: $MOUNT_POINT"

    MAC_EXE=$(
        find "$MOUNT_POINT" \
            -path "*/Objo Studio.app/Contents/MacOS/objo" \
            -type f \
            | head -n1
    )

    if [[ -z "$MAC_EXE" ]]; then
        echo "Could not find macOS objo executable inside DMG" >&2
        find "$MOUNT_POINT" -maxdepth 4
        hdiutil detach "$MOUNT_POINT" -quiet
        exit 1
    fi

    cp "$MAC_EXE" "mac/objo"
    chmod +x "mac/objo"

    hdiutil detach "$MOUNT_POINT" -quiet
fi

echo "Extracting Linux executable..."

if [[ -f "linux/objo" ]]; then
    echo "Using existing linux/objo"
else
    rm -rf extracted/linux
    mkdir -p extracted/linux

    tar -xzf "downloads/${LINUX_FILE}" -C extracted/linux

    LINUX_EXE=$(
        find extracted/linux \
            -type f \
            -name objo \
            | head -n1
    )

    if [[ -z "$LINUX_EXE" ]]; then
        echo "Could not find Linux objo executable" >&2
        exit 1
    fi

    cp "$LINUX_EXE" "linux/objo"
    chmod +x "linux/objo"
fi

echo "Extracting Windows executable..."

if [[ -f "windows/objo.exe" ]]; then
    echo "Using existing windows/objo.exe"
else
    rm -rf extracted/windows
    mkdir -p extracted/windows

    unzip -q "downloads/${WIN_FILE}" -d extracted/windows

    WIN_EXE=$(
        find extracted/windows \
            -type f \
            -iname objo.exe \
            | head -n1
    )

    if [[ -z "$WIN_EXE" ]]; then
        echo "Could not find Windows objo.exe" >&2
        exit 1
    fi

    cp "$WIN_EXE" "windows/objo.exe"
fi

VERSION_UNDERSCORE="${VERSION//./_}"

echo "Creating 7z archives..."

7zz a -t7z "objo_mac_${VERSION_UNDERSCORE}.7z" "mac/objo"
7zz a -t7z "objo_linux_${VERSION_UNDERSCORE}.7z" "linux/objo"
7zz a -t7z "objo_win_${VERSION_UNDERSCORE}.7z" "windows/objo.exe"

echo
echo "Finished:"
echo "  mac/objo"
echo "  linux/objo"
echo "  windows/objo.exe"
echo
echo "Archives:"
echo "  objo_mac_${VERSION_UNDERSCORE}.7z"
echo "  objo_linux_${VERSION_UNDERSCORE}.7z"
echo "  objo_windows_${VERSION_UNDERSCORE}.7z"

