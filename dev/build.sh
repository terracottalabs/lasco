#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2129

### Windows
# to run with Bash: "C:\Program Files\Git\bin\bash.exe" ./dev/build.sh
###

export APP_NAME="LASCO"
export ASSETS_REPOSITORY="rocky-terracotta/lasco-demo"
export BINARY_NAME="lasco"
export CI_BUILD="no"
export GH_REPO_PATH="rocky-terracotta/lasco-demo"
export ORG_NAME="LASCO"
export DISABLE_UPDATE="yes"
export SHOULD_BUILD="yes"
export SKIP_ASSETS="yes"
export SKIP_BUILD="no"
export SKIP_SOURCE="no"
export VSCODE_LATEST="no"
export VSCODE_QUALITY="stable"
export VSCODE_SKIP_NODE_VERSION_CHECK="yes"

while getopts ":ilops" opt; do
  case "$opt" in
    i)
      export ASSETS_REPOSITORY="VSCodium/vscodium-insiders"
      export BINARY_NAME="codium-insiders"
      export VSCODE_QUALITY="insider"
      ;;
    l)
      export VSCODE_LATEST="yes"
      ;;
    o)
      export SKIP_BUILD="yes"
      ;;
    p)
      export SKIP_ASSETS="no"
      ;;
    s)
      export SKIP_SOURCE="yes"
      ;;
    *)
      ;;
  esac
done

case "${OSTYPE}" in
  darwin*)
    export OS_NAME="osx"
    ;;
  msys* | cygwin*)
    export OS_NAME="windows"
    ;;
  *)
    export OS_NAME="linux"
    ;;
esac

UNAME_ARCH=$( uname -m )

if [[ "${UNAME_ARCH}" == "aarch64" || "${UNAME_ARCH}" == "arm64" ]]; then
  export VSCODE_ARCH="arm64"
elif [[ "${UNAME_ARCH}" == "ppc64le" ]]; then
  export VSCODE_ARCH="ppc64le"
elif [[ "${UNAME_ARCH}" == "riscv64" ]]; then
  export VSCODE_ARCH="riscv64"
elif [[ "${UNAME_ARCH}" == "loongarch64" ]]; then
  export VSCODE_ARCH="loong64"
elif [[ "${UNAME_ARCH}" == "s390x" ]]; then
  export VSCODE_ARCH="s390x"
else
  export VSCODE_ARCH="x64"
fi

export NODE_OPTIONS="--max-old-space-size=8192"

echo "OS_NAME=\"${OS_NAME}\""
echo "SKIP_SOURCE=\"${SKIP_SOURCE}\""
echo "SKIP_BUILD=\"${SKIP_BUILD}\""
echo "SKIP_ASSETS=\"${SKIP_ASSETS}\""
echo "VSCODE_ARCH=\"${VSCODE_ARCH}\""
echo "VSCODE_LATEST=\"${VSCODE_LATEST}\""
echo "VSCODE_QUALITY=\"${VSCODE_QUALITY}\""

if [[ "${SKIP_SOURCE}" == "no" ]]; then
  rm -rf vscode* VSCode*

  . get_repo.sh
  . version.sh

  # save variables for later
  echo "MS_TAG=\"${MS_TAG}\"" > dev/build.env
  echo "MS_COMMIT=\"${MS_COMMIT}\"" >> dev/build.env
  echo "RELEASE_VERSION=\"${RELEASE_VERSION}\"" >> dev/build.env
  echo "BUILD_SOURCEVERSION=\"${BUILD_SOURCEVERSION}\"" >> dev/build.env
else
  if [[ "${SKIP_ASSETS}" != "no" ]]; then
    rm -rf vscode-* VSCode-*
  fi

  . dev/build.env

  echo "MS_TAG=\"${MS_TAG}\""
  echo "MS_COMMIT=\"${MS_COMMIT}\""
  echo "RELEASE_VERSION=\"${RELEASE_VERSION}\""
  echo "BUILD_SOURCEVERSION=\"${BUILD_SOURCEVERSION}\""
fi

if [[ "${SKIP_BUILD}" == "no" ]]; then
  if [[ "${SKIP_SOURCE}" != "no" ]]; then
    cd vscode || { echo "'vscode' dir not found"; exit 1; }

    git add .
    git reset -q --hard HEAD

    while [[ -n "$( git log -1 | grep "VSCODIUM HELPER" )" ]]; do
      git reset -q --hard HEAD~
    done

    rm -rf .build out*

    cd ..
  fi

  if [[ -f "./include_${OS_NAME}.gypi" ]]; then
    echo "Installing custom ~/.gyp/include.gypi"

    mkdir -p ~/.gyp

    if [[ -f "${HOME}/.gyp/include.gypi" ]]; then
      mv ~/.gyp/include.gypi ~/.gyp/include.gypi.pre-vscodium
    else
      echo "{}" > ~/.gyp/include.gypi.pre-vscodium
    fi

    cp ./build/osx/include.gypi ~/.gyp/include.gypi
  fi

  . build.sh

  # {{{ bundle LASCO extensions + workspace template
  LASCO_DIR="$(cd "$(dirname "$0")/.." && pwd)/lasco"
  LASCO_EXTS="${LASCO_DIR}/extensions"
  LASCO_TMPL="${LASCO_DIR}/template"

  if [[ "${OS_NAME}" == "osx" ]]; then
    APP_DIR="VSCode-darwin-${VSCODE_ARCH}/LASCO.app/Contents/Resources"
    EXT_DIR="${APP_DIR}/app/extensions"
  elif [[ "${OS_NAME}" == "windows" ]]; then
    APP_DIR="VSCode-win32-${VSCODE_ARCH}/resources"
    EXT_DIR="${APP_DIR}/app/extensions"
  elif [[ "${OS_NAME}" == "linux" ]]; then
    APP_DIR="VSCode-linux-${VSCODE_ARCH}/resources"
    EXT_DIR="${APP_DIR}/app/extensions"
  else
    echo "ERROR: Unknown OS_NAME '${OS_NAME}' — cannot determine app directory."
    exit 1
  fi

  # --- Extensions (all VSIX-based) ---
  for vsix_path in "${LASCO_EXTS}"/*.vsix; do
    [[ -f "${vsix_path}" ]] || continue
    VSIX_FILE="$(basename "${vsix_path}")"
    # Skip Claude Code (handled separately below as platform-specific)
    [[ "${VSIX_FILE}" == anthropic.claude-code-* ]] && continue
    # Skip lasco-auth (not bundled)
    [[ "${VSIX_FILE}" == lasco-auth-* ]] && continue
    # Derive extension name: strip trailing -MAJOR.MINOR.PATCH.vsix
    EXT_NAME="$(echo "${VSIX_FILE}" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+\.vsix$//')"
    TMP=$(mktemp -d)
    unzip -qo "${vsix_path}" -d "${TMP}"
    cp -r "${TMP}/extension" "${EXT_DIR}/${EXT_NAME}"
    rm -rf "${TMP}"
    echo "  Bundled: ${EXT_NAME}"
  done

  # Claude Code: platform-specific VSIX
  case "${OS_NAME}" in
    osx)     OS_NAME_MAP="darwin" ;;
    windows) OS_NAME_MAP="win32" ;;
    linux)   OS_NAME_MAP="linux" ;;
  esac
  CLAUDE_VSIX="${LASCO_EXTS}/anthropic.claude-code-2.1.39-${OS_NAME_MAP}-${VSCODE_ARCH}.vsix"
  if [[ ! -f "${CLAUDE_VSIX}" ]]; then
    echo "ERROR: Claude Code VSIX not found: ${CLAUDE_VSIX}"
    exit 1
  fi
  TMP=$(mktemp -d)
  unzip -qo "${CLAUDE_VSIX}" -d "${TMP}"
  cp -r "${TMP}/extension" "${EXT_DIR}/anthropic.claude-code"
  rm -rf "${TMP}"

  # --- Workspace Template ---
  TMPL="${APP_DIR}/lasco-template"
  rm -rf "${TMPL}"
  cp -R "${LASCO_TMPL}/." "${TMPL}"
  find "${TMPL}" -name '.DS_Store' -delete

  # Install dependencies (replaces copying pre-built node_modules)
  ( cd "${TMPL}" && npm ci --production )
  ( cd "${TMPL}/scripts" && npm ci --production )

  echo "Bundled LASCO extensions and workspace template"
  # }}}

  if [[ -f "./include_${OS_NAME}.gypi" ]]; then
    mv ~/.gyp/include.gypi.pre-vscodium ~/.gyp/include.gypi
  fi

  if [[ "${VSCODE_LATEST}" == "yes" ]]; then
    jsonTmp=$( cat "./upstream/${VSCODE_QUALITY}.json" | jq --arg 'tag' "${MS_TAG/\-insider/}" --arg 'commit' "${MS_COMMIT}" '. | .tag=$tag | .commit=$commit' )
    echo "${jsonTmp}" > "./upstream/${VSCODE_QUALITY}.json" && unset jsonTmp
  fi
fi

if [[ "${SKIP_ASSETS}" == "no" ]]; then
  if [[ "${OS_NAME}" == "windows" ]]; then
    rm -rf build/windows/msi/releasedir
  fi

  if [[ "${OS_NAME}" == "osx" && -f "dev/osx/codesign.env" ]]; then
    . dev/osx/macos-codesign.env

    echo "CERTIFICATE_OSX_ID: ${CERTIFICATE_OSX_ID}"
  fi

  . prepare_assets.sh
fi
