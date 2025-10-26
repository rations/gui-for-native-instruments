#!/bin/bash
set -euo pipefail
# Simple packaging helper to build a single-architecture amd64 .deb for vst_installer
#
# Usage:
#   ./pack-deb.sh VERSION
# Example:
#   ./pack-deb.sh 0.1.0
#
# This script expects the repository root contains:
# - vst_installer.sh (the GUI script)
# - debian/ control files (if not present, this script will create sensible defaults)
#
# Output: ./dist/vst-installer_${VERSION}_amd64.deb

PKG_NAME="vst-installer"
ARCH="amd64"
DEST_DIR="dist"

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 VERSION"
  exit 2
fi

VERSION="$1"
MAINTAINER="Your Name <you@example.com>"
DESCRIPTION="GUI wrapper to install Native Instruments VSTs using Wine and yabridge."
DEPENDENCIES="zenity, wine"

# Paths
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEBIAN_DIR="$REPO_ROOT/debian"
PKG_BUILD_DIR="$(mktemp -d)"
INSTALL_PREFIX="$PKG_BUILD_DIR/usr/bin"
USR_SHARE_DIR="$PKG_BUILD_DIR/usr/share/$PKG_NAME"

echo "Preparing package layout in $PKG_BUILD_DIR"

# Ensure required files exist
if [ ! -f "$REPO_ROOT/vst_installer.sh" ]; then
  echo "Error: vst_installer.sh not found in repository root."
  exit 1
fi

mkdir -p "$INSTALL_PREFIX"
mkdir -p "$USR_SHARE_DIR"
mkdir -p "$DEST_DIR"

# Copy the main script into the package tree (do not use an intermediate INSTALL_PREFIX inside the build dir)
mkdir -p "$PKG_BUILD_DIR/usr/bin"
cp "$REPO_ROOT/vst_installer.sh" "$PKG_BUILD_DIR/usr/bin/$PKG_NAME"
chmod 755 "$PKG_BUILD_DIR/usr/bin/$PKG_NAME"

# Install any supporting files (none required now, placeholder)
# cp -r "$REPO_ROOT/assets" "$USR_SHARE_DIR" || true

# Create debian control metadata if not present
if [ ! -d "$DEBIAN_DIR" ]; then
  echo "Creating minimal debian/ control files"
  mkdir -p "$DEBIAN_DIR"
  cat > "$DEBIAN_DIR/control" <<EOF
Source: $PKG_NAME
Section: utils
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper (>= 9)
Standards-Version: 4.5.0
Homepage: https://github.com/your-username/vst_installer

Package: $PKG_NAME
Architecture: $ARCH
Depends: ${DEPENDENCIES}
Description: $DESCRIPTION
EOF

  # postinst for any runtime setup (optional: create desktop entry later)
  cat > "$DEBIAN_DIR/postinst" <<'EOPOST'
#!/bin/sh
set -e
# post-install: ensure executable is owned correctly
if [ -e /usr/bin/vst-installer ]; then
  chmod 755 /usr/bin/vst-installer
fi
exit 0
EOPOST
  chmod 755 "$DEBIAN_DIR/postinst"

  # prerm to allow clean removal (no-op)
  cat > "$DEBIAN_DIR/prerm" <<'EOPRERM'
#!/bin/sh
set -e
# pre-removal hook (no special actions)
exit 0
EOPRERM
  chmod 755 "$DEBIAN_DIR/prerm"
fi

# Create control file inside package (DEBIAN/control)
mkdir -p "$PKG_BUILD_DIR/DEBIAN"
# Always generate a minimal, complete DEBIAN/control to avoid parsing issues with multi-stanza debian/control
cat > "$PKG_BUILD_DIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: $DEPENDENCIES
Description: $DESCRIPTION
EOF

# Ensure a usable DEBIAN/control exists with all required fields
# If not present or incomplete, overwrite with a minimal valid control file.
need_write=0
if [ ! -f "$PKG_BUILD_DIR/DEBIAN/control" ]; then
  need_write=1
else
  # Check for at least Package and Version and Architecture fields
  if ! grep -q '^Package:' "$PKG_BUILD_DIR/DEBIAN/control" || ! grep -q '^Version:' "$PKG_BUILD_DIR/DEBIAN/control" || ! grep -q '^Architecture:' "$PKG_BUILD_DIR/DEBIAN/control"; then
    need_write=1
  fi
fi

if [ "$need_write" -eq 1 ]; then
  cat > "$PKG_BUILD_DIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: $DEPENDENCIES
Description: $DESCRIPTION
EOF
else
  # Ensure Version/Architecture fields exist (add if missing)
  if ! grep -q '^Version:' "$PKG_BUILD_DIR/DEBIAN/control"; then
    sed -i "1iVersion: $VERSION" "$PKG_BUILD_DIR/DEBIAN/control"
  fi
  if ! grep -q '^Architecture:' "$PKG_BUILD_DIR/DEBIAN/control"; then
    sed -i "1iArchitecture: $ARCH" "$PKG_BUILD_DIR/DEBIAN/control"
  fi
fi

# Copy maintainer scripts if available
if [ -f "$DEBIAN_DIR/postinst" ]; then
  cp "$DEBIAN_DIR/postinst" "$PKG_BUILD_DIR/DEBIAN/postinst"
  chmod 755 "$PKG_BUILD_DIR/DEBIAN/postinst"
fi
if [ -f "$DEBIAN_DIR/prerm" ]; then
  cp "$DEBIAN_DIR/prerm" "$PKG_BUILD_DIR/DEBIAN/prerm"
  chmod 755 "$PKG_BUILD_DIR/DEBIAN/prerm"
fi

# (Files already placed into the package tree earlier)
# Ensure usr/bin exists (idempotent)
mkdir -p "$PKG_BUILD_DIR/usr/bin"

# Optionally add a simple desktop entry /usr/share/applications (not required)
mkdir -p "$PKG_BUILD_DIR/usr/share/applications"
cat > "$PKG_BUILD_DIR/usr/share/applications/$PKG_NAME.desktop" <<EOF
[Desktop Entry]
Name=VST Installer
Exec=/usr/bin/$PKG_NAME
Type=Application
Categories=Utility;
EOF

# Set permissions
find "$PKG_BUILD_DIR" -type d -exec chmod 755 {} \;
find "$PKG_BUILD_DIR" -type f -exec chmod 644 {} \;
# Ensure maintainer scripts in DEBIAN have executable bit (dpkg-deb requires 0555-0775)
if [ -f "$PKG_BUILD_DIR/DEBIAN/postinst" ]; then
  chmod 755 "$PKG_BUILD_DIR/DEBIAN/postinst"
fi
if [ -f "$PKG_BUILD_DIR/DEBIAN/prerm" ]; then
  chmod 755 "$PKG_BUILD_DIR/DEBIAN/prerm"
fi
chmod 755 "$PKG_BUILD_DIR/usr/bin/$PKG_NAME"
chmod 644 "$PKG_BUILD_DIR/usr/share/applications/$PKG_NAME.desktop"

# Build the package
OUT_FILE="$DEST_DIR/${PKG_NAME}_${VERSION}_${ARCH}.deb"
echo "Building $OUT_FILE"
dpkg-deb --build "$PKG_BUILD_DIR" "$OUT_FILE"

# Cleanup
rm -rf "$PKG_BUILD_DIR"
echo "Package created: $OUT_FILE"
echo "You can install it with: sudo apt install ./$OUT_FILE"