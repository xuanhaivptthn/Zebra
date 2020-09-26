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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setProgress:(CGFloat)progress {
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
        self.progressView.alpha = 1.0;
    }
    
    [self.progressView setProgress:progress animated:YES];
    
    if (progress >= 1.0 && !self.progressView.hidden) {
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.0;
        }];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.iconView.image = [UIImage imageNamed:@"Unknown"];
}

@end
