//
//  ZBQueue.m
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueue.h"

#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <Downloads/ZBDownloadManager.h>
#import <Tabs/Packages/Helpers/ZBPackage.h>

@interface ZBQueue () {
    NSMutableArray *installQueue;
    NSMutableArray *removeQueue;
    NSMutableArray *reinstallQueue;
    NSMutableArray *upgradeQueue;
    NSMutableArray *downgradeQueue;
    NSMutableArray *dependencyQueue;
    NSMutableArray *conflictQueue;
    NSMutableArray *packagesToDownload;
    
    ZBDownloadManager *downloadManager;
}
@end

NSString *const ZBQueueUpdateNotification = @"ZBQueueUpdate";

@implementation ZBQueue

#pragma mark - Initializers

+ (instancetype)sharedQueue {
    static ZBQueue *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBQueue new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        installQueue = [NSMutableArray new];
        removeQueue = [NSMutableArray new];
        reinstallQueue = [NSMutableArray new];
        upgradeQueue = [NSMutableArray new];
        downgradeQueue = [NSMutableArray new];
        dependencyQueue = [NSMutableArray new];
        conflictQueue = [NSMutableArray new];
        packagesToDownload = [NSMutableArray new];
        
        downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
    }
    
    return self;
}

#pragma mark - Properties

- (unsigned long long)count {
    return installQueue.count + removeQueue.count + reinstallQueue.count + upgradeQueue.count + downgradeQueue.count + dependencyQueue.count + conflictQueue.count;
}

- (unsigned long long)downloadsRemaining {
    return packagesToDownload.count;
}

#pragma mark - Queue Management

- (void)add:(ZBPackage *)package to:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    switch(queue) {
        case ZBQueueTypeInstall:
        case ZBQueueTypeReinstall:
        case ZBQueueTypeUpgrade:
        case ZBQueueTypeDowngrade:
        case ZBQueueTypeDependency:
            if (![package debPath]) { // Packages that are already downloaded will have debPath set
                [packagesToDownload addObject:package];
                if ([ZBDevice connectionType] == ZBConnectionTypeWiFi) [downloadManager downloadPackages:@[package]];
            }
        case ZBQueueTypeRemove:
        case ZBQueueTypeConflict: {
            NSMutableArray *array = [self queueForType:queue];
            if (![array containsObject:package]) {
                [array addObject:package];
            }
        }
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZBQueueUpdateNotification object:self];
}

- (void)remove:(ZBPackage *)package {
    [self remove:package from:[self locate:package]];
}

- (void)remove:(ZBPackage *)package from:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    switch(queue) {
        case ZBQueueTypeInstall:
        case ZBQueueTypeReinstall:
        case ZBQueueTypeUpgrade:
        case ZBQueueTypeDowngrade:
        case ZBQueueTypeDependency:
            [packagesToDownload removeObject:package];
        case ZBQueueTypeRemove:
        case ZBQueueTypeConflict:
            [[self queueForType:queue] removeObject:package];
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZBQueueUpdateNotification object:self];
}

- (ZBQueueType)locate:(ZBPackage *)package {
    for (ZBQueueType queue = ZBQueueTypeInstall; queue <= ZBQueueTypeDependency; queue++) {
        if ([[self queueForType:queue] containsObject:package]) {
            return queue;
        }
    }
    return ZBQueueTypeNone;
}

- (BOOL)contains:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    return [[self queueForType:queue] containsObject:package];
}

#pragma mark - Download Delegate

- (void)startedDownloads {
    NSLog(@"[Zebra] Started downloads");
}

- (void)finishedAllDownloads {
    NSLog(@"[Zebra] Finished All Downloads");
}

- (void)startedPackageDownload:(ZBPackage *)package {
    NSLog(@"[Zebra] Started download for package %@", package);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZBQueueUpdateNotification object:self];
}

- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package {
    NSLog(@"[Zebra] %@ Progress: %f", package, progress);
}

- (void)finishedPackageDownload:(ZBPackage *)package withError:(NSError *_Nullable)error {
    NSLog(@"[Zebra] Finished download for package %@", package);
    
    [packagesToDownload removeObject:package];
    [[NSNotificationCenter defaultCenter] postNotificationName:ZBQueueUpdateNotification object:self];
}

#pragma mark - Helper Methods

- (NSMutableArray *)queueForType:(ZBQueueType)queue {
    switch(queue) {
        case ZBQueueTypeInstall:
            return installQueue;
        case ZBQueueTypeRemove:
            return removeQueue;
        case ZBQueueTypeReinstall:
            return reinstallQueue;
        case ZBQueueTypeUpgrade:
            return upgradeQueue;
        case ZBQueueTypeDowngrade:
            return downgradeQueue;
        case ZBQueueTypeDependency:
            return dependencyQueue;
        case ZBQueueTypeConflict:
            return conflictQueue;
        default:
            return NULL;
    }
}

- (NSString *)displayableNameForQueueType:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeInstall:
        case ZBQueueTypeDependency:
            return NSLocalizedString(@"Install", @"");
        case ZBQueueTypeConflict:
        case ZBQueueTypeRemove:
            return NSLocalizedString(@"Remove", @"");
        case ZBQueueTypeReinstall:
            return NSLocalizedString(@"Reinstall", @"");
        case ZBQueueTypeUpgrade:
            return NSLocalizedString(@"Upgrade", @"");
        case ZBQueueTypeDowngrade:
            return NSLocalizedString(@"Downgrade", @"");
        default:
            return NULL;
    }
}

+ (UIColor *)colorForQueueType:(ZBQueueType)queue {
    switch (queue) {
        case ZBQueueTypeDependency:
        case ZBQueueTypeInstall:
            return [UIColor systemTealColor];
        case ZBQueueTypeConflict:
        case ZBQueueTypeRemove:
            return [UIColor systemPinkColor];
        case ZBQueueTypeReinstall:
            return [UIColor systemOrangeColor];
        case ZBQueueTypeUpgrade:
            return [UIColor systemBlueColor];
        case ZBQueueTypeDowngrade:
            return [UIColor systemPurpleColor];
        default:
            return nil;
    }
}

@end
