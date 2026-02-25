# Lasco (App Bundle Repo)

This repo contains the VSCodium fork that produces the Lasco.app macOS application. Active extension/service development happens in the sibling repo `~/Projects/lasco-dev`.

## Repo Structure

```
lasco/
├── vscode/                  # VSCodium source (Electron + VS Code)
├── VSCode-darwin-arm64/     # Built app bundle output (Lasco.app)
├── lasco/
│   ├── extensions/          # Staging dir for VSIX files (copied from lasco-dev)
│   └── template/            # Workspace template (CLAUDE.md, scripts, package.json)
├── assets/                  # Distribution outputs (ZIP, DMG)
│   └── dmg-background.png   # DMG background image (#180400, MLK quote)
├── sign-local.sh            # Codesign + notarize + staple + DMG
├── build.sh                 # Full VSCodium compilation from source
├── patches/                 # Branding and build patches
├── icons/                   # App icons
└── product.json             # Product metadata (name, URLs, etc.)
```

## Bundled Extensions

Extensions are declared in `~/Projects/lasco-dev/extensions.json` (single source of truth). Currently ships:

- **lasco** — Core extension: auth, file watcher, OCR proxy, search, WPS editor
- **claude-code** — Claude Code AI agent (prebuilt VSIX)

To build and stage extensions from `lasco-dev`:

```bash
cd ~/Projects/lasco-dev
bun run bundle          # builds + copies VSIXs to ../lasco/lasco/extensions/
bun run bundle:verify   # checks all expected VSIXs are present
```

## Release Build (macOS arm64)

### Prerequisites

- Xcode command line tools
- "Developer ID Application: Terracotta Cyber Solutions Limited (M4WGLKG3TR)" in keychain
- Notarytool keychain profile: `xcrun notarytool store-credentials lasco`
- `@electron/osx-sign` installed: `cd vscode && npm install @electron/osx-sign`
- `brew install create-dmg` (for DMG creation)

### Full Release Flow

1. **Build extensions** (in lasco-dev):

```bash
cd ~/Projects/lasco-dev
bun run bundle
```

2. **Install extensions into app bundle** — extract each VSIX from `lasco/extensions/` into the app bundle's extensions directory:

```bash
APP_EXT="VSCode-darwin-arm64/Lasco.app/Contents/Resources/app/extensions"

# For each extension, unzip VSIX and copy contents:
tmpdir=$(mktemp -d)
unzip -q lasco/extensions/lasco-0.1.0.vsix -d "$tmpdir"
rm -rf "$APP_EXT/lasco/dist" "$APP_EXT/lasco/static" "$APP_EXT/lasco/package.json"
cp -R "$tmpdir/extension/"* "$APP_EXT/lasco/"
rm -rf "$tmpdir"

# Same for claude-code (creates new dir if needed):
tmpdir=$(mktemp -d)
unzip -q lasco/extensions/Anthropic.claude-code-*.vsix -d "$tmpdir"
mkdir -p "$APP_EXT/claude-code"
cp -R "$tmpdir/extension/"* "$APP_EXT/claude-code/"
rm -rf "$tmpdir"
```

3. **Codesign, notarize, staple, and create ZIP**:

```bash
./sign-local.sh              # full pipeline: sign → notarize → staple → zip
./sign-local.sh --sign-only  # just codesign (skip notarization, for local testing)
./sign-local.sh --dmg        # also create DMG after notarization
```

4. **Create DMG manually** (with custom background):

```bash
create-dmg \
  --volname "Lasco" \
  --background assets/dmg-background.png \
  --window-pos 200 120 \
  --window-size 660 480 \
  --icon-size 120 \
  --icon "Lasco.app" 170 180 \
  --hide-extension "Lasco.app" \
  --app-drop-link 490 180 \
  --text-size 14 \
  assets/Lasco-darwin-arm64-VERSION.dmg \
  VSCode-darwin-arm64/Lasco.app
```

### Distribution Outputs

- `assets/Lasco-darwin-arm64-VERSION.zip` — signed + notarized + stapled ZIP
- `assets/Lasco-darwin-arm64-VERSION.dmg` — DMG with drag-to-Applications layout

### Codesign Identity

- **Identity:** Developer ID Application: Terracotta Cyber Solutions Limited (M4WGLKG3TR)
- **Notary profile:** `lasco` (stored via `xcrun notarytool store-credentials`)
- **Electron version:** 39.2.7 (must match the Electron version in the build)

## Building VSCodium from Source

Only needed when updating the base VSCodium version or applying new patches. This is a long process (~30 min).

```bash
./build.sh    # compiles VSCodium → outputs to VSCode-darwin-arm64/
```

The build process automatically runs `cleanup-extensions.sh` after VSCodium compilation to strip unnecessary language extensions and reduce app size.

### Extension Cleanup Strategy

Lasco removes ~70 unnecessary extensions (Python, Ruby, Go, Dart, etc.) to keep the app lightweight for legal research. This aligns with VSCodium's philosophy of minimal, curated builds.

**Kept extensions:**
- `lasco` — Lasco core extension
- `claude-code` — Claude Code AI agent
- `markdown-*` — Document editing
- `json` — Configuration
- `git` — Version control
- `github-*` — GitHub integration
- `simple-browser` — Open links to case law
- `theme-defaults`, `theme-solarized-dark` — UI themes
- `terminal-suggest` — Shell completion
- `extension-editing` — Edit extensions locally

**Customize:**
Edit `cleanup-extensions.sh` to adjust the `KEEP` array.

**Size breakdown (darwin-arm64):**
- Total app: ~893 MB
- Claude Code extension: 221 MB (96% of extensions)
- Essential extensions: ~8 MB (markdown, git, JSON, themes, etc.)
- Removed extensions: ~40 MB saved (~79 unnecessary language extensions)
- VSCodium core + Electron: ~664 MB

The cleanup script removed programming language support (Python, Ruby, Go, Dart, etc.) that lawyers don't need, saving ~40MB. Claude Code size is unavoidable as it's a prebuilt Anthropic extension.

For day-to-day extension updates, skip the full build — just update extensions in the existing app bundle and re-sign.

## Clean Install (for testing)

Remove all user data before testing a fresh install:

```bash
rm -rf ~/Applications/Lasco.app
rm -rf ~/Library/Application\ Support/Lasco
rm -rf ~/Library/Application\ Support/lasco
rm -rf ~/Library/Application\ Support/VSCodium
rm -rf ~/Library/Preferences/com.lasco.app.plist
rm -rf ~/.vscode-oss
```
