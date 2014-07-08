//
// GSSplitViewController.h
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

#import <UIKit/UIKit.h>

#define GS_STATUS_BAR_ORIENTATION() [[UIApplication sharedApplication] statusBarOrientation]

@protocol GSSplitViewControllerDelegate;

@interface GSSplitViewController : UIViewController

/**
 The delegate object that will receive split view controller messages.
 */
@property (nonatomic, weak) id <GSSplitViewControllerDelegate> delegate;

/**
 The array of view controllers managed by the receiver. The array in this property must contain exactly two view controllers. The view controllers are presented left-to-right in the split view interface when it is in a landscape orientation. Thus, the view controller at index 0 is displayed on the left side and the view controller at index 1 is displayed on the right side of the interface.

 The first view controller in this array is typically hidden when the device is in a portrait orientation. Assign a delegate object to the receiver if you want to coordinate the display of this view controller using a bar button item that can be installed in a navigation controller.
 */
@property (nonatomic, copy) NSArray *viewControllers;

/**
 Specifies whether the left view controller (a.k.a. Master Pane) can be presented and dismissed via a swipe gesture.

 The default value is YES.
 */
@property (nonatomic) BOOL presentsWithGesture;

/**
 Specifies the width of the left view controller (a.k.a. Master Pane).

 @note The default value is 320.0f.
 */
@property (nonatomic) CGFloat masterPaneWidth;

/**
 The bar button item associated with the master panes hide and show target-action.
 */
@property (nonatomic, strong, readonly) UIBarButtonItem *barButtonItem;

/**
 If the master pane can be hidden in portrait orientation (see GSSplitViewControllerDelegate), this boolean determines the initial state of the master pane (i.e. shown or hidden) each time the device is rotated to the portrait orientation.
 */
@property (nonatomic, getter = isMasterPaneShownOnInitialRotationToPortrait) BOOL masterPaneShownOnInitialRotationToPortrait;

/**
 If the master pane can be hidden in the portrait orientation (see GSSplitViewControllerDelegate), this method will either hide or show the master pane, optionnaly animating the transition.
 @param masterPaneShown YES if the master pane should be shown, NO if it should be hidden.
 @param animated YES if the transition should be animated, NO otherwise.
 */
- (void)setMasterPaneShown:(BOOL)masterPaneShown animated:(BOOL)animated;

@end

//_______________________________________________________________________________________________________________

@protocol GSSplitViewControllerDelegate <NSObject>

@optional

// Called when a button should be added to a toolbar for a hidden view controller.
// Implementing this method allows the hidden view controller to be presented via a swipe gesture if 'presentsWithGesture' is 'YES' (the default).
- (void)splitViewController:(GSSplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem;

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(GSSplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem;

// Returns YES if a view controller should be hidden by the split view controller in a given orientation.
// (This method is only called on the leftmost view controller and only discriminates portrait from landscape.)
- (BOOL)splitViewController:(GSSplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation;

- (NSUInteger)splitViewControllerSupportedInterfaceOrientations:(GSSplitViewController *)splitViewController;

@end

//_______________________________________________________________________________________________________________
