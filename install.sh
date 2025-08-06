#!/usr/bin/env bash
set -e

REPO="MatejKis/zuite"
VERSION="0.1.0"
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64 | arm64) ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

FILENAME="zuite-${VERSION}-${OS}-${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${FILENAME}"

INSTALL_DIR="$HOME/.local/bin"
TMPDIR=$(mktemp -d)

echo "TMPDIR = $TMPDIR"
echo "FILENAME = $FILENAME"
echo "Download path: $TMPDIR/$FILENAME"

echo "Downloading $URL"
curl -L "$URL" -o "$TMPDIR/$FILENAME"

echo "Extracting..."
tar -xzf "$TMPDIR/$FILENAME" -C "$TMPDIR"

echo "Installing to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mv "$TMPDIR/zuite" "$INSTALL_DIR/zuite"
chmod +x "$INSTALL_DIR/zuite"

rm -rf "$TMPDIR"

echo "Installed zuite to $INSTALL_DIR/zuite"

if ! command -v zuite &> /dev/null; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "Add this line to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "Done! You can now run 'zuite'."

