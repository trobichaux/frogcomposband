/* AngbandPreferencesWindowController.h
 *
 * Unified Preferences panel for FrogComposband (Cmd-,).
 * Three tabs: Font  |  Display  |  Sound
 *
 * The controller is a singleton; call +sharedPreferences to get or create it,
 * then -showWindow: to bring it to the front.
 *
 * Font changes are applied immediately to the main terminal when the user
 * clicks "Apply" or hits Return in the font tab.
 * Display/Sound changes are applied immediately on control interaction.
 */

#ifndef ANGBAND_PREFERENCES_WINDOW_CONTROLLER_H
#define ANGBAND_PREFERENCES_WINDOW_CONTROLLER_H

#import <Cocoa/Cocoa.h>

/* Callback types so the controller can drive AngbandContext without importing
 * main-cocoa.m internals.  The delegate (AngbandAppDelegate) sets these. */
typedef void (^AngbandFontChangeBlock)(NSFont *newFont);
typedef void (^AngbandResizeBlock)(NSInteger cols, NSInteger rows);

@interface AngbandPreferencesWindowController : NSWindowController

/* Singleton accessor */
+ (instancetype)sharedPreferences;

/* Called by the app delegate to wire up live callbacks */
- (void)setFontChangeHandler:(AngbandFontChangeBlock)handler;
- (void)setResizeHandler:(AngbandResizeBlock)handler;

/* Refresh the displayed font to match whatever is currently active */
- (void)setDisplayedFont:(NSFont *)font;

@end

#endif /* ANGBAND_PREFERENCES_WINDOW_CONTROLLER_H */
