//
//  ZBQueue.m
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueue.h"

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
}
@end

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
    }
    
    return self;
}

#pragma mark - Properties

- (unsigned long long)count {
    return installQueue.count + removeQueue.count + dependencyQueue.count + conflictQueue.count;
}

- (unsigned long long)downloadsRemaining {
    return packagesToDownload.count;
}

#pragma mark - Adding to the Queue

- (void)add:(ZBPackage *)package to:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    switch(queue) {
        case ZBQueueTypeInstall:
        case ZBQueueTypeReinstall:
        case ZBQueueTypeUpgrade:
        case ZBQueueTypeDowngrade:
        case ZBQueueTypeDependency:
            [packagesToDownload addObject:package];
        case ZBQueueTypeRemove:
        case ZBQueueTypeConflict:
            [[self queueForType:queue] addObject:package];
        default:
            break;
    }
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
}

- (ZBQueueType)locate:(ZBPackage *)package {
    for (ZBQueueType queue = ZBQueueTypeInstall; queue <= ZBQueueTypeDependency; queue++) {
        if ([[self queueForType:queue] containsObject:package]) {
            return queue;
        }
    }
    return ZBQueueTypeNone;
}

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

@end
