//
//  ZBStoresListTableViewController.m
//  Zebra
//
//  Created by va2ron1 on 6/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBStoresListTableViewController.h"
#import "UICKeyChainStore.h"

#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <Extensions/UIColor+GlobalColors.h>
//#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Tabs/Sources/Views/ZBSourceTableViewCell.h>
//#import <Database/ZBDatabaseManager.h>
//#import <Tabs/Sources/Helpers/ZBSourceManager.h>
#import <UI/Sources/ZBSourceAccountTableViewController.h>

@import SDWebImage;

@interface ZBStoresListTableViewController () {
    NSArray <ZBSource *> *sources;
    UICKeyChainStore *keychain;
    NSString *callbackURI;
}
@end

@implementation ZBStoresListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES];
    //sources = //[[[ZBDatabaseManager sharedInstance] sourcesWithPaymentEndpoint] sortedArrayUsingDescriptors:@[descriptor]];
    
    self.title = NSLocalizedString(@"Stores", @"");
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return sources.count ? 65 : 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(sources.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (sources.count) {
        ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
        
        ZBSource *source = [sources objectAtIndex:indexPath.row];
        
//        cell.sourceLabel.text = [source label];
        cell.sourceLabel.textColor = [UIColor primaryTextColor];
        
//        cell.urlLabel.text = [source repositoryURI];
        cell.urlLabel.textColor = [UIColor secondaryTextColor];
        
//        [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noStoresCell"];
        cell.textLabel.text = NSLocalizedString(@"No Storefronts Available", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor secondaryTextColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!sources.count) return;
    
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
//    [source authenticate:^(BOOL success, BOOL notify, NSError * _Nullable error) {
//        if (!success || error) {
//            if (notify) {
//                if (error) {
//                    [ZBAppDelegate sendAlertFrom:self message:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Could not authenticate", @""), error.localizedDescription]];
//                }
//                else {
//                    [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Could not authenticate", @"")];
//                }
//            }
//        }
//        else {
//            ZBSourceAccountTableViewController *accountController = [[ZBSourceAccountTableViewController alloc] initWithSource:source];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.navigationController pushViewController:accountController animated:YES];
//            });
//        }
//    }];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return sources.count ? NSLocalizedString(@"Signing in to sources allows for the purchase of paid packages.", @"") : NULL;
}

@end
