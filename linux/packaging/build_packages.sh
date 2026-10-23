#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
ARCH="amd64"
APP_NAME="focus-oasis"
APP_TITLE="Focus Oasis"
BUNDLE_DIR="build/linux/x64/release/bundle"
OUTPUT_DIR="dist"

echo "=========================================="
echo "Packaging ${APP_TITLE} v${VERSION} for Linux"
echo "=========================================="

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Bundle directory '$BUNDLE_DIR' not found."
    echo "Please run 'flutter build linux --release' first."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ----------------------------------------------------
# 1. Create Tarball (.tar.gz)
# ----------------------------------------------------
echo "==> Creating release archive (.tar.gz)..."
TARBALL_NAME="${APP_NAME}-${VERSION}-linux-x64.tar.gz"
tar -czvf "${OUTPUT_DIR}/${TARBALL_NAME}" -C "$BUNDLE_DIR" .
echo "Created ${OUTPUT_DIR}/${TARBALL_NAME}"

# ----------------------------------------------------
# 2. Create Debian Package (.deb)
# ----------------------------------------------------
echo "==> Creating Debian package (.deb)..."
DEB_DIR="build/deb_pkg"
rm -rf "$DEB_DIR"

mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/usr/lib/${APP_NAME}"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/share/applications"
mkdir -p "${DEB_DIR}/usr/share/metainfo"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/512x512/apps"

# Copy binary bundle
cp -r "${BUNDLE_DIR}/"* "${DEB_DIR}/usr/lib/${APP_NAME}/"

# Launcher symlinks (supports both focus-oasis and focus_oasis commands)
ln -s "/usr/lib/${APP_NAME}/focus_oasis" "${DEB_DIR}/usr/bin/${APP_NAME}"
ln -s "/usr/lib/${APP_NAME}/focus_oasis" "${DEB_DIR}/usr/bin/focus_oasis"

# Desktop & metadata
cp linux/packaging/io.github.ashrafcode519.focus_oasis.desktop "${DEB_DIR}/usr/share/applications/"
cp linux/packaging/io.github.ashrafcode519.focus_oasis.metainfo.xml "${DEB_DIR}/usr/share/metainfo/"
cp linux/packaging/io.github.ashrafcode519.focus_oasis.png "${DEB_DIR}/usr/share/icons/hicolor/512x512/apps/"

# Control file
cat <<EOF > "${DEB_DIR}/DEBIAN/control"
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: AshrafCode519 <https://github.com/AshrafCode519>
Depends: libgtk-3-0, liblzma5, libgstreamer1.0-0, gstreamer1.0-plugins-base, gstreamer1.0-plugins-good
Description: Smart Pomodoro timer with gamified tree planting and cloud sync
 Focus Oasis (واحة التركيز) combines the proven Pomodoro Technique with
 virtual forest gamification to help you stay focused, defeat procrastination,
 and cultivate deep work habits.
EOF

dpkg-deb --build --root-owner-group "${DEB_DIR}" "${OUTPUT_DIR}/${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "Created ${OUTPUT_DIR}/${APP_NAME}_${VERSION}_${ARCH}.deb"

# ----------------------------------------------------
# 3. Create AppImage (.AppImage)
# ----------------------------------------------------
if command -v appimagetool &> /dev/null || [ -f "./appimagetool" ]; then
    echo "==> Creating AppImage..."
    APPDIR="build/AppDir"
    rm -rf "$APPDIR"
    mkdir -p "${APPDIR}/usr/bin"
    mkdir -p "${APPDIR}/usr/lib"
    mkdir -p "${APPDIR}/usr/share/applications"
    mkdir -p "${APPDIR}/usr/share/icons/hicolor/512x512/apps"

    cp -r "${BUNDLE_DIR}/"* "${APPDIR}/usr/bin/"
    cp linux/packaging/io.github.ashrafcode519.focus_oasis.desktop "${APPDIR}/"
    cp linux/packaging/io.github.ashrafcode519.focus_oasis.desktop "${APPDIR}/usr/share/applications/"
    cp linux/packaging/io.github.ashrafcode519.focus_oasis.png "${APPDIR}/"
    cp linux/packaging/io.github.ashrafcode519.focus_oasis.png "${APPDIR}/usr/share/icons/hicolor/512x512/apps/"
    ln -s usr/bin/focus_oasis "${APPDIR}/AppRun"
    chmod +x "${APPDIR}/AppRun"

    TOOL="appimagetool"
    if [ -f "./appimagetool" ]; then
        TOOL="./appimagetool"
    fi

    ARCH=x86_64 $TOOL "$APPDIR" "${OUTPUT_DIR}/FocusOasis-${VERSION}-x86_64.AppImage"
    echo "Created ${OUTPUT_DIR}/FocusOasis-${VERSION}-x86_64.AppImage"
else
    echo "==> Note: appimagetool not found locally, skipping AppImage step (handled in CI)."
fi

echo "=========================================="
echo "Packaging Complete! Artifacts in ${OUTPUT_DIR}:"
ls -la "${OUTPUT_DIR}"
echo "=========================================="
