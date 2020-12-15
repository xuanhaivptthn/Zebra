//
//  ZBSourceFilter.h
//  Zebra
//
//  Created by Wilson Styres on 12/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZBSourceSortOrder) {
    ZBSourceSortOrderName,
    ZBSourceSortOrderPackageCount,
};

@interface ZBSourceFilter : NSObject
@property (nonatomic) ZBSource *source;
@property (nonatomic, nullable) NSString *searchTerm;
@property (nonatomic) BOOL stores;
@property (nonatomic) ZBSourceSortOrder sortOrder;
@end

NS_ASSUME_NONNULL_END
