//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"

#import "ZBQueue.h"
#import "ZBQueueTableViewCell.h"

#import <Tabs/Packages/Views/ZBBoldTableViewHeaderView.h>

@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
}
@end

@implementation ZBQueueViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = NSLocalizedString(@"Queue", @"");
        queue = [ZBQueue sharedQueue];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueueBar) name:@"ZBQueueUpdate" object:nil];
    }
    
    return [[UINavigationController alloc] initWithRootViewController:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBQueueUpdate" object:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBQueueTableViewCell" bundle:nil] forCellReuseIdentifier:@"queueTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
}

#pragma mark - Popup Bar Management

- (void)updateQueueBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned long long queueCount = [[ZBQueue sharedQueue] count];
        if (queueCount > 0) {
            if (queueCount == 1) {
                self.navigationController.popupItem.title = NSLocalizedString(@"1 Package Queued", @"");
            }
            else {
                self.navigationController.popupItem.title = [NSString stringWithFormat:NSLocalizedString(@"%llu Packages Queued", @""), queueCount];
            }
            self.navigationController.popupItem.subtitle = NSLocalizedString(@"Tap to manage", @"");
        }
        else {
            self.navigationController.popupItem.title = NSLocalizedString(@"No Packages Queued", @"");
        }
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBQueueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"queueTableViewCell"];
    
    cell.iconView.image = [UIImage imageNamed:@"Tweaks"];
    cell.packageNameLabel.text = @"NoBlur";
    cell.statusLabel.text = @"Ready to install";
    cell.progressView.progress = 0.2;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
    cell.titleLabel.text = NSLocalizedString(@"Install", @"");
    return cell;
}

@end
