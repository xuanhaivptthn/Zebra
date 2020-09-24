//
//  ZBConsoleViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import UIKit;

#import <Downloads/ZBDownloadDelegate.h>
#import <Database/ZBDatabaseDelegate.h>
#import "ZBCommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    ZBStageRemove,
    ZBStageInstall,
    ZBStageReinstall,
    ZBStageUpgrade,
    ZBStageDowngrade,
    ZBStageFinished
} ZBStage;

@interface ZBConsoleViewController : UIViewController <ZBCommandDelegate, UIGestureRecognizerDelegate>
@end

NS_ASSUME_NONNULL_END
