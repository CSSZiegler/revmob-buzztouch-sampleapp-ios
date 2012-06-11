#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RevMobAdvertisement.h"

@protocol RevMobAdsDelegate <NSObject>

@optional

# pragma mark Fullscreen Callbacks

- (void) adDidReceive:(id<RevMobAdvertisement>)ad;

- (void) adDidFailWithError:(NSError *)error;


# pragma mark Popup Callbacks

- (void)popupDidReceive;
// Called when a popup is available

- (void)popupDidFail;
// Called when a popup is not available

- (void)popupDidBecomeActive;
// Called when popup is displayed

- (void)popupDidDismissActive;
// Called when user is back to the app

- (void)userWillLeaveApplication;
// Called when user clicked and is about to leave the application


# pragma mark Advertiser Callbacks

- (void)installDidReceive;
// Called if install is successfully registered

- (void)installDidFail;
// Called if install couldn't be registered

@end
