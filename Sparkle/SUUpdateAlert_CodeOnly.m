//
//  SUUpdateAlert_CodeOnly.m
//  Sparkle
//
//  Created by Noah Nübling on 07.07.25.
//  Copyright © 2025 Sparkle Project. All rights reserved.
//

/// This is a pure-code replacement for SUUpdateAlert.xib
///     The main benefit of this is that it allows adjusting the design by macOS version via `if (@available())` guards

#import "SUUpdateAlert_CodeOnly.h"
#import "SUUpdateAlert.h"


#pragma clang diagnostic ignored "-Wgnu-auto-type"
#pragma clang diagnostic ignored "-Wkeyword-macro"
#pragma clang diagnostic ignored "-Wc++98-compat"
#pragma clang diagnostic ignored "-Wvariadic-macros"
#pragma clang diagnostic ignored "-Wobjc-messaging-id"

#define TOSTR(str) #str

#define nowarn_begin(warning)                           \
    _Pragma("clang diagnostic push")                    \
    _Pragma(TOSTR(clang diagnostic ignored #warning))

#define nowarn_end() \
    _Pragma("clang diagnostic pop")

#define auto __auto_type
#define stringf(fmt, args...) [NSString stringWithFormat: fmt, args]

NSWindow *SUUpdateAlert_makeWindow(SUUpdateAlert *owner) {
    
    /// MARK: SUI Componenents
    
    auto sui_window = ^ NSWindow * (NSView *contentView) {
        auto v = [[NSWindow alloc] init];
        v.styleMask = 0
            | NSWindowStyleMaskClosable
            | NSWindowStyleMaskMiniaturizable
            | NSWindowStyleMaskResizable
            | NSWindowStyleMaskTitled
        ;
        v.contentView = contentView;
        return v;
    };
    
    #define sui_view(classname) ({                                  \
        auto _result = [[classname alloc] init];                    \
        _result.translatesAutoresizingMaskIntoConstraints = NO;     \
        _result;                                                    \
    })
    
    auto sui_button = ^ NSButton * (NSString *title) {
        auto v = sui_view(NSButton);
        v.controlSize = NSControlSizeLarge;
        v.title = title;
        return v;
    };
    auto sui_button_default = ^ NSButton * (NSString *title) {
        auto v = sui_button(title);
        v.keyEquivalent = stringf(@"%c", NSCarriageReturnCharacter);
        return v;
    };
    
    auto sui_checkbox = ^ NSButton * (NSString *title) {
        auto v = sui_view(NSButton);
        [v setButtonType: NSButtonTypeSwitch];
        v.controlSize = NSControlSizeSmall;
        v.title = title;
        return v;
    };
    
    auto sui_image = ^ NSImageView * (NSString *imageName, double width) {
        auto v = sui_view(NSImageView);
        
        auto image = [NSImage imageNamed: imageName];
        v.image = image;
        
        NSSize sz = v.image.size;
        double x = width / sz.width;
        double height = sz.height * x;
    
        [v.widthAnchor constraintEqualToConstant: width].active = YES;
        [v.heightAnchor constraintEqualToConstant: height].active = YES;
        
        return v;
    };

    auto sui_label = ^ NSTextField * (NSString *text) {
        auto v = sui_view(NSTextField);
        v.stringValue = text;
        v.editable = NO;
        v.drawsBackground = NO;
        v.bordered = NO;
        [v setContentHuggingPriority: 1000 forOrientation: NSLayoutConstraintOrientationVertical];
        [v setContentHuggingPriority: 1000 forOrientation: NSLayoutConstraintOrientationHorizontal];
        return v;
    };
    auto sui_title = ^ NSTextField * (NSString *text) {
        auto v = sui_label(text);
        if ((0)) v.font = [NSFont preferredFontForTextStyle: NSFontTextStyleHeadline options: @{}];
        if ((1)) v.font = [NSFont systemFontOfSize: NSFont.systemFontSize weight: NSFontWeightBold];
        return v;
    };
    auto sui_subtitle = ^ NSTextField * (NSString *text) {
        auto v = sui_label(text);
        if ((0)) v.font = [NSFont preferredFontForTextStyle: NSFontTextStyleSubheadline options: @{}];
        if ((1)) v.font = [NSFont systemFontOfSize: NSFont.smallSystemFontSize weight: NSFontWeightRegular];
        return v;
    };
    auto sui_label_releasenotes = ^ NSTextField * (NSString *text) {
        auto v = sui_label(text);
        v.font = [NSFont preferredFontForTextStyle: NSFontTextStyleCaption1 options: @{}];
        return v;
    };
    auto sui_box = ^ NSBox * (NSView *contentView) {
        auto v = sui_view(NSBox);
        v.contentView = contentView;
        
        const double boxCornerRadius = 5.0;
        const double boxBorderWidth = 1.0;
        const double boxMinHeight = 200;
        
        v.titlePosition = NSNoTitle;
        v.boxType = NSBoxCustom;
        v.cornerRadius = boxCornerRadius;
        v.borderWidth = boxBorderWidth;
        v.borderColor = NSColor.separatorColor;
        v.fillColor = NSColor.textBackgroundColor;
        [v.heightAnchor constraintGreaterThanOrEqualToConstant: boxMinHeight].active = YES;
        
        contentView.wantsLayer = YES;
        contentView.layer.masksToBounds = YES;
        contentView.layer.cornerRadius = boxCornerRadius - boxBorderWidth;
    
        return v;
    };
    
    
    /// MARK: SUI Layout
    
    auto _sui_stack = ^ NSStackView * (char orientation, CGFloat spacing, NSArray <NSView *> *subviews) {

        
        auto v = sui_view(NSStackView);
        for (NSView *subview in subviews) {
            [v addArrangedSubview: subview];
        }
        assert(orientation == 'h' || orientation == 'v');
        v.orientation = orientation == 'h' ? NSUserInterfaceLayoutOrientationHorizontal : NSUserInterfaceLayoutOrientationVertical;
        v.spacing = spacing;
        if (orientation == 'v') {
            v.alignment = NSLayoutAttributeWidth; /// Stretch vertically stacked views to full width
        }
        
        { /// Set vhugging priority higher on vstack than on hstack. Otherwise there are autolayout ambiguities when nesting them. If vhugging priority is *higher* on hstack than on vstack, then the vstack will get vertically stretched by the parent hstack instead of centered. This feels a bit hacky, but works for now for the SUUpdateAlert.
            if (orientation == 'h') {
                [v setHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationVertical]; /// 250 is default, this is just for documentation
            }
            if (orientation == 'v') {
                [v setHuggingPriority: 251 forOrientation: NSLayoutConstraintOrientationVertical];
            }
        };
        
        return v;
    };
    #define sui_hstack(spacing, subviews...) _sui_stack('h', spacing, @[ subviews ])
    #define sui_vstack(spacing, subviews...) _sui_stack('v', spacing, @[ subviews ])
    
    auto sui_spacer = ^NSView * () {
        auto v = sui_view(NSView);
        v.identifier = @"sui_spacer"; /// Identifer helps us spot these during view hierarchy debugging. Not sure there's a better way.
        { /// Set autolayout constraints. Don't notice any layout difference, but it silences some "ambiguous width" warnings in the view hierarchy debugger.
            NSLayoutConstraint *w = [v.widthAnchor constraintEqualToConstant: 0];
            NSLayoutConstraint *h = [v.heightAnchor constraintEqualToConstant: 0];
            w.priority = 1;
            h.priority = 1;
            w.active = YES;
            h.active = YES;
        }
        return v;
    };
    
    typedef struct {
        double top, trailing, bottom, leading; /// Arranged like a clock. Common in webdev.
    } sui_padding;
    
    auto sui_padder = ^NSView * (sui_padding padding, NSView *subview) {
        
        auto v = sui_view(NSView);
        [v addSubview: subview];
        
        [v.topAnchor       constraintEqualToAnchor: subview.topAnchor      constant: -padding.top].active = YES;
        [v.trailingAnchor  constraintEqualToAnchor: subview.trailingAnchor constant:  padding.trailing].active = YES;
        [v.bottomAnchor    constraintEqualToAnchor: subview.bottomAnchor   constant:  padding.bottom].active = YES;
        [v.leadingAnchor   constraintEqualToAnchor: subview.leadingAnchor  constant: -padding.leading].active = YES;
        
        return v;
    };
    
    /// MARK: SUI helpers
    
    #define sui_outlet_kvc(owner_property_name, view) ({    /** Connect a view from the hierarchy to an IBOutlet in the owner via KVC. This allows our pure-code view-hierarchy to function as a drop-in replacement for an interface-builder file.*/\
        nowarn_begin(-Wshadow)                              \
            auto _view = (view);                            \
            [owner setValue: _view forKey: owner_property_name]; /** I think this throws a exception if the owner is not kvc compliant for this key. */\
            _view;                                          \
        nowarn_end()                                        \
    })
    
    #define sui_outlet(lvalue, view) ({                     /** Store a view from the hierarchy in any lvalue. (local variables or object properties). This is better than `sui_outlet_kvc()` since it's more flexible and checked by the compiler. */\
        nowarn_begin(-Wshadow)                              \
            auto _view = (view);                            \
            lvalue = _view;                                 \
            _view;                                          \
        nowarn_end()                                        \
    })
    
    
    /// MARK: Outlets
    
    NSButton *skipButton = nil;
    NSButton *laterButton = nil;
    NSButton *installButton = nil;
    
    /// MARK: Create window and view hierarchy
    
    NSWindow *win = sui_outlet_kvc(@"window", sui_window(sui_padder((sui_padding) { 20, 20, 20, 20 }, sui_outlet_kvc(@"_stackView", sui_vstack(0,
        
        sui_padder((sui_padding){ -10, 0, 10, 0 }, sui_hstack(0,
            sui_padder((sui_padding){ 0, 10, 0, 0 }, sui_image(@"NSApplicationIcon", 64)),
            sui_vstack(5,
                sui_hstack(0, sui_title(@"Version Title"), sui_spacer()),
                sui_hstack(0, sui_subtitle(@"Question\nfor youuuu"), sui_spacer()),
            ),
            sui_spacer(),
        )),
        
        sui_outlet_kvc(@"_releaseNotesContainerView", sui_vstack(0,
            sui_padder((sui_padding) { 0, 0, 8, 0 }, sui_hstack(0,
                sui_outlet_kvc(@"_releaseNotesLabel", sui_label_releasenotes(@"Release Notes:")),
                sui_spacer(),
            )),
            
            sui_outlet_kvc(@"_releaseNotesBoxView", sui_box(
                sui_outlet_kvc(@"_releaseNotesContentView", sui_view(NSView))
            )),
        )),
        
        sui_padder((sui_padding){ 10, 0, 10, 0 }, sui_hstack(0,
            sui_outlet_kvc(@"_automaticallyInstallUpdatesButton", sui_checkbox(@"Automatically download and install updates in the future")),
            sui_spacer(),
        )),
        
        sui_padder((sui_padding){ 0, -5, -5, -5 }, /// Bring the big rounded buttons a bit closer to the window edge. NSAlerts under Tahoe seem to do the same.
            sui_hstack(12,
                sui_outlet(skipButton,     sui_outlet_kvc(@"_skipButton", sui_button(@"Skip This Version"))),
                sui_spacer(),
                sui_outlet(laterButton,    sui_outlet_kvc(@"_laterButton", sui_button(@"Remind Me Later"))),
                sui_outlet(installButton,  sui_outlet_kvc(@"_installButton", sui_button_default(@"Install Update"))),
            )
        )
    )))));
    
    /// Connect outlets in the other direction -> from owner to window
    win.delegate = owner;
    
    /// Connect IBActions
    #define setTargetAction(view, target, action) ({ \
        auto _view = (view);            \
        [_view setTarget: (target)];    \
        [_view setAction: (action)];    \
        _view;                          \
    })
    setTargetAction(skipButton,     owner, @selector(skipThisVersion:));
    setTargetAction(laterButton,    owner, @selector(remindMeLater:));
    setTargetAction(installButton,  owner, @selector(installUpdate:));
    #undef setTargetAction
    
    /// Setup CocoaBindings
    
    
    /// Return
    return win;
}

#define MF_TEST 0

#if MF_TEST
    
    @implementation NSObject (SUUpdateAlert_CodeOnly_Tests)
    
        + (void) load {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
                auto win = SUUpdateAlert_makeWindow(nil);
                [win makeKeyAndOrderFront: nil];
            });
        }
    
    @end
    
#endif
