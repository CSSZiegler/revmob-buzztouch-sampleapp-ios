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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "revmobiossampleapp_appDelegate.h"
#import "BT_rotatingNavController.h"
#import "BT_rotatingTabBarController.h"
#import "BT_viewControllerManager.h"
#import "BT_viewUtilities.h"
#import "BT_color.h"
#import "BT_fileManager.h"
#import "BT_strings.h"
#import "JSON.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_user.h"
#import "BT_device.h"
#import "BT_uploadItem.h"
#import "BT_locationManager.h"
#import "BT_application.h"


@implementation BT_application
@synthesize downloader, dataURL, jsonVars, themes, tabs, screens;
@synthesize rootTheme, rootNavController, rootTabBarController;
@synthesize rootUser, rootDevice, rootLocationManager, rootNetworkState;
@synthesize currentMenuItemData, previousMenuItemData, currentScreenData, previousScreenData, currentItemUpload;
@synthesize transitionTypeHistory;

//init application
-(id)init{
    if((self = [super init])){
	[BT_debugger showIt:self:[NSString stringWithFormat:@"initializing buzztouch application %@", @""]];
			
		//init variables.
		self.jsonVars = nil;	
		self.rootNavController = nil;
		self.rootTabBarController = nil;
		self.rootTheme = nil;
		self.rootDevice = nil;
		self.rootUser = nil;
		self.rootNetworkState = nil;
		self.rootLocationManager = nil;
		self.currentItemUpload = nil;
		self.tabs = [[NSMutableArray alloc] init];
		self.screens = [[NSMutableArray alloc] init];
		self.themes = [[NSMutableArray alloc] init];	

		//initialize the rootDevice to store information associated with this device
		self.rootDevice = [[BT_device alloc] init];
		
		//initialized the rootUser to store information associated with the user (may or may not be logged in)
		self.rootUser = [[BT_user alloc] init];

		//initialized the rootNetworkState to track network state changes
		self.rootNetworkState = [[BT_networkState alloc] init];
			
	}
	return self;
}


/* 
	this method validates the format of the JSON data. It checks for required elements and returns false if
	an element is missing
*/
-(BOOL)validateApplicationData:(NSString *)theAppData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"validateApplicationData %@", @""]];
	
	//assume it's valid
	BOOL isValid = TRUE;
	
	//for debugger
	NSString *errorMessage = @"";
	
	//create dictionary from the JSON string
	SBJsonParser *parser = [SBJsonParser new];
  	id jsonData = [parser objectWithString:theAppData];
	if(!jsonData){
		
		[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR parsing JSON in validateApplicationData: %@", parser.errorTrace]];
		errorMessage = NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed");
		isValid = FALSE;
	}else{
	
		if(![jsonData objectForKey:@"BT_appConfig"]){
			isValid = FALSE;
			errorMessage = [errorMessage stringByAppendingString:@"\nThe appConfig data doesn't contain the root BT_appConfig property?"];
		}else{
			//look for root items array
			if(![[jsonData objectForKey:@"BT_appConfig"] objectForKey:@"BT_items"]){
				isValid = FALSE;
				errorMessage = [errorMessage stringByAppendingString:@"\nThe appConfig data doesn't contain any root-items?"];
			}
		}
	}
		
	//if not valid, show in debugger
	if(!isValid){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"validateApplicationData: ERROR: %@", errorMessage]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"The application data appears to be valid. %@", @""]];
	}
	
	//return
	return isValid;

}


//init with JSON data string
-(BOOL)parseJSONData:(NSString *)appDataString{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"parseJSONData: parsing application data %@", @""]];
	
	@try{	
	
		//re-set array so they are empty
		self.tabs = [[NSMutableArray alloc] init];
		self.screens = [[NSMutableArray alloc] init];
		self.themes = [[NSMutableArray alloc] init];
		self.transitionTypeHistory = [[NSMutableArray alloc] init];
	
		//create dictionary from the JSON string
		SBJsonParser *parser = [SBJsonParser new];
		id jsonData = [parser objectWithString:appDataString];
	   	if(!jsonData){
		
			[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR parsing JSON in parseJSONData: %@", parser.errorTrace]];
			return FALSE;
		
		}else{

			//get the first item in the list of BT_item, it should be a BT_item.itemType == "BT_app"
			if([[jsonData objectForKey:@"BT_appConfig"] objectForKey:@"BT_items"]){
				NSArray *tmpItems = [[jsonData objectForKey:@"BT_appConfig"] objectForKey:@"BT_items"];
				if([tmpItems count] < 1){
					[BT_debugger showIt:self:[NSString stringWithFormat:@"the BT_items array is empty?%@", @""]];
				}else{
					NSDictionary *thisApp = [tmpItems objectAtIndex:0];
					if([[thisApp objectForKey:@"itemType"] isEqualToString:@"BT_app"]){
						
						//set this app's json vars
						[self setJsonVars:thisApp];
						
						//First look at the basic app properties and try to find a dataURL
						if([thisApp objectForKey:@"dataURL"]){
							if([[thisApp objectForKey:@"dataURL"] length] > 3){
								//set this app's dataURL
								[self setDataURL:[thisApp objectForKey:@"dataURL"]];
							}
						}
						
						
						/*
							Fill these array's...
							------------------------------------
							"BT_themes", "BT_tabs", "BT_screens"
						*/
						
						//fill possible themes array
						if([thisApp objectForKey:@"BT_themes"]){
							NSArray *tmpThemes = [thisApp objectForKey:@"BT_themes"];
							[BT_debugger showIt:self:[NSString stringWithFormat:@"parsing themes, count: %d", [tmpThemes count]]];
							for (NSDictionary *tmpTheme in tmpThemes){
								if([[tmpTheme objectForKey:@"itemType"] isEqualToString:@"BT_theme"]){
									BT_item *thisTheme = [[BT_item alloc] init];
									thisTheme.itemId = [tmpTheme objectForKey:@"itemId"];
									thisTheme.itemType = [tmpTheme objectForKey:@"itemType"];
									if([tmpTheme objectForKey:@"itemNickname"]){
										thisTheme.itemNickname = [tmpTheme objectForKey:@"itemNickname"];
									}else{
										thisTheme.itemNickname = @"";
									}
									thisTheme.jsonVars = tmpTheme;
									[self.themes addObject:thisTheme];
									[thisTheme release];
								}
							}
						}//end if themes

						//fill possible tabs arrSay
						if([thisApp objectForKey:@"BT_tabs"]){
							NSArray *tmpTabs = [thisApp objectForKey:@"BT_tabs"];
							[BT_debugger showIt:self:[NSString stringWithFormat:@"parsing tabs, count: %d", [tmpTabs count]]];
							for (NSDictionary *tmpTab in tmpTabs){
								if([[tmpTab objectForKey:@"itemType"] isEqualToString:@"BT_tab"]){
									BT_item *thisTab = [[BT_item alloc] init];
									thisTab.itemId = [tmpTab objectForKey:@"itemId"];
									if([tmpTab objectForKey:@"itemNickname"]){
										thisTab.itemNickname = [tmpTab objectForKey:@"itemNickname"];
									}else{
										thisTab.itemNickname = @"";
									}
									thisTab.itemType = [tmpTab objectForKey:@"itemType"];
									thisTab.jsonVars = tmpTab;
									[self.tabs addObject:thisTab];
									[thisTab release];
								}
							}
						}//end if tabs

						//fill possible screens array
						if([thisApp objectForKey:@"BT_screens"]){
							NSArray *tmpScreens = [thisApp objectForKey:@"BT_screens"];
							[BT_debugger showIt:self:[NSString stringWithFormat:@"parsing screens, count: %d", [tmpScreens count]]];
							for(NSDictionary *tmpScreen in tmpScreens){
								BT_item *thisScreen = [[BT_item alloc] init];
								thisScreen.itemId = [tmpScreen objectForKey:@"itemId"];
								if([tmpScreen objectForKey:@"itemNickname"]){
									thisScreen.itemNickname = [tmpScreen objectForKey:@"itemNickname"];
								}else{
									thisScreen.itemNickname = @"";
								}
								thisScreen.itemType = [tmpScreen objectForKey:@"itemType"];
								thisScreen.jsonVars = tmpScreen;
								[self.screens addObject:thisScreen];
								[thisScreen release];
							}//end for each screen
						}//end if screens		
						
														
					}//if this item was a BT_app
				}
			}else{
				[BT_debugger showIt:self:[NSString stringWithFormat:@"there are no BT_items in the configuration data?%@", @""]];
			}

			//done
			return TRUE;
		
		}
		
	}@catch (NSException * e) {
	
		[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing application data in parseJSONData: %@", e]];
		return FALSE;
	
	} 
		
	return FALSE;
}


//returns a BT_item Object from the array of screens
-(BT_item *)getScreenDataByItemId:(NSString *)theScreenItemId{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"getScreenDataByItemId %@", theScreenItemId]];
	int foundIt = 0;
	BT_item *returnScreen = nil;
	for(int i = 0; i < [[self screens] count]; i++){
		BT_item *thisScreen = (BT_item *)[[self screens] objectAtIndex:i];
		if([[thisScreen itemId] isEqualToString:theScreenItemId]){
			foundIt = 1;
			returnScreen = thisScreen;
			break;
		}			
	}
	if(foundIt == 1){
		if([returnScreen.itemNickname length] > 1){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"screenType is %@ for screen with nickname: \"%@\" and itemId: %@", [returnScreen itemType], [returnScreen itemNickname], theScreenItemId]];
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"screenType is %@ for screen with nickname: \"%@\" and itemId: %@", [returnScreen itemType], @"no nickname?", theScreenItemId]];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"could not find screen with itemId: %@", theScreenItemId]];
	}
	return returnScreen;
}

//returns a BT_item Object from the array of screens
-(BT_item *)getScreenDataByNickname:(NSString *)theScreenNickname{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"getScreenDataByNickname %@", theScreenNickname]];
	int foundIt = 0;
	BT_item *returnScreen = nil;
	for(int i = 0; i < [[self screens] count]; i++){
		BT_item *thisScreen = (BT_item *)[[self screens] objectAtIndex:i];
		if([[thisScreen itemNickname] isEqualToString:theScreenNickname]){
			foundIt = 1;
			returnScreen = thisScreen;
			break;
		}
	}
	if(foundIt == 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"screenType is %@ for screen with nickname: %@", [returnScreen itemType], theScreenNickname]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"could not find screen with nickname: %@", theScreenNickname]];
	}
	return returnScreen;
}


//returns a BT_theme_data Object from the array of themes
-(BT_item *)getThemeDataByItemId:(NSString *)theThemeItemId{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"getThemeDataByItemId %@", theThemeItemId]];
	int foundIt = 0;
	BT_item *returnTheme = nil;
	for(int i = 0; i < [[self themes] count]; i++){
		BT_item *thisTheme = (BT_item *)[[self themes] objectAtIndex:i];
		if([[thisTheme itemId] isEqualToString:theThemeItemId]){
			foundIt = 1;
			returnTheme = thisTheme;
			break;
		}			
	}
	if(foundIt == 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"returning BT_theme_data object with itemId: %@",theThemeItemId]];
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"could not find BT_theme_data with this itemId: %@", theThemeItemId]];
	}
	return returnTheme;
}


//build application interface.
-(void)buildInterface{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"buildInterface app interface%@",@""]];
	
	/*
		1) 	Create a navigation controller interface or a tabbed navigation interface if we have an array of tabs.
		2) 	Create an optional splash screen, bring it to the front. It will remove itself after the amount of time
			set in the splash screens startTransitionAfterSeconds data.
	*/
	
	//before we start, set the rootTheme if we have one..
	if([self.themes count] > 0){
		self.rootTheme = [self.themes objectAtIndex:0];
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	1A) If this app does NOT have any tabs in it's tabs array, create a single navigation controller app with 
	//		the first screen in the list of screens as the home screen
	if([self.tabs count] < 1){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"building a single navigation controller app%@", @""]];
		if([self.screens count] > 0){
			
			//screen data for the home screen
			BT_item *theScreen = [self.screens objectAtIndex:0];
			[theScreen setIsHomeScreen:TRUE];
			
			//if the home screen is a splash screen, build an error screen instead
			if([theScreen.itemType isEqualToString:@"BT_screen_splash"]){

				[BT_debugger showIt:self:[NSString stringWithFormat:@"home screen cannot be a BT_screen_splash%@", @""]];
				theScreen = [BT_viewControllerManager getErrorViewController];
	
			}
			
			//remember this screen as the "currently loaded screen", also make it the "previously loaded screen"
			[self setCurrentScreenData:theScreen];
			[self setPreviousScreenData:theScreen];

			//if theScreen has an audio file..load it in the delegate
			if([[BT_strings getJsonPropertyValue:theScreen.jsonVars:@"audioFileName":@""] length] > 3){
			
				//appDelegate
				revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
			
				//start audio in different thread to prevent UI blocking
				[NSThread detachNewThreadSelector: @selector(loadAudioForScreen:) toTarget:appDelegate withObject:theScreen];

			}
			
			//initialize a view controller for the appropriate screen type for the home screen
			UIViewController *useViewController = (UIViewController *)[BT_viewControllerManager initViewControllerForScreen:theScreen];
			[useViewController.view setFrame:[[UIScreen mainScreen] bounds]];
			
			//initizlize the navigation controller
			rootNavController = [[BT_rotatingNavController alloc] initWithRootViewController:useViewController];
			
			//set the background color of the navigation bar
			[[rootNavController navigationBar] setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreen]];
			
			rootNavController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
			[rootNavController setDelegate:self];
			
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"The application does not have any screens?%@", @""]];
		}
	}//end singleNavController	


	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	1B) If this app uses tabs, create a tabbed navigation application and set the default screen for each tab
	//		to the defaultScreenGuid in the tabs data
	if([self.tabs count] > 0){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"building a tabbed based navigation app%@", @""]];
		
		if([self.screens count] > 0){
		
			//appDelegate
			revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
		
			//initialize the tab bar controller
			rootTabBarController = [[BT_rotatingTabBarController alloc] init];
			[rootTabBarController.view setFrame:[[UIScreen mainScreen] bounds]];
			[rootTabBarController setDelegate:appDelegate];
			rootTabBarController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
			
			//if we have a tabbar color setup in the theme
			if(self.rootTheme != nil){
				if([self.rootTheme.jsonVars objectForKey:@"tabBarColor"]){
					if([[self.rootTheme.jsonVars objectForKey:@"tabBarColor"] length] > 3){
						UIColor *tabberColor = [BT_color getColorFromHexString:[self.rootTheme.jsonVars objectForKey:@"tabBarColor"]];
						NSString *tabberOpacity = @".50";
						if([self.rootTheme.jsonVars objectForKey:@"tabBarColorOpacity"]){
							if([[self.rootTheme.jsonVars objectForKey:@"tabBarColorOpacity"] length] > 0){
								tabberOpacity = [NSString stringWithFormat:@".%@", [self.rootTheme.jsonVars objectForKey:@"tabBarColorOpacity"]];
								if([tabberOpacity isEqualToString:@".100"]) tabberOpacity = @".50";
							}
							//colorize the tab-bar
							[rootTabBarController addTabColor:tabberColor:[tabberOpacity doubleValue]];
						}
					}
				}
			}
			
			//Fill a temporary array of view controllers to assign to tab bar controller
			NSMutableArray *tmpViewControllers = [[NSMutableArray alloc] init];	
			
			//loop through each tab bar item in application data
			for(int i = 0; i < [[self tabs] count]; i++){
							
				//this tab
				BT_item *thisTab = (BT_item *)[[self tabs] objectAtIndex:i];
				NSString *textLabel = [[thisTab jsonVars] objectForKey:@"textLabel"];				
				UIImage *tabIcon = [UIImage imageNamed:[[thisTab jsonVars] objectForKey:@"iconName"]];				

				//get the screen from the apps array of screens for this tab's view controller
				if([[thisTab jsonVars] objectForKey:@"homeScreenItemId"]){
				
					BT_item *thisTabsDefaultScreenData = [self getScreenDataByItemId:[[thisTab jsonVars] objectForKey:@"homeScreenItemId"]];
					
					//if this is the first tab in the list, remember it as the "currently loaded screen", also make it the "previously loaded screen"
					if(i == 0){
						[self setCurrentScreenData:thisTabsDefaultScreenData];
						[self setPreviousScreenData:thisTabsDefaultScreenData];
						[thisTabsDefaultScreenData setIsHomeScreen:TRUE];
						
						//if theScreen has an audio file..load it in the delegate
						if([[BT_strings getJsonPropertyValue:thisTabsDefaultScreenData.jsonVars:@"audioFileName":@""] length] > 3){
						
							//appDelegate
							revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
						
							//initialize audio in different thread to prevent UI blocking
							[NSThread detachNewThreadSelector: @selector(loadAudioForScreen:) toTarget:appDelegate withObject:thisTabsDefaultScreenData];

						}						
						
					}	
					
					//initialize a view controller for this type of screen (ClassName == BT_item.screenType)
					UIViewController *thisTabsDefaultViewController = (UIViewController *)[BT_viewControllerManager initViewControllerForScreen:thisTabsDefaultScreenData];
					[thisTabsDefaultViewController.view setFrame:[[UIScreen mainScreen] bounds]];
					thisTabsDefaultViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

					//initialize a navigation controller using the view controller
					BT_rotatingNavController *thisTabsNavController = [[BT_rotatingNavController alloc] initWithRootViewController:thisTabsDefaultViewController];
					[thisTabsNavController.view setFrame:[[UIScreen mainScreen] bounds]];
					[thisTabsNavController setDelegate:self];
					[thisTabsNavController.tabBarItem setTitle:textLabel];
					[thisTabsNavController.tabBarItem setImage:tabIcon];
					
					//set the background color of the navigation bar
					[[thisTabsNavController navigationBar] setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:thisTabsDefaultScreenData]];
					
					//add this navigation controller to the temporary array of view controllers
					[tmpViewControllers addObject:thisTabsNavController];	
					
					//clean up
					[thisTabsNavController release];
					
				}else{
					[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR: This tab does not have a homeScreenItemId in it's configuration data%@", @""]];
				}
				
			}//end for each tab in this apps list array of tabs
				
			//assign temporary array of view controllers to tab bar controller
			rootTabBarController.viewControllers = tmpViewControllers;
			
			//if we have tabs..(something seriously wrong if we don't!)
			if([tmpViewControllers count] > 0){
				
				//select first tab
				[rootTabBarController setSelectedIndex:0];
			
				//fire the viewWillAppear method in the selected tab
				[rootTabBarController.navigationController viewWillAppear:NO];
			}
		
			//clean up tmpViewControllers
			[tmpViewControllers release];
		
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"The application is a tabbed app but it does not have any screens?%@", @""]];
		}
		
	}//end tabBarController

	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	2) 	Add a splash screen if the selected theme uses one. This screen will remove itself after the
	//		screen.startTransitionAfterSeconds expires. This is normally set to a few seconds.
	if(self.rootTheme != nil && [self.themes count] > 0 && [self.screens count] > 0){
		if([[self.rootTheme.jsonVars objectForKey:@"splashScreenItemId"] length] > 0){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"initialzing a splash screen with itemId: %@", [self.rootTheme.jsonVars objectForKey:@"splashScreenItemId"]]];
			
			//get the BT_item from the screens array
			BT_item *splashScreenData = [self getScreenDataByItemId:[self.rootTheme.jsonVars objectForKey:@"splashScreenItemId"]];
			
			//initialize a view controller with ClassName == screenType
			UIViewController *splashViewController = [BT_viewControllerManager initViewControllerForScreen:splashScreenData];
			[splashViewController.view setFrame:[[UIScreen mainScreen] bounds]];

			//add splash screen to appropriate navigation controller (see step 1)
			if(self.tabs.count > 0 && self.screens.count > 0){
				[rootTabBarController.view addSubview:[splashViewController view]];
				[rootTabBarController.view bringSubviewToFront:[splashViewController view]];
			}else{
				if(self.screens.count > 0){
					[rootNavController.view addSubview:[splashViewController view]];
					[rootNavController.view bringSubviewToFront:[splashViewController view]];
				}
			}
		
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This app does not use a splash screen", @""]];
		}
	}
	
	/*
		Location Manager Logic
		----------------------
		If the app's owner has not turned off location tracking, and the app's user has not prevented this
		from a possible settings screen... try to init a location manager.
	*/
	BOOL initLocationManager = TRUE;
	NSString *locationMessage = @"";
	if(![self.rootDevice canReportLocation] == TRUE){
		initLocationManager = FALSE;
		locationMessage = [locationMessage stringByAppendingString:@"This device cannot report it's location. "];
	}
	//has the user prevented location updates in a location settings screen?
	if([[BT_strings getPrefString:@"userAllowLocation"] isEqualToString:@"prevent"]){
		locationMessage = [locationMessage stringByAppendingString:@"User has prevented location monitoring in the app's settings panel. "];
		initLocationManager = FALSE;
	}
	
	//does the core config data want us to start the location manager?
	if([self.jsonVars objectForKey:@"startLocationUpdates"]){
		if([[self.jsonVars objectForKey:@"startLocationUpdates"] isEqualToString:@"0"]){
			locationMessage = [locationMessage stringByAppendingString:@"App has \"Start Location Updates\" set to \"No\". "];
			initLocationManager = FALSE;
		}
	}		
	//finally, init the manager and turn it on...
	if(initLocationManager){
		locationMessage = [locationMessage stringByAppendingString:@"App is starting the location monitor. "];
		self.rootLocationManager = [[BT_locationManager alloc] init];
		[self.rootLocationManager startLocationUpdates];
	}else{
		locationMessage = [locationMessage stringByAppendingString:@"App is NOT starting the location monitor. "];
	}
	[BT_debugger showIt:self:locationMessage];		
	

}


//dealloc
- (void)dealloc {
    [super dealloc];
	[downloader release];
	[dataURL release];
	[jsonVars release];
	
	[tabs release];
	[screens release];
	[themes release];

	[rootNavController release];
	[rootTabBarController release];
	[rootTheme release];
	[rootUser release];
	[rootDevice release];
	[rootLocationManager release];
	[rootNetworkState release];
	
	[currentMenuItemData release];
	[previousMenuItemData release];
	[currentScreenData release];
	[previousScreenData release];
	[currentItemUpload release];
	[transitionTypeHistory release];
		
}


@end











