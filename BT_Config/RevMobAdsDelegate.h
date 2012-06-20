#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RevMobAdsDelegate <NSObject>

@optional

# pragma mark Fullscreen Callbacks

- (void) revmobAdDidReceive;

- (void) revmobAdDidFailWithError:(NSError *)error;

- (void) revmobUserClickedInTheCloseButton;

- (void) revmobUserClickedInTheAd;

# pragma mark Popup Callbacks

// Called when a popup is available
- (void)popupDidReceive;

// Called when a popup is not available
- (void)popupDidFail;

// Called when popup is displayed
- (void)popupDidBecomeActive;

// Called when user is back to the app
- (void)popupDidDismissActive;

// Called when user clicked and is about to leave the application
- (void)userWillLeaveApplication;


# pragma mark Advertiser Callbacks

// Called if install is successfully registered
- (void)installDidReceive;

// Called if install couldn't be registered
- (void)installDidFail;

@end
