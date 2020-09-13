//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import Foundation;
@import CoreGraphics;

@class ZBPackage;

typedef NS_ENUM(NSUInteger, ZBQueueType) {
    ZBQueueTypeNone,
    ZBQueueTypeInstall,
    ZBQueueTypeRemove,
    ZBQueueTypeReinstall,
    ZBQueueTypeUpgrade,
    ZBQueueTypeDowngrade,
    ZBQueueTypeConflict,
    ZBQueueTypeDependency
};

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueue : NSObject
@property (readonly) unsigned long long count;
@property (readonly) unsigned long long downloadsRemaining;
@property (readonly) CGFloat downloadProgress;
+ (instancetype)sharedQueue;
- (void)add:(ZBPackage *)package to:(ZBQueueType)queue;
- (void)remove:(ZBPackage *)package;
- (void)remove:(ZBPackage *)package from:(ZBQueueType)queue;
- (ZBQueueType)locate:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
