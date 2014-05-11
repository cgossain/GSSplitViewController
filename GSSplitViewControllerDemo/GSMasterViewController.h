//
//  GSMasterViewController.h
//  GSSplitViewControllerDemo
//
//  Created by Christian Gossain on 2014-05-10.
//  Copyright (c) 2014 Christian Gossain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSDetailViewController;

@interface GSMasterViewController : UITableViewController

@property (strong, nonatomic) GSDetailViewController *detailViewController;

@end
