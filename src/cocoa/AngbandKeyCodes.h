/* AngbandKeyCodes.h
 *
 * Keyboard virtual key-code constants for the macOS Cocoa frontend.
 * These replace the Carbon HIToolbox/Events.h kVK_* constants so that
 * main-cocoa.m no longer needs to include <Carbon/Carbon.h>.
 *
 * Values are the stable macOS virtual keycodes defined by the hardware ADB
 * scan-code set; they have not changed since Mac OS X 10.0.
 *
 * When building for iOS/iPadOS, UIKey provides its own keyCode constants via
 * UIKeyboardHIDUsage (iOS 13.4+), which are *different* from these values.
 * Wrap usage of this header in #if TARGET_OS_OSX as needed.
 */

#ifndef ANGBAND_KEY_CODES_H
#define ANGBAND_KEY_CODES_H

/* Modifier / control keys */
#define AngbandKeyReturn          0x24
#define AngbandKeyTab             0x30
#define AngbandKeyDelete          0x33  /* Backspace / Delete (top-right of alpha area) */
#define AngbandKeyEscape          0x35
#define AngbandKeyKeypadEnter     0x4C  /* Enter on numeric keypad */

/* Map the kVK_* names used in main-cocoa.m to the Angband equivalents so the
 * rest of the file needs no changes other than removing the Carbon import. */
#define kVK_Return            AngbandKeyReturn
#define kVK_Tab               AngbandKeyTab
#define kVK_Delete            AngbandKeyDelete
#define kVK_Escape            AngbandKeyEscape
#define kVK_ANSI_KeypadEnter  AngbandKeyKeypadEnter

#endif /* ANGBAND_KEY_CODES_H */
