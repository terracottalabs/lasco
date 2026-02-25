#!/usr/bin/env bash
# Lasco Extension Cleanup
# Removes unnecessary language extensions from the bundled VSCodium to reduce app size
# Keeps only extensions needed for legal research and document editing

set -e

if [[ -z "$1" ]]; then
  APP_EXT="${PWD}/VSCode-darwin-arm64/Lasco.app/Contents/Resources/app/extensions"
else
  APP_EXT="$1"
fi

if [[ ! -d "$APP_EXT" ]]; then
  echo "Error: Extension directory not found: $APP_EXT"
  exit 1
fi

echo "🧹 Cleaning up extensions in: $APP_EXT"
echo "---"

# Extensions to KEEP (legal research + document editing essentials)
KEEP=(
  "lasco"                          # Lasco core extension
  "claude-code"                     # Claude Code AI
  "markdown-basics"                 # Markdown syntax
  "markdown-language-features"      # Markdown editor
  "json"                            # JSON editing
  "git"                             # Git support
  "git-base"                        # Git base
  "github"                          # GitHub integration
  "github-authentication"           # GitHub auth
  "simple-browser"                  # Open links
  "theme-defaults"                  # Default theme
  "theme-solarized-dark"            # Alternative theme
  "terminal-suggest"                # Terminal completion (small, useful)
  "extension-editing"               # Edit extensions locally
)

# Create a string for matching (for grep)
KEEP_PATTERN=$(printf "|%s" "${KEEP[@]}" | cut -c 2-)

# Count before
BEFORE=$(ls -1 "$APP_EXT" | wc -l)

# Remove extensions NOT in the keep list
for ext_dir in "$APP_EXT"/*; do
  if [[ -d "$ext_dir" ]]; then
    ext_name=$(basename "$ext_dir")

    # Skip if it matches keep pattern
    if echo "$ext_name" | grep -qE "^($KEEP_PATTERN)$"; then
      size=$(du -sh "$ext_dir" | cut -f1)
      echo "✓ Keeping: $ext_name ($size)"
    else
      size=$(du -sh "$ext_dir" | cut -f1)
      echo "✗ Removing: $ext_name ($size)"
      rm -rf "$ext_dir"
    fi
  fi
done

# Count after
AFTER=$(ls -1 "$APP_EXT" | wc -l)
SAVED_SIZE=$(du -sh "$APP_EXT" | cut -f1)

echo "---"
echo "📊 Summary:"
echo "   Extensions before: $BEFORE"
echo "   Extensions after:  $AFTER"
echo "   Extensions removed: $((BEFORE - AFTER))"
echo "   Extensions folder size: $SAVED_SIZE"
