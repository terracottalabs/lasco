#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

{ set +x; } 2>/dev/null

# {{{ product.json
cp product.json{,.bak}

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --argjson 'value' "${3}" "setpath(path(.${2}); \$value)" "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath "product" "licenseUrl" "https://github.com/rocky-terracotta/lasco-demo/blob/main/LICENSE"
setpath "product" "reportIssueUrl" "https://github.com/rocky-terracotta/lasco-demo/issues/new"
setpath "product" "checksumFailMoreInfoUrl" "https://github.com/rocky-terracotta/lasco-demo"
setpath "product" "documentationUrl" "https://github.com/rocky-terracotta/lasco-demo#documentation"
setpath_json "product" "extensionsGallery" '{}'

setpath "product" "introductoryVideosUrl" "https://github.com/rocky-terracotta/lasco-demo#getting-started"
setpath "product" "keyboardShortcutsUrlLinux" "https://github.com/rocky-terracotta/lasco-demo#keyboard-shortcuts"
setpath "product" "keyboardShortcutsUrlMac" "https://github.com/rocky-terracotta/lasco-demo#keyboard-shortcuts"
setpath "product" "keyboardShortcutsUrlWin" "https://github.com/rocky-terracotta/lasco-demo#keyboard-shortcuts"
setpath "product" "licenseUrl" "https://github.com/rocky-terracotta/lasco-demo/blob/main/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org", "https://github.com", "https://getlasco.com"]'
setpath "product" "releaseNotesUrl" "https://github.com/rocky-terracotta/lasco-demo/releases"
setpath "product" "reportIssueUrl" "https://github.com/rocky-terracotta/lasco-demo/issues/new"
setpath "product" "requestFeatureUrl" "https://github.com/rocky-terracotta/lasco-demo/issues/new"
setpath "product" "tipsAndTricksUrl" "https://github.com/rocky-terracotta/lasco-demo#tips"
setpath "product" "twitterUrl" "https://github.com/rocky-terracotta/lasco-demo"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/VSCodium/versions/refs/heads/master"

  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    setpath "product" "downloadUrl" "https://github.com/VSCodium/vscodium-insiders/releases"
  else
    setpath "product" "downloadUrl" "https://github.com/VSCodium/vscodium/releases"
  fi
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "VSCodium - Insiders"
  setpath "product" "nameLong" "VSCodium - Insiders"
  setpath "product" "applicationName" "codium-insiders"
  setpath "product" "dataFolderName" ".vscodium-insiders"
  setpath "product" "linuxIconName" "vscodium-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "vscodium-insiders"
  setpath "product" "serverApplicationName" "codium-server-insiders"
  setpath "product" "serverDataFolderName" ".vscodium-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.vscodium.VSCodiumInsiders"
  setpath "product" "win32AppUserModelId" "VSCodium.VSCodiumInsiders"
  setpath "product" "win32DirName" "VSCodium Insiders"
  setpath "product" "win32MutexName" "vscodiuminsiders"
  setpath "product" "win32NameVersion" "VSCodium Insiders"
  setpath "product" "win32RegValueName" "VSCodiumInsiders"
  setpath "product" "win32ShellNameShort" "VSCodium Insiders"
  setpath "product" "win32AppId" "{{EF35BB36-FA7E-4BB9-B7DA-D1E09F2DA9C9}"
  setpath "product" "win32x64AppId" "{{B2E0DDB2-120E-4D34-9F7E-8C688FF839A2}"
  setpath "product" "win32arm64AppId" "{{44721278-64C6-4513-BC45-D48E07830599}"
  setpath "product" "win32UserAppId" "{{ED2E5618-3E7E-4888-BF3C-A6CCC84F586F}"
  setpath "product" "win32x64UserAppId" "{{20F79D0D-A9AC-4220-9A81-CE675FFB6B41}"
  setpath "product" "win32arm64UserAppId" "{{2E362F92-14EA-455A-9ABD-3E656BBBFE71}"
  setpath "product" "tunnelApplicationName" "codium-insiders-tunnel"
  setpath "product" "win32TunnelServiceMutex" "vscodiuminsiders-tunnelservice"
  setpath "product" "win32TunnelMutex" "vscodiuminsiders-tunnel"
  setpath "product" "win32ContextMenu.x64.clsid" "90AAD229-85FD-43A3-B82D-8598A88829CF"
  setpath "product" "win32ContextMenu.arm64.clsid" "7544C31C-BDBF-4DDF-B15E-F73A46D6723D"
else
  setpath "product" "nameShort" "Lasco"
   setpath "product" "nameLong" "Lasco"
   setpath "product" "applicationName" "lasco"
   setpath "product" "dataFolderName" ".lasco"
   setpath "product" "linuxIconName" "lasco"
   setpath "product" "quality" "stable"
   setpath "product" "urlProtocol" "lasco"
   setpath "product" "serverApplicationName" "lasco-server"
   setpath "product" "serverDataFolderName" ".lasco-server"
   setpath "product" "darwinBundleIdentifier" "com.lasco.app"
   setpath "product" "win32AppUserModelId" "Lasco.Lasco"
   setpath "product" "win32DirName" "Lasco"
   setpath "product" "win32MutexName" "lasco"
   setpath "product" "win32NameVersion" "Lasco"
   setpath "product" "win32RegValueName" "Lasco"
   setpath "product" "win32ShellNameShort" "Lasco"
   setpath "product" "win32AppId" "{{763CBF88-25C6-4B10-952F-326AE657F16B}"
   setpath "product" "win32x64AppId" "{{88DA3577-054F-4CA1-8122-7D820494CFFB}"
   setpath "product" "win32arm64AppId" "{{67DEE444-3D04-4258-B92A-BC1F0FF2CAE4}"
   setpath "product" "win32UserAppId" "{{0FD05EB4-651E-4E78-A062-515204B47A3A}"
   setpath "product" "win32x64UserAppId" "{{2E1F05D1-C245-4562-81EE-28188DB6FD17}"
   setpath "product" "win32arm64UserAppId" "{{57FD70A5-1B8D-4875-9F40-C5553F094828}"
   setpath "product" "tunnelApplicationName" "lasco-tunnel"
   setpath "product" "win32TunnelServiceMutex" "lasco-tunnelservice"
   setpath "product" "win32TunnelMutex" "lasco-tunnel"
   setpath "product" "win32ContextMenu.x64.clsid" "D910D5E6-B277-4F4A-BDC5-759A34EEE25D"
   setpath "product" "win32ContextMenu.arm64.clsid" "4852FC55-4A84-4EA1-9C86-D53BE3DF83C0"
fi

setpath_json "product" "tunnelApplicationConfig" '{}'

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json
# }}}

# include common functions
. ../utils.sh

# {{{ apply patches

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "ASSETS_REPOSITORY=\"${ASSETS_REPOSITORY}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "GLOBAL_DIRNAME=\"${GLOBAL_DIRNAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""
echo "TUNNEL_APP_NAME=\"${TUNNEL_APP_NAME}\""

if [[ "${DISABLE_UPDATE}" == "yes" && -f "../patches/disable-update.patch.yet" ]]; then
  mv ../patches/disable-update.patch.yet ../patches/disable-update.patch
fi

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done
# }}}

set -x

# {{{ install dependencies
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
else
  if [[ "${CI_BUILD}" != "no" ]]; then
    clang++ --version
  fi
fi

node build/npm/preinstall.ts

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  if [[ "${CI_BUILD}" != "no" && "${OS_NAME}" == "osx" ]]; then
    CXX=clang++ npm ci && break
  else
    npm ci && break
  fi

  if [[ $i == 5 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc
# }}}

# {{{ remove unwanted built-in extensions
echo "Removing unwanted built-in extensions..."
for ext in git git-base github github-authentication debug-auto-launch debug-server-ready; do
  if [[ -d "extensions/${ext}" ]]; then
    rm -rf "extensions/${ext}"
    echo "  Removed: ${ext}"
  fi
done
# }}}

# package.json
cp package.json{,.bak}

setpath "package" "version" "${RELEASE_VERSION%-insider}"

replace 's|Microsoft Corporation|Lasco|' package.json

cp resources/server/manifest.json{,.bak}

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "resources/server/manifest" "name" "VSCodium - Insiders"
  setpath "resources/server/manifest" "short_name" "VSCodium - Insiders"
else
  setpath "resources/server/manifest" "name" "Lasco"
  setpath "resources/server/manifest" "short_name" "Lasco"
fi

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|Lasco|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 Lasco|' build/lib/electron.ts
replace "s|VS Code HelpBook|Lasco HelpBook|g" build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to vscodium
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/codium-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/codium/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|VSCodium|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/VSCodium/vscodium#download-install|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|VSCodium Team https://github.com/VSCodium/vscodium/graphs/contributors|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|VSCodium|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/VSCodium/vscodium#download-install|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|VSCodium Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|VSCodium Team https://github.com/VSCodium/vscodium/graphs/contributors|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|VSCodium|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/VSCodium/vscodium#download-install|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|VSCodium|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    ISS_PATH="build/win32/code-insider.iss"
  else
    ISS_PATH="build/win32/code.iss"
  fi

  # code.iss
  sed -i 's|https://code.visualstudio.com|https://www.terracotta.dev|' "${ISS_PATH}"
  sed -i 's|Microsoft Corporation|Lasco|' "${ISS_PATH}"
fi

# {{{ PostHog analytics & session replay
WORKBENCH_HTML="src/vs/code/electron-browser/workbench/workbench.html"

if [[ -f "../posthog-init.js" && -f "${WORKBENCH_HTML}" ]]; then
  cp ../posthog-init.js "src/vs/code/electron-browser/workbench/posthog-init.js"

  # Inject <script> tag before </head>, update CSP for PostHog CDN + Trusted Types
  node -e "
    const fs = require('fs');
    let html = fs.readFileSync('${WORKBENCH_HTML}', 'utf8');
    html = html.replace('</head>', '\t<script src=\"posthog-init.js\"></script>\n\t</head>');
    // Allow PostHog CDN in script-src (multi-line CSP — add after 'self')
    html = html.replace(
      /(script-src\s[\s\S]*?)'self'/,
      \"\\\$1'self' https://eu-assets.i.posthog.com\"
    );
    // Add 'default' to trusted-types whitelist (not require-trusted-types-for)
    html = html.replace(
      /((?<!require-)trusted-types[\s\S]*?)(;\n)/,
      '\$1 default\$2'
    );
    fs.writeFileSync('${WORKBENCH_HTML}', html);
  "

  # Ensure posthog-init.js is included in vscodeResources so it survives the gulp bundleTask
  node -e "
    const fs = require('fs');
    const gulpfile = 'build/gulpfile.vscode.ts';
    let src = fs.readFileSync(gulpfile, 'utf8');
    const marker = 'out-build/vs/code/electron-browser/workbench/workbench.html';
    if (src.includes(marker) && !src.includes('posthog-init.js')) {
      src = src.replace(
        marker,
        marker + \"',\\n\\t'out-build/vs/code/electron-browser/workbench/posthog-init.js\"
      );
      fs.writeFileSync(gulpfile, src);
      console.log('Added posthog-init.js to vscodeResources in gulpfile.vscode.ts');
    } else {
      console.log('posthog-init.js already in vscodeResources or marker not found');
    }
  "

  # Inject PostHog child snippet into webview iframes for cross-origin session recording
  WEBVIEW_HTML="src/vs/workbench/contrib/webview/browser/pre/index.html"
  if [[ -f "${WEBVIEW_HTML}" ]]; then
    node -e "
      const fs = require('fs');
      let html = fs.readFileSync('${WEBVIEW_HTML}', 'utf8');

      // 1. Update outer CSP: allow PostHog CDN in script-src and add connect-src
      html = html.replace(
        /(script-src[^;]*)/,
        '\$1 https://eu-assets.i.posthog.com'
      );
      html = html.replace(
        /(style-src 'unsafe-inline';)/,
        \"\\\$1 connect-src https://eu.i.posthog.com;\"
      );

      // 2. Inject PostHog child snippet into toContentHtml() using DOM APIs
      //    The function uses DOMParser, so we create a script element on newDocument.head
      const phSnippetJs = '!function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(\\\".\\\");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement(\\\"script\\\")).type=\\\"text/javascript\\\",p.crossOrigin=\\\"anonymous\\\",p.async=!0,p.src=s.api_host.replace(\\\".i.posthog.com\\\",\\\"-assets.i.posthog.com\\\")+\\\"/static/array.js\\\",(r=t.getElementsByTagName(\\\"script\\\")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a=\\\"posthog\\\",u.people=u.people||[],u.toString=function(t){var e=\\\"posthog\\\";return\\\"posthog\\\"!==a&&(e+=\\\".\\\"+a),t||(e+=\\\" (stub)\\\"),e},u.people.toString=function(){return u.toString(1)+\\\".people (stub)\\\"},o=\\\"init capture register register_once register_for_session unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures on onFeatureFlags onSessionId getSurveys getActiveMatchingSurveys renderSurvey canRenderSurvey getNextSurveyStep identify setPersonProperties\\\".split(\\\" \\\"),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);posthog.init(\\\"phc_xRu36ASMkpDVQWeXZThwzlfY8cfottFshNpaLH833hG\\\",{api_host:\\\"https://eu.i.posthog.com\\\",session_recording:{recordCrossOriginIframes:true},autocapture:false,capture_pageleave:false});';

      const injection = [
        '',
        '\t\t\t// Inject PostHog session recording child snippet',
        '\t\t\t{',
        '\t\t\t\tconst phScript = newDocument.createElement(\"script\");',
        '\t\t\t\tphScript.textContent = \'' + phSnippetJs + '\';',
        '\t\t\t\tnewDocument.head.prepend(phScript);',
        '\t\t\t}',
        ''
      ].join('\\n');

      const marker = '// Inject default styles';
      if (html.includes(marker)) {
        html = html.replace(marker, injection + '\\n\\t\\t\\t' + marker);
        console.log('PostHog child snippet injected into toContentHtml()');
      } else {
        console.error('Could not find injection marker in toContentHtml()');
        process.exit(1);
      }

      fs.writeFileSync('${WEBVIEW_HTML}', html);
      console.log('Webview index.html patched successfully');
    "
  else
    echo "Warning: ${WEBVIEW_HTML} not found, skipping webview PostHog injection"
  fi

  echo "PostHog analytics injected into workbench"
else
  echo "Warning: posthog-init.js or ${WORKBENCH_HTML} not found, skipping PostHog injection"
fi
# }}}

cd ..
