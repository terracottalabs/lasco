#!/usr/bin/env bash
#
# fix-win32-natives.sh
#
# Replaces Mach-O arm64 native addons in VSCode-win32-x64/ with correct
# PE32+ x86-64 binaries so the Electron app can run on Windows.
#
# Run from the vscodium project root (where VSCode-win32-x64/ lives).
#
# Usage:
#   chmod +x fix-win32-natives.sh
#   ./fix-win32-natives.sh
#
set -euo pipefail

###############################################################################
# Configuration
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

WIN_BUILD="$PROJECT_ROOT/VSCode-win32-x64"
WIN_APP="$WIN_BUILD/resources/app"
WIN_MODULES="$WIN_APP/node_modules"
SRC_MODULES="$PROJECT_ROOT/vscode/node_modules"

ELECTRON_VERSION="39.3.0"
WORK_DIR="$PROJECT_ROOT/.win32-cross-build"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

passed=0
failed=0
skipped=0
failed_modules=()

###############################################################################
# Helpers
###############################################################################
log()   { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; ((passed++)) || true; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; ((skipped++)) || true; }
err()   { echo -e "${RED}[FAIL]${NC} $*"; ((failed++)) || true; }
die()   { echo -e "${RED}[FATAL]${NC} $*" >&2; exit 1; }

verify_pe32() {
    local f="$1"
    local label="${2:-$f}"
    if file "$f" | grep -q "PE32+"; then
        ok "$label -> PE32+ x86-64"
        return 0
    else
        err "$label -> $(file "$f" | cut -d: -f2-)"
        return 1
    fi
}

###############################################################################
# Pre-flight checks
###############################################################################
log "=== Cross-compile Lasco natives for Windows x64 ==="
log ""

[[ -d "$WIN_BUILD" ]] || die "VSCode-win32-x64/ not found at $WIN_BUILD"
[[ -d "$SRC_MODULES" ]] || die "vscode/node_modules/ not found at $SRC_MODULES"

# Check for node/npm
command -v node >/dev/null 2>&1 || die "node not found"
command -v npm >/dev/null 2>&1 || die "npm not found"

mkdir -p "$WORK_DIR"

###############################################################################
# Step 0: Check/install llvm-mingw toolchain
###############################################################################
log "Step 0: Checking cross-compilation toolchain..."

if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    log "mingw-w64 already available: $(which x86_64-w64-mingw32-gcc)"
else
    log "Installing mingw-w64 via Homebrew..."
    if command -v brew >/dev/null 2>&1; then
        brew install mingw-w64
    else
        die "Homebrew not found. Install mingw-w64 manually: brew install mingw-w64"
    fi
fi

# Verify the toolchain
command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 || die "x86_64-w64-mingw32-gcc not found after install"
command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1 || die "x86_64-w64-mingw32-g++ not found after install"
command -v x86_64-w64-mingw32-ar  >/dev/null 2>&1 || die "x86_64-w64-mingw32-ar not found after install"
MINGW_CC="$(which x86_64-w64-mingw32-gcc)"
MINGW_CXX="$(which x86_64-w64-mingw32-g++)"
MINGW_AR="$(which x86_64-w64-mingw32-ar)"
MINGW_PREFIX="$(dirname "$MINGW_CC")"

# Find the mingw sysroot for headers/libs
MINGW_SYSROOT=""
for candidate in \
    "$(dirname "$MINGW_PREFIX")/x86_64-w64-mingw32" \
    "/opt/homebrew/opt/llvm-mingw/x86_64-w64-mingw32" \
    "/usr/local/opt/llvm-mingw/x86_64-w64-mingw32"; do
    if [[ -d "$candidate/include" ]]; then
        MINGW_SYSROOT="$candidate"
        break
    fi
done

if [[ -z "$MINGW_SYSROOT" ]]; then
    # Try to find it relative to the gcc binary
    MINGW_SYSROOT="$(x86_64-w64-mingw32-gcc -print-sysroot 2>/dev/null || true)"
    if [[ -z "$MINGW_SYSROOT" || ! -d "$MINGW_SYSROOT" ]]; then
        # Last resort: search common locations
        MINGW_SYSROOT="$(find /opt/homebrew /usr/local -name "x86_64-w64-mingw32" -type d 2>/dev/null | head -1 || true)"
    fi
fi

log "MinGW sysroot: ${MINGW_SYSROOT:-NOT FOUND}"

###############################################################################
# Step 1: Download Electron headers for win32-x64
###############################################################################
log ""
log "Step 1: Fetching Electron ${ELECTRON_VERSION} headers for win32-x64..."

ELECTRON_HEADERS_DIR="$WORK_DIR/electron-headers"
ELECTRON_HEADER_TARBALL="$WORK_DIR/electron-v${ELECTRON_VERSION}-headers.tar.gz"

if [[ ! -f "$ELECTRON_HEADERS_DIR/include/node/node_api.h" ]]; then
    mkdir -p "$ELECTRON_HEADERS_DIR"
    HEADERS_URL="https://electronjs.org/headers/v${ELECTRON_VERSION}/node-v${ELECTRON_VERSION}-headers.tar.gz"
    log "Downloading from $HEADERS_URL ..."
    curl -fSL "$HEADERS_URL" -o "$ELECTRON_HEADER_TARBALL"
    tar -xzf "$ELECTRON_HEADER_TARBALL" -C "$ELECTRON_HEADERS_DIR" --strip-components=1
    ok "Electron headers extracted"
else
    log "Electron headers already cached"
fi

# Also get the win-x64 node.lib (needed for linking .node DLLs)
NODE_LIB_DIR="$WORK_DIR/electron-win-x64-lib"
if [[ ! -f "$NODE_LIB_DIR/node.lib" ]]; then
    mkdir -p "$NODE_LIB_DIR"
    NODE_LIB_URL="https://electronjs.org/headers/v${ELECTRON_VERSION}/win-x64/node.lib"
    log "Downloading win-x64 node.lib..."
    curl -fSL "$NODE_LIB_URL" -o "$NODE_LIB_DIR/node.lib"
    ok "node.lib downloaded"
else
    log "node.lib already cached"
fi

###############################################################################
# Step 2: Download prebuilt binaries
###############################################################################
log ""
log "Step 2: Downloading prebuilt binaries..."

# --- 2a: @parcel/watcher (from npm @parcel/watcher-win32-x64) ---
log ""
log "--- @parcel/watcher ---"
PARCEL_TMP="$WORK_DIR/parcel-watcher"
rm -rf "$PARCEL_TMP"
mkdir -p "$PARCEL_TMP"

if npm pack "@parcel/watcher-win32-x64@2.5.6" --pack-destination "$PARCEL_TMP" 2>/dev/null; then
    PARCEL_TGZ="$(ls "$PARCEL_TMP"/*.tgz 2>/dev/null | head -1)"
    if [[ -n "$PARCEL_TGZ" ]]; then
        tar -xzf "$PARCEL_TGZ" -C "$PARCEL_TMP"
        PARCEL_NODE="$(find "$PARCEL_TMP" -name "*.node" -type f | head -1)"
        if [[ -n "$PARCEL_NODE" ]]; then
            mkdir -p "$WIN_MODULES/@parcel/watcher/build/Release"
            cp "$PARCEL_NODE" "$WIN_MODULES/@parcel/watcher/build/Release/watcher.node"
            # Also place in prebuilds path if the module looks for it there
            mkdir -p "$WIN_MODULES/@parcel/watcher-win32-x64"
            cp "$PARCEL_NODE" "$WIN_MODULES/@parcel/watcher-win32-x64/" 2>/dev/null || true
            verify_pe32 "$WIN_MODULES/@parcel/watcher/build/Release/watcher.node" "@parcel/watcher"
        else
            err "@parcel/watcher: no .node found in tarball"
            failed_modules+=("@parcel/watcher")
        fi
    else
        err "@parcel/watcher: npm pack produced no tarball"
        failed_modules+=("@parcel/watcher")
    fi
else
    err "@parcel/watcher: npm pack failed"
    failed_modules+=("@parcel/watcher")
fi

# --- 2b: @vscode/ripgrep (download rg.exe for win32-x64) ---
log ""
log "--- @vscode/ripgrep ---"
RG_VERSION="v13.0.0-13"
RG_TARGET="x86_64-pc-windows-msvc"
RG_ASSET="ripgrep-${RG_VERSION}-${RG_TARGET}.zip"
RG_TMP="$WORK_DIR/ripgrep"
rm -rf "$RG_TMP"
mkdir -p "$RG_TMP"

RG_API_URL="https://api.github.com/repos/microsoft/ripgrep-prebuilt/releases/tags/${RG_VERSION}"
log "Fetching ripgrep release info from $RG_API_URL..."
RG_DOWNLOAD_URL=""

# Get the asset download URL from GitHub API
RG_RELEASE_JSON="$(curl -fsSL "$RG_API_URL" 2>/dev/null || true)"
if [[ -n "$RG_RELEASE_JSON" ]]; then
    RG_DOWNLOAD_URL="$(echo "$RG_RELEASE_JSON" | node -e "
        const data = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
        const asset = (data.assets||[]).find(a => a.name === '${RG_ASSET}');
        if (asset) console.log(asset.browser_download_url);
    " 2>/dev/null || true)"
fi

if [[ -z "$RG_DOWNLOAD_URL" ]]; then
    # Fallback: construct the URL directly
    RG_DOWNLOAD_URL="https://github.com/microsoft/ripgrep-prebuilt/releases/download/${RG_VERSION}/${RG_ASSET}"
fi

log "Downloading $RG_ASSET..."
if curl -fSL "$RG_DOWNLOAD_URL" -o "$RG_TMP/$RG_ASSET" 2>/dev/null; then
    # It's a .zip file, use unzip
    unzip -q -o "$RG_TMP/$RG_ASSET" -d "$RG_TMP" 2>/dev/null || true
    if [[ -f "$RG_TMP/rg.exe" ]]; then
        # Replace the macOS rg with rg.exe
        rm -f "$WIN_MODULES/@vscode/ripgrep/bin/rg"
        cp "$RG_TMP/rg.exe" "$WIN_MODULES/@vscode/ripgrep/bin/rg.exe"
        verify_pe32 "$WIN_MODULES/@vscode/ripgrep/bin/rg.exe" "@vscode/ripgrep (rg.exe)"
    else
        err "@vscode/ripgrep: rg.exe not found in archive"
        failed_modules+=("@vscode/ripgrep")
    fi
else
    err "@vscode/ripgrep: download failed"
    failed_modules+=("@vscode/ripgrep")
fi

# --- 2c: @vscodium/native-keymap (has prebuilt downloads) ---
log ""
log "--- @vscodium/native-keymap ---"
KEYMAP_VERSION="3.3.7-258424"
KEYMAP_ASSET="native-keymap-${KEYMAP_VERSION}-win32-x64.tar.gz"
KEYMAP_TMP="$WORK_DIR/native-keymap"
rm -rf "$KEYMAP_TMP"
mkdir -p "$KEYMAP_TMP"

KEYMAP_URL="https://github.com/VSCodium/native-keymap/releases/download/v${KEYMAP_VERSION}/${KEYMAP_ASSET}"
log "Downloading $KEYMAP_ASSET..."
if curl -fSL "$KEYMAP_URL" -o "$KEYMAP_TMP/$KEYMAP_ASSET" 2>/dev/null; then
    tar -xzf "$KEYMAP_TMP/$KEYMAP_ASSET" -C "$KEYMAP_TMP" 2>/dev/null
    if [[ -f "$KEYMAP_TMP/keymapping.node" ]]; then
        mkdir -p "$WIN_MODULES/@vscodium/native-keymap/build/Release"
        cp "$KEYMAP_TMP/keymapping.node" "$WIN_MODULES/@vscodium/native-keymap/build/Release/keymapping.node"
        verify_pe32 "$WIN_MODULES/@vscodium/native-keymap/build/Release/keymapping.node" "@vscodium/native-keymap"
    else
        err "@vscodium/native-keymap: keymapping.node not found in archive"
        failed_modules+=("@vscodium/native-keymap")
    fi
else
    warn "@vscodium/native-keymap: prebuilt download failed, will try cross-compile"
    failed_modules+=("@vscodium/native-keymap")
fi

# --- 2d: kerberos (uses prebuild-install) ---
log ""
log "--- kerberos ---"
KERBEROS_TMP="$WORK_DIR/kerberos"
rm -rf "$KERBEROS_TMP"
mkdir -p "$KERBEROS_TMP"

# kerberos 2.1.1 uses prebuild-install; try to download prebuilt
# The prebuild URL format is: https://github.com/mongodb-js/kerberos/releases/download/v2.1.1/kerberos-v2.1.1-napi-v4-win32-x64.tar.gz
# Try common NAPI versions
KERBEROS_PREBUILT_FOUND=false
for NAPI_VER in 4 3 6; do
    KERBEROS_ASSET="kerberos-v2.1.1-napi-v${NAPI_VER}-win32-x64.tar.gz"
    KERBEROS_URL="https://github.com/mongodb-js/kerberos/releases/download/v2.1.1/${KERBEROS_ASSET}"
    if curl -fSL "$KERBEROS_URL" -o "$KERBEROS_TMP/$KERBEROS_ASSET" 2>/dev/null; then
        tar -xzf "$KERBEROS_TMP/$KERBEROS_ASSET" -C "$KERBEROS_TMP" 2>/dev/null
        KERBEROS_NODE="$(find "$KERBEROS_TMP" -name "kerberos.node" -type f | head -1)"
        if [[ -n "$KERBEROS_NODE" ]]; then
            mkdir -p "$WIN_MODULES/kerberos/build/Release"
            cp "$KERBEROS_NODE" "$WIN_MODULES/kerberos/build/Release/kerberos.node"
            if verify_pe32 "$WIN_MODULES/kerberos/build/Release/kerberos.node" "kerberos (napi-v${NAPI_VER})"; then
                KERBEROS_PREBUILT_FOUND=true
                break
            fi
        fi
    fi
done

if ! $KERBEROS_PREBUILT_FOUND; then
    # Try Electron-specific prebuild
    ELECTRON_ABI="$(node -e "console.log(process.versions.modules || '130')" 2>/dev/null || echo "130")"
    KERBEROS_ASSET="kerberos-v2.1.1-electron-v${ELECTRON_ABI}-win32-x64.tar.gz"
    KERBEROS_URL="https://github.com/mongodb-js/kerberos/releases/download/v2.1.1/${KERBEROS_ASSET}"
    if curl -fSL "$KERBEROS_URL" -o "$KERBEROS_TMP/$KERBEROS_ASSET" 2>/dev/null; then
        tar -xzf "$KERBEROS_TMP/$KERBEROS_ASSET" -C "$KERBEROS_TMP" 2>/dev/null
        KERBEROS_NODE="$(find "$KERBEROS_TMP" -name "kerberos.node" -type f | head -1)"
        if [[ -n "$KERBEROS_NODE" ]]; then
            mkdir -p "$WIN_MODULES/kerberos/build/Release"
            cp "$KERBEROS_NODE" "$WIN_MODULES/kerberos/build/Release/kerberos.node"
            verify_pe32 "$WIN_MODULES/kerberos/build/Release/kerberos.node" "kerberos (electron)"
            KERBEROS_PREBUILT_FOUND=true
        fi
    fi
fi

if ! $KERBEROS_PREBUILT_FOUND; then
    warn "kerberos: no prebuilt found, will try cross-compile later"
fi

# --- 2e: @vscode/sqlite3 (uses node-pre-gyp from TryGhost) ---
log ""
log "--- @vscode/sqlite3 ---"
SQLITE_TMP="$WORK_DIR/sqlite3"
rm -rf "$SQLITE_TMP"
mkdir -p "$SQLITE_TMP"

# The binary field in package.json gives us the URL template:
# host: https://github.com/TryGhost/node-sqlite3/releases/download/
# remote_path: v{version} = v5.1.12-vscode
# package_name: napi-v{napi_build_version}-{platform}-{libc}-{arch}.tar.gz
# napi_versions: [3, 6]
SQLITE_PREBUILT_FOUND=false
for NAPI_VER in 6 3; do
    # libc is empty/unknown on Windows, the convention is often just "unknown"
    for LIBC in "unknown" "glibc" ""; do
        if [[ -n "$LIBC" ]]; then
            SQLITE_ASSET="napi-v${NAPI_VER}-win32-${LIBC}-x64.tar.gz"
        else
            SQLITE_ASSET="napi-v${NAPI_VER}-win32-x64.tar.gz"
        fi
        SQLITE_URL="https://github.com/TryGhost/node-sqlite3/releases/download/v5.1.12-vscode/${SQLITE_ASSET}"
        log "  Trying $SQLITE_ASSET..."
        if curl -fSL "$SQLITE_URL" -o "$SQLITE_TMP/$SQLITE_ASSET" 2>/dev/null; then
            tar -xzf "$SQLITE_TMP/$SQLITE_ASSET" -C "$SQLITE_TMP" 2>/dev/null
            SQLITE_NODE="$(find "$SQLITE_TMP" -name "*.node" -type f | head -1)"
            if [[ -n "$SQLITE_NODE" ]]; then
                mkdir -p "$WIN_MODULES/@vscode/sqlite3/build/Release"
                cp "$SQLITE_NODE" "$WIN_MODULES/@vscode/sqlite3/build/Release/vscode-sqlite3.node"
                if verify_pe32 "$WIN_MODULES/@vscode/sqlite3/build/Release/vscode-sqlite3.node" "@vscode/sqlite3 (napi-v${NAPI_VER})"; then
                    SQLITE_PREBUILT_FOUND=true
                    break 2
                fi
            fi
            rm -rf "$SQLITE_TMP"/*
        fi
    done
done

if ! $SQLITE_PREBUILT_FOUND; then
    warn "@vscode/sqlite3: no prebuilt found, will try cross-compile later"
fi

# --- 2f: node-pty ConPTY binaries ---
log ""
log "--- node-pty (ConPTY DLLs) ---"
CONPTY_SRC="$SRC_MODULES/node-pty/third_party/conpty/1.23.251008001/win10-x64"
if [[ -d "$CONPTY_SRC" ]]; then
    # Create the target directory for conpty files
    CONPTY_DEST="$WIN_MODULES/node-pty/build/Release"
    mkdir -p "$CONPTY_DEST"

    for f in conpty.dll OpenConsole.exe; do
        if [[ -f "$CONPTY_SRC/$f" ]]; then
            cp "$CONPTY_SRC/$f" "$CONPTY_DEST/$f"
            log "  Copied $f"
        fi
    done
    ok "node-pty ConPTY binaries copied"
else
    warn "node-pty: ConPTY source dir not found at $CONPTY_SRC"
fi


###############################################################################
# Step 3: Cross-compile native modules with llvm-mingw
###############################################################################
log ""
log "Step 3: Cross-compiling native modules with llvm-mingw..."

# We use a custom node-gyp cross-compilation approach.
# Instead of fighting node-gyp's OS detection, we compile each module manually
# using the mingw toolchain, linking against Electron's node.lib.

NAPI_INCLUDE="$(node -e "console.log(require('node-addon-api').include_dir)" 2>/dev/null || true)"
NODE_INCLUDE="$ELECTRON_HEADERS_DIR/include/node"

# Common flags for cross-compiling NAPI modules to Windows x64
CROSS_CC="$MINGW_CC"
CROSS_CXX="$MINGW_CXX"
CROSS_AR="$MINGW_AR"
COMMON_CFLAGS="-O2 -DWIN32 -D_WIN32 -DWINDOWS -D_WINDOWS -DNAPI_DISABLE_CPP_EXCEPTIONS -DNODE_API_SWALLOW_UNTHROWABLE_EXCEPTIONS -DBUILDING_NODE_EXTENSION -D_CRT_SECURE_NO_WARNINGS"
COMMON_INCLUDES="-I${NODE_INCLUDE}"
if [[ -n "$NAPI_INCLUDE" ]]; then
    COMMON_INCLUDES="$COMMON_INCLUDES -I${NAPI_INCLUDE}"
fi

# node.lib for linking
NODE_LIB="$NODE_LIB_DIR/node.lib"

# Helper: cross-compile a single .node module
cross_compile_node_module() {
    local module_name="$1"
    local output_name="$2"
    local src_dir="$3"
    local dest_dir="$4"
    shift 4
    local sources=("$@")

    local extra_cflags=""
    local extra_ldflags=""
    local extra_includes=""
    local extra_libs=""

    # Parse any extra flags passed via env
    extra_cflags="${XTRA_CFLAGS:-}"
    extra_includes="${XTRA_INCLUDES:-}"
    extra_libs="${XTRA_LIBS:-}"
    extra_ldflags="${XTRA_LDFLAGS:-}"

    log "  Compiling $module_name..."

    local obj_dir="$WORK_DIR/obj/$module_name"
    rm -rf "$obj_dir"
    mkdir -p "$obj_dir"

    local objects=()
    for src in "${sources[@]}"; do
        local src_path="$src_dir/$src"
        if [[ ! -f "$src_path" ]]; then
            err "  $module_name: source file not found: $src_path"
            return 1
        fi
        local obj_name
        obj_name="$(basename "$src" | sed 's/\.[^.]*$/.o/')"
        local obj_path="$obj_dir/$obj_name"

        if ! $CROSS_CXX -c $COMMON_CFLAGS $extra_cflags $COMMON_INCLUDES $extra_includes \
            -std=c++17 -fPIC -shared \
            "$src_path" -o "$obj_path" 2>"$obj_dir/compile_${obj_name}.log"; then
            err "  $module_name: compilation failed for $src"
            cat "$obj_dir/compile_${obj_name}.log" 2>/dev/null | head -20
            return 1
        fi
        objects+=("$obj_path")
    done

    # Link into a .node (which is a .dll)
    mkdir -p "$dest_dir"
    local output_path="$dest_dir/$output_name"

    if ! $CROSS_CXX -shared -o "$output_path" \
        "${objects[@]}" \
        "$NODE_LIB" \
        $extra_ldflags $extra_libs \
        -lkernel32 -luser32 -ladvapi32 -lole32 -loleaut32 -luuid \
        -static-libgcc -static-libstdc++ \
        2>"$obj_dir/link.log"; then
        err "  $module_name: linking failed"
        cat "$obj_dir/link.log" 2>/dev/null | head -20
        return 1
    fi

    verify_pe32 "$output_path" "$module_name"
}

# --- 3a: @vscode/native-watchdog ---
log ""
log "--- @vscode/native-watchdog ---"
XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "@vscode/native-watchdog" \
    "watchdog.node" \
    "$SRC_MODULES/@vscode/native-watchdog" \
    "$WIN_MODULES/@vscode/native-watchdog/build/Release" \
    "src/watchdog.cc" \
    || failed_modules+=("@vscode/native-watchdog")

# --- 3b: native-is-elevated ---
log ""
log "--- native-is-elevated ---"
XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "native-is-elevated" \
    "iselevated.node" \
    "$SRC_MODULES/native-is-elevated" \
    "$WIN_MODULES/native-is-elevated/build/Release" \
    "src/iselevated.cc" \
    || failed_modules+=("native-is-elevated")

# --- 3c: windows-foreground-love ---
log ""
log "--- windows-foreground-love ---"
XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "windows-foreground-love" \
    "foreground_love.node" \
    "$SRC_MODULES/windows-foreground-love" \
    "$WIN_MODULES/windows-foreground-love/build/Release" \
    "src/foreground-love.cc" \
    || failed_modules+=("windows-foreground-love")

# --- 3d: @vscode/deviceid ---
log ""
log "--- @vscode/deviceid ---"
XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "@vscode/deviceid" \
    "windows.node" \
    "$SRC_MODULES/@vscode/deviceid" \
    "$WIN_MODULES/@vscode/deviceid/build/Release" \
    "src/windows.cc" \
    || failed_modules+=("@vscode/deviceid")

# --- 3e: @vscodium/policy-watcher ---
log ""
log "--- @vscodium/policy-watcher ---"
# policy-watcher needs NAPI_CPP_EXCEPTIONS (its code uses Napi::Object iterators
# which are only available when C++ exceptions are enabled)
XTRA_CFLAGS="-DWINDOWS -DNAPI_CPP_EXCEPTIONS -fexceptions -UNAPI_DISABLE_CPP_EXCEPTIONS" XTRA_INCLUDES="" XTRA_LIBS="-luserenv" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "@vscodium/policy-watcher" \
    "vscodium-policy-watcher.node" \
    "$SRC_MODULES/@vscodium/policy-watcher" \
    "$WIN_MODULES/@vscodium/policy-watcher/build/Release" \
    "src/main.cc" "src/windows/PolicyWatcher.cc" "src/windows/StringPolicy.cc" "src/windows/NumberPolicy.cc" "src/windows/BooleanPolicy.cc" \
    || failed_modules+=("@vscodium/policy-watcher")

# --- 3f: @vscode/spdlog ---
log ""
log "--- @vscode/spdlog ---"
SPDLOG_INCLUDES="-I${SRC_MODULES}/@vscode/spdlog/deps/spdlog/include -DSPDLOG_WCHAR_FILENAMES"
XTRA_CFLAGS="$SPDLOG_INCLUDES" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "@vscode/spdlog" \
    "spdlog.node" \
    "$SRC_MODULES/@vscode/spdlog" \
    "$WIN_MODULES/@vscode/spdlog/build/Release" \
    "src/main.cc" "src/logger.cc" \
    || failed_modules+=("@vscode/spdlog")

# --- 3g: node-pty (Windows ConPTY .node) ---
log ""
log "--- node-pty (pty.node) ---"
# node-pty on Windows builds two targets: conpty and conpty_console_list
# The main one is conpty -> pty.node, and conpty_console_list -> conpty_console_list.node
NODEPTY_EXTRA="-I${SRC_MODULES}/node-pty/src/win -lshlwapi"
XTRA_CFLAGS="" XTRA_INCLUDES="-I${SRC_MODULES}/node-pty/src/win" XTRA_LIBS="-lshlwapi" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "node-pty (conpty)" \
    "pty.node" \
    "$SRC_MODULES/node-pty" \
    "$WIN_MODULES/node-pty/build/Release" \
    "src/win/conpty.cc" "src/win/path_util.cc" \
    || failed_modules+=("node-pty")

# Also compile conpty_console_list
XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
    cross_compile_node_module \
    "node-pty (console_list)" \
    "conpty_console_list.node" \
    "$SRC_MODULES/node-pty" \
    "$WIN_MODULES/node-pty/build/Release" \
    "src/win/conpty_console_list.cc" \
    || warn "node-pty conpty_console_list: cross-compile failed (non-critical)"


###############################################################################
# Step 4: Handle Windows-only modules not in current build
###############################################################################
log ""
log "Step 4: Cross-compiling Windows-only modules..."

# --- 4a: @vscode/windows-registry ---
log ""
log "--- @vscode/windows-registry ---"
if [[ -d "$SRC_MODULES/@vscode/windows-registry" ]]; then
    mkdir -p "$WIN_MODULES/@vscode/windows-registry/build/Release"
    # Copy the JS files too
    cp -r "$SRC_MODULES/@vscode/windows-registry/"*.js "$WIN_MODULES/@vscode/windows-registry/" 2>/dev/null || true
    cp -r "$SRC_MODULES/@vscode/windows-registry/"*.d.ts "$WIN_MODULES/@vscode/windows-registry/" 2>/dev/null || true
    cp "$SRC_MODULES/@vscode/windows-registry/package.json" "$WIN_MODULES/@vscode/windows-registry/" 2>/dev/null || true

    XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
        cross_compile_node_module \
        "@vscode/windows-registry" \
        "winregistry.node" \
        "$SRC_MODULES/@vscode/windows-registry" \
        "$WIN_MODULES/@vscode/windows-registry/build/Release" \
        "src/winregistry.cc" \
        || failed_modules+=("@vscode/windows-registry")
else
    warn "@vscode/windows-registry: source not found in vscode/node_modules"
fi

# --- 4b: @vscode/windows-mutex ---
log ""
log "--- @vscode/windows-mutex ---"
if [[ -d "$SRC_MODULES/@vscode/windows-mutex" ]]; then
    mkdir -p "$WIN_MODULES/@vscode/windows-mutex/build/Release"
    cp -r "$SRC_MODULES/@vscode/windows-mutex/"*.js "$WIN_MODULES/@vscode/windows-mutex/" 2>/dev/null || true
    cp -r "$SRC_MODULES/@vscode/windows-mutex/"*.d.ts "$WIN_MODULES/@vscode/windows-mutex/" 2>/dev/null || true
    cp "$SRC_MODULES/@vscode/windows-mutex/package.json" "$WIN_MODULES/@vscode/windows-mutex/" 2>/dev/null || true

    XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
        cross_compile_node_module \
        "@vscode/windows-mutex" \
        "CreateMutex.node" \
        "$SRC_MODULES/@vscode/windows-mutex" \
        "$WIN_MODULES/@vscode/windows-mutex/build/Release" \
        "src/main.cc" "src/mutex.cc" \
        || failed_modules+=("@vscode/windows-mutex")
else
    warn "@vscode/windows-mutex: source not found in vscode/node_modules"
fi

# --- 4c: @vscode/windows-process-tree ---
log ""
log "--- @vscode/windows-process-tree ---"
if [[ -d "$SRC_MODULES/@vscode/windows-process-tree" ]]; then
    mkdir -p "$WIN_MODULES/@vscode/windows-process-tree/build/Release"
    cp -r "$SRC_MODULES/@vscode/windows-process-tree/"*.js "$WIN_MODULES/@vscode/windows-process-tree/" 2>/dev/null || true
    cp -r "$SRC_MODULES/@vscode/windows-process-tree/"*.d.ts "$WIN_MODULES/@vscode/windows-process-tree/" 2>/dev/null || true
    cp "$SRC_MODULES/@vscode/windows-process-tree/package.json" "$WIN_MODULES/@vscode/windows-process-tree/" 2>/dev/null || true

    XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="-lpsapi" XTRA_LDFLAGS="" \
        cross_compile_node_module \
        "@vscode/windows-process-tree" \
        "windows_process_tree.node" \
        "$SRC_MODULES/@vscode/windows-process-tree" \
        "$WIN_MODULES/@vscode/windows-process-tree/build/Release" \
        "src/addon.cc" "src/cpu_worker.cc" "src/process.cc" "src/process_worker.cc" "src/process_commandline.cc" \
        || failed_modules+=("@vscode/windows-process-tree")
else
    warn "@vscode/windows-process-tree: source not found in vscode/node_modules"
fi

# --- kerberos cross-compile (if prebuilt not found) ---
if ! $KERBEROS_PREBUILT_FOUND; then
    log ""
    log "--- kerberos (cross-compile) ---"
    XTRA_CFLAGS="-DWIN32" XTRA_INCLUDES="" XTRA_LIBS="-lcrypt32 -lsecur32 -lshlwapi" XTRA_LDFLAGS="" \
        cross_compile_node_module \
        "kerberos" \
        "kerberos.node" \
        "$SRC_MODULES/kerberos" \
        "$WIN_MODULES/kerberos/build/Release" \
        "src/kerberos.cc" "src/win32/kerberos_sspi.cc" "src/win32/kerberos_win32.cc" \
        || failed_modules+=("kerberos")
fi

# --- @vscodium/native-keymap cross-compile (if prebuilt not found) ---
if [[ " ${failed_modules[*]} " == *"@vscodium/native-keymap"* ]]; then
    log ""
    log "--- @vscodium/native-keymap (cross-compile fallback) ---"
    # Remove from failed list since we're retrying
    temp_failed=()
    for m in "${failed_modules[@]}"; do
        [[ "$m" != "@vscodium/native-keymap" ]] && temp_failed+=("$m")
    done
    failed_modules=("${temp_failed[@]}")

    XTRA_CFLAGS="" XTRA_INCLUDES="" XTRA_LIBS="" XTRA_LDFLAGS="" \
        cross_compile_node_module \
        "@vscodium/native-keymap" \
        "keymapping.node" \
        "$SRC_MODULES/@vscodium/native-keymap" \
        "$WIN_MODULES/@vscodium/native-keymap/build/Release" \
        "src/keymapping.cc" "src/keyboard_win.cc" "src/string_conversion.cc" \
        || failed_modules+=("@vscodium/native-keymap")
fi

# --- @vscode/sqlite3 cross-compile (if prebuilt not found) ---
if ! $SQLITE_PREBUILT_FOUND; then
    log ""
    log "--- @vscode/sqlite3 (cross-compile) ---"
    # sqlite3 needs the embedded sqlite source extracted from the tarball and compiled
    SQLITE3_DEP_DIR="$SRC_MODULES/@vscode/sqlite3/deps"
    SQLITE3_EXTRACT_DIR="$WORK_DIR/sqlite3-extracted"
    SQLITE3_TARBALL="$SQLITE3_DEP_DIR/sqlite-autoconf-3390400.tar.gz"

    if [[ -f "$SQLITE3_TARBALL" ]]; then
        # Extract sqlite3.c from the tarball
        rm -rf "$SQLITE3_EXTRACT_DIR"
        mkdir -p "$SQLITE3_EXTRACT_DIR"
        tar -xzf "$SQLITE3_TARBALL" -C "$SQLITE3_EXTRACT_DIR" 2>/dev/null
        SQLITE3_SRC_DIR="$(find "$SQLITE3_EXTRACT_DIR" -name "sqlite3.c" -type f -exec dirname {} \; | head -1)"

        if [[ -n "$SQLITE3_SRC_DIR" && -f "$SQLITE3_SRC_DIR/sqlite3.c" ]]; then
            # Compile sqlite3.c first as a static library
            log "  Compiling embedded sqlite3..."
            SQLITE_OBJ="$WORK_DIR/obj/sqlite3_dep"
            mkdir -p "$SQLITE_OBJ"
            if $CROSS_CC -c -O2 -DWIN32 -D_WIN32 \
                -D_REENTRANT=1 \
                -DSQLITE_THREADSAFE=1 -DHAVE_USLEEP=1 \
                -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 \
                -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_RTREE \
                -DSQLITE_ENABLE_DBSTAT_VTAB=1 -DSQLITE_ENABLE_MATH_FUNCTIONS \
                "$SQLITE3_SRC_DIR/sqlite3.c" \
                -o "$SQLITE_OBJ/sqlite3.o" 2>"$SQLITE_OBJ/compile.log"; then

                XTRA_CFLAGS="-I${SQLITE3_SRC_DIR} -DNAPI_VERSION=6 -DSQLITE_THREADSAFE=1 -DHAVE_USLEEP=1 -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_DBSTAT_VTAB=1 -DSQLITE_ENABLE_MATH_FUNCTIONS" \
                    XTRA_INCLUDES="" \
                    XTRA_LIBS="" XTRA_LDFLAGS="$SQLITE_OBJ/sqlite3.o" \
                    cross_compile_node_module \
                    "@vscode/sqlite3" \
                    "vscode-sqlite3.node" \
                    "$SRC_MODULES/@vscode/sqlite3" \
                    "$WIN_MODULES/@vscode/sqlite3/build/Release" \
                    "src/backup.cc" "src/database.cc" "src/node_sqlite3.cc" "src/statement.cc" \
                    || failed_modules+=("@vscode/sqlite3")
            else
                err "@vscode/sqlite3: failed to compile embedded sqlite3.c"
                cat "$SQLITE_OBJ/compile.log" 2>/dev/null | head -20
                failed_modules+=("@vscode/sqlite3")
            fi
        else
            warn "@vscode/sqlite3: sqlite3.c not found in extracted tarball"
            failed_modules+=("@vscode/sqlite3")
        fi
    else
        warn "@vscode/sqlite3: tarball not found at $SQLITE3_TARBALL, cannot cross-compile"
        failed_modules+=("@vscode/sqlite3")
    fi
fi


###############################################################################
# Step 5: Verify all binaries
###############################################################################
log ""
log "============================================="
log "Step 5: Final verification"
log "============================================="
log ""

# Check all .node files
log "Checking all .node files in VSCode-win32-x64/..."
log ""

TOTAL_NODES=0
GOOD_NODES=0
BAD_NODES=0

while IFS= read -r -d '' node_file; do
    ((TOTAL_NODES++)) || true
    rel_path="${node_file#$WIN_BUILD/}"
    if file "$node_file" | grep -q "PE32+"; then
        echo -e "  ${GREEN}OK${NC}  $rel_path"
        ((GOOD_NODES++)) || true
    else
        file_type="$(file "$node_file" | cut -d: -f2- | xargs)"
        echo -e "  ${RED}BAD${NC} $rel_path -> $file_type"
        ((BAD_NODES++)) || true
    fi
done < <(find "$WIN_BUILD" -name "*.node" -print0 2>/dev/null)

log ""

# Check ripgrep
if [[ -f "$WIN_MODULES/@vscode/ripgrep/bin/rg.exe" ]]; then
    if file "$WIN_MODULES/@vscode/ripgrep/bin/rg.exe" | grep -q "PE32+"; then
        echo -e "  ${GREEN}OK${NC}  rg.exe"
    else
        echo -e "  ${RED}BAD${NC} rg.exe"
        ((BAD_NODES++)) || true
    fi
else
    echo -e "  ${RED}MISSING${NC} rg.exe"
    ((BAD_NODES++))
fi

# Check ConPTY
for f in conpty.dll OpenConsole.exe; do
    if [[ -f "$WIN_MODULES/node-pty/build/Release/$f" ]]; then
        echo -e "  ${GREEN}OK${NC}  node-pty/$f"
    else
        echo -e "  ${YELLOW}MISSING${NC} node-pty/$f (non-critical)"
    fi
done

log ""
log "============================================="
log "  Summary"
log "============================================="
log "  Total .node files: $TOTAL_NODES"
log "  PE32+ (correct):   $GOOD_NODES"
log "  Wrong arch:        $BAD_NODES"
if [[ ${#failed_modules[@]} -gt 0 ]]; then
    log "  Failed modules:    ${failed_modules[*]}"
fi
log ""

###############################################################################
# Step 6: Package
###############################################################################
log "Step 6: Packaging..."

# Remove the old macOS rg binary if rg.exe exists
if [[ -f "$WIN_MODULES/@vscode/ripgrep/bin/rg.exe" && -f "$WIN_MODULES/@vscode/ripgrep/bin/rg" ]]; then
    rm -f "$WIN_MODULES/@vscode/ripgrep/bin/rg"
    log "Removed old macOS rg binary"
fi

# Copy mingw runtime DLLs that cross-compiled modules depend on
log "Copying mingw runtime DLLs..."
MINGW_BIN_DIR="$(dirname "$MINGW_CC")/../x86_64-w64-mingw32/bin"
if [[ ! -d "$MINGW_BIN_DIR" ]]; then
    MINGW_BIN_DIR="$(find /opt/homebrew /usr/local -path "*/x86_64-w64-mingw32/bin" -type d 2>/dev/null | head -1)"
fi
for dll in libwinpthread-1.dll; do
    DLL_SRC="$MINGW_BIN_DIR/$dll"
    if [[ -f "$DLL_SRC" ]]; then
        cp "$DLL_SRC" "$WIN_BUILD/$dll"
        ok "Bundled $dll"
    else
        warn "$dll not found in mingw toolchain (modules may fail to load on Windows)"
    fi
done

ZIP_NAME="Lasco-win32-x64.zip"
log "Creating $ZIP_NAME..."

# Remove old zip if exists
rm -f "$PROJECT_ROOT/$ZIP_NAME"

# Create zip (from project root, so paths inside zip start with VSCode-win32-x64/)
(cd "$PROJECT_ROOT" && zip -r -q "$ZIP_NAME" "VSCode-win32-x64/")

ZIP_SIZE="$(du -h "$PROJECT_ROOT/$ZIP_NAME" | cut -f1)"
ok "Created $ZIP_NAME ($ZIP_SIZE)"

log ""
log "============================================="
if [[ $BAD_NODES -eq 0 ]]; then
    echo -e "${GREEN}All native modules are PE32+ x86-64. Ready for Windows!${NC}"
else
    echo -e "${YELLOW}Some modules could not be replaced. The app will still work${NC}"
    echo -e "${YELLOW}but with degraded functionality for failed modules.${NC}"
fi
log ""
log "To serve for download:"
log "  python3 -m http.server 8080"
log "  # Then download from http://<your-mac-ip>:8080/$ZIP_NAME"
log "============================================="
