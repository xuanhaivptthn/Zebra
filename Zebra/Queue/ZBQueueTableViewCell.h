//
//  ZBQueueTableViewCell.h
//  Zebra
//
//  Created by Wilson Styres on 9/19/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueueTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet UILabel *packageNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
- (void)setProgress:(CGFloat)progress;
- (void)setStatus:(ZBQueueStatus)status queueType:(ZBQueueType)queue;
@end

NS_ASSUME_NONNULL_END
