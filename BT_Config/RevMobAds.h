#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RevMobAdsDelegate.h"


@interface RevMobAds : NSObject

/*! @function showFullscreenAdWithAppID:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @discussion
 
 Same as showFullscreenAdWithAppID:withDelegate: with delegate nil.
 
 */
+ (void) showFullscreenAdWithAppID:(NSString *)appID;


/*! @function showFullscreenAdWithAppID:withDelegate:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param delegate: You can receive notifications when the Ad is or is not loaded, when the user click in the close button or in the Ad.
 @discussion
 
 Example of Usage:
 
 
 ** MyRevMobAdsDelegate.h
 
 #import <Foundation/Foundation.h>
 #import "RevMobAdsDelegate.h"
 
 @interface MyRevMobAdsDelegate : NSObject<RevMobAdsDelegate>
 @end
 
 
 ** MyRevMobAdsDelegate.m
 
 @implementation MyRevMobAdsDelegate
 
 - (void) revmobAdDidReceive {
 NSLog(@"[RevMob Sample App] Ad loaded.");
 }
 
 - (void) revmobAdDidFailWithError:(NSError *)error {
 NSLog(@"[RevMob Sample App] Ad failed.");
 }
 
 - (void) revmobUserClickedInTheCloseButton {
 NSLog(@"[RevMob Sample App] User clicked in the close button");
 }
 
 - (void) revmobUserClickedInTheAd {
 NSLog(@"[RevMob Sample App] User clicked in the Ad");
 }
 @end
 
 
 ** MyViewController.m
 
 #import "RevMobAds.h"
 #import "RevMobAdsDelegate.h"
 
 @implementation MyViewController
 
 - (void)someMethod {
 MyRevMobAdsDelegate *delegate = [[MyRevMobAdsDelegate alloc] init];
 [RevMobAds showFullscreenAdWithAppID:@"4f342dc09dcb890003003a7a" withDelegate:delegate];
 [delegate release];
 }
 
 */
+ (void) showFullscreenAdWithAppID:(NSString *)appID withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/*! @function showPopupWithAppID:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @discussion
 
 Same as showPopupWithAppID:withDelegate: with delegate nil.
 
 */
+ (void) showPopupWithAppID:(NSString *)appID;


/*! @function showPopupWithAppID:withDelegate:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param delegate: You can receive notifications when the Ad is or is not loaded.
 @discussion
 
 This will show a popup ad unit.
 
 (NSString *)appID => You can collect your App ID at http://revmob.com by looking up your apps. 
 If you haven't registered the apps yet, simply add an app in your BCFAds account. Example of
 NSString *appID:@"4f342dc09dcb890003003a7a".
 
 (NSObject<RevMobAdsDelegate> *)delegate => Optional assignment of a delegate, otherwise simply 
 return nil. Default is nil.
 
 You can call this on: Delegate, UIViewController or any other type of object.
 Performance: You will be paid primarily by the number of installs your app generates and 
 sometimes by the number of clicks on the popups. Impressions shouldn't provide revenue.
 Deactivation: Not necessary.
 When: Best to show when app opens, but can be shown whenever you want.
 
 Example:
 
 *** in a Delegate, if you have multi-tasking in your app
 - (void)applicationDidBecomeActive:(UIApplication *)application {
    [BCFAds showPopupWithAppID:@"4f342dc09dcb890003003a7a" withDelegate:nil];
 }
 
 *** in a UIViewController
 - (void)viewDidLoad {
    [BCFAds showPopupWithAppID:@"4f342dc09dcb890003003a7a" withDelegate:nil];
 
    // The remaining part of your code goes here
 
    [super viewDidLoad];
 }
 
 *** any other object or method will work
 */
+ (void) showPopupWithAppID:(NSString *)appID withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/*! @function showBannerAdWithAppID:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param delegate: You can receive notifications when the Ad is or is not loaded.
 @discussion
 
 Same as showBannerAdWithAppID:withDelegate: with delegate nil.

 */
+ (void) showBannerAdWithAppID:(NSString *)appID;


/*! @function showBannerAdWithAppID:withDelegate:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param delegate: You can receive notifications when the Ad is or is not loaded.
 @discussion
 
 The banner will be stucked to the bottom, with width 100% and height 50 points, no matter the orientation.
 */
+ (void) showBannerAdWithAppID:(NSString *)appID withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/*! @function showBannerAdWithAppID:withFrame:withDelegate:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @param frame: A CGRect that will be used to draw the banner. The 0,0 point of the coordinate system will be always in the top-left corner. 
 @param delegate: You can receive notifications when the Ad is or is not loaded.
 @discussion
 
 With this method you can customize the size of the banner, but the minimum accepted size is 320,50.
 Using this method, the developer has the responsibility to adjust the banner frame on rotation.
 */
+ (void) showBannerAdWithAppID:(NSString *)appID withFrame:(CGRect)frame withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;


/*! @function hideBannerAdWithAppID:
 @param appID: You can collect your App ID at http://revmob.com by looking up your apps.
 @discussion
 
 Hide a banner.
 
 */
+ (void) hideBannerAdWithAppID:(NSString *)appID;

@end
