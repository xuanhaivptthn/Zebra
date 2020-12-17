//
//  ZBSourceFilterViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceFilterViewController.h"

#import <Extensions/UIColor+GlobalColors.h>
#import <Model/ZBSourceFilter.h>
#import <UI/Common/ZBSelectionViewController.h>

@interface ZBSourceFilterViewController () {
    id <ZBFilterDelegate> delegate;
}
@property (nonatomic) ZBSourceFilter *filter;
@end

@implementation ZBSourceFilterViewController

#pragma mark - Initializers

- (instancetype)initWithFilter:(ZBSourceFilter *)filter delegate:(id <ZBFilterDelegate>)delegate {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        self->delegate = delegate;
        self.filter = filter;
        
        self.title = NSLocalizedString(@"Filters", @"");
        self.view.tintColor = [UIColor accentColor];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)setTitle:(NSString *)title {
    UILabel *titleLabel = [UILabel new];
    titleLabel.textColor = [UIColor primaryTextColor];
    titleLabel.text = title;
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    UIFont *largeTitleFont = [UIFont fontWithDescriptor:[titleFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:titleFont.pointSize];
    titleLabel.font = largeTitleFont;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down.circle.fill"] style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor tertiaryTextColor];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Selection Delegate

- (void)selectedChoices:(NSArray *)choices fromIndexPath:(NSIndexPath *)indexPath {
    // Our indexPath section is only going to be 0 in this controller
//    switch (indexPath.row) {
//        case 0: { // Sections
//            self.filter.sections = choices;
//            break;
//        }
//        case 1: {
//            NSArray *roles = @[@"User", @"Hacker", @"Developer", @"Deity"];
//            NSString *role = choices.firstObject;
//            if (role) {
//                NSUInteger index = [roles indexOfObject:role];
//                self.filter.role = index;
//                self.filter.userSetRole = index != [ZBSettings role];
//            }
//            break;
//        }
//        default:
//            break;
//    }
//
//    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    [delegate applyFilter:self.filter];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"filterCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Stores";
                    break;
            }
            break;
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Name";
                    break;
                case 1:
                    cell.textLabel.text = @"Package Count";
                    break;
            }
            if (self.filter.sortOrder == indexPath.row) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? NSLocalizedString(@"Filter By", @"") : NSLocalizedString(@"Sort By", @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    self.filter.stores = !self.filter.stores;
                    break;
            }
            break;
        }
        case 1: {
            self.filter.sortOrder = indexPath.row;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            [delegate applyFilter:self.filter];
            break;
        }
    }
}

@end
