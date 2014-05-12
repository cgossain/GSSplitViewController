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

#define GS_STATUS_BAR_ORIENTATION() [[UIApplication sharedApplication] statusBarOrientation]
#define GS_INTERFACE_IS_LANDSCAPE UIInterfaceOrientationIsLandscape(GS_STATUS_BAR_ORIENTATION())
#define GS_INTERFACE_IS_PORTRAIT UIInterfaceOrientationIsPortrait(GS_STATUS_BAR_ORIENTATION())

#define kDivderWidth 1.0f

#define kSwipeXDirectionThreshold 60.0  // gesture needs to be greater than this value in the X direction to be considered a swipe

@interface GSSplitViewController ()

@property (strong, nonatomic) UIPanGestureRecognizer *detailPanGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *detailTapGestureRecognizer;

@property (strong, nonatomic) UIView *dividerView;

@property (strong, nonatomic) UIBarButtonItem *barButtonItem;

@end

@implementation GSSplitViewController {
    NSArray *_layoutConstaints;
    
    BOOL _isMasterVisible;
    CGPoint _lastGestureLocation;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _detailPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _detailTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        _masterPaneWidth = 320.0f;
        _presentsWithGesture = YES;
        
        [_detailPanGestureRecognizer requireGestureRecognizerToFail:_detailTapGestureRecognizer];
        
        _dividerView = [[UIView alloc] init];
        _dividerView.backgroundColor = [UIColor darkGrayColor];
        
    }
    return self;
}

#pragma mark - View Lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1.0f];
    
    // If the interface orientation is Portrait, this method will call the delegate to give it a chance to add a bar button item to it's nav bar.
    if ([self shouldHideMasterViewControllerInOrientation:GS_STATUS_BAR_ORIENTATION()]) {
        [self splitViewWillRotateToPortraitOrientation];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
    
    UIViewController *master = [self.viewControllers objectAtIndex:0];
    UIViewController *detail = [self.viewControllers objectAtIndex:1];
    
    [self addDetailViewController:detail];
    
    // add the divider view on top of the detail view but below the master (in case master content wants to overlap the divider
    self.dividerView.frame = [self dividerFrameForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    [self.view addSubview:self.dividerView];
    
    // add master on top of the detail view
    [self addMasterViewController:master];
    
    // add tap gesture recognizer
    [detail.view addGestureRecognizer:self.detailTapGestureRecognizer];
    
    // add pan gesture recognizer
    if (self.presentsWithGesture) {
        [detail.view addGestureRecognizer:self.detailPanGestureRecognizer];
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
        
        UIViewController *detail = [self.viewControllers objectAtIndex:1];
        
        [detail.view removeGestureRecognizer:self.detailTapGestureRecognizer];
        [detail.view removeGestureRecognizer:self.detailPanGestureRecognizer];
        
    }
    
    _viewControllers = [viewControllers copy];
    
    [self.view setNeedsLayout];
    
}

- (void)setMasterPaneWidth:(CGFloat)masterPaneWidth {
    
    _masterPaneWidth = masterPaneWidth;
    
    [self adjustFramesForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    
}

- (void)setPresentsWithGesture:(BOOL)presentsWithGesture {
    
    if (_presentsWithGesture != presentsWithGesture) {
        
        _presentsWithGesture = presentsWithGesture;
        
        if (_viewControllers) {
            
            if (presentsWithGesture) {
                UIViewController *detail = [self.viewControllers objectAtIndex:1];
                [detail.view addGestureRecognizer:self.detailPanGestureRecognizer];
            }
            else {
                UIViewController *detail = [self.viewControllers objectAtIndex:1];
                [detail.view removeGestureRecognizer:self.detailPanGestureRecognizer];
            }
            
        }
        
    }
    
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
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        
        [self splitViewWillRotateToPortraitOrientation];
        
    }
    else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        
        if ([self.delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)]) {
            
            [self.delegate splitViewController:self
                        willShowViewController:self.viewControllers[0]
                     invalidatingBarButtonItem:self.barButtonItem];
            
        }
        
    }
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // this rotation method is called from an animation block, therefore the following changes will be animated
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        _isMasterVisible = NO;
    }
    else {
        _isMasterVisible = YES;
    }
    
    [self adjustFramesForInterfaceOrientation:toInterfaceOrientation];
    
}

#pragma mark - UIViewControllerContainment

- (void)addMasterViewController:(UIViewController *)contentViewController {
    
    [self addChildViewController:contentViewController];
    
    contentViewController.view.frame = [self masterPaneFrameForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    
    [self.view addSubview:contentViewController.view];
    
    [contentViewController didMoveToParentViewController:self];
    
}

- (void)addDetailViewController:(UIViewController *)contentViewController {
    
    [self addChildViewController:contentViewController];
    
    contentViewController.view.frame = [self detailPaneFrameForInterfaceOrientation:GS_STATUS_BAR_ORIENTATION()];
    
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
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation]) {
        
        if (!_isMasterVisible) {
            
            GSSplitViewController *__weak weakSelf = self;
            
            _isMasterVisible = YES;
            
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [weakSelf adjustFramesForInterfaceOrientation:interfaceOrientation];
                             }
                             completion:nil];
            
        }
        
    }
    
}

#pragma mark - Selectors

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation]) {
        
        if (_isMasterVisible) {
            
            GSSplitViewController *__weak weakSelf = self;
            
            _isMasterVisible = NO;
            
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [weakSelf adjustFramesForInterfaceOrientation:interfaceOrientation];
                             }
                             completion:nil];
            
        }
        
    }
    
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation]) {
        
        CGPoint location = [gestureRecognizer locationInView:self.view];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            
            _lastGestureLocation = location;
            
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            
            GSSplitViewController *__weak weakSelf = self;
            
            CGFloat diffX = location.x - _lastGestureLocation.x;
            
            if (diffX < 0) {
                // overall left movement
                if (fabsf(diffX) > kSwipeXDirectionThreshold) {
                    // hide the master view
                    _isMasterVisible = NO;
                    
                    [UIView animateWithDuration:0.2
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         [weakSelf adjustFramesForInterfaceOrientation:interfaceOrientation];
                                     }
                                     completion:nil];
                    
                    _lastGestureLocation = location;
                }
                
            }
            else if (diffX > 0) {
                // overall right movement
                if (fabsf(diffX) > kSwipeXDirectionThreshold) {
                    // show the master view
                    _isMasterVisible = YES;
                    
                    [UIView animateWithDuration:0.2
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         [weakSelf adjustFramesForInterfaceOrientation:interfaceOrientation];
                                     }
                                     completion:nil];
                    
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
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation]) {
        
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
    
    CGFloat xOffset = self.masterPaneWidth + kDivderWidth;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && [self shouldHideMasterViewControllerInOrientation:interfaceOrientation]) {
        xOffset = 0.0f;
    }
    
    return CGRectMake(xOffset, 0.0f, (self.view.bounds.size.width - xOffset), self.view.bounds.size.height);
    
}

- (CGRect)dividerFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    CGRect masterFrame = [self masterPaneFrameForInterfaceOrientation:interfaceOrientation];
    
    return CGRectMake(masterFrame.origin.x + masterFrame.size.width, masterFrame.origin.y, kDivderWidth, masterFrame.size.height);
    
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

@end
