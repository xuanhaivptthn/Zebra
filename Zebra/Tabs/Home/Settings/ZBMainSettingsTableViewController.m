//
//  MainSettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBMainSettingsTableViewController.h"
#import "ZBSettingsSelectionTableViewController.h"
#import "Table/UITableView+Settings.h"
#import <Extensions/UIImageView+Zebra.h>
#import "Cells/ZBLinkSettingsTableViewCell.h"
#import "Cells/ZBRightIconTableViewCell.h"
#import "Cells/ZBDetailedLinkSettingsTableViewCell.h"
#import "Cells/ZBSwitchSettingsTableViewCell.h"
#import "Cells/ZBButtonSettingsTableViewCell.h"
#import "Display/ZBDisplaySettingsTableViewController.h"
#import "Reset/ZBSettingsResetTableViewController.h"
#import "Filters/ZBFilterSettingsTableViewController.h"
#import "Language/ZBLanguageSettingsTableViewController.h"
#import <Tabs/Sources/Controllers/ZBSourceSelectTableViewController.h>

#import <ZBSettings.h>
#import <Queue/ZBQueue.h>
#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <Extensions/UIColor+GlobalColors.h>

typedef NS_ENUM(NSInteger, ZBSectionOrder) {
    ZBInterface,
    ZBFilters,
    ZBFeatured,
    ZBSources,
    ZBChanges,
    ZBPackages,
    ZBConsole,
    ZBMisc,
    ZBAnalytics,
    ZBReset
};

typedef NS_ENUM(NSUInteger, ZBInterfaceOrder) {
    ZBDisplay,
    ZBLanguage,
    ZBAppIcon
};

typedef NS_ENUM(NSUInteger, ZBFeatureOrder) {
    ZBFeaturedEnable,
    ZBFeatureOrRandomToggle,
    ZBFeatureBlacklist
};

@interface ZBMainSettingsTableViewController () {
    NSMutableDictionary *_colors;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}

@end

@implementation ZBMainSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    accentColor = [ZBSettings accentColor];
    interfaceStyle = [ZBSettings interfaceStyle];
    
    [self.tableView registerCellTypes:@[@(ZBLinkSettingsCell), @(ZBDetailedLinkSettingsCell), @(ZBSwitchSettingsCell), @(ZBButtonSettingsCell)]];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRightIconTableViewCell" bundle:nil] forCellReuseIdentifier:@"settingsAppIconCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (IBAction)closeButtonTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBFeatured:
            return NSLocalizedString(@"Home", @"");
        case ZBSources:
            return NSLocalizedString(@"Sources", @"");
        case ZBChanges:
            return NSLocalizedString(@"Changes", @"");
//        case ZBSearch:
//            return NSLocalizedString(@"Search", @"");
        case ZBMisc:
            return NSLocalizedString(@"Miscellaneous", @"");
        case ZBConsole:
            return NSLocalizedString(@"Console", @"");
        case ZBPackages:
            return NSLocalizedString(@"Packages", @"");
        default:
            return NULL;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 11;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section_ {
    ZBSectionOrder section = section_;
    switch (section) {
        case ZBFilters:
        case ZBChanges:
        case ZBMisc:
//        case ZBSearch:
        case ZBConsole:
        case ZBAnalytics:
            return 1;
        case ZBInterface:
            return 3;
        case ZBFeatured: {
            if ([ZBSettings wantsFeaturedPackages]) {
                if ([ZBSettings featuredPackagesType] == ZBFeaturedTypeRandom) {
                    return 3;
                }
                return 2;
            }
            
            return 1;
        }
        case ZBPackages:
        case ZBSources:
        case ZBReset:
            return 2;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == ZBInterface && indexPath.row == ZBAppIcon) {
        if (@available(iOS 10.3, *)) {
            ZBRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsAppIconCell"];
            cell.backgroundColor = [UIColor cellBackgroundColor];
            
            cell.label.text = NSLocalizedString(@"App Icon", @"");
            
            NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
            UIImage *iconImage = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
            [cell setAppIcon:iconImage border:[[icon objectForKey:@"border"] boolValue]];
            
            return cell;
        }
    }
    else if ((indexPath.section == ZBFeatured && indexPath.row == ZBFeatureOrRandomToggle) || indexPath.section == ZBMisc || (indexPath.section == ZBSources && indexPath.row == 1)) {
        static NSString *cellIdentifier = @"settingsRightDetailCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
    } else {
        static NSString *cellIdentifier = @"settingsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor cellBackgroundColor];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
    
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInterface: {
            ZBLinkSettingsTableViewCell *cell;
            ZBInterfaceOrder row = indexPath.row;
            switch (row) {
                case ZBDisplay: {
                    cell = [tableView dequeueLinkSettingsCellForIndexPath:indexPath];
                    cell.textLabel.text = NSLocalizedString(@"Display", @"");
                    break;
                }
                case ZBLanguage: {
                    cell = [tableView dequeueLinkSettingsCellForIndexPath:indexPath];
                    cell.textLabel.text = NSLocalizedString(@"Language", @"");
                    break;
                }
                case ZBAppIcon: {
                    ZBRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsAppIconCell" forIndexPath:indexPath];
                    
                    cell.backgroundColor = [UIColor cellBackgroundColor];
                    cell.label.text = NSLocalizedString(@"App Icon", @"");
                    
                    NSDictionary *icon = [ZBAlternateIconController iconForName:[[UIApplication sharedApplication] alternateIconName]];
                    UIImage *iconImage = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
                    [cell setAppIcon:iconImage border:[[icon objectForKey:@"border"] boolValue]];
                    
                    return cell;
                }
            }
            [cell applyStyling];
            return cell;
        }
        case ZBFilters: {
            ZBLinkSettingsTableViewCell *cell = [tableView dequeueLinkSettingsCellForIndexPath:indexPath];

            cell.textLabel.text = NSLocalizedString(@"Filters", @"");

            [cell applyStyling];
            return cell;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeaturedEnable: {
                    ZBSwitchSettingsTableViewCell *cell = [tableView dequeueSwitchSettingsCellForIndexPath:indexPath];

                    cell.textLabel.text = NSLocalizedString(@"Featured Packages", @"");
                    [cell setOn:[ZBSettings wantsFeaturedPackages]];
                    [cell setTarget:self action:@selector(toggleFeatured:)];

                    [cell applyStyling];
                    return cell;
                }
                case ZBFeatureOrRandomToggle: {
                    ZBDetailedLinkSettingsTableViewCell *cell = [tableView dequeueDetailedLinkSettingsCellForIndexPath:indexPath];

                    ZBFeaturedType type = [ZBSettings featuredPackagesType];
                    if (type == ZBFeaturedTypeSource) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Repo Featured", @"");
                    } else {
                        cell.detailTextLabel.text = NSLocalizedString(@"Random", @"");
                    }
                    cell.textLabel.text = NSLocalizedString(@"Feature Type", @"");
                    
                    [cell applyStyling];
                    return cell;
                }
                case ZBFeatureBlacklist: {
                    ZBLinkSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsLinkCell" forIndexPath:indexPath];
                    
                    cell.textLabel.text = NSLocalizedString(@"Select Repos to be Featured", @"");
                    
                    [cell applyStyling];
                    return cell;
                }
                default:
                    break;
            }
        }
        case ZBSources: {
            if (indexPath.row == 0) {
                ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];

                cell.textLabel.text = NSLocalizedString(@"Automatic Refresh", @"");
                [cell setOn:[ZBSettings wantsAutoRefresh]];
                [cell setTarget:self action:@selector(toggleAutoRefresh:)];

                [cell applyStyling];
                return cell;
            } else {
                ZBDetailedLinkSettingsTableViewCell *cell = [tableView dequeueDetailedLinkSettingsCellForIndexPath:indexPath];

                int timeout = (int)[ZBSettings sourceRefreshTimeout];

                cell.textLabel.text = NSLocalizedString(@"Download Timeout", @"");
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Seconds", @""), timeout];

                [cell applyStyling];
                return cell;
            }
        }
        case ZBChanges: {
            ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(@"Community News", @"");
            [cell setOn:[ZBSettings wantsCommunityNews]];
            [cell setTarget:self action:@selector(toggleNews:)];

            [cell applyStyling];
            return cell;
        }
        case ZBPackages: {
            if (indexPath.row == 0) {
                ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
                
                cell.textLabel.text = NSLocalizedString(@"Always Install Latest", @"");
                [cell setOn:[ZBSettings alwaysInstallLatest]];
                [cell setTarget:self action:@selector(toggleLatest:)];

                [cell applyStyling];
                return cell;
            } else {
                ZBDetailedLinkSettingsTableViewCell *cell = [tableView dequeueDetailedLinkSettingsCellForIndexPath:indexPath];

                uint8_t type = [ZBSettings role];
                NSArray *choices = @[@"User", @"Hacker", @"Developer", @"Deity"];
                cell.detailTextLabel.text = type < choices.count ? choices[type] : @"Deity";
                cell.textLabel.text = NSLocalizedString(@"Role", @"");
                
                [cell applyStyling];
                return cell;
            }
        }
//        case ZBSearch: {
//            ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
//
//            cell.textLabel.text = NSLocalizedString(@"Live Search", @"");
//            [cell setOn:[ZBSettings wantsLiveSearch]];
//            [cell setTarget:self action:@selector(toggleLiveSearch:)];
//
//            [cell applyStyling];
//            return cell;
//        }
        case ZBConsole: {
            ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(@"Finish Automatically", @"");
            [cell setOn:[ZBSettings wantsFinishAutomatically]];
            [cell setTarget:self action:@selector(toggleFinishAutomatically:)];

            [cell applyStyling];
            return cell;
        }
        case ZBMisc: {
            ZBDetailedLinkSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsDetailedLinkCell" forIndexPath:indexPath];
            
            ZBSwipeActionStyle style = [ZBSettings swipeActionStyle];
            if (style == ZBSwipeActionStyleText) {
                cell.detailTextLabel.text = NSLocalizedString(@"Text", @"");
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"Icon", @"");
            }
            cell.textLabel.text = NSLocalizedString(@"Swipe Actions Display As", @"");;
            
            [cell applyStyling];
            return cell;
        }
        case ZBAnalytics: {
            ZBSwitchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsSwitchCell" forIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(@"Analytics & Crash Reporting", @"");
            [cell setOn:[ZBSettings allowsCrashReporting]];
            [cell setTarget:self action:@selector(toggleCrashReporting:)];

            [cell applyStyling];
            return cell;
        }
        case ZBReset: {
            if (indexPath.row == 0) {
                ZBLinkSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsLinkCell" forIndexPath:indexPath];
                
                cell.textLabel.text = NSLocalizedString(@"Reset", @"");

                [cell applyStyling];
                return cell;
            } else {
                ZBButtonSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsButtonCell" forIndexPath:indexPath];

                cell.textLabel.text = NSLocalizedString(@"Open Documents Directory", @"");

                [cell applyStyling];
                return cell;
            }
        }
        default:
            break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSectionOrder section = indexPath.section;
    switch (section) {
        case ZBInterface: {
            ZBInterfaceOrder row = indexPath.row;
            switch (row) {
                case ZBDisplay:
                    [self displaySettings];
                    break;
                case ZBLanguage:
                    [self chooseLanguage];
                    break;
                case ZBAppIcon:
                    [self changeIcon];
                    break;
            }
            break;
        }
        case ZBFilters: {
            [self filterSettings];
            break;
        }
        case ZBFeatured: {
            ZBFeatureOrder row = indexPath.row;
            switch (row) {
                case ZBFeaturedEnable: {
                    [self toggleSwitchAtIndexPath:indexPath];
                    break;
                }
                case ZBFeatureOrRandomToggle:
                    [self featureOrRandomToggle];
                    break;
                case ZBFeatureBlacklist:
                    [self sourceBlacklist];
                    break;
                default:
                    break;
            }
            break;
        }
        case ZBSources: {
            if (indexPath.row == 0) {
                [self toggleSwitchAtIndexPath:indexPath];
                break;
            } else {
                [self chooseSourcesTimeout];
                break;
            }
        }
        case ZBChanges:
        case ZBPackages: {
            if (indexPath.row == 0) {
                [self toggleSwitchAtIndexPath:indexPath];
                break;
            } else {
                [self selectRole];
                break;
            }
        }
        case ZBConsole: {
            [self toggleSwitchAtIndexPath:indexPath];
            break;
        }
        case ZBMisc: {
            [self misc];
            break;
        }
        case ZBReset: {
            switch (indexPath.row) {
                case 0:
                    [self resetSettings];
                    break;
                case 1:
                    [self openDocumentsDirectory];
                    break;
            }
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case ZBFeatured:
            return NSLocalizedString(@"Display featured packages on the homepage.", @"");
        case ZBSources:
            return NSLocalizedString(@"Refresh Zebra's sources when opening the app.", @"");
        case ZBChanges:
            return NSLocalizedString(@"Display recent community posts from /r/jailbreak.", @"");
//        case ZBSearch:
//            return NSLocalizedString(@"Search packages while typing. Disabling this feature may reduce lag on older devices.", @"");
        case ZBMisc:
            return NSLocalizedString(@"Configure the appearance of table view swipe actions.", @"");
        case ZBConsole:
            return NSLocalizedString(@"Automatically dismiss the Console when all of its tasks have been completed.", @"");
        case ZBPackages:
            return NSLocalizedString(@"Always install the most recent version of a package if it is not already installed.", @"");
        default:
            return NULL;
    }
}

# pragma mark selected cells methods

- (void)filterSettings {
    ZBFilterSettingsTableViewController *filterController = [[ZBFilterSettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:filterController animated:YES];
}

- (void)displaySettings {
    ZBDisplaySettingsTableViewController *displayController = [[ZBDisplaySettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:displayController animated:YES];
}

- (void)chooseLanguage {
    ZBLanguageSettingsTableViewController *languageController = [[ZBLanguageSettingsTableViewController alloc] init];
    
    [[self navigationController] pushViewController:languageController animated:YES];
}

- (void)sourceBlacklist {
    NSMutableArray *sources = [NSMutableArray new];
    NSArray *baseFilenames = [ZBSettings sourceBlacklist];
    for (NSString *baseFilename in baseFilenames) {
        ZBSource *source = [[ZBSourceManager sharedInstance] sourceWithUUID:baseFilename];
        if (source) [sources addObject:source];
    }
    
    ZBSourceSelectTableViewController *selectSource = [[ZBSourceSelectTableViewController alloc] initWithSelectionType:ZBSourceSelectionTypeInverse limit:0 selectedSources:sources];
    [selectSource setSourcesSelected:^(NSArray<ZBSource *> * _Nonnull selectedSources) {
        NSMutableArray *blockedSources = [NSMutableArray new];
        for (ZBSource *source in selectedSources) {
            [blockedSources addObject:[source uuid]];
        }
        [ZBSettings setSourceBlacklist:blockedSources];
    }];
    
    [[self navigationController] pushViewController:selectSource animated:YES];
}

- (void)resetSettings {
    ZBSettingsResetTableViewController *advancedController = [[ZBSettingsResetTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] pushViewController:advancedController animated:YES];
}

- (void)openDocumentsDirectory {
    if ([[UIApplication sharedApplication] canOpenURL:[ZBAppDelegate documentsDirectoryURL]]) {
        [[UIApplication sharedApplication] openURL:[ZBAppDelegate documentsDirectoryURL] options:@{} completionHandler:nil];
    }
    else {
        UIAlertController *noMagicWord = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Filza Not Installed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Zebra cannot open its documents directory because Filza is not installed. Your documents directory is: %@", @""), [ZBAppDelegate documentsDirectory]] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
        [noMagicWord addAction:ok];
        
        [self presentViewController:noMagicWord animated:YES completion:nil];
    }
}

- (void)featureOrRandomToggle {
    ZBSettingsSelectionTableViewController * controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:@[@"Repo Featured", @"Random"] getter:@selector(featuredPackagesType) setter:@selector(setFeaturedPackagesType:) settingChangedCallback:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshCollection" object:self];
    }];
    
    [controller setTitle:@"Feature Type"];
    [controller setFooterText:@[@"Change the source of the featured packages on the homepage.", @"\"Repo Featured\" will display random packages from repos that support the Featured Package API.", @"\"Random\" will display random packages from all repositories that you have added to Zebra."]];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)selectRole {
    ZBSettingsSelectionTableViewController * controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:@[@"User", @"Hacker", @"Developer"] getter:@selector(role) setter:@selector(setRole:) settingChangedCallback:nil];
    
    [controller setTitle:@"Role"];
    [controller setFooterText:@[@"User: Apps, Tweaks, and Themes\nHacker: Adds Command Line Tools\nDeveloper: Everything (well, almost)"]];
    
    [self.navigationController pushViewController:controller animated:YES];
}


- (void)changeIcon {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBAlternateIconController *altIcon = [storyboard instantiateViewControllerWithIdentifier:@"alternateIconController"];
    [self.navigationController pushViewController:altIcon animated:YES];
}

- (void)chooseSourcesTimeout {
    NSArray *choices = @[@5, @10, @15, @30, @45, @60];
    NSMutableArray *formattedChoices = [NSMutableArray arrayWithCapacity:choices.count];

    NSString *localizedSeconds = NSLocalizedString(@"%d Seconds", @"");
    for (NSNumber *choice in choices) {
         [formattedChoices addObject:[NSString stringWithFormat:localizedSeconds, [choice intValue]]];
    }

    ZBSettingsSelectionTableViewController * controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:formattedChoices getter:@selector(sourceRefreshTimeoutIndex) setter:@selector(setSourceRefreshTimeout:) settingChangedCallback:nil];

    [controller setTitle:@"Download Timeout"];
    [controller setFooterText:@[@"Configure the amount of time Zebra will wait for a source to respond before timing out.", @"This timer will reset every time Zebra receives new information from a source."]];

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)toggleFeatured:(NSNumber *)newValue {
    [ZBSettings setWantsFeaturedPackages:[newValue boolValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleFeatured" object:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ZBFeatured] withRowAnimation:UITableViewRowAnimationFade];
    });
}

- (void)toggleAutoRefresh:(NSNumber *)newValue {
    [ZBSettings setWantsAutoRefresh:[newValue boolValue]];
}

- (void)toggleNews:(NSNumber *)newValue {
    [ZBSettings setWantsCommunityNews:[newValue boolValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleNews" object:self];
}

- (void)toggleLatest:(NSNumber *)newValue {
    [ZBSettings setAlwaysInstallLatest:[newValue boolValue]];
}

//- (void)toggleLiveSearch:(NSNumber *)newValue {
//    [ZBSettings setWantsLiveSearch:[newValue boolValue]];
//}

- (void)toggleFinishAutomatically:(NSNumber *)newValue {
    [ZBSettings setWantsFinishAutomatically:[newValue boolValue]];
}

- (void)toggleCrashReporting:(NSNumber *)newValue {
    [ZBSettings setAllowsCrashReporting:[newValue boolValue]];
}

- (void)misc {
    ZBSettingsSelectionTableViewController *controller = [[ZBSettingsSelectionTableViewController alloc] initWithOptions:@[@"Text", @"Icon"] getter:@selector(swipeActionStyle) setter:@selector(setSwipeActionStyle:) settingChangedCallback:nil];
    [controller setTitle:@"Swipe Actions Display As"];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
