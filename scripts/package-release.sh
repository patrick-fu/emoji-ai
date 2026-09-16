#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="EmojiAI"
VERSION="1.0.0"
ARCH="arm64"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
ZIP_NAME="${APP_NAME}-${VERSION}-${ARCH}.zip"
ZIP_PATH="${DIST_DIR}/${ZIP_NAME}"
SIGNING_IDENTITY="Developer ID Application: Patrick Fu (9N7UKH59LC)"
NOTARY_PROFILE="CodingAgentMetricsNotary"

export https_proxy="${https_proxy:-http://127.0.0.1:7897}"
export http_proxy="${http_proxy:-http://127.0.0.1:7897}"

echo "==> Step 1: Building ${APP_NAME} for ${ARCH} (release mode)..."
cd "${ROOT_DIR}"
swift build -c release --arch "${ARCH}"

echo "==> Step 2: Preparing distribution bundle..."
if [ -d "${APP_BUNDLE}" ]; then
    trash "${APP_BUNDLE}" 2>/dev/null || true
fi
if [ -f "${ZIP_PATH}" ]; then
    trash "${ZIP_PATH}" 2>/dev/null || true
fi

mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources/EmojiAI_EmojiAICore.bundle"

cp "${ROOT_DIR}/.build/${ARCH}-apple-macosx/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cp "${DIST_DIR}/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "${DIST_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
cp "${ROOT_DIR}/Sources/EmojiAICore/Resources/emoji.json" "${APP_BUNDLE}/Contents/Resources/emoji.json"
cp "${ROOT_DIR}/Sources/EmojiAICore/Resources/emoji.json" "${APP_BUNDLE}/Contents/Resources/EmojiAI_EmojiAICore.bundle/emoji.json"

cat > "${APP_BUNDLE}/Contents/Resources/EmojiAI_EmojiAICore.bundle/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.patrickfu.EmojiAI.resources</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>EmojiAI_EmojiAICore</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST

echo "==> Step 3: Clearing extended attributes and codesigning..."
xattr -cr "${APP_BUNDLE}"

codesign --force --options runtime --timestamp \
    --sign "${SIGNING_IDENTITY}" \
    "${APP_BUNDLE}/Contents/Resources/EmojiAI_EmojiAICore.bundle"

codesign --force --options runtime --timestamp \
    --entitlements "${DIST_DIR}/Entitlements.plist" \
    --sign "${SIGNING_IDENTITY}" \
    "${APP_BUNDLE}"

codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

echo "==> Step 4: Compressing bundle for notarization submission..."
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "==> Step 5: Submitting to Apple Notary Service..."
xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait

echo "==> Step 6: Stapling ticket to application bundle..."
xcrun stapler staple "${APP_BUNDLE}"
xcrun stapler validate "${APP_BUNDLE}"

echo "==> Step 7: Verifying Gatekeeper assessment..."
spctl --assess --type execute --verbose "${APP_BUNDLE}"

echo "==> Step 8: Creating final stapled release zip..."
trash "${ZIP_PATH}" 2>/dev/null || true
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "==> Done! Release artifact ready at: ${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}"
