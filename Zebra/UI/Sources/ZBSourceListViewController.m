//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"
#import "ZBSourceAddViewController.h"
#import "ZBSourceSectionsListTableViewController.h"
#import "ZBSourceFilterViewController.h"

#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBSettings.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <Extensions/UIAlertController+Zebra.h>
#import <Model/ZBSource.h>
#import <Model/ZBSourceFilter.h>
#import <Managers/ZBSourceManager.h>
#import <Tabs/Sources/Views/ZBSourceTableViewCell.h>
#import <UI/Common/ZBPartialPresentationController.h>

@interface ZBSourceListViewController () {
    UIBarButtonItem *addButton;
    NSArray *filterResults;
    UISearchController *searchController;
    NSMutableArray *selectedSources;
    ZBSourceManager *sourceManager;
    NSUInteger withProblems;
}
@property (nonnull) ZBSourceFilter *filter;
@end

@implementation ZBSourceListViewController

#pragma mark - Initializers

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = NSLocalizedString(@"Sources", @"");
        
        sourceManager = [ZBSourceManager sharedInstance];
        _filter = [[ZBSourceFilter alloc] init];
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.showsBookmarkButton = YES;
        searchController.searchBar.delegate = self;
        [searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];

        self.navigationItem.searchController = searchController;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceCell"];
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    
    [self layoutNavigationButtonsNormal];
    [self loadSources];
}

- (void)loadSources {
    if (_sources) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSArray *filteredSources = [self->sourceManager filterSources:self.sources withFilter:self.filter];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->filterResults = filteredSources;
                [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    if (self.filter.isActive) {
                        [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle.fill"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                    } else {
                        [self->searchController.searchBar setImage:[UIImage systemImageNamed:@"line.horizontal.3.decrease.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
                    }
                    [self.tableView reloadData];
                } completion:nil];
            });
        });
    } else {
        self.sources = self->sourceManager.sources;
        [self loadSources];
    }
}

- (void)handleURL:(NSURL *)url {
    NSString *scheme = [url scheme];
    NSArray *choices = @[@"file", @"zbra"];
    
    switch ([choices indexOfObject:scheme]) {
        case 0:
            // TODO: Re-implement source importing from .list
            break;
        case 1: {
            NSString *path = [url path];
            if (![path isEqualToString:@""]) {
                NSArray *components = [path pathComponents];
                if ([components count] >= 4) {
                    NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
                    if (![urlString hasSuffix:@"/"]) {
                        urlString = [urlString stringByAppendingString:@"/"];
                    }
                    
                    NSURL *url;
                    if ([urlString containsString:@"https://"] || [urlString containsString:@"http://"]) {
                        url = [NSURL URLWithString:urlString];
                    } else {
                        url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
                    }
                    
                    if (url && url.scheme && url.host) {
                        [self presentAddViewWithURL:url];
                    } else {
                        [self presentAddView];
                    }
                }
                break;
            }
        }
    }
}

#pragma mark - Navigation Button Layout

- (void)layoutNavigationButtons {
    if (self.refreshControl.isRefreshing) {
        [self layoutNavigationButtonsRefreshing];
    } else if (self.editing) {
        [self layoutNavigationButtonsEditing];
    } else {
        [self layoutNavigationButtonsNormal];
    }
}

- (void)layoutNavigationButtonsNormal {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        self->addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentAddView)];
        self.navigationItem.rightBarButtonItems = @[self->addButton];
    });
}

- (void)layoutNavigationButtonsRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem = nil;
    });
}

- (void)layoutNavigationButtonsEditing {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeSources)];
        deleteButton.enabled = NO;
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources)];
        self.navigationItem.rightBarButtonItems = @[shareButton, deleteButton];
    });
}

#pragma mark - Navigation Button Actions

- (void)presentAddView {
    [self presentAddViewWithURL:NULL];
}

- (void)presentAddViewWithURL:(NSURL *)url {
    ZBSourceAddViewController *addView = [[ZBSourceAddViewController alloc] initWithURL:url];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addView];
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)removeSources {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %lu sources?", @""), (unsigned long)selectedSources.count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self->sourceManager removeSources:[NSSet setWithArray:self->selectedSources] error:nil];
    }];
    [alert addAction:confirm];
    
    UIAlertAction *deny = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deny];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)exportSources {
    if (selectedSources.count) {
        NSMutableArray *debLines = [NSMutableArray new];
        for (ZBBaseSource *source in selectedSources) {
            [debLines addObject:source.debLine];
        }
        
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:debLines applicationActivities:nil];
        shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];
            
        [self presentViewController:shareSheet animated:YES completion:nil];
    }
    else {
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[[ZBAppDelegate sourcesListURL]] applicationActivities:nil];
        shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems[0];
            
        [self presentViewController:shareSheet animated:YES completion:nil];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self layoutNavigationButtonsEditing];
    } else {
        [self layoutNavigationButtonsNormal];
    }
}

#pragma mark - Filter Delegate

- (void)applyFilter:(ZBSourceFilter *)filter {
    self.filter = filter;
    
    [self loadSources];
    [ZBSettings setSourceFilter:self.filter];
}

#pragma mark - Search Results Updating Protocol

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchTerm = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.filter.searchTerm = searchTerm.length > 0 ? searchTerm : NULL;
    [self loadSources];
}

#pragma mark - Search Bar Delegate

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    ZBSourceFilterViewController *filter = [[ZBSourceFilterViewController alloc] initWithFilter:self.filter delegate:self];
    
    UINavigationController *filterVC = [[UINavigationController alloc] initWithRootViewController:filter];
    filterVC.modalPresentationStyle = UIModalPresentationCustom;
    filterVC.transitioningDelegate = self;
    
    [self presentViewController:filterVC animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (withProblems > 0) + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && withProblems > 0) {
        return 1;
    } else {
        return filterResults.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && withProblems > 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"problemChild"];
        
        return cell;
    }
    else {
        ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceCell"];
        [cell setSource:filterResults[indexPath.row]];
        
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !(indexPath.section == 0 && withProblems > 0);
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [super setEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && withProblems > 0) {
        cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu sources could not be fetched.", @""), (unsigned long)withProblems];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.tintColor = [UIColor systemPinkColor];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
        }
    }
    else {
        ZBBaseSource *source = filterResults[indexPath.row];
        
        BOOL busy = source.busy;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [(ZBSourceTableViewCell *)cell setSpinning:busy];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (withProblems > 0 && indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    ZBSource *source = filterResults[indexPath.row];
    if (!self.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if ([source isKindOfClass:[ZBSource class]]) {
            ZBSourceSectionsListTableViewController *sections = [[ZBSourceSectionsListTableViewController alloc] initWithSource:source editOnly:NO];
            [self.navigationController pushViewController:sections animated:YES];
        }
    }
    else {
        if (![self tableView:tableView canEditRowAtIndexPath:indexPath]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        
        [selectedSources addObject:source];
        self.navigationItem.rightBarButtonItems[1].enabled = selectedSources.count;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        ZBSource *source = filterResults[indexPath.row];
        if ([selectedSources containsObject:source]) {
            [selectedSources removeObject:source];
        }
        self.navigationItem.rightBarButtonItems[1].enabled = selectedSources.count;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 || withProblems == 0) {
        ZBSource *source = filterResults[indexPath.row];
        NSError *error;
        if (source.errors && source.errors.count) {
            error = source.errors.firstObject;
        }
        else if (source.warnings && source.warnings.count) {
            error = source.warnings.firstObject;
        }
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithError:error];
        
            switch (error.code) {
                case ZBSourceWarningInsecure: {
//                    UIAlertAction *switchAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Switch to HTTPS", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                        NSString *secureURIString = [@"https" stringByAppendingString:[source.repositoryURI substringFromIndex:4]];
//                        ZBBaseSource *secureBaseSource = [[ZBBaseSource alloc] initFromURL:[NSURL URLWithString:secureURIString]];
//                        
//                        [secureBaseSource verify:^(ZBSourceVerificationStatus status) {
//                            if (status == ZBSourceExists) {
//                                NSString *oldURI = source.repositoryURI;
//                                source.repositoryURI = secureURIString;
//                                
//                                [[ZBSourceManager sharedInstance] updateURIForSource:source oldURI:oldURI error:nil];
//                                
//                                NSMutableArray *mutableWarnings = [source.warnings mutableCopy];
//                                [mutableWarnings removeObject:error];
//                                source.warnings = mutableWarnings;
//                                
//                                dispatch_async(dispatch_get_main_queue(), ^{
//                                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                                });
//                            }
//                            else if (status == ZBSourceVerifying) {
//                                [(ZBSourceTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] setSpinning:YES];
//                            }
//                            else if (status == ZBSourceImaginary) {
//                                [(ZBSourceTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] setSpinning:NO];
//                                
//                                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Unable to locate a secure HTTPS version of %@ or the request timed out. The insecure HTTP version will be used instead.", @""), source.origin];
//                                UIAlertController *stayInsecureAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to switch", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
//                                
//                                UIAlertAction *removeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Source", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        [self->sourceManager removeSources:[NSSet setWithObject:source] error:nil];
//                                    });
//                                }];
//                                [stayInsecureAlert addAction:removeAction];
//                                
//                                UIAlertAction *continueAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"") style:UIAlertActionStyleCancel handler:nil];
//                                [stayInsecureAlert addAction:continueAction];
//                                dispatch_async(dispatch_get_main_queue(), ^{
//                                    [self presentViewController:stayInsecureAlert animated:YES completion:nil];
//                                });
//                            }
//                        }];
//                    }];
//                    [alert addAction:switchAction];
//                    
//                    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"") style:UIAlertActionStyleCancel handler:nil];
//                    [alert addAction:continueAction];
                    break;
                }
                case ZBSourceWarningIncompatible: {
                    UIAlertAction *switchAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Source", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self->sourceManager removeSources:[NSSet setWithArray:@[source]] error:nil];
                    }];
                    [alert addAction:switchAction];
                    
                    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Continue using %@", @""), source.origin] style:UIAlertActionStyleDestructive handler:nil];
                    [alert addAction:continueAction];
                    break;
                }
                default: {
                    UIAlertAction *switchAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Source", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [self->sourceManager removeSources:[NSSet setWithArray:@[source]] error:nil];
                    }];
                    [alert addAction:switchAction];
                    
                    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"") style:UIAlertActionStyleCancel handler:nil];
                    [alert addAction:continueAction];
                    break;
                }
            }
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filterResults[indexPath.row];
    
    UIContextualAction *copyAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Copy",@"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:source.repositoryURI];
        completionHandler(YES);
    }];
    
    if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
        copyAction.image = [UIImage imageNamed:@"doc_fill"];
    }
    copyAction.backgroundColor = [UIColor systemTealColor];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[copyAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = filterResults[indexPath.row];
    
    NSMutableArray *actions = [NSMutableArray new];
    if ([source canDelete]) {
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Delete", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            NSError *error = NULL;
            [self->sourceManager removeSources:[NSSet setWithArray:@[source]] error:&error];
            
            completionHandler(error == NULL);
        }];
        if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
            deleteAction.image = [UIImage imageNamed:@"delete_left"];
        }
        [actions addObject:deleteAction];
    }
    
    UIContextualAction *refreshAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Refresh", @"") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self->sourceManager refreshSources:@[source] useCaching:NO error:nil];
        completionHandler(YES);
    }];
    if ([ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon) {
        refreshAction.image = [UIImage imageNamed:@"arrow_clockwise"];
    }
    [actions addObject:refreshAction];
    
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

#pragma mark - Source Delegate

- (void)startedDownloadForSource:(ZBBaseSource *)source {
    NSUInteger index = [filterResults indexOfObject:(ZBSource *)source];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:withProblems > 0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (void)finishedDownloadForSource:(ZBBaseSource *)source {
    NSUInteger index = [filterResults indexOfObject:(ZBSource *)source];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:withProblems > 0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (void)startedImportForSource:(ZBBaseSource *)source {
    NSUInteger index = [filterResults indexOfObject:(ZBSource *)source];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:withProblems > 0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (void)finishedImportForSource:(ZBBaseSource *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger index = [self->filterResults indexOfObject:(ZBSource *)source];
        if (index != NSNotFound) {
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:index inSection:self->withProblems > 0];

            self.sources = self->sourceManager.sources;
            self->filterResults = [self->sourceManager filterSources:self.sources withFilter:self.filter];

            NSUInteger newIndex = [self->filterResults indexOfObject:(ZBSource *)source];
            if (newIndex != NSNotFound) {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:self->withProblems > 0];

                if ([oldIndexPath isEqual:newIndexPath]) {
                    [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                else {
                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:@[oldIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView endUpdates];
                }
            }
        }
    });
}

- (void)finishedSourceRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSPredicate *search = [NSPredicate predicateWithFormat:@"errors != nil AND errors[SIZE] > 0"];
        self->withProblems = [self.sources filteredArrayUsingPredicate:search].count;

        if (self->withProblems > 0 && self.tableView.numberOfSections == 1) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (self->withProblems == 0 && self.tableView.numberOfSections == 2) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    });
}

- (void)addedSources:(NSArray *)sources {
    self.sources = [self.sources arrayByAddingObjectsFromArray:sources];
    filterResults = [sourceManager filterSources:self.sources withFilter:self.filter];

    NSMutableArray *indexPaths = [NSMutableArray new];
    for (ZBSource *source in sources) {
        NSUInteger index = [filterResults indexOfObject:source];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:withProblems > 0];
            [indexPaths addObject:indexPath];
        }
    }

    if (indexPaths.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)removedSources:(NSArray *)sources {
    NSMutableArray *sourcesCopy = [self.sources mutableCopy];
    for (ZBBaseSource *source in sources) {
        [sourcesCopy removeObject:source];
    }
    self.sources = sourcesCopy;
    filterResults = [sourceManager filterSources:self.sources withFilter:self.filter];
    
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (ZBSource *source in sources) {
        NSUInteger index = [filterResults indexOfObject:source];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:withProblems > 0];
            [indexPaths addObject:indexPath];
        }
    }

    if (indexPaths.count) [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSPredicate *search = [NSPredicate predicateWithFormat:@"errors != nil AND errors[SIZE] > 0"];
        self->withProblems = [self.sources filteredArrayUsingPredicate:search].count;

        if (self->withProblems > 0 && self.tableView.numberOfSections == 1) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (self->withProblems == 0 && self.tableView.numberOfSections == 2) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    });
}

- (void)scrollToTop {
//    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

#pragma mark - Presentation Controller

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return [[ZBPartialPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting scale:0.52];
}

@end
