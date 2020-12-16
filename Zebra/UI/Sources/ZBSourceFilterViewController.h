//
//  ZBSourceFilterViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UI/Common/Delegates/ZBFilterDelegate.h>
#import <UI/Common/Delegates/ZBSelectionDelegate.h>

@class ZBSourceFilter;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceFilterViewController : UITableViewController <ZBSelectionDelegate>
- (instancetype)initWithFilter:(ZBSourceFilter *)filter delegate:(id <ZBFilterDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
