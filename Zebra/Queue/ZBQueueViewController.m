//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"

#import "ZBQueue.h"

@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
}
@end

@implementation ZBQueueViewController

- (id)init {
    self = [super init];
    
    if (self) {
        queue = [ZBQueue sharedQueue];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueueBar) name:@"ZBQueueUpdate" object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBQueueUpdate" object:nil];
}

- (void)updateQueueBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned long long queueCount = [[ZBQueue sharedQueue] count];
        if (queueCount > 0) {
            if (queueCount == 1) {
                self.popupItem.title = NSLocalizedString(@"1 Package Queued", @"");
            }
            else {
                self.popupItem.title = [NSString stringWithFormat:NSLocalizedString(@"%llu Packages Queued", @""), queueCount];
            }
            self.popupItem.subtitle = NSLocalizedString(@"Tap to manage", @"");
        }
        else {
            self.popupItem.title = NSLocalizedString(@"No Packages Queued", @"");
        }
    });
}

@end
