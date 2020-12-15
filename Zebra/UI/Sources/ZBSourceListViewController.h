//
//  ZBSourceListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import UIKit;

#import <Managers/Delegates/ZBSourceDelegate.h>

@class ZBSource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceListViewController : UITableViewController <ZBSourceDelegate, UISearchResultsUpdating, UISearchControllerDelegate> {
    NSMutableArray <ZBSource *> *sources;
    NSArray <ZBSource *> *filteredSources;
}
- (void)handleURL:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
