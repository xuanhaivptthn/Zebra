//
//  ZBQueueTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 9/19/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBQueueTableViewCell.h"

@implementation ZBQueueTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.iconView.layer.cornerRadius = 10;
    self.iconView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.progressView.progress = 0.0;
    self.progressView.hidden = NO;
    self.statusLabel.text = NSLocalizedString(@"Downloading", @"");
    self.packageNameLabel.text = @"Package";
    self.iconView.image = [UIImage imageNamed:@"Tweaks"];
}

@end
