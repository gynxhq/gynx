#!/usr/bin/env sh
set -eu

REPO="gynxHQ/gynx"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

info() {
  printf "→ %s\n" "$1"
}

success() {
  printf "✔ %s\n" "$1"
}

fail() {
  printf "✖ %s\n" "$1" >&2
  exit 1
}

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLATFORM="darwin"; OS_NAME="macOS" ;;
  Linux) PLATFORM="linux"; OS_NAME="Linux" ;;
  *) fail "Unsupported OS: $OS" ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) fail "Unsupported architecture: $ARCH" ;;
esac

VERSION="${VERSION:-latest}"

if [ "$VERSION" = "latest" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"
fi

[ -n "$VERSION" ] || fail "Could not determine latest release version"

FILENAME="gynx_${VERSION#v}_${PLATFORM}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo "Installing Gynx..."
success "Detecting platform        $OS_NAME ($ARCH)"
success "Fetching version          $VERSION"
info "Downloading binary..."

if ! curl -fL "$URL" -o "$TMP_DIR/gynx.tar.gz"; then
  fail "Download failed: $URL"
fi

tar -xzf "$TMP_DIR/gynx.tar.gz" -C "$TMP_DIR"

mkdir -p "$INSTALL_DIR" || true

if install "$TMP_DIR/gynx" "$INSTALL_DIR/gynx" 2>/dev/null; then
  success "Installing to             $INSTALL_DIR"
else
  info "Permission required, retrying with sudo..."
  sudo install "$TMP_DIR/gynx" "$INSTALL_DIR/gynx"
  success "Installing to             $INSTALL_DIR"
fi

if ln -sf "$INSTALL_DIR/gynx" "$INSTALL_DIR/gx" 2>/dev/null; then
  success "Creating alias            gx"
else
  info "Permission required for alias, retrying with sudo..."
  sudo ln -sf "$INSTALL_DIR/gynx" "$INSTALL_DIR/gx"
  success "Creating alias            gx"
fi

echo ""
echo "Gynx installed successfully"
echo ""
echo "Run:"
echo "  gynx version"
echo ""
"$INSTALL_DIR/gynx" version
