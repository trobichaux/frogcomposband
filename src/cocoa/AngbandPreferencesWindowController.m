/* AngbandPreferencesWindowController.m
 *
 * Copyright (c) 2024 FrogComposband contributors.
 * Licence: same as main-cocoa.m (GPL v2 or Angband licence).
 */

#import "AngbandPreferencesWindowController.h"
#import "AngbandFontPicker.h"

/* UserDefaults keys (must match main-cocoa.m) */
static NSString * const kFontNameKey  = @"FontName-0";
static NSString * const kFontSizeKey  = @"FontSize-0";
static NSString * const kFPSKey       = @"FramesPerSecond";
static NSString * const kSoundKey     = @"AllowSound";

/* ------------------------------------------------------------------ */
#pragma mark - Size preset

typedef struct { NSInteger cols; NSInteger rows; } SizePreset;

static const SizePreset kSizePresets[] = {
    { 80,  24 },
    { 80,  50 },
    { 132, 50 },
};
static const NSInteger kNumPresets = 3;

/* ------------------------------------------------------------------ */
#pragma mark - AngbandPreferencesWindowController

@interface AngbandPreferencesWindowController ()
{
    /* Font tab */
    NSTextField  *_fontNameLabel;
    NSButton     *_chooseFontButton;

    /* Display tab */
    NSSegmentedControl *_sizeControl;
    NSSlider     *_fpsSlider;
    NSTextField  *_fpsLabel;

    /* Sound tab */
    NSButton     *_soundCheck;

    /* Callbacks */
    AngbandFontChangeBlock _fontHandler;
    AngbandResizeBlock     _resizeHandler;

    /* Currently displayed font */
    NSFont *_displayedFont;
}
@end

@implementation AngbandPreferencesWindowController

/* ------------------------------------------------------------------ */
#pragma mark Singleton

+ (instancetype)sharedPreferences {
    static AngbandPreferencesWindowController *sInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sInstance = [[self alloc] init];
    });
    return sInstance;
}

/* ------------------------------------------------------------------ */
#pragma mark Init

- (id)init {
    NSRect frame = NSMakeRect(0, 0, 420, 280);
    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:(NSWindowStyleMaskTitled |
                             NSWindowStyleMaskClosable |
                             NSWindowStyleMaskMiniaturizable)
                    backing:NSBackingStoreBuffered
                      defer:YES];
    [win setTitle:@"FrogComposband Preferences"];
    [win center];
    [win autorelease];

    self = [super initWithWindow:win];
    if (!self) return nil;

    /* Load font from defaults */
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *fname = [defs stringForKey:kFontNameKey];
    CGFloat fsize   = [defs floatForKey:kFPSKey]; /* intentional misread fixed below */
    fsize = [defs floatForKey:kFontSizeKey];
    if (fsize < 6.0) fsize = 13.0;
    _displayedFont = [NSFont fontWithName:(fname ?: @"Menlo") size:fsize];
    if (!_displayedFont) _displayedFont = [NSFont fontWithName:@"Menlo" size:13.0];
    [_displayedFont retain];

    [self buildUI];
    return self;
}

- (void)dealloc {
    [_fontHandler release];
    [_resizeHandler release];
    [_displayedFont release];
    [super dealloc];
}

/* ------------------------------------------------------------------ */
#pragma mark Callback setters

- (void)setFontChangeHandler:(AngbandFontChangeBlock)handler {
    AngbandFontChangeBlock old = _fontHandler;
    _fontHandler = [handler copy];
    [old release];
}

- (void)setResizeHandler:(AngbandResizeBlock)handler {
    AngbandResizeBlock old = _resizeHandler;
    _resizeHandler = [handler copy];
    [old release];
}

- (void)setDisplayedFont:(NSFont *)font {
    if (!font) return;
    [font retain];
    [_displayedFont release];
    _displayedFont = font;
    [self refreshFontLabel];
}

- (void)refreshFontLabel {
    NSString *label = [NSString stringWithFormat:@"%@  %.0f pt",
        [_displayedFont familyName], [_displayedFont pointSize]];
    _fontNameLabel.stringValue = label;
    _fontNameLabel.font = [NSFont fontWithName:[_displayedFont fontName]
                                          size:12.0]
                          ?: [NSFont systemFontOfSize:12.0];
}

/* ------------------------------------------------------------------ */
#pragma mark UI construction

- (void)buildUI {
    NSView *root = [[self window] contentView];

    /* NSTabView */
    NSTabView *tabs = [[NSTabView alloc]
        initWithFrame:NSInsetRect([root bounds], 8, 8)];
    tabs.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [root addSubview:tabs];
    [tabs release];

    NSTabViewItem *fontItem    = [self buildFontTab];
    NSTabViewItem *displayItem = [self buildDisplayTab];
    NSTabViewItem *soundItem   = [self buildSoundTab];
    [tabs addTabViewItem:fontItem];
    [tabs addTabViewItem:displayItem];
    [tabs addTabViewItem:soundItem];
}

/* ---- Font tab ---- */
- (NSTabViewItem *)buildFontTab {
    NSTabViewItem *item = [[[NSTabViewItem alloc] init] autorelease];
    [item setLabel:@"Font"];

    NSView *v = [[[NSView alloc] initWithFrame:NSMakeRect(0,0,380,220)] autorelease];

    /* Current font name display */
    NSTextField *label = [[NSTextField alloc]
        initWithFrame:NSMakeRect(16, 155, 348, 28)];
    label.bordered = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    label.font = [NSFont systemFontOfSize:13.0];
    _fontNameLabel = label;
    [v addSubview:label];
    [label release];
    [self refreshFontLabel];

    /* "Choose Font…" button */
    NSButton *choose = [[NSButton alloc]
        initWithFrame:NSMakeRect(16, 110, 140, 32)];
    [choose setTitle:@"Choose Font\u2026"];
    [choose setBezelStyle:NSBezelStyleRounded];
    choose.target = self;
    choose.action = @selector(chooseFontPressed:);
    _chooseFontButton = choose;
    [v addSubview:choose];
    [choose release];

    /* Explanatory note */
    NSTextField *note = [[NSTextField alloc]
        initWithFrame:NSMakeRect(16, 70, 348, 36)];
    note.stringValue = @"Only fixed-width (monospace) fonts are shown.\n"
                        "The terminal requires a monospace font to display correctly.";
    note.bordered = NO;
    note.drawsBackground = NO;
    note.editable = NO;
    note.selectable = NO;
    note.font = [NSFont systemFontOfSize:11.0];
    note.textColor = [NSColor secondaryLabelColor];
    [v addSubview:note];
    [note release];

    [item setView:v];
    return item;
}

/* ---- Display tab ---- */
- (NSTabViewItem *)buildDisplayTab {
    NSTabViewItem *item = [[[NSTabViewItem alloc] init] autorelease];
    [item setLabel:@"Display"];

    NSView *v = [[[NSView alloc] initWithFrame:NSMakeRect(0,0,380,220)] autorelease];
    const CGFloat pad = 16.0;

    /* --- Size presets --- */
    NSTextField *sizeLabel = [[NSTextField alloc]
        initWithFrame:NSMakeRect(pad, 165, 200, 17)];
    sizeLabel.stringValue = @"Main window size:";
    sizeLabel.bordered = NO;
    sizeLabel.drawsBackground = NO;
    sizeLabel.editable = NO;
    sizeLabel.selectable = NO;
    sizeLabel.font = [NSFont boldSystemFontOfSize:12.0];
    [v addSubview:sizeLabel];
    [sizeLabel release];

    _sizeControl = [[NSSegmentedControl alloc]
        initWithFrame:NSMakeRect(pad, 130, 340, 30)];
    _sizeControl.segmentCount = kNumPresets + 1;
    [_sizeControl setLabel:@"80 \u00d7 24" forSegment:0];
    [_sizeControl setLabel:@"80 \u00d7 50" forSegment:1];
    [_sizeControl setLabel:@"132 \u00d7 50" forSegment:2];
    [_sizeControl setLabel:@"Custom" forSegment:3];
    _sizeControl.target = self;
    _sizeControl.action = @selector(sizePresetChanged:);
    [v addSubview:_sizeControl];

    NSTextField *sizeNote = [[NSTextField alloc]
        initWithFrame:NSMakeRect(pad, 105, 340, 20)];
    sizeNote.stringValue = @"Resizes the main terminal window immediately.";
    sizeNote.bordered = NO;
    sizeNote.drawsBackground = NO;
    sizeNote.editable = NO;
    sizeNote.selectable = NO;
    sizeNote.font = [NSFont systemFontOfSize:11.0];
    sizeNote.textColor = [NSColor secondaryLabelColor];
    [v addSubview:sizeNote];
    [sizeNote release];

    /* --- FPS --- */
    NSTextField *fpsLabel2 = [[NSTextField alloc]
        initWithFrame:NSMakeRect(pad, 72, 200, 17)];
    fpsLabel2.stringValue = @"Frames per second:";
    fpsLabel2.bordered = NO;
    fpsLabel2.drawsBackground = NO;
    fpsLabel2.editable = NO;
    fpsLabel2.selectable = NO;
    fpsLabel2.font = [NSFont boldSystemFontOfSize:12.0];
    [v addSubview:fpsLabel2];
    [fpsLabel2 release];

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSInteger fps = [defs integerForKey:kFPSKey];
    if (fps < 30 || fps > 120) fps = 60;

    _fpsSlider = [[NSSlider alloc]
        initWithFrame:NSMakeRect(pad, 44, 260, 22)];
    _fpsSlider.minValue   = 30.0;
    _fpsSlider.maxValue   = 120.0;
    _fpsSlider.intValue   = (int)fps;
    _fpsSlider.target = self;
    _fpsSlider.action = @selector(fpsChanged:);
    [v addSubview:_fpsSlider];

    _fpsLabel = [[NSTextField alloc]
        initWithFrame:NSMakeRect(pad + 268, 44, 52, 22)];
    _fpsLabel.stringValue = [NSString stringWithFormat:@"%ld fps", (long)fps];
    _fpsLabel.bordered = NO;
    _fpsLabel.drawsBackground = NO;
    _fpsLabel.editable = NO;
    _fpsLabel.selectable = NO;
    [v addSubview:_fpsLabel];

    [item setView:v];
    return item;
}

/* ---- Sound tab ---- */
- (NSTabViewItem *)buildSoundTab {
    NSTabViewItem *item = [[[NSTabViewItem alloc] init] autorelease];
    [item setLabel:@"Sound"];

    NSView *v = [[[NSView alloc] initWithFrame:NSMakeRect(0,0,380,220)] autorelease];

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BOOL soundOn = [defs boolForKey:kSoundKey];

    _soundCheck = [[NSButton alloc]
        initWithFrame:NSMakeRect(16, 155, 300, 22)];
    [_soundCheck setButtonType:NSButtonTypeSwitch];
    [_soundCheck setTitle:@"Enable sound effects"];
    _soundCheck.state = soundOn ? NSControlStateValueOn : NSControlStateValueOff;
    _soundCheck.target = self;
    _soundCheck.action = @selector(soundToggled:);
    [v addSubview:_soundCheck];

    NSTextField *soundNote = [[NSTextField alloc]
        initWithFrame:NSMakeRect(16, 120, 348, 32)];
    soundNote.stringValue = @"Sound effects will be active once audio support is enabled "
                             "in a future build. Your preference is saved now.";
    soundNote.bordered = NO;
    soundNote.drawsBackground = NO;
    soundNote.editable = NO;
    soundNote.selectable = NO;
    soundNote.font = [NSFont systemFontOfSize:11.0];
    soundNote.textColor = [NSColor secondaryLabelColor];
    [v addSubview:soundNote];
    [soundNote release];

    [item setView:v];
    return item;
}

/* ------------------------------------------------------------------ */
#pragma mark Actions

- (void)chooseFontPressed:(id __unused)sender {
    [AngbandFontPicker
        presentAsSheetOnWindow:[self window]
                   initialFont:_displayedFont
             completionHandler:^(NSFont *chosen) {
        if (!chosen) return;
        [self setDisplayedFont:chosen];
        /* Persist */
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        [defs setValue:[chosen fontName] forKey:kFontNameKey];
        [defs setFloat:[chosen pointSize]  forKey:kFontSizeKey];
        [defs synchronize];
        /* Notify app delegate */
        if (_fontHandler) _fontHandler(chosen);
    }];
}

- (void)sizePresetChanged:(NSSegmentedControl *)ctrl {
    NSInteger seg = ctrl.selectedSegment;
    if (seg >= kNumPresets) return; /* "Custom" — no automatic resize */
    SizePreset preset = kSizePresets[seg];
    if (_resizeHandler) _resizeHandler(preset.cols, preset.rows);
}

- (void)fpsChanged:(NSSlider *)slider {
    NSInteger fps = (NSInteger)round(slider.doubleValue);
    _fpsLabel.stringValue = [NSString stringWithFormat:@"%ld fps", (long)fps];
    [[NSUserDefaults standardUserDefaults] setInteger:fps forKey:kFPSKey];
    /* The global frames_per_second variable in main-cocoa.m is also updated
     * from UserDefaults on next read, but we signal it directly via a
     * notification so it takes effect without restarting. */
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"AngbandFPSChanged"
                      object:@(fps)];
}

- (void)soundToggled:(NSButton *)btn {
    BOOL on = (btn.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kSoundKey];
}

@end
