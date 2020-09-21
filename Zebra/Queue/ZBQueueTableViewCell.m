//
//  ZBQueueTableViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 9/19/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBQueueTableViewCell.h"
#import <Extensions/UIImageView+Zebra.h>

@implementation ZBQueueTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.iconView.layer.cornerRadius = 10;
    self.iconView.clipsToBounds = YES;
    [self.iconView applyBorder];
    [self setStatus:ZBQueueStatusPreparing];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setProgress:(CGFloat)progress {
    if (self.progressView.hidden) self.progressView.hidden = NO;
    
    [self.progressView setProgress:progress animated:YES];
    
    if (progress >= 1.0 && !self.progressView.hidden) {
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.0;
        }];
    }
}

- (void)setStatus:(ZBQueueStatus)status {
    switch (status) {
        case ZBQueueStatusPreparing:
            self.statusLabel.text = NSLocalizedString(@"Preparing...", @"");
            break;
        case ZBQueueStatusDependencies:
            self.statusLabel.text = NSLocalizedString(@"Calculating Dependencies...", @"");
            break;
        case ZBQueueStatusAuthorizing:
            self.statusLabel.text = NSLocalizedString(@"Authorizing Download...", @"");
            break;
        case ZBQueueStatusDownloading:
            self.statusLabel.text = NSLocalizedString(@"Downloading...", @"");
            self.progressView.alpha = 1.0;
            self.progressView.progress = 0.0;
            self.progressView.hidden = NO;
            break;
        case ZBQueueStatusReady:
            self.statusLabel.text = NSLocalizedString(@"Ready to %@", @"");
            break;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.iconView.image = [UIImage imageNamed:@"Unknown"];
}

@end
