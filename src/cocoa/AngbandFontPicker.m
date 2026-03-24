/* AngbandFontPicker.m
 *
 * Copyright (c) 2024 FrogComposband contributors.
 * Licence: same as main-cocoa.m (GPL v2 or Angband licence).
 */

#import "AngbandFontPicker.h"
#import <CoreText/CoreText.h>

/* Characters used in the preview — chosen to exercise both wide and narrow
 * glyphs and to look like game output. */
static NSString * const kPreviewString =
    @"@.#$!?ACDFHIKMNPRSTUVWXacdfghiklmnprstuvwx 0123456789";

/* ------------------------------------------------------------------ */
#pragma mark - Preview view

/* A simple NSView that renders kPreviewString with the current font in
 * the same white-on-black colour the game uses. */
@interface AngbandFontPreviewView : NSView {
    NSFont *_font;
}
@property (nonatomic, retain) NSFont *previewFont;
@end

@implementation AngbandFontPreviewView

@synthesize previewFont = _font;

- (void)dealloc {
    [_font release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    /* Black background */
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);

    if (!_font) return;

    NSDictionary *attrs = @{
        NSFontAttributeName            : _font,
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.8
                                                                   green:0.8
                                                                    blue:0.8
                                                                   alpha:1.0]
    };
    NSAttributedString *str = [[NSAttributedString alloc]
        initWithString:kPreviewString attributes:attrs];
    NSRect textRect = NSInsetRect(self.bounds, 6.0, 4.0);
    [str drawInRect:textRect];
    [str release];
}

- (void)setPreviewFont:(NSFont *)font {
    [font retain];
    [_font release];
    _font = font;
    [self setNeedsDisplay:YES];
}

@end

/* ------------------------------------------------------------------ */
#pragma mark - Monospace font discovery

/* Returns YES if every glyph in a small representative set has the same
 * advance width — a reliable test for fixed-pitch fonts without relying on
 * the isFixedPitch flag (which some fonts set incorrectly). */
static BOOL IsFontMonospace(CTFontRef font) {
    /* Characters whose advance widths we compare */
    static const UniChar testChars[] = { 'i', 'W', 'm', '.', '@' };
    enum { kTestCount = 5 };

    CGGlyph glyphs[kTestCount];
    CGSize  advances[kTestCount];

    /* Get glyphs */
    CFIndex found = CTFontGetGlyphsForCharacters(font, testChars, glyphs, kTestCount);
    if (found == 0) return NO; /* font doesn't cover basic Latin */

    /* Get advances (CTFontGetAdvancesForGlyphs fills CGSize; we only need .width) */
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal,
                                glyphs, advances, kTestCount);

    /* All advance widths must be equal (within floating-point tolerance) */
    CGFloat ref = advances[0].width;
    if (ref < 1.0) return NO;
    for (int i = 1; i < kTestCount; i++) {
        if (fabs(advances[i].width - ref) > 0.5) return NO;
    }
    return YES;
}

/* Build a sorted array of monospace font family names.
 * Called once and cached. */
static NSArray *BuildMonoFamilyList(void) {
    NSFontManager *mgr = [NSFontManager sharedFontManager];
    NSArray *allFamilies = [mgr availableFontFamilies];
    NSMutableArray *mono = [NSMutableArray array];

    for (NSString *family in allFamilies) {
        /* Pick the first regular member of the family for testing */
        NSArray *members = [mgr availableMembersOfFontFamily:family];
        if ([members count] == 0) continue;
        NSString *postscriptName = [[members objectAtIndex:0] objectAtIndex:0];
        NSFont *nsFont = [NSFont fontWithName:postscriptName size:13.0];
        if (!nsFont) continue;

        CTFontRef ctFont = CTFontCreateWithName(
            (CFStringRef)[nsFont fontName], 13.0, NULL);
        if (!ctFont) continue;
        BOOL isMonospace = IsFontMonospace(ctFont);
        CFRelease(ctFont);

        if (isMonospace) [mono addObject:family];
    }

    return [mono sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

/* ------------------------------------------------------------------ */
#pragma mark - AngbandFontPicker

@implementation AngbandFontPicker

@synthesize selectedFont = _selectedFont;

- (void)dealloc {
    [_monoFamilies release];
    [_selectedFont release];
    [_completionHandler release];
    [super dealloc];
}

/* ----------------------------------------------------------
 * Public entry point
 * ---------------------------------------------------------- */
+ (void)presentAsSheetOnWindow:(NSWindow *)parentWindow
                   initialFont:(NSFont *)initialFont
             completionHandler:(void (^)(NSFont *chosen))handler
{
    AngbandFontPicker *picker =
        [[AngbandFontPicker alloc] initWithInitialFont:initialFont
                                     completionHandler:handler];
    [parentWindow beginSheet:[picker window]
           completionHandler:^(NSModalResponse __unused r) {
        [picker release];
    }];
}

/* ----------------------------------------------------------
 * Init
 * ---------------------------------------------------------- */
- (id)initWithInitialFont:(NSFont *)initialFont
        completionHandler:(void (^)(NSFont *))handler
{
    /* Build the panel */
    NSRect panelFrame = NSMakeRect(0, 0, 500, 380);
    NSWindow *panel = [[NSWindow alloc]
        initWithContentRect:panelFrame
                  styleMask:NSWindowStyleMaskTitled
                    backing:NSBackingStoreBuffered
                      defer:YES];
    [panel setTitle:@"Choose Font"];
    [panel autorelease];

    self = [super initWithWindow:panel];
    if (!self) return nil;

    _completionHandler = [handler copy];
    _monoFamilies = [BuildMonoFamilyList() retain];

    /* Determine initial selection */
    NSFont *startFont = initialFont ? initialFont : [NSFont fontWithName:@"Menlo" size:13.0];
    _selectedFont = [startFont retain];

    [self buildUI];
    [self selectInitialFont:startFont];

    return self;
}

/* ----------------------------------------------------------
 * UI construction (programmatic — no XIB needed)
 * ---------------------------------------------------------- */
- (void)buildUI {
    NSView *root = [[self window] contentView];
    const CGFloat pad = 12.0;
    const CGFloat W = NSWidth([root bounds]);
    const CGFloat H = NSHeight([root bounds]);

    /* ---- Font list (left column) ---- */
    NSScrollView *scroll = [[NSScrollView alloc]
        initWithFrame:NSMakeRect(pad, 80, 220, H - 100)];
    scroll.hasVerticalScroller = YES;
    scroll.borderType = NSBezelBorder;
    scroll.autoresizingMask = NSViewHeightSizable;

    _fontTable = [[NSTableView alloc] initWithFrame:[[scroll contentView] bounds]];
    NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"Family"];
    col.title = @"Font";
    col.width = 200;
    [_fontTable addTableColumn:col];
    [col release];
    _fontTable.headerView = nil;
    _fontTable.dataSource = self;
    _fontTable.delegate   = self;
    _fontTable.allowsMultipleSelection = NO;
    scroll.documentView = _fontTable;
    [root addSubview:scroll];
    [scroll release];

    /* ---- Size field + stepper (below list) ---- */
    NSTextField *sizeLabel = [[NSTextField alloc]
        initWithFrame:NSMakeRect(pad, 52, 55, 22)];
    sizeLabel.stringValue = @"Size:";
    sizeLabel.bordered = NO;
    sizeLabel.drawsBackground = NO;
    sizeLabel.editable = NO;
    sizeLabel.selectable = NO;
    [root addSubview:sizeLabel];
    [sizeLabel release];

    _sizeField = [[NSTextField alloc] initWithFrame:NSMakeRect(pad + 55, 52, 60, 22)];
    _sizeField.doubleValue = [_selectedFont pointSize];
    _sizeField.target = self;
    _sizeField.action = @selector(sizeFieldChanged:);
    [root addSubview:_sizeField];

    _sizeStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(pad + 117, 52, 20, 22)];
    _sizeStepper.minValue = 6.0;
    _sizeStepper.maxValue = 72.0;
    _sizeStepper.increment = 1.0;
    _sizeStepper.doubleValue = [_selectedFont pointSize];
    _sizeStepper.target = self;
    _sizeStepper.action = @selector(stepperChanged:);
    [root addSubview:_sizeStepper];

    /* ---- Preview (right column) ---- */
    NSTextField *previewLabel = [[NSTextField alloc]
        initWithFrame:NSMakeRect(244, H - 28, W - 244 - pad, 20)];
    previewLabel.stringValue = @"Preview";
    previewLabel.bordered = NO;
    previewLabel.drawsBackground = NO;
    previewLabel.editable = NO;
    previewLabel.selectable = NO;
    [root addSubview:previewLabel];
    [previewLabel release];

    AngbandFontPreviewView *preview = [[AngbandFontPreviewView alloc]
        initWithFrame:NSMakeRect(244, 80, W - 244 - pad, H - 110)];
    preview.previewFont = _selectedFont;
    preview.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    _previewView = preview;
    [root addSubview:preview];
    [preview release];

    /* ---- Buttons ---- */
    NSButton *cancel = [[NSButton alloc]
        initWithFrame:NSMakeRect(W - 180, 12, 80, 32)];
    [cancel setTitle:@"Cancel"];
    [cancel setBezelStyle:NSBezelStyleRounded];
    [cancel setKeyEquivalent:@"\e"];
    cancel.target = self;
    cancel.action = @selector(cancelPressed:);
    [root addSubview:cancel];
    [cancel release];

    NSButton *ok = [[NSButton alloc]
        initWithFrame:NSMakeRect(W - 90, 12, 80, 32)];
    [ok setTitle:@"OK"];
    [ok setBezelStyle:NSBezelStyleRounded];
    [ok setKeyEquivalent:@"\r"];
    ok.target = self;
    ok.action = @selector(okPressed:);
    [root addSubview:ok];
    [ok release];
}

/* ----------------------------------------------------------
 * Scroll to and highlight the row matching initialFont
 * ---------------------------------------------------------- */
- (void)selectInitialFont:(NSFont *)font {
    NSString *family = [font familyName];
    NSInteger row = [_monoFamilies indexOfObject:family];
    if (row == NSNotFound && [_monoFamilies count] > 0) row = 0;
    if (row != NSNotFound) {
        [_fontTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
                byExtendingSelection:NO];
        [_fontTable scrollRowToVisible:row];
    }
    _sizeField.doubleValue  = [font pointSize];
    _sizeStepper.doubleValue = [font pointSize];
}

/* ----------------------------------------------------------
 * NSTableViewDataSource
 * ---------------------------------------------------------- */
- (NSInteger)numberOfRowsInTableView:(NSTableView * __unused)tv {
    return (NSInteger)[_monoFamilies count];
}

- (id)tableView:(NSTableView * __unused)tv
objectValueForTableColumn:(NSTableColumn * __unused)col
            row:(NSInteger)row {
    return [_monoFamilies objectAtIndex:row];
}

/* ----------------------------------------------------------
 * NSTableViewDelegate — render each cell with its own font
 * ---------------------------------------------------------- */
- (void)tableViewSelectionDidChange:(NSNotification * __unused)note {
    [self updateSelectedFont];
}

- (NSView *)tableView:(NSTableView *)tv
   viewForTableColumn:(NSTableColumn * __unused)col
                  row:(NSInteger)row
{
    NSTableCellView *cell = [tv makeViewWithIdentifier:@"FontCell" owner:self];
    if (!cell) {
        cell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0,0,200,18)] autorelease];
        NSTextField *tf = [[[NSTextField alloc] initWithFrame:cell.bounds] autorelease];
        tf.bordered = NO;
        tf.drawsBackground = NO;
        tf.editable = NO;
        tf.autoresizingMask = NSViewWidthSizable;
        cell.textField = tf;
        [cell addSubview:tf];
        cell.identifier = @"FontCell";
    }
    NSString *family = [_monoFamilies objectAtIndex:row];
    cell.textField.font = [NSFont fontWithName:family size:12.0]
                          ?: [NSFont systemFontOfSize:12.0];
    cell.textField.stringValue = family;
    return cell;
}

/* ----------------------------------------------------------
 * Size controls
 * ---------------------------------------------------------- */
- (void)sizeFieldChanged:(id __unused)sender {
    _sizeStepper.doubleValue = _sizeField.doubleValue;
    [self updateSelectedFont];
}

- (void)stepperChanged:(id __unused)sender {
    _sizeField.doubleValue = _sizeStepper.doubleValue;
    [self updateSelectedFont];
}

- (void)updateSelectedFont {
    NSInteger row = _fontTable.selectedRow;
    if (row < 0 || row >= (NSInteger)[_monoFamilies count]) return;

    NSString *family = [_monoFamilies objectAtIndex:row];
    CGFloat size = MAX(6.0, _sizeStepper.doubleValue);

    /* Try to get the regular weight member; fall back to the family name */
    NSFont *font = [NSFont fontWithName:family size:size];
    if (!font) {
        NSArray *members = [[NSFontManager sharedFontManager]
            availableMembersOfFontFamily:family];
        for (NSArray *m in members) {
            /* members[i] = [postscriptName, displayName, weight, traits] */
            NSFont *candidate = [NSFont fontWithName:[m objectAtIndex:0] size:size];
            if (candidate) { font = candidate; break; }
        }
    }
    if (!font) return;

    self.selectedFont = font;
    [(AngbandFontPreviewView *)_previewView setPreviewFont:font];
}

/* ----------------------------------------------------------
 * Button actions
 * ---------------------------------------------------------- */
- (void)okPressed:(id __unused)sender {
    NSWindow *sheet = [self window];
    NSWindow *parent = [sheet sheetParent];
    void (^handler)(NSFont *) = [[_completionHandler retain] autorelease];
    NSFont *chosen = [[_selectedFont retain] autorelease];
    [parent endSheet:sheet];
    if (handler) handler(chosen);
}

- (void)cancelPressed:(id __unused)sender {
    NSWindow *sheet = [self window];
    NSWindow *parent = [sheet sheetParent];
    void (^handler)(NSFont *) = [[_completionHandler retain] autorelease];
    [parent endSheet:sheet];
    if (handler) handler(nil);
}

@end
