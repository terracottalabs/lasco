#!/usr/bin/env bash
# sign-local.sh — Codesign, notarize, staple, and optionally publish Lasco.app
#
# Usage:
#   ./sign-local.sh              # sign + notarize + staple + zip
#   ./sign-local.sh --sign-only  # just codesign (skip notarization)
#   ./sign-local.sh --dmg        # also create DMG after notarization
#   ./sign-local.sh --publish    # also upload ZIP + latest.json to R2 for OTA updates
#   ./sign-local.sh --dmg --publish  # full release: sign, notarize, DMG, publish
#
# Prerequisites:
#   - "Developer ID Application: Terracotta Cyber Solutions Limited (M4WGLKG3TR)" in keychain
#   - notarytool keychain profile "lasco" (xcrun notarytool store-credentials lasco)
#   - @electron/osx-sign installed in vscode/node_modules
#   - rclone with R2 remote configured (brew install rclone) — for --publish

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_DIR="${SCRIPT_DIR}/vscode"
ARCH="arm64"
APP_DIR="${SCRIPT_DIR}/VSCode-darwin-${ARCH}"
APP_PATH="${APP_DIR}/Lasco.app"
ENTITLEMENTS_DIR="${VSCODE_DIR}/build/azure-pipelines/darwin"
IDENTITY="Developer ID Application: Terracotta Cyber Solutions Limited (M4WGLKG3TR)"
NOTARY_PROFILE="lasco"
ELECTRON_VERSION="39.2.7"
VERSION="$(plutil -extract CFBundleShortVersionString raw "${APP_PATH}/Contents/Info.plist")"

SIGN_ONLY=false
BUILD_DMG=false
PUBLISH=false
RELEASES_BASE_URL="https://releases.lasco.dev"

for arg in "$@"; do
  case "$arg" in
    --sign-only) SIGN_ONLY=true ;;
    --dmg) BUILD_DMG=true ;;
    --publish) PUBLISH=true ;;
  esac
done

# ── Pre-flight checks ─────────────────────────────────────────────

echo "=== Lasco Code Signing ==="
echo "App:      ${APP_PATH}"
echo "Version:  ${VERSION}"
echo "Arch:     ${ARCH}"
echo "Identity: ${IDENTITY}"
echo ""

[ -d "${APP_PATH}" ] || { echo "Error: App not found at ${APP_PATH}"; exit 1; }
[ -d "${ENTITLEMENTS_DIR}" ] || { echo "Error: Entitlements dir not found"; exit 1; }

security find-identity -p codesigning -v | grep -q "M4WGLKG3TR" \
  || { echo "Error: Signing identity not in keychain"; exit 1; }

(cd "${VSCODE_DIR}" && node --input-type=module -e "import '@electron/osx-sign'" 2>/dev/null) \
  || { echo "Error: @electron/osx-sign not installed. Run: cd ${VSCODE_DIR} && npm install @electron/osx-sign"; exit 1; }

echo "Pre-flight checks passed."
echo ""

# ── Step 1: Codesign with @electron/osx-sign ──────────────────────

echo "[1/4] Signing app (this takes a few minutes)..."

cd "${VSCODE_DIR}"
node --input-type=module <<SIGNSCRIPT
import { sign } from '@electron/osx-sign';
import path from 'path';

const entDir = '${ENTITLEMENTS_DIR}';

function getEntitlements(filePath) {
  if (filePath.includes('Helper (GPU).app'))
    return path.join(entDir, 'helper-gpu-entitlements.plist');
  if (filePath.includes('Helper (Renderer).app'))
    return path.join(entDir, 'helper-renderer-entitlements.plist');
  if (filePath.includes('Helper (Plugin).app'))
    return path.join(entDir, 'helper-plugin-entitlements.plist');
  return path.join(entDir, 'app-entitlements.plist');
}

try {
  await sign({
    app: '${APP_PATH}',
    platform: 'darwin',
    identity: '${IDENTITY}',
    optionsForFile: (filePath) => ({
      entitlements: getEntitlements(filePath),
      hardenedRuntime: true,
    }),
    preAutoEntitlements: false,
    preEmbedProvisioningProfile: false,
    version: '${ELECTRON_VERSION}',
  });
  console.log('  Signing complete.');
} catch (err) {
  console.error('  Signing failed:', err.message || err);
  process.exit(1);
}
SIGNSCRIPT

echo ""

# ── Step 2: Verify signature ──────────────────────────────────────

echo "[2/4] Verifying signature..."
codesign --verify --deep --strict "${APP_PATH}" 2>&1 \
  && echo "  Signature valid." \
  || { echo "  Signature INVALID!"; exit 1; }
codesign -dv "${APP_PATH}" 2>&1 | grep -E "Authority|TeamIdentifier|Signature"
echo ""

if [ "$SIGN_ONLY" = true ]; then
  echo "Done (--sign-only). Skipping notarization."
  exit 0
fi

# ── Step 3: Notarize ──────────────────────────────────────────────

echo "[3/4] Notarizing (this may take several minutes)..."

mkdir -p "${SCRIPT_DIR}/assets"
ZIP_FILE="${APP_DIR}/Lasco-notarize-tmp.zip"

# Use ditto for macOS-native zip that preserves extended attributes
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_FILE}"
echo "  Zip created ($(du -h "${ZIP_FILE}" | cut -f1)), submitting..."

xcrun notarytool submit "${ZIP_FILE}" --keychain-profile "${NOTARY_PROFILE}" --wait
rm -f "${ZIP_FILE}"

echo ""

# ── Step 4: Staple ────────────────────────────────────────────────

echo "[4/4] Stapling notarization ticket..."
xcrun stapler staple "${APP_PATH}"
echo ""

# ── Output assets ─────────────────────────────────────────────────

echo "=== Creating distribution assets ==="

mkdir -p "${SCRIPT_DIR}/assets"
ASSET_ZIP="${SCRIPT_DIR}/assets/Lasco-darwin-${ARCH}-${VERSION}.zip"
rm -f "${ASSET_ZIP}"
ditto -c -k --keepParent "${APP_PATH}" "${ASSET_ZIP}"
echo "  ZIP: ${ASSET_ZIP} ($(du -h "${ASSET_ZIP}" | cut -f1))"

# DMG (always built for publishing, optional otherwise)
if [ "$BUILD_DMG" = true ] || [ "$PUBLISH" = true ]; then
  ASSET_DMG="${SCRIPT_DIR}/assets/Lasco-darwin-${ARCH}-${VERSION}.dmg"
  rm -f "${ASSET_DMG}"
  if command -v create-dmg &>/dev/null; then
    create-dmg \
      --volname "Lasco" \
      --background "${SCRIPT_DIR}/assets/dmg-background.png" \
      --window-pos 200 120 \
      --window-size 660 480 \
      --icon-size 120 \
      --icon "Lasco.app" 170 180 \
      --hide-extension "Lasco.app" \
      --app-drop-link 490 180 \
      --text-size 14 \
      "${ASSET_DMG}" \
      "${APP_PATH}" 2>&1 || true
    if [ -f "${ASSET_DMG}" ]; then
      echo "  DMG: ${ASSET_DMG} ($(du -h "${ASSET_DMG}" | cut -f1))"
    else
      echo "  DMG: creation failed"
      [ "$PUBLISH" = true ] && { echo "Error: DMG required for publishing"; exit 1; }
    fi
  else
    echo "  DMG: skipped (create-dmg not found — brew install create-dmg)"
    [ "$PUBLISH" = true ] && { echo "Error: DMG required for publishing"; exit 1; }
  fi
fi

echo ""

# ── Publish to R2 for OTA updates ────────────────────────────────

if [ "$PUBLISH" = true ]; then
  echo "=== Publishing OTA update to R2 ==="

  command -v rclone &>/dev/null \
    || { echo "Error: rclone not found. Run: brew install rclone"; exit 1; }

  ASSET_DMG="${SCRIPT_DIR}/assets/Lasco-darwin-${ARCH}-${VERSION}.dmg"
  [ -f "${ASSET_DMG}" ] || { echo "Error: DMG not found at ${ASSET_DMG}"; exit 1; }

  DMG_FILENAME="$(basename "${ASSET_DMG}")"
  SHA1_HASH="$(shasum -a 1 "${ASSET_DMG}" | awk '{print $1}')"
  SHA256_HASH="$(shasum -a 256 "${ASSET_DMG}" | awk '{print $1}')"
  BUILD_VERSION="$(echo -n "${VERSION}" | shasum -a 1 | awk '{print $1}')"
  TIMESTAMP="$(node -e 'console.log(Date.now())')"

  # Transform version: 1.108.2 → 1.108.2.0
  PRODUCT_VERSION="${VERSION}.0"

  # Generate latest.json
  LATEST_JSON=$(cat <<EOJSON
{
  "url": "${RELEASES_BASE_URL}/artifacts/${DMG_FILENAME}",
  "name": "${VERSION}",
  "version": "${BUILD_VERSION}",
  "productVersion": "${PRODUCT_VERSION}",
  "hash": "${SHA1_HASH}",
  "sha256hash": "${SHA256_HASH}",
  "timestamp": ${TIMESTAMP}
}
EOJSON
  )

  LATEST_JSON_FILE="${SCRIPT_DIR}/assets/latest.json"
  echo "${LATEST_JSON}" > "${LATEST_JSON_FILE}"

  echo "  latest.json:"
  cat "${LATEST_JSON_FILE}"
  echo ""

  # Upload DMG artifact (rclone remote already points to lasco-releases bucket)
  echo "  Uploading ${DMG_FILENAME} to R2..."
  rclone copyto "${ASSET_DMG}" "r2:artifacts/${DMG_FILENAME}"

  # Upload latest.json
  R2_MANIFEST_KEY="stable/darwin/${ARCH}/latest.json"
  echo "  Uploading ${R2_MANIFEST_KEY} to R2..."
  rclone copyto "${LATEST_JSON_FILE}" "r2:${R2_MANIFEST_KEY}"

  rm -f "${LATEST_JSON_FILE}"

  echo ""
  echo "  Published! Verify:"
  echo "    curl ${RELEASES_BASE_URL}/${R2_MANIFEST_KEY}"
  echo ""
fi

echo "=== Done ==="
echo ""
spctl --assess -vv --type install "${APP_PATH}" 2>&1 || true
echo ""
echo "Distribution zip: ${ASSET_ZIP}"
