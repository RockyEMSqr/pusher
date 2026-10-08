#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "audio.h"

static NSMutableArray<AVAudioPlayer *> *players;

int play_audio(const char *path) {
    @autoreleasepool {
        if (!path) return 0;

        if (!players) {
            players = [NSMutableArray new];
        }

        NSString *filename =
            [NSString stringWithUTF8String:path];

        NSURL *url =
            [NSURL fileURLWithPath:filename];

        NSError *error = nil;

        AVAudioPlayer *player =
            [[AVAudioPlayer alloc]
                initWithContentsOfURL:url
                error:&error];

        if (!player) {
            NSLog(@"Audio error: %@", error);
            return 0;
        }

        [players addObject:player];

        if (![player play]) {
            [players removeObject:player];
            return 0;
        }

        return 1;
    }
}