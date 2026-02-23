#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

. version.sh

remove_unwanted_extensions() {
  local ext_base_dir="$1"
  echo "Removing unwanted built-in extensions from ${ext_base_dir}..."
  for ext in \
    git git-base github github-authentication debug-auto-launch debug-server-ready \
    bat clojure coffeescript cpp csharp dart diff docker dotenv fsharp go groovy \
    handlebars hlsl ini java javascript julia latex less log lua make objective-c \
    perl php powershell pug python r razor restructuredtext ruby rust scss \
    shaderlab shellscript sql swift typescript-basics vb \
    emmet extension-editing grunt gulp jake npm ipynb notebook-renderers \
    merge-conflict tunnel-forwarding terminal-suggest prompt-basics \
    mermaid-chat-features microsoft-authentication \
    theme-abyss theme-kimbie-dark theme-monokai theme-monokai-dimmed \
    theme-red theme-seti theme-solarized-dark theme-tomorrow-night-blue \
    vscode-api-tests vscode-colorize-perf-tests vscode-colorize-tests \
    vscode-test-resolver; do
    if [[ -d "${ext_base_dir}/${ext}" ]]; then
      rm -rf "${ext_base_dir}/${ext}"
      echo "  Removed: ${ext}"
    fi
  done
}

if [[ "${SHOULD_BUILD}" == "yes" ]]; then
  echo "MS_COMMIT=\"${MS_COMMIT}\""

  . prepare_vscode.sh

  cd vscode || { echo "'vscode' dir not found"; exit 1; }

  export NODE_OPTIONS="--max-old-space-size=8192"

  npm run monaco-compile-check
  npm run valid-layers-check

  npm run gulp compile-build-without-mangling
  npm run gulp compile-extension-media
  npm run gulp compile-extensions-build
  npm run gulp minify-vscode

  if [[ "${OS_NAME}" == "osx" ]]; then
    # remove win32 node modules
    rm -f .build/extensions/ms-vscode.js-debug/src/win32-app-container-tokens.*.node

    # generate Group Policy definitions
    npm run copy-policy-dto --prefix build
    node build/lib/policies/policyGenerator.ts build/lib/policies/policyData.jsonc darwin

    npm run gulp "vscode-darwin-${VSCODE_ARCH}-min-ci"

    remove_unwanted_extensions "../VSCode-darwin-${VSCODE_ARCH}/Lasco.app/Contents/Resources/app/extensions"

    find "../VSCode-darwin-${VSCODE_ARCH}" -print0 | xargs -0 touch -c

    # CLI build skipped — LASCO doesn't need tunnel/remote functionality
    # . ../build_cli.sh

    VSCODE_PLATFORM="darwin"
  elif [[ "${OS_NAME}" == "windows" ]]; then
    # in CI, packaging will be done by a different job
    if [[ "${CI_BUILD}" == "no" ]]; then
      . ../build/windows/rtf/make.sh

      # generate Group Policy definitions
      npm run copy-policy-dto --prefix build
      node build/lib/policies/policyGenerator.ts build/lib/policies/policyData.jsonc win32

      npm run gulp "vscode-win32-${VSCODE_ARCH}-min-ci"

      # Bundle vcruntime140.dll alongside the app for fresh Windows machines
      cp "build/win32/vcruntime140.dll" "../VSCode-win32-${VSCODE_ARCH}/vcruntime140.dll"

      remove_unwanted_extensions "../VSCode-win32-${VSCODE_ARCH}/resources/app/extensions"

      if [[ "${VSCODE_ARCH}" != "x64" ]]; then
        SHOULD_BUILD_REH="no"
        SHOULD_BUILD_REH_WEB="no"
      fi

      . ../build_cli.sh
    fi

    VSCODE_PLATFORM="win32"
  else # linux
    # remove win32 node modules
    rm -f .build/extensions/ms-vscode.js-debug/src/win32-app-container-tokens.*.node

    # in CI, packaging will be done by a different job
    if [[ "${CI_BUILD}" == "no" ]]; then
      # generate Group Policy definitions
      npm run copy-policy-dto --prefix build
      node build/lib/policies/policyGenerator.ts build/lib/policies/policyData.jsonc linux

      npm run gulp "vscode-linux-${VSCODE_ARCH}-min-ci"

      remove_unwanted_extensions "../VSCode-linux-${VSCODE_ARCH}/resources/app/extensions"

      find "../VSCode-linux-${VSCODE_ARCH}" -print0 | xargs -0 touch -c

      . ../build_cli.sh
    fi

    VSCODE_PLATFORM="linux"
  fi

  if [[ "${SHOULD_BUILD_REH}" != "no" ]]; then
    npm run gulp minify-vscode-reh
    npm run gulp "vscode-reh-${VSCODE_PLATFORM}-${VSCODE_ARCH}-min-ci"
  fi

  if [[ "${SHOULD_BUILD_REH_WEB}" != "no" ]]; then
    npm run gulp minify-vscode-reh-web
    npm run gulp "vscode-reh-web-${VSCODE_PLATFORM}-${VSCODE_ARCH}-min-ci"
  fi

  cd ..
fi
