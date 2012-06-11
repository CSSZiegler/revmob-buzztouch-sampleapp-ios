/*
 *	Copyright 2011, David Book, buzztouch.com
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors 
 *	may be used to endorse or promote products derived from this software without specific 
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */


#import "BT_viewUtilities.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "JSON.h"
#import "BT_strings.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_debugger.h"
#import "BT_color.h"
#import "BT_background_view.h"
#import "BT_cell_backgroundView.h"

@implementation BT_viewUtilities

//frame for nav bar
+(CGRect)frameForNavBarAtOrientation:(UIViewController *)theViewController:(BT_item *)theScreenData{
	CGFloat height = UIInterfaceOrientationIsPortrait(theViewController.interfaceOrientation) ? 44 : 44;
	
	//is the status bar hidden?
	if([UIApplication sharedApplication].statusBarHidden){
		return CGRectMake(0, 0, theViewController.view.bounds.size.width, height);
	}else{
		return CGRectMake(0, 20, theViewController.view.bounds.size.width, height);
	}
	
}

//frame for tool bar (same height as nav bar at bottom of screen)
+(CGRect)frameForToolBarAtOrientation:(UIViewController *)theViewController:(BT_item *)theScreenData{
	CGFloat height = UIInterfaceOrientationIsPortrait(theViewController.interfaceOrientation) ? 44 : 44;
	CGFloat top = theViewController.view.bounds.size.height - 44;
	return CGRectMake(0, top, theViewController.view.bounds.size.width, height);
}

//frame for advertising view
+(CGRect)frameForAdView:(UIViewController *)theViewController:(BT_item *)theScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"frameForAdViewAtOrientation %@", @""]];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	int height = 50;
	int width = 320;
	int statusBarHeight = 20;
	int navBarHeight = 44;
	if([[BT_strings getStyleValueForScreen:theScreenData:@"statusBarStyle":@""] isEqualToString:@"hidden"]){
		statusBarHeight = 0;
	}
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarStyle":@""] isEqualToString:@"hidden"]){
		navBarHeight = 0;
	}
	//iPads are wider and taller...
	if([appDelegate.rootApp.rootDevice isIPad]){
		height = 66;
		width = 768;
	}
	int top = theViewController.view.bounds.size.height - height;
	
	//if we have a bottom toolbar, we need to move the add "up" a bit. Bottom toolbars have tag 49
	for(UIView* subView in [theViewController.view subviews]){
		if(subView.tag == 49){
			top -= 44;
			break;
		}	
	}
	return CGRectMake(0, top, width, height);
    
}

//loading view
+(UIView *)getProgressView:(NSString *)loadingText{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"getProgressView %@", loadingText]];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//default loading if needed...
	if([loadingText length] < 1){
		loadingText = NSLocalizedString(@"loading",@"...loading...");
	}
	
	//get center point of top-most view
	CGPoint centerPoint;
	if([appDelegate.rootApp rootTabBarController] == nil && [appDelegate.rootApp rootNavController] == nil){
		centerPoint = [appDelegate.window center];
	}else{
		if([appDelegate.rootApp.tabs count] < 1){
			centerPoint = [appDelegate.rootApp.rootNavController.topViewController.view center];
		}else{
			centerPoint = [appDelegate.rootApp.rootTabBarController.selectedViewController.view center];
		}
	}
	
	UIView *progressView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 130)] autorelease];
	[progressView setCenter:centerPoint];
	progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin 
                                     | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
	//progress background
	UIImageView *imgView = [[UIImageView alloc] init];
	imgView.frame = CGRectMake(0, 0, 320, 110);
	UIImage *bgImage =  [[UIImage imageNamed:@"loadingBg.png"] retain];
	imgView.image = bgImage;
	[progressView addSubview:imgView];
	[imgView release];
	
	//activity wheel
	UIActivityIndicatorView *tmpWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(142, 30, 30, 30)];
	tmpWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	[tmpWheel startAnimating];
	[progressView addSubview:tmpWheel];
	[tmpWheel release];
	
	//label
	UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(95, 50, 125, 50)];
	loadingLabel.numberOfLines = 2;
	loadingLabel.font = [UIFont systemFontOfSize:16];
	loadingLabel.textAlignment = UITextAlignmentCenter;
	loadingLabel.textColor = [UIColor whiteColor];
	loadingLabel.backgroundColor = [UIColor clearColor];
	loadingLabel.text = loadingText;
	[progressView addSubview:loadingLabel];
	[loadingLabel release];
	
	return progressView;
}


/*
 This method returns the color for the text that goes on a background for a passed in screen.
 If background color is "light" then "dark" text should be used.
 
 */
+(UIColor *)getTextColorForScreen:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getTextColorForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getTextColorForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}
    
    
	//get textOnBackgroundColor from rootApp.rootTheme OR from screens JSON if over-riden
	UIColor *tmpColor = nil;
	if([[BT_strings getStyleValueForScreen:theScreenData:@"textOnBackgroundColor":@""] length] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"setting text on background color: %@", [BT_strings getStyleValueForScreen:theScreenData:@"textOnBackgroundColor":@""]]];
		tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"listBackgroundColor":@""]];
	}else{
		tmpColor = [UIColor blackColor];
	}
    
	return tmpColor;
	
}




/*
 This method returns the color for the navigation bar for a passed in screen. 
 The background color for the nav bar is set when the navigation
 controller is instantiated. BT_viewControllerManager.tapForMenuItem over-writes the navigation bar
 background color if the screen we are loading has a nav bar color set.
 */
+(UIColor *)getNavBarBackgroundColorForScreen:(BT_item *)theScreenData{
    
	UIColor *tmpColor = nil;
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"setting nav-bar background for \"%@\" color: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]]];
		tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
	}	
	
	return tmpColor;
	
}


/*
 configures navigation bar text, buttons, and the screens background color or image. We can't set the navigation bar background color in this 
 method, as much as it would make sense to be able to, thanks alot Apple! iOS only allows us to re-set the color when we are transitioning
 between screens. For this reason, the background color for the nav bar is set in BT_viewControllerManager.tapForMenuItem, 
 and then re-set in the BT_viewControllerManager.handleBackButton method
 */

+(void)configureBackgroundAndNavBar:(UIViewController *)theViewController:(BT_item *)theScreenData{	
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"configureBackgroundAndNavBar for screen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"configureBackgroundAndNavBar for screen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}	
	
	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//sets the title text from the jsonVars
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarTitleText":@""] length] > 0){
		[theViewController.navigationItem setTitle:[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarTitleText":@""]];
	}
	
	//set the status bar style (assume default)
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	if([[BT_strings getStyleValueForScreen:theScreenData:@"statusBarStyle":@""] isEqualToString:@"default"]){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
		[[UIApplication sharedApplication] setStatusBarHidden:FALSE animated:FALSE];
	}
    
	if([[BT_strings getStyleValueForScreen:theScreenData:@"statusBarStyle":@""] isEqualToString:@"solid"]){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
		[[UIApplication sharedApplication] setStatusBarHidden:FALSE animated:FALSE];
	}
	if([[BT_strings getStyleValueForScreen:theScreenData:@"statusBarStyle":@""] isEqualToString:@"transparent"]){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
		[[UIApplication sharedApplication] setStatusBarHidden:FALSE animated:FALSE];
	}
	if([[BT_strings getStyleValueForScreen:theScreenData:@"statusBarStyle":@""] isEqualToString:@"hidden"]){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
		[[UIApplication sharedApplication] setStatusBarHidden:TRUE animated:FALSE];
	}	
	
	//set the nav bar style
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarStyle":@""] isEqualToString:@"transparent"]){
		[theViewController.navigationController.navigationBar setTranslucent:TRUE];
	}else{
		[theViewController.navigationController.navigationBar setTranslucent:FALSE];
	}	
	
	//is the nav bar hidden?
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarStyle":@""] isEqualToString:@"hidden"]){
		[theViewController.navigationController.navigationBar setHidden:TRUE];
	}else{
		[theViewController.navigationController.navigationBar setHidden:FALSE];
	}
    
	//set the nav bar size, position. NAV BAR SETUP MUST BE DONE AFTER THE STATUS BAR SETUP.
	[theViewController.navigationController.navigationBar setFrame:[self frameForNavBarAtOrientation:theViewController:theScreenData]];
	
	/*
     add a back button or a refresh button. Back buttons go on all screens that are not the "home" screen.
     refresh button goes on the "home screen" BUT only if the app uses a dataURL
     */
	
	//is this the home screen (it could be the home screen of any tab)
	if([theViewController.navigationController.viewControllers count] < 2){
		if([appDelegate respondsToSelector:@selector(downloadAppData)]){
			if([appDelegate.rootApp.dataURL length] > 3){
                
				/*
                 When do we show the left refresh button? BT_application flags the isHomeScreen
                 property of the root controller of the app to allow for this. For tabbed apps, 
                 only the first tab will show the refresh button.
                 */
				
				if([theScreenData isHomeScreen]){
					UIBarButtonItem *theRefreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:appDelegate action:@selector(downloadAppData)];
					[theViewController.navigationItem setLeftBarButtonItem:theRefreshButtonItem];
					[theRefreshButtonItem release];
				}
				
			}
		}
	}else{
		if([theViewController respondsToSelector:@selector(navLeftTap)]){
			NSString *backText = NSLocalizedString(@"back",@"back");
			if(![[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarBackButtonText":@""] isEqualToString:@""]){
				backText = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarBackButtonText":@""];
			}
			UIBarButtonItem *theBackButtonItem = [[UIBarButtonItem alloc] initWithTitle:backText style:UIBarButtonItemStylePlain target:theViewController action:@selector(navLeftTap)];
			[theViewController.navigationItem setLeftBarButtonItem:theBackButtonItem];
			[theBackButtonItem release];
		}else{
			[theViewController.navigationItem setLeftBarButtonItem:nil];
		}
	}
	
	
	//add the right side button based on the choice in screen data
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarRightButtonType":@""] length] > 1){
		NSArray *supportedButtonTypes = [NSArray arrayWithObjects:@"home", @"next", @"infoLight", @"infoDark", @"details", @"addBlue", @"done",
                                         @"cancel", @"edit", @"save", @"add", @"compose", @"reply", @"action", @"organize", 
                                         @"bookmark", @"search", @"refresh", @"camera", @"trash", @"play", @"pause", 
                                         @"stop", @"rewind", @"fastForward", nil];
		
		NSString *rightButtonType = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"navBarRightButtonType":@""];
		if([supportedButtonTypes containsObject:rightButtonType]){
            
			//create the button
			UIButton *theButton = nil;
			UIBarButtonItem *theBarButtonItem = nil;			
            
			//get the button or the bar button item type (there is a difference)
			if([rightButtonType isEqualToString:@"home"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"home", @"Home") style:UIBarButtonItemStylePlain target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"infoLight"]) theButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
			if([rightButtonType isEqualToString:@"infoDark"]) theButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
			if([rightButtonType isEqualToString:@"details"]) theButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			if([rightButtonType isEqualToString:@"addBlue"]) theButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
			if([rightButtonType isEqualToString:@"next"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next", @"Next") style:UIBarButtonItemStylePlain target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"done"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"cancel"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"edit"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"save"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"add"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"compose"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"reply"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"action"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"organize"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"bookmark"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"search"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"refresh"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"camera"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"trash"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"play"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"pause"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"stop"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"rewind"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:theViewController action:@selector(navRightTap) ];
			if([rightButtonType isEqualToString:@"fastForward"]) theBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:theViewController action:@selector(navRightTap) ];
			
			//add it only if the view controller can respond
			if([theViewController respondsToSelector:@selector(navRightTap)]){
				if(theButton != nil){
					[theButton addTarget:theViewController action:@selector(navRightTap) forControlEvents:UIControlEventTouchUpInside];
					UIBarButtonItem *tmpBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:theButton];
					[theViewController.navigationItem setRightBarButtonItem:tmpBarButtonItem];
					[tmpBarButtonItem release];
				}
				if(theBarButtonItem != nil){
					[theViewController.navigationItem setRightBarButtonItem:theBarButtonItem];
				}
			}
            
		}
	}	
	
	
	//update the global background. Logic depends on whether the app has tabs or not
	if([appDelegate.rootApp.tabs count] < 1){
		UINavigationController *theNavController = [appDelegate.rootApp rootNavController];
		
		//update the global background?
		for(UIView *view in theNavController.view.subviews){
			if(view.tag == 1968){
				for(UIView *subView in view.subviews){
					BT_background_view *globalBackground = (BT_background_view *)subView;
					[globalBackground updateProperties:theScreenData];
				}
			}
		}
		
	}else{
        
		//update the global background?
		UITabBarController *theTabController = [appDelegate.rootApp rootTabBarController];
		for(UIView *view in theTabController.view.subviews){
			if(view.tag == 1968){
				for(UIView *subView in view.subviews){
					BT_background_view *globalBackground = (BT_background_view *)subView;
					[globalBackground updateProperties:theScreenData];
				}
			}
		}	
		
	}
	
	
}

/*
 this method returns a UITable view for a screen. It uses the screen data to configure options such as
 style, header/footer height, colors, background if the global theme values are over-ridden in the screen data.
 Note: lists contain cells, cells also have styles applied. This can get confusing when working with
 backgrounds and colors. 
 */
+(UITableView *)getTableViewForScreen:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getTableViewForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getTableViewForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//assume we are building a standard, "square" table
	UITableViewStyle tmpTableStyle = UITableViewStylePlain;
	
	//if the global theme or the screen data want a round style table
	if([[BT_strings getStyleValueForScreen:theScreenData:@"listStyle":@""] isEqualToString:@"round"]){
		tmpTableStyle = UITableViewStyleGrouped;
	}
	
	//default values, may be over-ridden in global theme or screen data
	int tableRowHeight = 50;
	int tableHeaderHeight = 10;
	int tableFooterHeight = 50;
	UIColor *tableBackgroundColor = [UIColor whiteColor];
	
	//table background color
	tableBackgroundColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"listBackgroundColor":@"clear"]];
    
	/*
     Some styles depend on the device. Use global theme settings first, then screen-data if over-ridden
     */
	if([appDelegate.rootApp.rootDevice isIPad]){
		
		//use large device settings
		tableRowHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listRowHeightLargeDevice":@"50"] intValue];
		tableHeaderHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listHeaderHeightLargeDevice":@"10"] intValue];
		tableFooterHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listFooterHeightLargeDevice":@"50"] intValue];
		
	}else{
        
		//use small device settings
		tableRowHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listRowHeightSmallDevice":@"50"] intValue];
		tableHeaderHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listHeaderHeightSmallDevice":@"10"] intValue];
		tableFooterHeight = [[BT_strings getStyleValueForScreen:theScreenData:@"listFooterHeightSmallDevice":@"50"] intValue];
        
	}
	
	UITableView *tmpTable = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:tmpTableStyle] autorelease];
	[tmpTable setRowHeight:tableRowHeight];
	[tmpTable setBackgroundColor:tableBackgroundColor];
    
	//this is a hack because iPad does not recognize UITableView background color...
	if([tmpTable respondsToSelector:@selector(backgroundView)]){
		tmpTable.backgroundView = nil; 
	}	
	
	[tmpTable setSectionHeaderHeight:tableHeaderHeight];
	[tmpTable setSectionFooterHeight:tableFooterHeight];
	[tmpTable setShowsVerticalScrollIndicator:FALSE];
	[tmpTable setShowsHorizontalScrollIndicator:FALSE];
	tmpTable.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);	
    
	//separator color is set to clear here. BT_viewUtilities.getCellBackgroundForListRow handles the separator color
	[tmpTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
	//we may want to prevent scrolling. This is useful if a header or footer image is used.
	if([[BT_strings getStyleValueForScreen:theScreenData:@"listPreventScroll":@"0"] isEqualToString:@"1"]){
		[tmpTable setScrollEnabled:FALSE];
        
	}else{
        
		//if we are not preventing scrolling, add a table footer view so the user can always scroll to the
		//last item. This is helpful in tabbed apps where the last item doesn't quite scroll up high enough.
		UIView *tmpFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
		[tmpFooterView setBackgroundColor:[UIColor clearColor]];
		[tmpTable setTableFooterView:tmpFooterView];
		[tmpFooterView release];
        
	}
	
	//return
	return tmpTable;
    
}

/*
 This method returns a UIToolbar with buttom items configured for a web-view. The toolbar will only 
 have buttons that are configured in the theScreenData
 */
+(UIToolbar *)getWebToolBarForScreen:(UIViewController *)theViewController:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebNavBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebNavBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if we have no button options set in JSON and no audioFileName, return nil for toolbar
	BOOL screenUsesToolbar = FALSE;
	UIToolbar *theToolbar = nil;
	
	// create the array to hold the buttons for the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] init];
    
	//back
	if([theViewController respondsToSelector:@selector(goBack)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showBrowserBarBack":@""] isEqualToString:@"1"]){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"prev.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(goBack)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:101];
			[buttons addObject:button];
			[button release];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebToolBarForScreen: No goBack method found, cannot add back button for screen with itemId: %@", [theScreenData itemId]]];
	}
	
	//spacer forces remaining buttons to right
	UIBarButtonItem* bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
    
	//open in safari
	if([theViewController respondsToSelector:@selector(launchInNativeApp)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showBrowserBarLaunchInNativeApp":@""] isEqualToString:@"1"]){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc]	initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:theViewController action:@selector(launchInNativeApp)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:103];
			[buttons addObject:button];
			[button release];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebToolBarForScreen: No launchInNativeApp method found, cannot add launch in native app button for screen with itemId: %@", [theScreenData itemId]]];
	}
	
    //allow email document?
	if([theViewController respondsToSelector:@selector(emailDocument)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showBrowserBarEmailDocument":@""] isEqualToString:@"1"]){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc]	initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:theViewController action:@selector(emailDocument)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:104];
			[buttons addObject:button];
			[button release];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebToolBarForScreen: No emailDocument method found, cannot add email document button for screen with itemId: %@", [theScreenData itemId]]];
	}
    
	//refresh
	if([theViewController respondsToSelector:@selector(refreshData)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showBrowserBarRefresh":@""] isEqualToString:@"1"]){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(refreshData)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:105];
			[buttons addObject:button];
			[button release];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getWebToolBarForScreen: No refreshData method found, cannot add refresh button for screen with itemId: %@", [theScreenData itemId]]];
	}
	
    
	//audio controls in toolbar if we have an audioFileName
	if([theViewController respondsToSelector:@selector(showAudioControls)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 0 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 0){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"equalizer.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showAudioControls)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:106];
			[buttons addObject:button];
			[button release];
		}
	}	
	
	//if we are using a toolbar
	if(screenUsesToolbar){
        
		//create a toolbar to have two buttons in the right
		theToolbar = [[[UIToolbar alloc] initWithFrame:[self frameForToolBarAtOrientation:theViewController:theScreenData]] autorelease];
		theToolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
		
		//set toolbar color to nav bar color from rootApp.rootTheme OR from screens JSON if over-riden
		UIColor *tmpColor = nil;
		
		//nav bar background color
		if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"setting browser tool-bar background color: %@", [[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"navBarBackgroundColor"]]];
			tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
			[theToolbar setTintColor:tmpColor];
		}
		
		//set the toolbar style
		if([[BT_strings getStyleValueForScreen:theScreenData:@"toolbarStyle":@""] isEqualToString:@"transparent"]){
			[theToolbar setTranslucent:TRUE];
		}else{
			[theToolbar setTranslucent:FALSE];
		}
		
		//add the buttons to the toolbar
		[theToolbar setItems:buttons animated:NO];
        
	}
    
	//clean up button
	[buttons release];
    
	//return
	return theToolbar;
    
}

/*
 This method returns a UIToolbar with buttom items configured for a map view. 
 */
+(UIToolbar *)getMapToolBarForScreen:(UIViewController *)theViewController:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getMapToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getMapToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if we have no button options set in JSON and no audioFileName, return nil for toolbar
	BOOL screenUsesToolbar = FALSE;
	UIToolbar *theToolbar = nil; 
	
	// create the array to hold the buttons for the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] init];
	
	//are we showing map buttons?
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showMapTypeButtons":@""] isEqualToString:@"1"]){
        
		//flag that we are using a toolbar
		screenUsesToolbar = TRUE;
		
		//standard
		UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map_standard.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showMapType:)];
		button.style = UIBarButtonItemStyleBordered;
		[button setTag:1];
		[buttons addObject:button];
		[button release];
        
		//terrain
		UIBarButtonItem* button_1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map_terrain.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showMapType:)];
		button_1.style = UIBarButtonItemStyleBordered;
		[button_1 setTag:2];
		[buttons addObject:button_1];
		[button_1 release];	
        
		//hybrid
		UIBarButtonItem* button_2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map_hybrid.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showMapType:)];
		button_2.style = UIBarButtonItemStyleBordered;
		[button_2 setTag:3];
		[buttons addObject:button_2];
		[button_2 release];	
        
	}//if map type buttons
	
	
	//show refresh button?
	if([theViewController respondsToSelector:@selector(refreshData)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showRefreshButton":@""] isEqualToString:@"1"]){
			UIBarButtonItem* buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(refreshData)];
			buttonRefresh.style = UIBarButtonItemStyleBordered;
			[buttonRefresh setTag:102];
			[buttons addObject:buttonRefresh];
			[buttonRefresh release];
		}
	}	
	
	
	//spacer forces remaining buttons to right
	UIBarButtonItem* bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
    
	//user location button
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showUserLocationButton":@""] isEqualToString:@"1"]){
		screenUsesToolbar = TRUE;
		UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"location.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(centerDeviceLocation)];
		button.style = UIBarButtonItemStyleBordered;
		[button setTag:3];
		[buttons addObject:button];
		[button release];
	}	
    
	//audio controls in toolbar if we have an audioFileName
	if([theViewController respondsToSelector:@selector(showAudioControls)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 0 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 0){
			screenUsesToolbar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"equalizer.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showAudioControls)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:104];
			[buttons addObject:button];
			[button release];
		}
	}
	
	
	//if we are using a toolbar
	if(screenUsesToolbar){
		
		//create a toolbar to have two buttons in the right
		theToolbar = [[[UIToolbar alloc] initWithFrame:[self frameForToolBarAtOrientation:theViewController:theScreenData]] autorelease];
		theToolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
		
		//set toolbar color to nav bar color from rootApp.rootTheme OR from screens JSON if over-riden
		UIColor *tmpColor = nil;
		
		//nav bar background color
		if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"setting map tool-bar background color: %@", [[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"navBarBackgroundColor"]]];
			tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
			[theToolbar setTintColor:tmpColor];
		}
		
		//set the toolbar style
		if([[BT_strings getStyleValueForScreen:theScreenData:@"toolbarStyle":@""] isEqualToString:@"transparent"]){
			[theToolbar setTranslucent:TRUE];
		}else{
			[theToolbar setTranslucent:FALSE];
		}
		
		//add the buttons to the toolbar
		[theToolbar setItems:buttons animated:NO];
        
	}
    
	//clean up button
	[buttons release];
    
	//return
	return theToolbar;
	
	
}

/*
 This method returns a UIToolbar with buttom items configured for an image gallery screen.
 */

+(UIToolbar *)getImageToolBarForScreen:(UIViewController *)theViewController:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getImageToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getImageToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}	
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if we have no button options set in JSON and no audioFileName, return nil for toolbar
	UIToolbar *theToolbar = nil;
	BOOL showBar = FALSE;
	
	// create the array to hold the buttons for the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] init];
	
	//are showing prev / next buttons?
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showImageNavButtons":@""] isEqualToString:@"1"]){
		showBar = TRUE;
		
		UIBarButtonItem* buttonPrev = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"prev.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(gotoPreviousPage)];
		buttonPrev.style = UIBarButtonItemStyleBordered;
		[buttonPrev setTag:1];
		[buttons addObject:buttonPrev];
		[buttonPrev release];
        
		UIBarButtonItem* buttonNext = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"next.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(gotoNextPage)];
		buttonNext.style = UIBarButtonItemStyleBordered;
		[buttonNext setTag:2];
		[buttons addObject:buttonNext];
		[buttonNext release];
        
	}
	
	//show refresh button?
	if([theViewController respondsToSelector:@selector(refreshData)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showRefreshButton":@""] isEqualToString:@"1"]){
			showBar = TRUE;
			UIBarButtonItem* buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(refreshData)];
			buttonRefresh.style = UIBarButtonItemStyleBordered;
			[buttonRefresh setTag:102];
			[buttons addObject:buttonRefresh];
			[buttonRefresh release];
		}
	}
    
	//spacer forces remaining buttons to right
	UIBarButtonItem* bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
	
	//email image button
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showEmailImageButton":@""] isEqualToString:@"1"] ||
       [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showSaveImageButton":@""] isEqualToString:@"1"] ){
		showBar = TRUE;
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:theViewController action:@selector(showImageFunctions)];
		button.style = UIBarButtonItemStyleBordered;
		[button setTag:3];
		[buttons addObject:button];
		[button release];
	}
	
	//audio controls in toolbar if we have an audioFileName
	if([theViewController respondsToSelector:@selector(showAudioControls)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 0 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 0){
			showBar = TRUE;
			UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"equalizer.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showAudioControls)];
			button.style = UIBarButtonItemStyleBordered;
			[button setTag:104];
			[buttons addObject:button];
			[button release];
		}
	}
	
	//create a toolbar to have two buttons in the right
	theToolbar = [[[UIToolbar alloc] initWithFrame:[self frameForToolBarAtOrientation:theViewController:theScreenData]] autorelease];
	theToolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
	
	//set toolbar color to nav bar color from rootApp.rootTheme OR from screens JSON if over-riden
	UIColor *tmpColor = nil;
	
	//nav bar background color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"setting image tool-bar background color: %@", [[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"navBarBackgroundColor"]]];
		tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
		[theToolbar setTintColor:tmpColor];
	}
	
	//set the toolbar style
	if([[BT_strings getStyleValueForScreen:theScreenData:@"toolbarStyle":@""] isEqualToString:@"transparent"]){
		[theToolbar setTranslucent:TRUE];
	}else{
		[theToolbar setTranslucent:FALSE];
	}
	
	//add the buttons to the toolbar
	[theToolbar setItems:buttons animated:NO];
    
	//clean up button
	[buttons release];
    
	//if we did not have any buttons...remove the bar
	if(showBar){
		return theToolbar;
	}else{
		theToolbar = nil;
		return theToolbar;
	}
}


/*
 This method returns a UIToolbar with buttom items configured for an aduio screen.
 */

+(UIToolbar *)getAudioToolBarForScreen:(UIViewController *)theViewController:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getAudioToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getAudioToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}	
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if we have no button options set in JSON and no audioFileName, return nil for toolbar
	UIToolbar *theToolbar = nil;
	
	// create the array to hold the buttons for the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] init];
	
	UIBarButtonItem* buttonPlay = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:theViewController action:@selector(playAudio)];
	buttonPlay.style = UIBarButtonItemStyleBordered;
	[buttonPlay setTag:1];
	[buttons addObject:buttonPlay];
	[buttonPlay release];
    
	UIBarButtonItem* buttonPause = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:theViewController action:@selector(pauseAudio)];
	buttonPause.style = UIBarButtonItemStyleBordered;
	[buttonPause setTag:2];
	[buttons addObject:buttonPause];
	[buttonPause release];
    
	//show refresh button?
	if([theViewController respondsToSelector:@selector(refreshData)]){
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showRefreshButton":@""] isEqualToString:@"1"]){
			UIBarButtonItem* buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(refreshData)];
			buttonRefresh.style = UIBarButtonItemStyleBordered;
			[buttonRefresh setTag:5];
			[buttons addObject:buttonRefresh];
			[buttonRefresh release];
		}
	}
    
	//spacer forces remaining buttons to right
	UIBarButtonItem* bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
	
	//audio tools button
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"showAudioToolsButton":@""] isEqualToString:@"1"]){
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:theViewController action:@selector(showAudioFunctions)];
		button.style = UIBarButtonItemStyleBordered;
		[button setTag:5];
		[buttons addObject:button];
		[button release];
	}
	
	//create a toolbar to have two buttons in the right
	theToolbar = [[[UIToolbar alloc] initWithFrame:[self frameForToolBarAtOrientation:theViewController:theScreenData]] autorelease];
	theToolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
	
	//set toolbar color to nav bar color from rootApp.rootTheme OR from screens JSON if over-riden
	UIColor *tmpColor = nil;
	
	//nav bar background color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"setting audio tool-bar background color: %@", [[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"navBarBackgroundColor"]]];
		tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
		[theToolbar setTintColor:tmpColor];
	}
	
	//set the toolbar style
	if([[BT_strings getStyleValueForScreen:theScreenData:@"toolbarStyle":@""] isEqualToString:@"transparent"]){
		[theToolbar setTranslucent:TRUE];
	}else{
		[theToolbar setTranslucent:FALSE];
	}
	
	//add the buttons to the toolbar
	[theToolbar setItems:buttons animated:NO];
    
	//clean up button
	[buttons release];
    
	//return
	return theToolbar;
	
}


/*
 This method returns a UIToolbar with buttom items configured for a quiz.
 */

+(UIToolbar *)getQuizToolBarForScreen:(UIViewController *)theViewController:(BT_item *)theScreenData{
	if([[theScreenData.jsonVars objectForKey:@"itemNickname"] length] > 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getQuizToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", [theScreenData.jsonVars objectForKey:@"itemNickname"], [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"getQuizToolBarForScreen with nickname: \"%@\" and itemId: %@ and type: %@", @"no nickname?", [theScreenData.jsonVars objectForKey:@"itemId"], [theScreenData.jsonVars objectForKey:@"itemType"]]];
	}	
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if we have no button options set in JSON and no audioFileName, return nil for toolbar
	UIToolbar *theToolbar = nil;
	
	// create the array to hold the buttons for the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] init];
	
	//if we have a sound file, add a left refresh and a right audio... else just add timer...
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 3){
        
		//refresh button.
		UIBarButtonItem* buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:theViewController action:@selector(refreshData)];
		buttonRefresh.style = UIBarButtonItemStyleBordered;
		[buttonRefresh setTag:102];
		[buttons addObject:buttonRefresh];
		//disable it if not dataURL is provided for the parent screen
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"dataURL":@""] length] < 3){
			[buttonRefresh setEnabled:FALSE];
		}
		[buttonRefresh release];
        
	}
	
	
	//spacer forces buttons to left
	UIBarButtonItem* bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
	
	//quiz timer..(leave space on each end for buttons...
	UILabel *quizTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(75 , 11.0f, theViewController.view.frame.size.width - 150, 21.0f)];
	[quizTimeLabel setFont:[UIFont systemFontOfSize:16]];
	[quizTimeLabel setBackgroundColor:[UIColor clearColor]];
	[quizTimeLabel setTextColor:[UIColor whiteColor]];
	[quizTimeLabel setTag:105];
	[quizTimeLabel setText:@""];
	[quizTimeLabel setTextAlignment:UITextAlignmentCenter];
	UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:quizTimeLabel];
	[buttons addObject:title];
	[title release];
	[quizTimeLabel release];
	
	//spacer forces buttons to right
	UIBarButtonItem* bi_2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[buttons addObject:bi_2];
	[bi_2 release];
    
	//ALWAYS add the audio button in the quiz toolbar so timer label centers. Disable it if no background audio..
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 3){
		UIBarButtonItem* button;
		button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"equalizer.png"] style:UIBarButtonItemStylePlain  target:theViewController action:@selector(showAudioControls)];
		button.style = UIBarButtonItemStyleBordered;
		[buttons addObject:button];
		[button release];
		
	}
    
	//create a toolbar to have two buttons in the right
	theToolbar = [[[UIToolbar alloc] initWithFrame:[self frameForToolBarAtOrientation:theViewController:theScreenData]] autorelease];
	theToolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
	
	//set toolbar color to nav bar color from rootApp.rootTheme OR from screens JSON if over-riden
	UIColor *tmpColor = nil;
	
	//nav bar background color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""] length] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"setting quiz tool-bar background color: %@", [[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"navBarBackgroundColor"]]];
		tmpColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"navBarBackgroundColor":@""]];
		[theToolbar setTintColor:tmpColor];
	}
	
	//set the toolbar style
	if([[BT_strings getStyleValueForScreen:theScreenData:@"toolbarStyle":@""] isEqualToString:@"transparent"]){
		[theToolbar setTranslucent:TRUE];
	}else{
		[theToolbar setTranslucent:FALSE];
	}
	
	//add the buttons to the toolbar
	[theToolbar setItems:buttons animated:NO];
    
	//clean up button
	[buttons release];
    
	//return
	return theToolbar;
	
}

/*
 This method build a UISegementedControl that we use as a "button" so we can show "selected states"
 */
+(UISegmentedControl *)getButtonForQuiz:(UIViewController *)theViewController:(CGRect)theFrame:(int)theTag:(UIColor *)buttonColor{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"getButtonForQuiz%@", @""]];
    
	NSArray *txt = [NSArray arrayWithObjects:@"",nil];
	UISegmentedControl *tmpBtn = [[UISegmentedControl alloc] initWithItems:txt];
	tmpBtn.frame = theFrame;  
	tmpBtn.segmentedControlStyle = UISegmentedControlStyleBar;
	tmpBtn.momentary = YES;
	[tmpBtn setTintColor:buttonColor];
	[tmpBtn addTarget:theViewController action:@selector(answerClick:) forControlEvents:UIControlEventValueChanged];
	[tmpBtn setTag:theTag];
    
	return tmpBtn;
    
}

/*
 This method build a simple label that goes on top of a quiz-button (see previous method). We use this approach
 because the buttons are UISegementedControls and do not allow for font-size changes
 */
+(UILabel *)getLabelForQuizButton:(CGRect)theFrame:(int)fontSize:(UIColor *)fontColor{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"getLabelForQuizButton%@", @""]];
    
	UILabel *tmpLbl = [[[UILabel alloc] initWithFrame:theFrame] autorelease];
	[tmpLbl setBackgroundColor:[UIColor clearColor]];
	[tmpLbl setTextAlignment:UITextAlignmentCenter];
	[tmpLbl setFont:[UIFont systemFontOfSize:fontSize]];
	[tmpLbl setTextColor:fontColor];
	[tmpLbl setNumberOfLines:2];
	[tmpLbl setText:@""];
	
	return tmpLbl;
    
}



/*
 This method returns a custom view for a table view cell's background. It's the only way to add a background
 color without cutting off the rounded corners on a "round" style table. 
 */
+(UIView *)getCellBackgroundForListRow:(BT_item *)theScreenData:(NSIndexPath *)theIndexPath:(int)numRows{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"getCellBackgroundForListRow for screen with itemId: %@", [theScreenData itemId]]];
    
    BT_cell_backgroundView *bgView = [[[BT_cell_backgroundView alloc] initWithFrame:CGRectZero] autorelease];
	UIColor *borderColor = [UIColor grayColor];
	UIColor *backgroundColor = [UIColor clearColor];
	BOOL isRoundTable = FALSE;
	
	//if the global theme or the screen data want a round style table
	if([[BT_strings getStyleValueForScreen:theScreenData:@"listStyle":@""] isEqualToString:@"round"]){
		isRoundTable = TRUE;
	}	
	
	//cell background color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"listRowBackgroundColor":@""] length] > 0){
		backgroundColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"listRowBackgroundColor":@""]];
	}	
    
	//cell border color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"listRowSeparatorColor":@""] length] > 0){
		borderColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"listRowSeparatorColor":@""]];
	}		
	
	//set colors
	[bgView setFillColor:backgroundColor];
	[bgView setBorderColor:borderColor];
	
	
	//position is important to maintain rounded corners if this is a "round" table.
	if(isRoundTable == FALSE){
       	bgView.position = CustomCellBackgroundViewPositionMiddle;
	}else{
		if(theIndexPath.row == 0){
			bgView.position = CustomCellBackgroundViewPositionTop;
    	}else if(theIndexPath.row == numRows - 1){
     		bgView.position = CustomCellBackgroundViewPositionBottom;
		}else{
			bgView.position = CustomCellBackgroundViewPositionMiddle;
    	}
	}
	
	//return 
	return bgView;
	
}


//This method rounds the corners of a view
+(UIView *)applyRoundedCorners:(UIView *)theView:(int)radius{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyRoundedCorners radius:%i", radius]];
    theView.layer.cornerRadius = radius;
	return theView;
}
//This method rounds the corners of a UITextView
+(UITextView *)applyRoundedCornersToTextView:(UITextView *)theView:(int)radius{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyRoundedCornersToTextView radius:%i", radius]];
   	theView.layer.masksToBounds = YES;
	theView.layer.cornerRadius = radius;
	return theView;
}
//This method rounds the corners of a UIImageView
+(UIImageView *)applyRoundedCornersToImageView:(UIImageView *)theView:(int)radius{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyRoundedCornersToImageView radius:%i", radius]];
   	theView.layer.masksToBounds = YES;
	theView.layer.cornerRadius = radius;
	return theView;
}
//this method adds a border to a view
+(UIView *)applyBorder:(UIView *)theView:(int)borderWidth:(UIColor *)borderColor{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyBorder borderWidth:%i", borderWidth]];
    theView.layer.borderWidth = borderWidth;
    theView.layer.borderColor = [borderColor CGColor];
	return theView;
}
//this method adds a drop shadow to a view
+(UIView *)applyDropShadow:(UIView *)theView:(UIColor *)shadowColor{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyDropShadow", @""]];
	
	//drop shadow does not work on older devices (4.0 > required)
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if(version >= 4.0){
    	theView.layer.shadowColor = [shadowColor CGColor];
    	theView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    	theView.layer.shadowOpacity = 0.50;
	}
	return theView;
}

//this method adds a gradient to a view
+(UIView *)applyGradient:(UIView *)theView:(UIColor *)colorTop:(UIColor *)colorBottom {
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"applyGradient", @""]];
    
    //create a CAGradientLayer to draw the gradient on
    CAGradientLayer *layer = [CAGradientLayer layer];
	layer.colors = [NSArray arrayWithObjects:(id)[colorTop CGColor], (id)[colorBottom CGColor], nil];
    layer.frame = theView.bounds;
    [theView.layer insertSublayer:layer atIndex:0];
	return theView;
	
}



@end








