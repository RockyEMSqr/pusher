
#import <Cocoa/Cocoa.h>
#import "menu.h"
#include <string.h>
static NSStatusItem *statusItem;
static NSMenuItem *pauseItem;
static NSMenuItem *audioItem;
static NSString *selectedFolder;

static int pendingAction = 0;
static int audioEnabled = 1;

@interface WatchMenuHandler : NSObject
- (void)chooseFolder:(id)sender;
- (void)togglePause:(id)sender;
- (void)toggleAudio:(id)sender;
- (void)quit:(id)sender;
@end

@implementation WatchMenuHandler

- (void)chooseFolder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;

    if ([panel runModal] == NSModalResponseOK) {
        selectedFolder = panel.URL.path;
        pendingAction = 1;
    }
}

- (void)togglePause:(id)sender {
    pendingAction = 2;
}

- (void)toggleAudio:(id)sender {
    audioEnabled = !audioEnabled;
    audioItem.state = audioEnabled
        ? NSControlStateValueOn
        : NSControlStateValueOff;
}

- (void)quit:(id)sender {
    pendingAction = 3;
}

@end

static WatchMenuHandler *handler;

void menu_init(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:
        NSApplicationActivationPolicyAccessory];
    [NSApp finishLaunching];

    handler = [WatchMenuHandler new];

    statusItem = [[NSStatusBar systemStatusBar]
        statusItemWithLength:NSSquareStatusItemLength];

    statusItem.button.title = @"♫";

    NSMenu *menu = [NSMenu new];

    NSMenuItem *folderItem =
        [[NSMenuItem alloc]
            initWithTitle:@"Choose Folder..."
            action:@selector(chooseFolder:)
            keyEquivalent:@""];

    folderItem.target = handler;
    [menu addItem:folderItem];

    pauseItem =
        [[NSMenuItem alloc]
            initWithTitle:@"Pause Watching"
            action:@selector(togglePause:)
            keyEquivalent:@""];

    pauseItem.target = handler;
    [menu addItem:pauseItem];

    audioItem =
        [[NSMenuItem alloc]
            initWithTitle:@"Play Audio Automatically"
            action:@selector(toggleAudio:)
            keyEquivalent:@""];

    audioItem.target = handler;
    audioItem.state = NSControlStateValueOn;
    [menu addItem:audioItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem =
        [[NSMenuItem alloc]
            initWithTitle:@"Quit"
            action:@selector(quit:)
            keyEquivalent:@""];

    quitItem.target = handler;
    [menu addItem:quitItem];

    statusItem.menu = menu;
}

void menu_poll(void) {
    @autoreleasepool {
        NSEvent *event;

        while ((event = [NSApp
            nextEventMatchingMask:NSEventMaskAny
            untilDate:[NSDate distantPast]
            inMode:NSDefaultRunLoopMode
            dequeue:YES])) {

            [NSApp sendEvent:event];
        }

        [NSApp updateWindows];
    }
}

int menu_get_action(void) {
    int action = pendingAction;
    pendingAction = 0;
    return action;
}

int menu_get_audio_enabled(void) {
    return audioEnabled;
}

void menu_set_paused(int paused) {
    pauseItem.title = paused
        ? @"Resume Watching"
        : @"Pause Watching";
}

void menu_set_folder(const char *path) {
    if (!path) return;

    NSString *folder =
        [NSString stringWithUTF8String:path];

    statusItem.button.toolTip = folder;
}

const char *menu_choose_folder(void) {
    return selectedFolder
        ? selectedFolder.UTF8String
        : NULL;
}

int menu_copy_selected_folder(unsigned char *buffer, int capacity) {
    if (!buffer || capacity <= 0 || !selectedFolder) {
        return 0;
    }

    const char *path = selectedFolder.UTF8String;
    size_t length = strlen(path);

    if (length + 1 > (size_t)capacity) {
        return 0;
    }

    memcpy(buffer, path, length + 1);

    return (int)length;
}

const char *menu_get_selected_folder(void) {
    return selectedFolder ? selectedFolder.UTF8String : "";
}