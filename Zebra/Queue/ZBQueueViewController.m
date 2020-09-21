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

#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Tabs/Packages/Views/ZBBoldTableViewHeaderView.h>

@import LNPopupController;

@interface ZBQueueViewController () {
    ZBQueue *queue;
    NSArray <NSArray <ZBPackage *> *> *packagesQueued;
}
@end

@implementation ZBQueueViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = NSLocalizedString(@"Queue", @"");
        queue = [ZBQueue sharedQueue];
        queue.delegate = self;
        packagesQueued = queue.packages;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueue) name:@"ZBQueueUpdate" object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBQueueUpdate" object:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UITableView appearance] setBackgroundColor:[UIColor whiteColor]];
    [self.tableView setTableFooterView:[UIView new]];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBQueueTableViewCell" bundle:nil] forCellReuseIdentifier:@"queueTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
}

#pragma mark - Popup Bar Management

- (void)updateQueue {
    packagesQueued = queue.packages;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
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
    return packagesQueued.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return packagesQueued[section].count;
}

- (ZBQueueTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBQueueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"queueTableViewCell"];
    ZBPackage *package = packagesQueued[indexPath.section][indexPath.row];
    
    cell.packageNameLabel.text = package.name;
    
    [package setIconImageForImageView:cell.iconView];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([tableView numberOfRowsInSection:section] != 0) {
        ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
        cell.titleLabel.text = [self titleForHeaderInSection:section];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [tableView numberOfRowsInSection:section] != 0 ? UITableViewAutomaticDimension : 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    return [queue displayableNameForQueueType:section + 1];
}

#pragma mark - Queue Delegate

- (void)packages:(NSArray<ZBPackage *> *)packages addedToQueue:(ZBQueueType)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:queue - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)packages:(NSArray<ZBPackage *> *)packages removedFromQueue:(ZBQueueType)queue {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:queue - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)statusUpdate:(ZBQueueStatus)status forPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    NSUInteger row = [packagesQueued[queue - 1] indexOfObject:package];
    if (row != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:queue - 1];
        dispatch_async(dispatch_get_main_queue(), ^{
            ZBQueueTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell setStatus:status];
            
            if (status == ZBQueueStatusReady) {
                NSString *status = [NSString stringWithFormat:@"Ready to %@", [self->queue displayableNameForQueueType:queue].lowercaseString];
                cell.statusLabel.text = NSLocalizedString(status, @"");
            }
        });
    }
}

- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    NSUInteger row = [packagesQueued[queue - 1] indexOfObject:package];
    if (row != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:queue - 1];
        dispatch_async(dispatch_get_main_queue(), ^{
            ZBQueueTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell setProgress:progress];
        });
    }
}

@end
