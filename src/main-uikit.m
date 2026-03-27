/* main-uikit.m — Skeleton UIKit frontend for FrogComposband (iPad / iPhone)
 *
 * Copyright (c) 2024 FrogComposband contributors.
 * Licence: same as main-cocoa.m (GPL v2 or Angband licence).
 *
 * This file is compiled ONLY when TARGET_OS_IOS is defined (i.e. in an Xcode
 * target building for iPadOS/iOS).  On macOS the whole file is a no-op.
 *
 * Architecture overview
 * ----------------------
 * The game's terminal abstraction (z-term.c) communicates with the platform
 * layer through five hook function pointers set in Term_init_uikit():
 *
 *   Term_text_uikit   — draw N characters at (x, y) with attribute a
 *   Term_wipe_uikit   — erase N cells starting at (x, y)
 *   Term_curs_uikit   — draw the cursor at (x, y)
 *   Term_xtra_uikit   — miscellaneous events (flush, delay, sound, …)
 *   Term_init_uikit   — called once per terminal at startup
 *
 * Rendering strategy (mirrors main-cocoa.m)
 * ------------------------------------------
 * Each terminal maps to an AngbandUIView (UIView subclass) backed by a
 * CALayer.  All drawing is done into an off-screen CGLayerRef (the same
 * CoreGraphics path used on macOS); the result is composited by CALayer.
 * This means the drawing primitives in main-cocoa.m can be reused almost
 * verbatim once the NSView ↔ UIView wrapper differences are addressed.
 *
 * Input
 * ------
 * UIKeyInput / UITextInput for hardware-keyboard events (iPad with Smart
 * Keyboard or Magic Keyboard).  UIGestureRecognizer for touch input (tap to
 * move, swipe for directional commands).  See TODO markers below.
 *
 * File I/O
 * ---------
 * NSOpenPanel / NSSavePanel are macOS-only.  On iOS use
 * UIDocumentPickerViewController (see angband_open_file_dialog stub in
 * main-cocoa.m) and the Files app sandbox.
 *
 * Build instructions
 * -------------------
 * 1. Create an Xcode project with an iPadOS App target.
 * 2. Add all C source files from src/ (same set as Makefile.osx) EXCEPT
 *    main-cocoa.m; add main-uikit.m instead.
 * 3. Link: UIKit, CoreGraphics, CoreText, AVFoundation.
 * 4. Set MACH_O_CARBON=1 in Other C Flags (the Angband glue expects it).
 * 5. Set the bundle identifier, icons, etc. from FrogComposband.app.
 */

#if TARGET_OS_IOS   /* ---- entire file guarded ---- */

#undef BOOL
#undef bool
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>

#include "angband.h"   /* term, Term_keypress, etc. */

/* ======================================================================
 * Section 1: AngbandUIContext — per-terminal state
 * ====================================================================== */

@interface AngbandUIContext : NSObject
{
@public
    term     *terminal;
    size_t    cols;
    size_t    rows;
    CGSize    tileSize;
    CGSize    borderSize;
    CGLayerRef angbandLayer;   /* off-screen rendering surface */
    NSFont   *font;            /* NOTE: on iOS use UIFont instead */

    /* UIView that displays this terminal */
    UIView   *view;
}

/* TODO: add overdraw cache (same wchar_t / int arrays as main-cocoa.m) */

- (instancetype)initWithCols:(size_t)cols rows:(size_t)rows;
- (CGContextRef)lockFocus;
- (void)unlockFocus;
- (CGRect)rectForTileAtX:(int)x y:(int)y;
- (void)setNeedsDisplay;

@end

@implementation AngbandUIContext

- (instancetype)initWithCols:(size_t)c rows:(size_t)r {
    self = [super init];
    if (!self) return nil;
    cols = c;
    rows = r;
    borderSize = CGSizeMake(2, 2);
    /* TODO: compute tileSize from the chosen font's metrics (same as
     *       updateGlyphInfo in main-cocoa.m) */
    tileSize = CGSizeMake(8, 16); /* placeholder */
    return self;
}

- (void)dealloc {
    if (angbandLayer) { CGLayerRelease(angbandLayer); angbandLayer = NULL; }
    [super dealloc];
}

/* TODO: implement lockFocus / unlockFocus using CGLayerGetContext, mirroring
 *       main-cocoa.m's lockFocus / unlockFocus. */
- (CGContextRef)lockFocus  { return NULL; }
- (void)unlockFocus        {}

- (CGRect)rectForTileAtX:(int)x y:(int)y {
    return CGRectMake(borderSize.width  + x * tileSize.width,
                      borderSize.height + y * tileSize.height,
                      tileSize.width, tileSize.height);
}

- (void)setNeedsDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{ [view setNeedsDisplay]; });
}

@end

/* ======================================================================
 * Section 2: AngbandUIView — UIView that renders a terminal
 * ====================================================================== */

@interface AngbandUIView : UIView
{
    AngbandUIContext *_context;
}
- (instancetype)initWithContext:(AngbandUIContext *)ctx frame:(CGRect)frame;
@end

@implementation AngbandUIView

- (instancetype)initWithContext:(AngbandUIContext *)ctx frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _context = [ctx retain];
    ctx->view = self;
    self.backgroundColor = [UIColor blackColor];
    /* TODO: add UITapGestureRecognizer for touch-to-move, long-press for
     *       context menu, pinch for font size change */
    return self;
}

- (void)dealloc {
    [_context release];
    [super dealloc];
}

- (void)drawRect:(CGRect __unused)rect {
    /* TODO: composite _context->angbandLayer into the current CGContext,
     *       mirroring AngbandView's drawRect: in main-cocoa.m. */
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    /* Placeholder: fill black */
    CGContextSetGrayFillColor(ctx, 0.0, 1.0);
    CGContextFillRect(ctx, self.bounds);
}

@end

/* ======================================================================
 * Section 3: Term hooks
 * ====================================================================== */

/* Global array of per-terminal contexts, parallel to angband_term[] */
static AngbandUIContext *uikit_contexts[ANGBAND_TERM_MAX];

static errr Term_text_uikit(int x, int y, int n, byte_hack a, cptr cp)
{
    AngbandUIContext *ctx = (__bridge AngbandUIContext *)Term->data;
    /* TODO: mirror Term_text_cocoa:
     *   1. Update charOverdrawCache / attrOverdrawCache
     *   2. lockFocus on angbandLayer
     *   3. Fill black background rect
     *   4. Set text colour via set_color_for_index(a)
     *   5. drawWChar(cp[i]) for each i in [0, n)
     *   6. Handle overdraw for left (x-1) and right (x+n) neighbours
     *   7. unlockFocus; setNeedsDisplay */
    (void)ctx; (void)x; (void)y; (void)n; (void)a; (void)cp;
    return 0;
}

static errr Term_wipe_uikit(int x, int y, int n)
{
    AngbandUIContext *ctx = (__bridge AngbandUIContext *)Term->data;
    /* TODO: mirror Term_wipe_cocoa:
     *   1. Zero charOverdrawCache/attrOverdrawCache for cells [x, x+n) in row y
     *   2. lockFocus; fill black rect; unlockFocus; setNeedsDisplay */
    (void)ctx; (void)x; (void)y; (void)n;
    return 0;
}

static errr Term_curs_uikit(int x, int y)
{
    AngbandUIContext *ctx = (__bridge AngbandUIContext *)Term->data;
    /* TODO: mirror Term_curs_cocoa:
     *   Draw a 1-cell white/yellow outline rect at (x, y) */
    (void)ctx; (void)x; (void)y;
    return 0;
}

static errr Term_xtra_uikit(int n, int v)
{
    /* TODO: mirror Term_xtra_cocoa:
     *   TERM_XTRA_EVENT  — run the UIKit run loop to drain events
     *   TERM_XTRA_FLUSH  — flush drawing to screen
     *   TERM_XTRA_DELAY  — sleep for v milliseconds
     *   TERM_XTRA_REACT  — re-read terminal settings after resize
     *   TERM_XTRA_NOISE  — play a system sound (AudioServicesPlaySystemSound)
     *   TERM_XTRA_SOUND  — play named sound via AVAudioPlayer */
    (void)n; (void)v;
    return 0;
}

static void Term_init_uikit(term *t)
{
    /* TODO: mirror Term_init_cocoa:
     *   1. Load saved font / size from NSUserDefaults
     *   2. Create AngbandUIContext with saved cols / rows
     *   3. Create AngbandUIView and add it to the window scene
     *   4. Set t->data = context */
    (void)t;
}

/* ======================================================================
 * Section 4: Angband initialisation entry point
 * ====================================================================== */

/* Called from UIApplicationDelegate on a background thread.
 * Mirrors the work done inside [AngbandContext beginGame] in main-cocoa.m. */
static void angband_uikit_start(void)
{
    /* TODO:
     *   1. Set ANGBAND_SYS = "ios" (or "mac" to reuse pref-mac.prf)
     *   2. For each terminal index i in [0, ANGBAND_TERM_MAX):
     *        a. Allocate a term struct
     *        b. Call term_init(t, cols, rows, …)
     *        c. Call Term_init_uikit(t)
     *        d. Set angband_term[i] = t
     *   3. Term_activate(angband_term[0])
     *   4. init_angband()   ← game main loop; does not return until quit
     *   5. Dispatch back to main thread to exit the app */
}

/* ======================================================================
 * Section 5: UIApplicationDelegate
 * ====================================================================== */

@interface AngbandUIAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AngbandUIAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    (void)application; (void)launchOptions;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    /* TODO: create root UIViewController, add AngbandUIView for term[0] */
    [self.window makeKeyAndVisible];

    /* Run the game on a background thread so UIKit remains responsive */
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        angband_uikit_start();
    });

    return YES;
}

@end

/* ======================================================================
 * Section 6: main()
 * ====================================================================== */

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
                                 NSStringFromClass([AngbandUIAppDelegate class]));
    }
}

#endif /* TARGET_OS_IOS */
