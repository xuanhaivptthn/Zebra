//
//  ZBQueue.h
//  Zebra
//
//  Created by Wilson Styres on 1/29/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import Foundation;
@import CoreGraphics;

#import <Downloads/ZBDownloadDelegate.h>
#import <Console/ZBCommand.h>

@class ZBQueueViewController;
@class ZBPackage;
@class UIColor;

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

typedef NS_ENUM(NSUInteger, ZBQueueStatus) {
    ZBQueueStatusPreparing,
    ZBQueueStatusDependencies,
    ZBQueueStatusAuthorizing,
    ZBQueueStatusDownloading,
    ZBQueueStatusReady
};

NS_ASSUME_NONNULL_BEGIN

@protocol ZBQueueDelegate
- (void)packages:(NSArray <ZBPackage *> *)packages addedToQueue:(ZBQueueType)queue;
- (void)packages:(NSArray <ZBPackage *> *)packages removedFromQueue:(ZBQueueType)queue;
- (void)statusUpdate:(ZBQueueStatus)status forPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (void)startedDownloadForPackage:(ZBPackage *)package;
- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (void)finishedDownloadForPackage:(ZBPackage *)package error:(NSError *)error;
@end

@interface ZBQueue : NSObject <ZBDownloadDelegate>
@property (readonly) unsigned long long count;
@property (readonly) NSArray <NSArray <ZBPackage *> *> *packages;
@property (readonly) ZBQueueViewController *controller;
@property (readonly) NSDictionary *statusMap;
@property (readonly) NSArray <NSArray *> *commands;
+ (instancetype)sharedQueue;
- (void)addPackage:(ZBPackage *)package toQueue:(ZBQueueType)queue;
- (void)removePackage:(ZBPackage *)package;
- (void)removePackage:(ZBPackage *)package fromQueue:(ZBQueueType)queue;
- (ZBQueueType)locate:(ZBPackage *)package;
- (BOOL)contains:(ZBPackage *)package inQueue:(ZBQueueType)queue;
- (void)removeAllPackages;
- (NSArray <ZBPackage *> *)packagesToRemove;
- (NSArray <ZBPackage *> *)packagesToInstall;
- (NSString *)displayableNameForQueueType:(ZBQueueType)queue;
+ (UIColor *)colorForQueueType:(ZBQueueType)queue;
@end

NS_ASSUME_NONNULL_END
