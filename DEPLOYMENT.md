# macOS Installation & Deployment Guide

## Building from Source

### Prerequisites

- **macOS 12.0** or later
- **Xcode Command Line Tools** (`xcode-select --install`)
- **LLVM/Clang** compiler (included with Xcode)

### Build Steps

```bash
cd frogcomposband/src
make -f Makefile.osx clean
make -f Makefile.osx -j4
```

This creates `FrogComposband.app` in the parent directory.

### Build Output

- **Executable:** `FrogComposband.app/Contents/MacOS/FrogComposband`
- **Bundle Size:** ~5-6 MB (stripped)
- **Resources:** Included in `FrogComposband.app/Contents/Resources/`

## Creating a Distributable Package

### Option 1: DMG (Recommended for Distribution)

```bash
cd frogcomposband
hdiutil create -volname "FrogComposband" -srcfolder FrogComposband.app \
  -ov -format UDZO FrogComposband-7.1.salmiak.dmg
```

**Result:** `FrogComposband-7.1.salmiak.dmg` (~6.4 MB)
- Users download and mount the DMG
- Drag app to Applications folder
- Launch from Spotlight or Applications

### Option 2: Zip Archive

```bash
cd frogcomposband
ditto -c -k --sequesterRsrc FrogComposband.app FrogComposband-7.1.salmiak.zip
```

**Result:** `FrogComposband-7.1.salmiak.zip` (~4-5 MB)
- Users extract and move app to Applications

### Option 3: Direct App Distribution

Simply provide `FrogComposband.app` in a zip or upload to a web server.

## Code Signing (Optional)

For distribution outside the App Store or to add trusted certificate:

```bash
# Sign with ad-hoc identity (works on the machine that built it)
codesign -s - FrogComposband.app

# Sign with valid Apple Developer ID (requires certificate)
codesign -s "Developer ID Application: Your Name" FrogComposband.app

# Verify signature
codesign -v FrogComposband.app
```

## Notarization (Optional, for Gatekeeper bypass)

For wider distribution, Apple notarization removes Gatekeeper warnings:

```bash
# Notarize (requires Apple Developer account)
xcrun altool --notarize-app -f FrogComposband-7.1.salmiak.dmg \
  -primary-bundle-id com.trobichaux.frogcomposband \
  -username YOUR_APPLE_ID -password @keychain:AC_PASSWORD

# Staple notarization ticket
xcrun stapler staple FrogComposband-7.1.salmiak.dmg
```

## Distribution Channels

### 1. GitHub Releases

1. Push changes to GitHub
2. Create a new release with tag `v7.1.salmiak`
3. Upload DMG as release artifact
4. Add RELEASE_NOTES.md content to release description

### 2. Homebrew Cask

Create a formula in a tap repository:

```ruby
cask 'frogcomposband' do
  version '7.1.salmiak'
  sha256 'CHECKSUM_OF_DMG'
  url "https://github.com/trobichaux/frogcomposband/releases/download/v#{version}/FrogComposband-#{version}.dmg"
  name 'FrogComposband'
  homepage 'https://github.com/trobichaux/frogcomposband'
  app 'FrogComposband.app'
end
```

### 3. Website

Host the DMG on your website with installation instructions pointing users to:
1. Download the DMG
2. Mount it (double-click)
3. Drag app to Applications
4. Launch

## Deployment Checklist

- [ ] Code changes committed and pushed
- [ ] App builds successfully: `make -f Makefile.osx clean && make -f Makefile.osx`
- [ ] No compiler warnings (or documented)
- [ ] Release notes created (`RELEASE_NOTES.md`)
- [ ] DMG created: `hdiutil create ...`
- [ ] DMG tested on target macOS version
- [ ] Version numbers updated in:
  - [ ] `src/Makefile.osx` (VERSION variable if needed)
  - [ ] DMG filename
  - [ ] Release notes
- [ ] GitHub release created with:
  - [ ] DMG uploaded
  - [ ] Release notes in description
  - [ ] Correct version tag
- [ ] Announcement posted (if applicable)

## Testing Deployment

1. **Delete local app:** `rm -rf /Applications/FrogComposband.app`
2. **Mount DMG:** `open FrogComposband-7.1.salmiak.dmg`
3. **Install:** Drag app to Applications folder
4. **Test:** Launch from Spotlight (Cmd+Space, type "FrogComposband")
5. **Verify UI:** Test font picker and all menus

## Troubleshooting

### "Application is damaged" error

**Cause:** Gatekeeper blocking unsigned app
**Solution:** 
```bash
xattr -d com.apple.quarantine /Applications/FrogComposband.app
```

Or enable unsigned app execution (Security & Privacy settings).

### Build fails with MACH_O_CARBON undefined

**Cause:** Not using Makefile.osx
**Solution:** Always use: `make -f Makefile.osx`

### Fonts not rendering

**Cause:** Font selection issue
**Fix:** Use Edit > Font menu to select a monospace font (Menlo, Monaco, etc.)

## Size Optimization

- **App Bundle:** ~5-6 MB (includes all game data)
- **DMG (compressed):** ~6.4 MB
- **Zip Archive:** ~4-5 MB

To reduce size, remove unused graphics/sound:
```bash
rm -rf FrogComposband.app/Contents/Resources/lib/xtra/graf/*.png
rm -rf FrogComposband.app/Contents/Resources/lib/xtra/sound/*.mp3
```

## Version Management

Update version strings consistently:

1. **Makefile.osx:**
   ```makefile
   VERSION = 7.1.salmiak
   ```

2. **Release files:**
   - DMG: `FrogComposband-7.1.salmiak.dmg`
   - Zip: `FrogComposband-7.1.salmiak.zip`

3. **Git tag:**
   ```bash
   git tag -a v7.1.salmiak -m "FrogComposband 7.1.salmiak macOS build"
   git push origin v7.1.salmiak
   ```

---

For questions or issues, consult the main [readme.txt](readme.txt) or check the [AGENTS.md](AGENTS.md) developer guide.
