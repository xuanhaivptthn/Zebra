//
//  ZBSourceSectionsListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceSectionsListTableViewController.h"
#import "ZBSourceAccountTableViewController.h"
#import "ZBFeaturedCollectionViewCell.h"
#import "ZBSourcesAccountBanner.h"

#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Model/ZBPackage.h>
#import <UI/Packages/ZBPackageListViewController.h>
#import <Managers/ZBSourceManager.h>
#import <Extensions/UIBarButtonItem+blocks.h>
#import <Extensions/UIImageView+Zebra.h>

#import <Model/ZBSource.h>

@import SDWebImage;

@interface ZBSourceSectionsListTableViewController () {
    CGSize bannerSize;
    UICKeyChainStore *keychain;
    BOOL editOnly;
}
@property (nonatomic, strong) IBOutlet UICollectionView *featuredCollection;
@property (nonatomic, strong) NSArray *featuredPackages;
@property (nonatomic, strong) NSArray *sectionNames;
@property (nonatomic, strong) NSMutableArray *filteredSections;
@property (nonatomic, strong) NSDictionary *sectionReadout;
@property (nonatomic, weak) ZBPackageListViewController *previewPackageListVC;
@end

@implementation ZBSourceSectionsListTableViewController

@synthesize source;
@synthesize sectionNames;
@synthesize sectionReadout;
@synthesize filteredSections;

#pragma mark - Initializers

- (id)initWithSource:(ZBSource *)source editOnly:(BOOL)edit {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"sourceSectionsController"];
    
    if (self) {
        self.source = source;
        editOnly = edit;
    }
    
    return self;
}

- (id)initWithPackage:(ZBPackage *)package {
    return [self initWithSource:package.source editOnly:NO];
}

- (BOOL)showFeaturedSection {
    return !editOnly;
}

#pragma mark - Localization

- (NSString *)localizedSection:(NSString *)section {
    NSRange range = [section rangeOfString:@"("];

    if (range.length > 0) {
        NSString *section_ = [[section substringToIndex:range.location] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(section_, @""), [section substringFromIndex:range.location]];
    } else {
        return NSLocalizedString(section, @"");
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sectionReadout = source.sections;
    sectionNames = [[sectionReadout allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSString *section1 = [self localizedSection:obj1];
        NSString *section2 = [self localizedSection:obj2];
            
        return [section1 compare:section2];
    }];
    if (!editOnly) keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    filteredSections = [[[ZBSettings filteredSources] objectForKey:[source uuid]] mutableCopy];
    if (!filteredSections) filteredSections = [NSMutableArray new];
    
    if (!editOnly) self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = self.navigationItem.titleView.center;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    
    [imageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && !error) {
                imageView.image = image;
            }
            else {
                self.navigationItem.titleView = nil;
                self.navigationItem.title = [self->source label];
            }
        });
    }];
    [container addSubview:imageView];
    self.navigationItem.titleView = container;
    self.title = [source label];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    if (!editOnly) {
        [self.featuredCollection registerNib:[UINib nibWithNibName:@"ZBFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"imageCell"];
        [self checkFeaturedPackages];
    }
    else {
        [self.featuredCollection removeFromSuperview];
        self.tableView.tableHeaderView = nil;
        [self.tableView layoutIfNeeded];
    }
    
    if (!editOnly && [source supportsPaymentAPI]) { // If the source supports payments/external accounts
        ZBSourcesAccountBanner *accountBanner = [[ZBSourcesAccountBanner alloc] initWithSource:source andOwner:self];
        [self.view addSubview:accountBanner];
        
        accountBanner.translatesAutoresizingMaskIntoConstraints = NO;
        [accountBanner.topAnchor constraintEqualToAnchor: self.view.layoutMarginsGuide.topAnchor].active = YES;
        [accountBanner.leadingAnchor constraintEqualToAnchor: self.view.leadingAnchor].active = YES;
        [accountBanner.widthAnchor constraintEqualToAnchor: self.view.widthAnchor].active = YES; // You can't use a trailing anchor with a UITableView apparently?
        [accountBanner.heightAnchor constraintEqualToConstant:75].active = YES;
        
        accountBanner.layer.zPosition = 100;
        self.tableView.contentInset = UIEdgeInsetsMake(75, 0, 0, 0);
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO]; // hack
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (editOnly) [self setEditing:YES animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (self.editing) {
        for (NSInteger i = 1; i < sectionNames.count + 1; ++i) {
            NSString *section = [sectionNames objectAtIndex:i - 1];
            if (![filteredSections containsObject:section]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
    }
}

- (void)accountButtonPressed:(id)sender {
    [source authenticate:^(BOOL success, BOOL notify, NSError * _Nullable error) {
        if (!success || error) {
            if (notify) {
                if (error) {
                    if (error.code != 1) [ZBAppDelegate sendAlertFrom:self message:[NSString stringWithFormat:NSLocalizedString(@"Could not authenticate: %@", @""), error.localizedDescription]];
                }
                else {
                    [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Could not authenticate", @"")];
                }
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];
                ZBSourceAccountTableViewController *accountController = [[ZBSourceAccountTableViewController alloc] initWithSource:self->source];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:accountController];
                
                [self presentViewController:navController animated:YES completion:nil];
            });
        }
    }];
}

- (void)checkFeaturedPackages {
    [self.featuredCollection removeFromSuperview];
    self.tableView.tableHeaderView = nil;
    [self.tableView layoutIfNeeded];
    
    [source getFeaturedPackages:^(NSDictionary * _Nullable featuredPackages) {
        NSMutableDictionary *featuredItems = [[NSDictionary dictionaryWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]] mutableCopy];
        if (featuredPackages) {
            NSArray *banners = featuredPackages[@"banners"];
            self->bannerSize = CGSizeFromString(featuredPackages[@"itemSize"]);
            self.featuredPackages = banners;
            
            [featuredItems setObject:banners forKey:[self->source uuid]];
            [featuredItems writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupFeaturedPackages];
            });
        }
    }];
}

- (void)setupFeaturedPackages {
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = self.featuredCollection;
    self.tableView.tableHeaderView.frame = CGRectZero;
    self.featuredCollection.delegate = self;
    self.featuredCollection.dataSource = self;
    [self.featuredCollection setContentInset:UIEdgeInsetsMake(0.f, 15.f, 0.f, 15.f)];
    self.featuredCollection.backgroundColor = [UIColor clearColor];
    // self.featuredCollection.collectionViewLayout.collectionViewContentSize.height = height;
    /*self.featuredCollection.frame = CGRectMake (self.featuredCollection.frame.origin.x,self.featuredCollection.frame.origin.y,self.featuredCollection.frame.size.width,height);*/ // objective c
    // [self.featuredCollection setNeedsLayout];
    // [self.featuredCollection reloadData];
    [UIView animateWithDuration:.25f animations:^{
        self.tableView.tableHeaderView.frame = CGRectMake(self.featuredCollection.frame.origin.x, self.featuredCollection.frame.origin.y, self.featuredCollection.frame.size.width, self->bannerSize.height + 30);
    }];
    [self.tableView endUpdates];
    // [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sectionNames.count + 1;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceSectionCell" forIndexPath:indexPath];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.usesGroupingSeparator = YES;
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    cell.selectedBackgroundView.backgroundColor = [UIColor cellSelectedBackgroundColor];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"All Packages", @"");
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout.allValues valueForKeyPath:@"@sum.self"]];
        cell.imageView.image = NULL;
    } else {
        NSString *section = sectionNames[indexPath.row - 1];
        
        cell.textLabel.text = [self localizedSection:section];
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout objectForKey:section]];
        cell.imageView.image = [ZBSource imageForSection:section];
        [cell.imageView resize:CGSizeMake(32, 32) applyRadius:YES];
    }
    
    return cell;
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing && indexPath.row == 0) return nil;
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing) {
        ZBPackageListViewController *packageList = [[ZBPackageListViewController alloc] initWithSource:source section:indexPath.row == 0 ? NULL : sectionNames[indexPath.row - 1]];
        
        [[self navigationController] pushViewController:packageList animated:YES];
        
    } else {
        if (indexPath.row == 0) return;
        
        NSString *section = sectionNames[indexPath.row - 1];
        [filteredSections removeObject:section];
        [ZBSettings setSection:section filtered:NO forSource:self.source];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        if (indexPath.row == 0) return;
        
        NSString *section = sectionNames[indexPath.row - 1];
        [filteredSections addObject:section];
        [ZBSettings setSection:section filtered:YES forSource:self.source];
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return !self.editing;
}

// 3D Touch Actions

- (NSArray *)previewActionItems {
    UIPreviewAction *refresh = [UIPreviewAction actionWithTitle:NSLocalizedString(@"Refresh", @"") style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        //TODO: Update for new refresh
//        [self->databaseManager updateSource:self->source useCaching:YES];
    }];
    
    if ([source canDelete]) {
        UIPreviewAction *delete = [UIPreviewAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteSourceTouchAction" object:self userInfo:@{@"source": self->source}];
        }];
        
        return @[refresh, delete];
    }
    
    return @[refresh];
}

#pragma mark UICollectionView delegates
- (ZBFeaturedCollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBFeaturedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    NSDictionary *currentBanner = [self.featuredPackages objectAtIndex:indexPath.row];
    [cell.imageView sd_setImageWithURL:currentBanner[@"url"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    cell.packageID = currentBanner[@"package"];
    [cell.titleLabel setText:currentBanner[@"title"]];
    
    // dispatch_async(dispatch_get_main_queue(), ^{
//        if ([[self.fullJSON objectForKey:@"itemCornerRadius"] doubleValue]) {
//            cell.layer.cornerRadius = [self->_fullJSON[@"itemCornerRadius"] doubleValue];
//        }
    // });
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _featuredPackages.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return bannerSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    self.editing = NO;
//    ZBFeaturedCollectionViewCell *cell = (ZBFeaturedCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:cell.packageID];
//    
//    if (package) {
//        ZBPackageViewController *packageDepiction = [[ZBPackageViewController alloc] initWithPackage:package];
//        [[self navigationController] pushViewController:packageDepiction animated:YES];
//    }
}

//- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
//    typeof(self) __weak weakSelf = self;
//    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
//        return weakSelf.previewPackageListVC;
//    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
//        weakSelf.previewPackageListVC = (ZBPackageListViewController *)[weakSelf.storyboard instantiateViewControllerWithIdentifier:@"ZBPackageListViewController"];
//        weakSelf.previewPackageListVC.source = self->source;
//        if (indexPath.row > 0) {
//            NSString *section = [self->sectionNames objectAtIndex:indexPath.row - 1];
//            weakSelf.previewPackageListVC.section = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
//            weakSelf.title = section;
//        }
//        else {
//            weakSelf.title = NSLocalizedString(@"All Packages", @"");
//        }
////        [weakSelf setDestinationVC:indexPath destination:weakSelf.previewPackageListVC];
//        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageListVC contextMenuActionItemsForIndexPath:indexPath]];
//    }];
//}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageListVC animated:YES];
    }];
}

//- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
//    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
//    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    previewingContext.sourceRect = cell.frame;
//    ZBPackageListViewController *packageListVC = (ZBPackageListViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ZBPackageListViewController"];
//    packageListVC.source = self->source;
//    if (indexPath.row > 0) {
//        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
//        packageListVC.section = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
//        packageListVC.title = section;
//    }
//    else {
//        packageListVC.title = NSLocalizedString(@"All Packages", @"");
//    }
////    [self setDestinationVC:indexPath destination:packageDepictionVC];
//    return packageListVC;
//}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

@end
