//
//  GSDetailViewController.h
//  GSSplitViewControllerDemo
//
//  Created by Christian Gossain on 2014-05-10.
//  Copyright (c) 2014 Christian Gossain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSSplitViewController.h"

@interface GSDetailViewController : UIViewController <GSSplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) UILabel *detailDescriptionLabel;
@end
