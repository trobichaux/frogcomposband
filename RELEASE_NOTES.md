# FrogComposband 7.1.salmiak - macOS Release

**Release Date:** June 15, 2026

## Overview

This is a native macOS Cocoa build of FrogComposband 7.1.salmiak. The application now runs as a full-featured native macOS application with proper window management, menus, and a responsive UI.

## What's Fixed

### 🎯 Critical: Font Picker UI Freeze (Resolved)

**Issue:** When opening the "Edit Font..." menu option, the entire application UI would freeze and become unresponsive. Clicking anywhere would generate a warning beep, and the only recourse was to force-quit the application.

**Root Cause:** The font picker (`AngbandFontPicker`) was not being retained in memory after display, causing the window controller to be deallocated while the sheet was still shown. This left the UI event handlers orphaned.

**Solution:** Updated the font picker to use ARC (Automatic Reference Counting) compatible memory management with a strong `selfReference` property that keeps the picker alive during sheet display and is cleared when the sheet closes.

**Status:** ✅ Resolved - Font picker is now fully responsive and functional.

## Build Information

- **Platform:** macOS (Apple Silicon and Intel)
- **Deployment Target:** macOS 12.0+
- **Build System:** Native Cocoa (Makefile.osx)
- **Memory Management:** ARC (Automatic Reference Counting)

## Installation

1. Download `FrogComposband-7.1.salmiak.dmg`
2. Double-click the DMG to mount it
3. Drag `FrogComposband.app` to your Applications folder
4. Launch from Applications or Spotlight search

## Features

- **Native macOS Interface:** Full Cocoa framework integration with system menus and windows
- **Responsive UI:** Font picker and all dialogs work smoothly without freezing
- **Customizable Fonts:** Select from monospace fonts with live preview
- **Full Game Functionality:** All roguelike features and gameplay intact

## Known Limitations

- Graphics tiles (PNG format) are optional and not included in this build
- Sound support requires manual configuration
- Preferences are stored in the standard macOS locations

## Technical Details

### Development Guidelines

For developers working with the macOS Cocoa backend:

1. **Build Command:**
   ```bash
   cd src && make -f Makefile.osx clean && make -f Makefile.osx -j4
   ```

2. **ARC Compatibility:** All Objective-C code must be compatible with Automatic Reference Counting. Do not use manual `retain`/`release` calls.

3. **Font Picker Pattern:** The font picker implementation demonstrates proper ARC memory management for modal sheets. Use it as a reference for future modal dialogs.

### Memory Management

The font picker fix showcases proper ARC patterns for keeping objects alive during asynchronous operations:
- Use strong properties to extend object lifetime
- Clear references when operations complete
- Avoid manual memory management (retain/release)

## Testing Checklist

- ✅ Application launches successfully
- ✅ Main game window displays correctly
- ✅ Font picker opens and responds to clicks
- ✅ Font selection works without UI freeze
- ✅ OK and Cancel buttons function properly
- ✅ Preferences dialog accessible and responsive
- ✅ Game rendering and controls functional

## Support

For bug reports or feature requests, please visit the FrogComposband repository:
https://github.com/trobichaux/frogcomposband

## License

FrogComposband is licensed under the GNU General Public License v2 (GPLv2) or the Angband license.

---

**Built with:** Xcode/LLVM, macOS 12.0+ SDK
**Package:** FrogComposband-7.1.salmiak.dmg (6.4 MB)
