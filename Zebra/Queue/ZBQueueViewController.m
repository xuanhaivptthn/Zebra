//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import LNPopupController;

#import "ZBQueueViewController.h"

#import "ZBQueue.h"
#import "ZBQueueTableViewCell.h"

#import <Console/ZBConsoleViewController.h>
#import <Tabs/ZBTabBarController.h>
#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Tabs/Packages/Views/ZBBoldTableViewHeaderView.h>
#import <ZBAppDelegate.h>

@import LNPopupController;

@interface ZBQueueViewController () {
    NSArray <NSArray <ZBPackage *> *> *packagesQueued;
}
@end

@implementation ZBQueueViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = NSLocalizedString(@"Queue", @"");
        
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
    
    UIBarButtonItem *dismissItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Chevron Down"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", @"") style:UIBarButtonItemStylePlain target:self action:@selector(clearQueue:)];
    self.navigationItem.leftBarButtonItems = @[dismissItem, clearItem];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Confirm", @"") style:UIBarButtonItemStyleDone target:self action:@selector(confirm)];
    
    [[UITableView appearance] setBackgroundColor:[UIColor whiteColor]];
    [self.tableView setTableFooterView:[UIView new]];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBQueueTableViewCell" bundle:nil] forCellReuseIdentifier:@"queueTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
}

- (void)dismiss {
    [[ZBAppDelegate tabBarController] closePopupAnimated:YES completion:nil];
}

- (void)clearQueue:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:NSLocalizedString(@"Are you sure you want to clear the Queue?", @"") preferredStyle:UIAlertControllerStyleActionSheet];
        
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[ZBQueue sharedQueue] clear];
    }];
    [alert addAction:confirm];
        
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
        
    alert.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirm {
    ZBConsoleViewController *console = [[ZBConsoleViewController alloc] init];
    [self.navigationController pushViewController:console animated:YES];
}

#pragma mark - Popup Bar Management

- (void)updateQueue {
    packagesQueued = [ZBQueue sharedQueue].packages;
    
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
    
    ZBQueueStatus status = [[[[ZBQueue sharedQueue] statusMap] objectForKey:package.identifier] unsignedIntegerValue];
    [cell setStatus:status queueType:indexPath.section + 1];
    
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
    return [[ZBQueue sharedQueue] displayableNameForQueueType:section + 1];
}

#pragma mark - Queue Delegate

- (void)packages:(NSArray<ZBPackage *> *)packages addedToQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:queue - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)packages:(NSArray<ZBPackage *> *)packages removedFromQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:queue - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)statusUpdate:(ZBQueueStatus)status forPackage:(ZBPackage *)package inQueue:(ZBQueueType)queue {
    if (queue == ZBQueueTypeNone) return;
    
    NSUInteger row = [packagesQueued[queue - 1] indexOfObject:package];
    if (row != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:queue - 1];
        dispatch_async(dispatch_get_main_queue(), ^{
            ZBQueueTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell setStatus:status queueType:indexPath.section + 1];
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
