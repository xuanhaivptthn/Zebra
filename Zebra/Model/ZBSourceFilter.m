//
//  ZBSourceFilter.m
//  Zebra
//
//  Created by Wilson Styres on 12/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceFilter.h"
#import <ZBSettings.h>

@implementation ZBSourceFilter

- (instancetype)init {
    ZBSourceFilter *filter = [ZBSettings sourceFilter];
    if (filter) return filter;
    
    self = [super init];
    
    if (self) {
        _searchTerm = NULL;
        _stores = YES;
        _sortOrder = ZBSourceSortOrderName;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    if (self) {
        _stores = [decoder decodeBoolForKey:@"stores"];
        _sortOrder = [[decoder decodeObjectForKey:@"sortOrder"] unsignedIntValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:_stores forKey:@"stores"];
    [coder encodeInt:(int)_sortOrder forKey:@"sortOrder"];
}

- (NSCompoundPredicate *)compoundPredicate {
    NSMutableArray *predicates = [NSMutableArray new];
    
    if (_searchTerm) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"label contains[cd] %@ OR repositoryURI contains[cd] %@", _searchTerm, _searchTerm];
        [predicates addObject:searchPredicate];
    }
    
    if (!_stores) {
        NSPredicate *storesPredicate = [NSPredicate predicateWithFormat:@"supportsPaymentAPI == NO"];
        [predicates addObject:storesPredicate];
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (NSArray <NSSortDescriptor *> *)sortDescriptors {
    NSMutableArray *descriptors = [NSMutableArray new];
    
    if (self.sortOrder == ZBSourceSortOrderPackageCount) {
        [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"numberOfPackages" ascending:NO]];
    }
    
    [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    return descriptors;
}

- (BOOL)isActive {
    return _searchTerm || !_stores;
}

@end
