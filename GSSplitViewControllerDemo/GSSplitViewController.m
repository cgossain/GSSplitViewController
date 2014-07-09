
//
// GSSplitViewController.m
//
// Copyright (c) 2014 Christian R. Gossain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "GSSplitViewController.h"

#define DEBUG_LAYOUT 0

#define kDivderWidth 1.0f / [[UIScreen mainScreen] scale]

#define kSwipeXDirectionThreshold 60.0  // gesture needs to be greater than this value in the X direction to be considered a swipe

NSString * const GSSplitViewControllerDidShowMasterPaneNotification = @"com.gossainsoftware.GSSplitViewControllerDidShowMasterPaneNotification";
NSString * const GSSplitViewControllerDidHideMasterPaneNotification = @"com.gossainsoftware.GSSplitViewControllerDidHideMasterPaneNotification";

@interface GSSplitViewController ()

@property (strong, nonatomic) UIPanGestureRecognizer *detailPanGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *detailTapGestureRecognizer;

@property (strong, nonatomic) UIView *dividerView;

@property (strong, nonatomic) UIBarButtonItem *barButtonItem;

@property (strong, nonatomic) UIView *gestureOverlayView;

@end

@implementation GSSplitViewController {
    NSArray *_layoutConstaints;
    
    BOOL _isMasterVisible;
    CGPoint _lastGestureLocation;
    
    BOOL _didLayoutViewControllers;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _detailPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _detailTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        
        _gestureOverlayView = [[UIView alloc] init];
        
#if DEBUG_LAYOUT
        _gestureOverlayView.layer.borderColor = [UIColor greenColor].CGColor;
        _gestureOverlayView.layer.borderWidth = 2.0f;
#endif
        
        _masterPaneWidth = 320.0f;
        _presentsWithGesture = YES;
        
        _dividerView = [[UIView alloc] init];
        _dividerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:38.0f/255.0f];
        
        _barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(showMasterPaneBarButtonItemTapped:)];
        
    }
    return self;
}

#pragma mark - View Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1.0f];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
    
    if (!_didLayoutViewControllers) {
        
        // this is the initial layout of the split view controllers view controllers, subsequent layouts will consist only of frame changes.
        
        UIViewController *master = [self.viewControllers objectAtIndex:0];
        UIViewController *detail = [self.viewControllers objectAtIndex:1];
        
        // add the detail view
        [self addDetailViewController:detail];
        
        // add the master view
        [self addMasterViewController:master];
        
        // add the divider as a subview
        [self.view addSubview:self.dividerView];
        
        if ([self masterPaneCanBePresentedInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
            
            // ensure that the master is visible according to the 'isMasterPaneShown...' property
            _isMasterVisible = self.isMasterPaneShownOnInitialRotationToPortrait;
            
            // ensure that the delegate has a chance to add a bar button item if the view will be laid out in portrait
            [self splitViewWillRotateToPortraitOrientation];
            
        }
        
        _didLayoutViewControllers = YES;
        
    }
    
    // update the layout for the current orientation
    [self updateSplitViewForOrientation:GS_STATUS_BAR_ORIENTATION()];
    
}

#pragma mark - Methods (Public)

- (void)setMasterPaneShown:(BOOL)masterPaneShown animated:(BOOL)animated {
    
    // only bother if the master pane can be shown
    if ([self masterPaneCanBePresentedInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
        
        _isMasterVisible = masterPaneShown;
        
        if (animated) {
            
            GSSplitViewController *__weak weakSelf = self;
            
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 
                                 GSSplitViewController *strongSelf = weakSelf;
                                 
                                 [strongSelf adjustFramesForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
                                 [strongSelf configureGestureRecognizersForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
                                 
                             }
                             completion:nil];
            
        }
        else {
            
            [self adjustFramesForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
            [self configureGestureRecognizersForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
            
        }
        
        if (masterPaneShown) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GSSplitViewControllerDidShowMasterPaneNotification object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:GSSplitViewControllerDidHideMasterPaneNotification object:nil];
        }
        
    }
    
}

#pragma mark - Setters

- (void)setViewControllers:(NSArray *)viewControllers {
    
    NSString *assertionMessage = @"GSSplitViewController %@ must be provided a view controllers array that contains exactly two UIViewController instances.";
    
    // ensure the array contains view controller
    NSAssert(viewControllers.count == 2, assertionMessage);
    
    // assert that both objects in the array are instances of the UIViewControllerClass
    for (id object in viewControllers) {
        
        NSAssert([object isKindOfClass:[UIViewController class]], assertionMessage);
        
    }
    
    if (_viewControllers) {
        
        // remove the existing view controllers
        for (UIViewController *viewController in _viewControllers) {
            [self removeContentViewController:viewController];
        }
        
        _didLayoutViewControllers = NO; // new view controllers were provided, need to make sure they get layed out
        
    }
    
    _viewControllers = [viewControllers copy];
    
    [self.view setNeedsLayout];
    
}

- (void)setMasterPaneWidth:(CGFloat)masterPaneWidth {
    
    _masterPaneWidth = masterPaneWidth;
    
    [self adjustFramesForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    [self configureGestureRecognizersForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    
}

- (void)setPresentsWithGesture:(BOOL)presentsWithGesture {
    
    if (_presentsWithGesture != presentsWithGesture) {
        
        _presentsWithGesture = presentsWithGesture;
        
        // update the gesture recognizers
        [self configureGestureRecognizersForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
        
    }
    
}

#pragma mark - Getters

- (BOOL)isMasterPaneVisible {
    
    if ([self masterPaneCanBePresentedInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
        
        return _isMasterVisible;
        
    }
    
    return YES; // if the master pane can't be presented (i.e. it can be hidden or shown) in a particular orientation, then it is technically always shown
    
}

#pragma mark - Interface Orientation

- (NSUInteger)supportedInterfaceOrientations {
    
    if ([self.delegate respondsToSelector:@selector(splitViewControllerSupportedInterfaceOrientations:)]) {
        return [self.delegate splitViewControllerSupportedInterfaceOrientations:self];
    }
    
    return UIInterfaceOrientationMaskAll;
    
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    NSLog(@"GSSplitViewWillRotate");
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        
        _isMasterVisible = self.masterPaneShownOnInitialRotationToPortrait; // default state of the master pane when rotating to portrait
        
        [self splitViewWillRotateToPortraitOrientation];
        
    }
    else {
        
        _isMasterVisible = YES; // master always shown in landscape orientation
        
        if ([self.delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)]) {
            
            [self.delegate splitViewController:self
                        willShowViewController:self.viewControllers[0]
                     invalidatingBarButtonItem:self.barButtonItem];
            
        }
        
    }
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    NSLog(@"GSSplitViewAnimateRotatation");
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    // this rotation method is called from an animation block, therefore the following changes will be animated
    [self adjustFramesForInterfaceOrientation:toInterfaceOrientation];
    [self configureGestureRecognizersForInterfaceOrientation:toInterfaceOrientation];
    
}

#pragma mark - UIViewControllerContainment

- (void)addMasterViewController:(UIViewController *)contentViewController {
    
    [self addChildViewController:contentViewController];
    
    contentViewController.view.frame = [self masterPaneFrameForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    contentViewController.view.clipsToBounds = YES;
    
    [self.view addSubview:contentViewController.view];
    
    [contentViewController didMoveToParentViewController:self];
    
}

- (void)addDetailViewController:(UIViewController *)contentViewController {
    
    [self addChildViewController:contentViewController];
    
    contentViewController.view.frame = [self detailPaneFrameForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    contentViewController.view.clipsToBounds = YES;
    
    [self.view addSubview:contentViewController.view];
    
    [contentViewController didMoveToParentViewController:self];
    
}

- (void)removeContentViewController:(UIViewController *)contentViewController {
    
    [contentViewController willMoveToParentViewController:nil];
    
    [contentViewController.view removeFromSuperview];
    
    [contentViewController removeFromParentViewController];
    
}

#pragma mark - Actions

- (void)showMasterPaneBarButtonItemTapped:(UIBarButtonItem *)item {
    
    [self setMasterPaneShown:!_isMasterVisible animated:YES];
    
}

#pragma mark - Selectors

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    
    if ([self masterPaneCanBePresentedInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
        [self setMasterPaneShown:NO animated:YES];
    }
    
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    
    // only bother panning the master pane if it can be shown
    if ([self masterPaneCanBePresentedInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
        
        CGPoint location = [gestureRecognizer locationInView:self.view];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            
            _lastGestureLocation = location;
            
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            
            CGFloat diffX = location.x - _lastGestureLocation.x;
            
            if (diffX < 0) {
                
                // overall left movement
                if (fabsf(diffX) > kSwipeXDirectionThreshold) {
                    
                    // hide the master view
                    if (_isMasterVisible) {
                        [self setMasterPaneShown:NO animated:YES];
                    }
                    
                    // update the last gesture location since a movent was detected
                    _lastGestureLocation = location;
                    
                }
                
            }
            else if (diffX > 0) {
                
                // overall right movement
                if (fabsf(diffX) > kSwipeXDirectionThreshold) {
                    
                    // show the master view
                    if (!_isMasterVisible) {
                        [self setMasterPaneShown:YES animated:YES];
                    }
                    
                    // update the last gesture location since a movent was detected
                    _lastGestureLocation = location;
                    
                }
                
            }
            
        }
        
    }
    
}

#pragma mark - Helpers

- (void)adjustFramesForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (_viewControllers) {
        
        UIViewController *master = [self.viewControllers objectAtIndex:0];
        master.view.frame = [self masterPaneFrameForInterfaceOrientation:interfaceOrientation];
        
        UIViewController *detail = [self.viewControllers objectAtIndex:1];
        detail.view.frame = [self detailPaneFrameForInterfaceOrientation:interfaceOrientation];
        
        self.dividerView.frame = [self dividerFrameForInterfaceOrientation:interfaceOrientation];
        
    }
    
}

- (CGRect)masterPaneFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    CGFloat xOffset = 0.0f;
    
    if ([self masterPaneCanBePresentedInOrientation:interfaceOrientation]) {
        
        if (_isMasterVisible) {
            xOffset = 0.0f;
        }
        else {
            xOffset = - (self.masterPaneWidth + kDivderWidth);
        }
        
    }
    
    return CGRectMake(xOffset, 0.0f, self.masterPaneWidth, self.view.bounds.size.height);
    
}

- (CGRect)detailPaneFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    CGFloat xOffset = self.masterPaneWidth;
    
    if ([self masterPaneCanBePresentedInOrientation:interfaceOrientation]) {
        xOffset = 0.0f;
    }
    
    return CGRectMake(xOffset, 0.0f, (self.view.bounds.size.width - xOffset), self.view.bounds.size.height);
    
}

- (CGRect)dividerFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    CGRect masterFrame = [self masterPaneFrameForInterfaceOrientation:interfaceOrientation];
    
    return CGRectMake(masterFrame.origin.x + masterFrame.size.width - kDivderWidth, masterFrame.origin.y, kDivderWidth, masterFrame.size.height);
    
}

- (void)splitViewWillRotateToPortraitOrientation {
    
    if ([self.delegate respondsToSelector:@selector(splitViewController:willHideViewController:withBarButtonItem:)]) {
        
        self.barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(showMasterPaneBarButtonItemTapped:)];
        
        [self.delegate splitViewController:self
                    willHideViewController:self.viewControllers[0]
                         withBarButtonItem:self.barButtonItem];
        
    }
    
}

- (BOOL)shouldHideMasterViewControllerInOrientation:(UIInterfaceOrientation)orientation {
    
    // ask the delegate
    if ([self.delegate respondsToSelector:@selector(splitViewController:shouldHideViewController:inOrientation:)]) {
        return [self.delegate splitViewController:self shouldHideViewController:self.viewControllers[0] inOrientation:orientation];
    }
    
    // default behaviour
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        return YES;
    }
    else {
        return NO;
    }
    
}

- (void)configureGestureRecognizersForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    UIViewController *detail = [self.viewControllers objectAtIndex:1];
    
    if ([self masterPaneCanBePresentedInOrientation:interfaceOrientation] && self.presentsWithGesture && self.viewControllers) {
        
        if (_isMasterVisible) {
            
            CGRect masterFrame = [self masterPaneFrameForInterfaceOrientation:interfaceOrientation];
            CGRect detailFrame = [self detailPaneFrameForInterfaceOrientation:interfaceOrientation];
            
            // there should be a gesture overlay to intercept touches and prevent them from leaking into the detail view
            self.gestureOverlayView.frame = CGRectMake(masterFrame.size.width, 0.0f, detailFrame.size.width - masterFrame.size.width, detailFrame.size.height);
            
            // remove the gesture recognizers to the detail view
            [detail.view removeGestureRecognizer:self.detailPanGestureRecognizer];
            [detail.view removeGestureRecognizer:self.detailTapGestureRecognizer];
            
            // add the gesture overlay view as a subview to the view
            [self.view addSubview:self.gestureOverlayView];
            
            // add the gesture recognizers to the overlay view
            [self.gestureOverlayView addGestureRecognizer:self.detailPanGestureRecognizer];
            [self.gestureOverlayView addGestureRecognizer:self.detailTapGestureRecognizer];
            
        }
        else {
            
            // remove the gesture recognizers from the overlay view
            [self.gestureOverlayView removeGestureRecognizer:self.detailPanGestureRecognizer];
            [self.gestureOverlayView removeGestureRecognizer:self.detailTapGestureRecognizer];
            
            // remove the gesture overlay view from the view
            [self.gestureOverlayView removeFromSuperview];
            
            // add the pan recognizer to the detail view
            [detail.view addGestureRecognizer:self.detailPanGestureRecognizer];
            
        }
        
    }
    else {
        
        /********************************************************************************************
         NOTE: If the master pane can't be presented, then there is no reason for gesture recognizers
         *******************************************************************************************/
        
        // remove the gesture recognizers from the overlay view
        [self.gestureOverlayView removeGestureRecognizer:self.detailPanGestureRecognizer];
        [self.gestureOverlayView removeGestureRecognizer:self.detailTapGestureRecognizer];
        
        // remove the gesture overlay view from the view
        [self.gestureOverlayView removeFromSuperview];
        
        // remove the gesture recognizers from the view
        [detail.view removeGestureRecognizer:self.detailPanGestureRecognizer];
        [detail.view removeGestureRecognizer:self.detailTapGestureRecognizer];
        
    }
    
}

#pragma mark - Helpers (Layout Assistance)

- (void)updateSplitViewForOrientation:(UIInterfaceOrientation)orientation {
    
    [self adjustFramesForInterfaceOrientation:orientation];
    [self configureGestureRecognizersForInterfaceOrientation:orientation];
    
    // trigger the relevant delegate methods
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        
        [self splitViewWillRotateToPortraitOrientation];
        
    }
    else if (UIInterfaceOrientationIsLandscape(orientation)) {
        
        if ([self.delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)]) {
            
            [self.delegate splitViewController:self
                        willShowViewController:self.viewControllers[0]
                     invalidatingBarButtonItem:self.barButtonItem];
            
        }
        
    }
    
}

- (BOOL)masterPaneCanBePresentedInOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    /* 
     The current idea with split view controller is that the master pane will always be shown in the landscape orientation, and in portrait orientation 
     can be shown or hidden based on the delegate implementation. So based on these conditions, this method will return a boolean that informs wether or not
     the master pane can be shown.
     */
    return UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation];
    
}

@end
