/* AngbandFontPicker.h
 *
 * Custom font-selection sheet for FrogComposband.
 * Shows only fixed-pitch (monospace) fonts so the player can't accidentally
 * break the terminal layout by picking a proportional face.
 *
 * Usage — present as a document-modal sheet:
 *
 *   [AngbandFontPicker presentAsSheetOnWindow:parentWindow
 *                               initialFont:currentFont
 *                         completionHandler:^(NSFont *chosen) {
 *       if (chosen) { ... apply chosen font ... }
 *   }];
 */

#ifndef ANGBAND_FONT_PICKER_H
#define ANGBAND_FONT_PICKER_H

#import <Cocoa/Cocoa.h>

@interface AngbandFontPicker : NSWindowController
    <NSTableViewDataSource, NSTableViewDelegate>
{
    NSTableView  *_fontTable;
    NSTextField  *_sizeField;
    NSStepper    *_sizeStepper;
    NSView       *_previewView;
    NSTextField  *_previewLabel;

    NSArray      *_monoFamilies;   /* sorted list of monospace family names */
    NSFont       *_selectedFont;   /* the font the user has currently chosen */

    void (^_completionHandler)(NSFont *chosen); /* nil == cancelled */
}

/* Present the picker as a sheet attached to parentWindow.
 * completionHandler is called with the chosen font, or nil if cancelled. */
+ (void)presentAsSheetOnWindow:(NSWindow *)parentWindow
                   initialFont:(NSFont *)initialFont
             completionHandler:(void (^)(NSFont *chosen))handler;

/* The font currently shown in the picker (updated live as the user navigates). */
@property (nonatomic, strong) NSFont *selectedFont;

@end

#endif /* ANGBAND_FONT_PICKER_H */
