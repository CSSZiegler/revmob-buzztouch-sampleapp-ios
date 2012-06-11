#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RevMobAdsDelegate.h"

@interface RevMobAds : NSObject

#pragma mark PUBLISHER METHODS

/* 
 * This will show a popup ad unit.
 *
 * (NSString *)appID => You can collect your App ID at http://revmob.com by looking up your apps. 
 * If you haven't registered the apps yet, simply add an app in your BCFAds account. Example of
 * NSString *appID:@"4f342dc09dcb890003003a7a".
 *
 * (NSObject<RevMobAdsDelegate> *)delegate => Optional assignment of a delegate, otherwise simply 
 * return nil. Default is nil.
 *
 * You can call this on: Delegate, UIViewController or any other type of object.
 * Performance: You will be paid primarily by the number of installs your app generates and 
 * sometimes by the number of clicks on the popups. Impressions shouldn't provide revenue.
 * Deactivation: Not necessary.
 * When: Best to show when app opens, but can be shown whenever you want.
 *
 * Example:
 *
 * *** in a Delegate, if you have multi-tasking in your app
 * - (void)applicationDidBecomeActive:(UIApplication *)application {
 *   [BCFAds showPopupWithAppID:@"4f342dc09dcb890003003a7a" withDelegate:nil];
 * }
 *
 * *** in a UIViewController
 * - (void)viewDidLoad {
 *   [BCFAds showPopupWithAppID:@"4f342dc09dcb890003003a7a" withDelegate:nil];
 *
 *   // The remaining part of your code goes here
 *
 *   [super viewDidLoad];
 * }
 *
 * *** any other object or method will work
 */
+ (void) showPopupWithAppID:(NSString *)appID withDelegate:(NSObject<RevMobAdsDelegate> *)delegate;

/*
 
 Example of Usage:
 
 #import "RevMobAds.h"
 
 @implementation MyViewController
 
 - (void)someMethod {
     [RevMobAds showFullscreenAdWithAppID:@"4f342dc09dcb890003003a7a"];
 }
 
 */
+ (void) showFullscreenAdWithAppID:(NSString *)appID;


/*
 
 Example of Usage:

 
 ** MyRevMobAdsDelegate.h
 
 #import <Foundation/Foundation.h>
 #import "RevMobAdsDelegate.h"
 
 @interface MyRevMobAdsDelegate : NSObject<RevMobAdsDelegate>
 @end

 
 ** MyRevMobAdsDelegate.m
 
 @implementation MyRevMobAdsDelegate
 
- (void) adDidReceive:(id<RevMobAdvertisement> *)ad {
     if ([ad isLoaded]) {
         [ad show];
     }
 }
 
 - (void) adDidFailWithError:(NSError*)error {
    NSLog(@"Ad did fail with error: %@", error);
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

@end
