//
//  GSDetailViewController.m
//  GSSplitViewControllerDemo
//
//  Created by Christian Gossain on 2014-05-10.
//  Copyright (c) 2014 Christian Gossain. All rights reserved.
//

#import "GSDetailViewController.h"

@interface GSDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation GSDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _detailDescriptionLabel = [[UILabel alloc] init];
        _detailDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview:_detailDescriptionLabel];
        
        [self.view setNeedsUpdateConstraints];
    }
    return self;
    
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(GSSplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
}

- (void)splitViewController:(GSSplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

#pragma mark - Constraints

- (void)updateViewConstraints {
    
    [super updateViewConstraints];
    
    NSLayoutConstraint *centerLabelX = [NSLayoutConstraint constraintWithItem:self.detailDescriptionLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0f
                                                                     constant:0.0f];
    
    [self.view addConstraint:centerLabelX];
    
    NSLayoutConstraint *centerLabelY = [NSLayoutConstraint constraintWithItem:self.detailDescriptionLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0f
                                                                     constant:0.0f];
    
    [self.view addConstraint:centerLabelY];
    
    
    
}

@end
