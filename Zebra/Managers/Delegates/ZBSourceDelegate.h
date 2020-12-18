//
//  ZBSourceDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 8/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import Foundation;
@import CoreGraphics;

@class ZBBaseSource;
@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

#ifndef ZBSourceDelegate_h
#define ZBSourceDelegate_h

@protocol ZBSourceDelegate
@optional
- (void)startedSourceRefresh;
- (void)startedDownloadForSource:(ZBBaseSource *)source;
- (void)finishedDownloadForSource:(ZBBaseSource *)source;
- (void)startedImportForSource:(ZBBaseSource *)source;
- (void)finishedImportForSource:(ZBBaseSource *)source;
- (void)updatesAvailable:(NSUInteger)numberOfUpdates;
- (void)finishedSourceRefresh;
- (void)addedSources:(NSArray <ZBBaseSource *> *)sources;
- (void)removedSources:(NSArray <ZBBaseSource *> *)sources;
- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)source;
@end

#endif /* ZBSourceDelegate_h */

NS_ASSUME_NONNULL_END
