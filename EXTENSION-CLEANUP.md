# Lasco Extension Cleanup Strategy

## Overview

Lasco uses a **post-build extension cleanup approach** that aligns with VSCodium's philosophy of minimal, curated builds. This removes unnecessary programming language extensions to reduce app size while keeping everything needed for legal research.

## Why This Approach?

**Alignment with VSCodium Philosophy:**
- ✅ Minimal, modular builds (user gets only what they need)
- ✅ Transparent configuration (version-controlled)
- ✅ Maintainable and reproducible
- ✅ Easy to customize per use case

**Not a post-packaging hack:**
- The cleanup runs during the build process (`./build.sh`)
- Extensions are removed before final packaging/signing
- Configuration is documented in `cleanup-extensions.sh`

## Cleanup Script

**Location:** `./cleanup-extensions.sh`

**What it does:**
1. Removes 79 unnecessary programming language extensions (~40 MB saved)
2. Keeps only essential extensions for legal research
3. Provides detailed before/after reporting

**Integrated into build flow:**
```bash
./build.sh
# ... compiles VSCodium ...
# ... automatically runs cleanup-extensions.sh at the end ...
```

## Extensions Kept

| Extension | Reason |
|-----------|--------|
| `lasco` | Core functionality |
| `claude-code` | AI agent (221 MB, unavoidable) |
| `markdown-*` | Document editing for legal briefs |
| `json` | Configuration files |
| `git`, `git-base` | Version control |
| `github`, `github-authentication` | GitHub integration |
| `simple-browser` | Open links to case law |
| `theme-defaults`, `theme-solarized-dark` | UI theming |
| `terminal-suggest` | Shell completion |
| `extension-editing` | Edit extensions locally |

## Extensions Removed

All programming language support that lawyers don't use:
- Python, Ruby, Go, Rust, Java, C++, C#, Dart, Julia, Perl, R, Swift, etc.
- JavaScript, TypeScript, and their language features
- Build tools: npm, gulp, grunt, jake
- Containers: Docker
- Scientific: LaTeX, Jupyter
- Most themes (kept 1-2 defaults)

## Size Impact

**Before cleanup:**
```
Extensions folder: 269 MB
  - claude-code: 221 MB
  - Unnecessary extensions: 48 MB
  - Essential extensions: 0 MB (mixed in)
```

**After cleanup:**
```
Extensions folder: 229 MB
  - claude-code: 221 MB
  - Essential extensions: 8 MB
  - Saved: ~40 MB
```

**Total app bundle:** 893 MB
- VSCodium core + Electron: 664 MB (unavoidable)
- Claude Code: 221 MB (unavoidable, prebuilt)
- Essential extensions: 8 MB

## Future Optimization Opportunities

1. **Claude Code minification** (if smaller build available from Anthropic)
2. **VSCodium core optimization** (minimal core build)
3. **Optional Claude Code** (ship separately for users who don't need it)

## Customization

To adjust which extensions are kept:

```bash
# Edit the KEEP array in cleanup-extensions.sh
KEEP=(
  "lasco"
  "claude-code"
  # Add/remove extensions here
)

# Run manually to test
./cleanup-extensions.sh /path/to/extensions/dir
```

## Testing

After building, verify kept extensions are present:
```bash
ls VSCode-darwin-arm64/Lasco.app/Contents/Resources/app/extensions/
# Should show only ~15 directories
```

## Philosophy

> "Minimal, user-controlled builds" — VSCodium

Lasco follows this by:
- Not forcing unnecessary tooling on lawyers
- Being transparent about what's included
- Making it easy to customize
- Keeping size reasonable for distribution
