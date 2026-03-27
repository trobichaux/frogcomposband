# ARC Migration + XCTest Design

**Date:** 2026-03-26
**Status:** Approved

## Overview

Two parallel tracks in a single effort:

1. **ARC Migration** — modernize the three Objective-C source files from manual retain/release to Automatic Reference Counting, and clean up deprecated API usage.
2. **XCTest Target** — add an Xcode test project that covers the Cocoa layer, providing a foundation for ongoing testing and validating the ARC migration.

The existing Makefile build is untouched.

---

## Track 1: ARC Migration

### Files Changed

| File | Changes |
|---|---|
| `src/Makefile.osx` | Add `-fobjc-arc` to `OBJ_CFLAGS` |
| `src/main-cocoa.m` | Remove retain/release/autorelease, replace NSAutoreleasePool, fix color APIs, add `__bridge` casts where needed |
| `src/cocoa/AngbandFontPicker.m` | Remove manual retain/release on `_font` |
| `src/cocoa/AngbandPreferencesWindowController.m` | Remove manual retain/release throughout |

### Changes in Detail

**`src/Makefile.osx`**
Add `-fobjc-arc` to `OBJ_CFLAGS`. This is the enforcement mechanism — the compiler errors on any surviving manual memory management, so incomplete migration is impossible to ship accidentally.

**`src/main-cocoa.m`**
- Replace all `NSAutoreleasePool` alloc/drain/release patterns with `@autoreleasepool { }` blocks (15+ instances)
- Remove all `[obj retain]`, `[obj release]`, `[obj autorelease]` calls
- Replace `colorWithCalibratedRed:green:blue:alpha:` with `colorWithSRGBRed:green:blue:alpha:`
- Add `__bridge` casts at C/ObjC boundaries where ObjC objects are passed through `void *`

**`src/cocoa/AngbandFontPicker.m`**
Remove manual retain/release on `_font`; ARC manages property lifecycle automatically.

**`src/cocoa/AngbandPreferencesWindowController.m`**
Remove manual retain/release throughout; property setters become trivial under ARC.

### Verification

A clean build with `-fobjc-arc` is the primary correctness signal — the compiler rejects any manual memory management left behind.

---

## Track 2: XCTest Target

### Directory Structure

```
FrogCompsbandTests/
  FrogComposband.xcodeproj
  FrogCompsbandTests/
    AppDelegateTests.m
    FontPickerTests.m
    PreferencesTests.m
    SoundDiscoveryTests.m
```

### Test Coverage

| File | What It Tests |
|---|---|
| `AppDelegateTests.m` | `AppDelegate` allocates and `applicationDidFinishLaunching:` runs without exception |
| `FontPickerTests.m` | `AngbandFontPicker` instantiates and `availableFonts` returns a non-empty list |
| `PreferencesTests.m` | Preferences round-trip correctly to/from `NSUserDefaults`; cleans up after each test |
| `SoundDiscoveryTests.m` | Bundle contains `sound.cfg` and it is non-empty and parseable |

### Xcode Project Setup

- One target: the test bundle
- Compiles `AngbandFontPicker.m`, `AngbandPreferencesWindowController.m`, and the relevant portions of `main-cocoa.m` directly — no C game engine files
- XCTest provides its own host; no stub `main` needed
- Deployment target: macOS 12.0 (matches main build)

### Out of Scope

Anything requiring the C game engine to be initialized is explicitly out of scope. The game loop, dungeon generation, monster AI, combat, and rendering all depend on global state initialized by `main()` and are not practical to unit test in isolation.

---

## CI Integration

Add a step to `.github/workflows/build-macos.yml` after "Build app bundle":

```yaml
- name: Run tests
  run: |
    xcodebuild test \
      -project FrogCompsbandTests/FrogComposband.xcodeproj \
      -scheme FrogCompsbandTests \
      -destination 'platform=macOS'
```

This runs on every push and PR, not just tag pushes.

---

## Implementation Order

1. ARC migration (`src/Makefile.osx`, then each `.m` file, verify clean build)
2. XCTest project scaffold (`.xcodeproj`, empty test files)
3. Test implementations (one file at a time)
4. CI step

Tracks are independent — ARC migration can be verified before XCTest work begins.
