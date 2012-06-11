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
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "BT_viewUtilities.h"
#import "BT_fileManager.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_strings.h"
#import "BT_rotatingNavController.h"
#import "BT_debugger.h"
#import "BT_item.h"
#import "BT_color.h"
#import "BT_viewController.h"
#import "BT_viewControllerManager.h"

@implementation BT_viewControllerManager


/*
 initWithViewController
 -------------------------
 This method returns the appropriate screen view controller for the passed in screen object.
 All BT_screen controllers have an initWithBTscreen method that is used to initialize the controller.
 It's possible that the app is asked to init a screen that doesn't exist in it's configuration data.
 */

+(id)initViewControllerForScreen:(BT_item *)theScreen{
	if([theScreen itemId] == nil){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"initViewControllerForScreen: ERROR finding screen with itemId: %@", [theScreen itemId]]];
	}else{
		if([theScreen.itemNickname length] > 1){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"initViewControllerForScreen nickname: \"%@\" itemId: %@ type: %@", [theScreen itemNickname], [theScreen itemId], [theScreen itemType]]];
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"initViewControllerForScreen nickname: \"%@\" itemId: %@ type: %@", @"no nickname?", [theScreen itemId], [theScreen itemType]]];
		}
	}
	
	/*
     Instantiate a view controller with ClassName == BT_item.itemType. If the itemType is a custom plug-in we need to get
     the type of view controller to allocate from the JSON data...
     */
	
	//return this view controller.
	NSObject *theViewController = nil;
	NSString *theClassName = [theScreen itemType];
    
    
    //are we loading a custom plugin?
    if([[theScreen itemType] isEqualToString:@"BT_screen_plugIn"]){
        
        //get the class name of the custom UIViewController we want to load...
        theClassName = [BT_strings getJsonPropertyValue:theScreen.jsonVars:@"classFileName":@""];
        
    }
    
    
	//screenType required
	if([theClassName length] > 0){
		Class theClass = NSClassFromString(theClassName);
		if(theClass != nil){
			if([theClass respondsToSelector:@selector(alloc)]){
				theViewController = [[theClass performSelector:@selector(alloc)] initWithScreenData:theScreen];
				return theViewController;
			}
		}
		
	}//screenType length
	
	if(theViewController == nil){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"initViewControllerForScreen: ERROR, could not initialize view controller for screen with itemId: %@", [theScreen itemId]]];
		
		//get error screen data
		BT_item *errorScreenData = [self getErrorViewController];
		theViewController = [[BT_viewController alloc] initWithScreenData:errorScreenData];
	}
	
	//should not be here.
	return theViewController;
	
}



/* 
 this method returns a BT_screen_menuList view to serve as an error screen
 */
+(BT_item *)getErrorViewController{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"getErrorViewController%@", @""]];
    
	BT_item *errorScreen = [[BT_item alloc] init]; 
	[errorScreen setItemId:@"error view controller has no itemId"];
	[errorScreen setItemType:@"BT_screen_menuList"];
    
	//create a dictionary for the dynamic screen. 
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"error view controller has no itemId", @"itemId", 
                          @"BT_screen_menuList", @"itemType", 
                          NSLocalizedString(@"appScreenNotFound",@"Screen not found?"), @"navBarTitleText", nil];
	[errorScreen setJsonVars:dict];
	return errorScreen;
	[errorScreen release];
    
}

/*
 handleTapToLoadScreen
 ----------------------
 This method takes three objects.
 1) The BT_item data object for the screen displaying the menu/button that was tapped
 2) The BT_item data object for the menu/button that was tapped
 3) The BT_item data object holding the info about screen we are going to load / launch. 
 
 */

+(void)handleTapToLoadScreen:(BT_item *)parentScreenData:(BT_item *)theMenuItemData:(BT_item *)theScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"handleTapToLoadScreen%@", @""]];
	[BT_debugger showIt:self:[NSString stringWithFormat:@"the parent screen nickname: \"%@\" itemId: %@ itemType: %@", [parentScreenData itemNickname], [parentScreenData itemId], [parentScreenData itemType]]];
	[BT_debugger showIt:self:[NSString stringWithFormat:@"the menu/button tapped is itemId: %@", [theMenuItemData itemId]]];
	[BT_debugger showIt:self:[NSString stringWithFormat:@"the screen to load is nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
	
	//if the loadScreenItemId == "none".....
	if([[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars:@"loadScreenWithItemId":@""] isEqualToString:@"none"]){
		return;
	}
	
	//find the nav controller
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	///////////////////////////////////////////////////////
	//quick and dirty app exit. May be useful on a button?
	//[[UIApplication sharedApplication] terminate];	
	
	BT_rotatingNavController *theNavController;
	if([appDelegate.rootApp.tabs count] > 0){
		theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
	}else{
		theNavController = [appDelegate.rootApp rootNavController];
	}
    
	//if the screen we are loading requires a login, we can't continue unless the user is logged in.
	//assume that the screen does not require a login.
	BOOL allowNextScreen = TRUE;
	if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"loginRequired":@"0"] isEqualToString:@"1"]){
		if(![[appDelegate.rootApp.rootUser userIsLoggedIn] isEqualToString:@"1"]){
			allowNextScreen = FALSE;
		}
	}
	
	//show password protected message or continue...
	if(!allowNextScreen){
        
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loginRequired",@"~ Login Required ~")
                                            message:NSLocalizedString(@"loginRequiredMessage", @"You are not logged in. A login is required to access this screen.") 
                                            delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                            otherButtonTitles:nil];
		[alertView setTag:101];
		[alertView show];
		[alertView release];
		
		//bail
		return;
        
	}
	if(allowNextScreen){
        
		//play a possible sound effect attached to the menu/button
		if([[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars:@"soundEffectFileName":@""] length] > 3){
			[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:theMenuItemData.jsonVars:@"soundEffectFileName":@""]];
		}
		
		//if the screen we are coming from has an audio track, it may have "audioStopsOnScreenExit"...
		if([[BT_strings getJsonPropertyValue:parentScreenData.jsonVars:@"audioStopsOnScreenExit":@""] isEqualToString:@"1"]){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"stopping audio on screen exit for screen with itemId:%@", [parentScreenData itemId]]];
			if(appDelegate.audioPlayer != nil){
				[appDelegate.audioPlayer stopAudio];
			}
		}		
		
		//remember previous menu item before setting current menu item
		[appDelegate.rootApp setPreviousMenuItemData:[appDelegate.rootApp currentMenuItemData]];
		
		//remember this  menu item as current
		[appDelegate.rootApp setCurrentMenuItemData:theMenuItemData];
        
		//remember current screen object
		[appDelegate.rootApp setCurrentScreenData:theScreenData];
        
		//remember previous screen object
		[appDelegate.rootApp setPreviousScreenData:parentScreenData];
        
        
		//some screens aren't screens at all! Like "Call Us" and "Email Us" item. In these cases, we only
		//trigger a method and do not load a BT_screen view controller.
		
		//place call
		if([[theScreenData itemType] isEqualToString:@"BT_screen_call"] || 
           [[theScreenData itemType] isEqualToString:@"BT_placeCall"]){
            
			if([appDelegate.rootApp.rootDevice canMakePhoneCalls]){
                
				//trigger the place-call method
				[self placeCallWithScreenData:theScreenData];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"callsNotSupportedTitle",@"Calls Not Supported")
                                                        message:NSLocalizedString(@"callsNotSupportedMessage", @"Placing calls is not supported on this device.") 
                                                        delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                        otherButtonTitles:nil];
				[alertView setTag:102];
				[alertView show];
				[alertView release];
			}
			
			//bail
			return;
		}
		
		//send email or share email
		if([[theScreenData itemType] isEqualToString:@"BT_screen_email"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendEmail"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareEmail"] ||
           [[theScreenData itemType] isEqualToString:@"BT_screen_shareEmail"]){
            
			if([appDelegate.rootApp.rootDevice canSendEmails]){
                
				//trigger the email method
				[self sendEmailWithScreenData:theScreenData:nil:nil];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"emailsNotSupportedTitle",@"Email Not Supported")
                                                            message:NSLocalizedString(@"emailsNotSupportedMessage", @"Sending eamils is not supported on this device.") 
                                                            delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                            otherButtonTitles:nil];
				[alertView setTag:103];
				[alertView show];
				[alertView release];
				
			}
            
			//bail
			return;
            
		}
        
		//send SMS or share SMS
		if([[theScreenData itemType] isEqualToString:@"BT_screen_sms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendSms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_sendSMS"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareSms"] ||
           [[theScreenData itemType] isEqualToString:@"BT_shareSMS"] ||
           [[theScreenData itemType] isEqualToString:@"BT_screen_shareSms"]){
            
			if([appDelegate.rootApp.rootDevice canSendSMS]){
                
				//trigger the SMS method
				[self sendTextMessageWithScreenData:theScreenData];
                
			}else{
                
				//show error message
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"textMessageNotSupportedTitle", "SMS Not Supported")
                                                message:NSLocalizedString(@"textMessageNotSupportedMessage",  "Sending SMS / Text messages is not supported on this device.") 
                                                delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                otherButtonTitles:nil];
				[alertView setTag:104];
				[alertView show];
				[alertView release];//features not supported messages
			}
			
			//bail
			return;
            
		}
        
		//BT_screen_video
		if([[theScreenData itemType] isEqualToString:@"BT_screen_video"]){
			
			NSString *localFileName = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"localFileName":@""];
			NSString *dataURL = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"dataURL":@""];
			NSURL *escapedUrl = nil;
			
			/*
             video file
             --------------------------------
             a)	No dataURL is provided in the screen data - use the localFileName configured in the screen data
             b)	A dataURL is provided, check for local copy, download if not available
             
             */
			if([dataURL length] < 3){
				if([localFileName length] > 3){
					if([BT_fileManager doesFileExistInBundle:localFileName]){
						NSString *rootPath = [[NSBundle mainBundle] resourcePath];
						NSString *filePath = [rootPath stringByAppendingPathComponent:localFileName];
						escapedUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
					}
				}
			}else{
				//merge possible varialbes in url
				dataURL = [BT_strings mergeBTVariablesInString:dataURL];
				escapedUrl = [NSURL URLWithString:[dataURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			
			// iPhone 3.2 > requires adding the movie players view as a subView as described here...
			//developer.apple.com/iphone/library/releasenotes/General/RN-iPhoneSDK-4_0/index.html
			if(escapedUrl != nil){
                
				if([[[UIDevice currentDevice] systemVersion] doubleValue] >= 3.2) {
					
					//NSLog(@"Embedding video WITH subView..");
					[BT_debugger showIt:self:[NSString stringWithFormat:@"Embedding video WITH subView..%@", @""]];
					MPMoviePlayerViewController *moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:escapedUrl];
					[moviePlayerController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
					[theNavController presentModalViewController:moviePlayerController animated:YES];
					
				}else{
                    
					[BT_debugger showIt:self:[NSString stringWithFormat:@"Embedding video WITHOUT subView..%@", @""]];
					//init moviePlayer...with iPhone OS 3.2 or earlier player
					MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:escapedUrl];
					moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
					moviePlayer.scalingMode = MPMovieScalingModeNone;
					
					[theNavController.visibleViewController.view addSubview:[moviePlayer view]];					
					[moviePlayer play];
                    
				}		
				
				
				
			}
			//bail
			return;
		}//end if video
		
		//BT_screen_launchNativeApp 
		if([[theScreenData itemType] isEqualToString:@"BT_screen_launchNativeApp"] ||
           [[theScreenData itemType] isEqualToString:@"BT_launchNativeApp"]){
			/*
             Launching native app requires an "appType" and a "dataURL"
             App Types:	browser, youTube, googleMaps, musicStore, appStore, mail, dialer, sms
             */
			NSString *appToLaunch = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"appToLaunch":@""];
			NSString *dataURL = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"dataURL":@""];
			NSString *encodedURL = @"";
			NSString *alertTitle = @"";
			NSString *alertMessage = @"";
			if([dataURL length] > 1){
				encodedURL =  [dataURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			}
			if([appToLaunch length] > 1 && [encodedURL length] > 3){
				
				//browser, musicStore, appStore
				if([appToLaunch isEqualToString:@"browser"] || [appToLaunch isEqualToString:@"googleMaps"]
                   || [appToLaunch isEqualToString:@"musicStore"] || [appToLaunch isEqualToString:@"appStore"]
                   || [appToLaunch isEqualToString:@"youTube"]){
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:encodedURL]];			
				}				
				
				//google maps
				if([appToLaunch isEqualToString:@"googleMaps"]){
					NSString *toAddress = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", encodedURL];
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:toAddress]];			
				}
				
				//mail
				if([appToLaunch isEqualToString:@"mail"]){
					if([appDelegate.rootApp.rootDevice canSendEmails]){
						NSString *emailAddress = [NSString stringWithFormat:@"mailto:%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailAddress]];			
					}else{
						alertTitle = NSLocalizedString(@"emailsNotSupportedTitle", "Email Not Supported");
						alertMessage = NSLocalizedString(@"emailsNotSupportedMessage", "Sending emails is not supported on this device");
					}
				}
                
				//dialer
				if([appToLaunch isEqualToString:@"dialer"]){
					if([appDelegate.rootApp.rootDevice canMakePhoneCalls]){
						NSString *phoneNumber = [NSString stringWithFormat:@"tel://%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];			
					}else{
						alertTitle = NSLocalizedString(@"callsNotSupportedTitle", "Calls Not Supported");
						alertMessage = NSLocalizedString(@"emailsNotSupportedTitle", "Placing calls is not supported on this device");
					}
				}
                
				//sms
				if([appToLaunch isEqualToString:@"sms"]){
					if([appDelegate.rootApp.rootDevice canSendSMS]){
						NSString *smsAddress = [NSString stringWithFormat:@"sms:%@", encodedURL];
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:smsAddress]];			
					}else{
						alertTitle = NSLocalizedString(@"textMessageNotSupportedTitle", "SMS Not Supported");
						alertMessage = NSLocalizedString(@"textMessageNotSupportedMessage", "Sending SMS / Text messages is not supported on this device");
					}
				}	

                
				//book store URL
				if([appToLaunch isEqualToString:@"bookStore"]){
                    NSString *iBooksAddress = [NSString stringWithFormat:@"itms-books:%@", encodedURL];
                    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:iBooksAddress]]) {			
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iBooksAddress]];			
					}else{
						alertTitle = NSLocalizedString(@"customURLSchemeNotSupported", "Can't Open Application");
						alertMessage = NSLocalizedString(@"customURLSchemeNotSupportedMessage", "This device cannot open the application with this URL Scheme");
					}                    
        		}	
                
                
				//customURLScheme
				if([appToLaunch isEqualToString:@"customURLScheme"]){
					if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:encodedURL]]) {			
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:encodedURL]];			
					}else{
						alertTitle = NSLocalizedString(@"customURLSchemeNotSupported", "Can't Open Application");
						alertMessage = NSLocalizedString(@"customURLSchemeNotSupportedMessage", "This device cannot open the application with this URL Scheme");
					}
				}		
				
				//show alert?
				if([alertMessage length] > 3){
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle 
                                                            message:alertMessage 
                                                            delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                            otherButtonTitles:nil];
					[alertView setTag:105];
					[alertView show];
					[alertView release];
				}
				
                
			}//dataURL, encodedURL length
            
			//bail
			return;		
            
		}//end if launching native app
        
        
		////////////////////////////////////////////////////////////////////////
		//if we are here, we are loading a new screen object
        UIViewController *theNextViewController = [self initViewControllerForScreen:theScreenData];
        
        
		//if we have nav controller and a view controller
		if(theNavController != nil && theNextViewController != nil){
            
			//if the screen we are loading has an audio track, spawn a new thread to load it...
			if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 3){
				
				if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 3){
					[BT_debugger showIt:self:[NSString stringWithFormat:@"this screen uses a background sound from the project bundle: %@", [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""]]];
				}else{
					[BT_debugger showIt:self:[NSString stringWithFormat:@"this screen uses a background sound from a URL: %@", [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""]]];
				}
				
				//load audio for this screen in another thread
				[NSThread detachNewThreadSelector: @selector(loadAudioForScreen:) toTarget:appDelegate withObject:theScreenData];
                
			}		
            
			//always hide the lower tab-bar when screens transition in unless it's overridden
			BOOL hideBottomBar = FALSE;
			if([[BT_strings getJsonPropertyValue:appDelegate.rootApp.rootTheme.jsonVars:@"hideBottomTabBarWhenScreenLoads":@""] isEqualToString:@"1"]){
				hideBottomBar = TRUE;
			}
			if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"hideBottomTabBarWhenScreenLoads":@""] length] > 0){
				if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"hideBottomTabBarWhenScreenLoads":@"1"] isEqualToString:@"0"]){
					hideBottomBar = FALSE;
				}else{
					hideBottomBar = TRUE;
				}
			}
			
			//always hide the bottom tab-bar for quiz screens
			if([[theScreenData itemType] isEqualToString:@"BT_screen_quiz"]){
				hideBottomBar = TRUE;
			}
            
			//hide bottom bar if needed
			[theNextViewController setHidesBottomBarWhenPushed:hideBottomBar];
			
			//always hide the "back" button. A custom button is added in BT_viewUtilities.configureBackgroundAndNavBar
			[theNextViewController.navigationItem setHidesBackButton:TRUE];
            
			//change this view controllers navigation bar background-color to this screens value
			[theNavController.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreenData]];
            
			//trigger our custom pushViewController method
			[theNavController pushViewController:theNextViewController animated:YES];
            
		}
		
	}//allowNextScreen	
}


/* 
 This method fires on back-button clicks.
 */
+(void)handleLeftButton:(BT_item *)parentScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"handleLeftButton for screen. nickname: \"%@\" itemId: %@ itemType: %@", [parentScreenData itemNickname], [parentScreenData itemId], [parentScreenData itemType]]];
    
	//appDelegate remebers the screen we are unloading.
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	BT_item *previousScreenData = [appDelegate.rootApp previousScreenData];
	
	//if the screen we are coming from has an audio track, it may have "audioStopsOnScreenExit"...
	if([[BT_strings getJsonPropertyValue:parentScreenData.jsonVars:@"audioStopsOnScreenExit":@""] isEqualToString:@"1"]){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"stopping audio on screen exit for screen with itemId:%@", [parentScreenData itemId]]];
		if(appDelegate.audioPlayer != nil){
			[appDelegate.audioPlayer stopAudio];
		}
	}		
    
	//nav controller depends on layout
	BT_rotatingNavController *theNavController;
	if([appDelegate.rootApp.tabs count] > 0){
		theNavController = (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
	}else{
		theNavController = [appDelegate.rootApp rootNavController];
	}
	
	//change this view controllers navigation bar background-color "back" to the value set in the "previous screen"
	[theNavController.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:previousScreenData]];
	
	//our custom navigation controller has over-riden the popViewControllerAnimated method. It refers to the menu item that 
	//was "remembered" in the rootApp when it was tapped. It uses this info to determine how to "reverse" the transition.
	[theNavController popViewControllerAnimated:YES];
    
}


/* 
 This method fires on nav bar "right button" clicks. It builds a temporary BT_item object to pass to the
 tapForMenuItem method. This is the same method that fires when a normal button or menu item is tapped. The method
 requires us to pass in a menuItem object, that's the only reason we build our own.
 */

+(void)handleRightButton:(BT_item *)parentScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"handleRightButton for screen with nickname: \"%@\" itemId: %@ itemType: %@", [parentScreenData itemNickname], [parentScreenData itemId], [parentScreenData itemType]]];
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//get possible itemId of the screen to load
	NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:parentScreenData.jsonVars:@"navBarRightButtonTapLoadScreenItemId":@""];
	
	//get possible nickname of the screen to load
	NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:parentScreenData.jsonVars:@"navBarRightButtonTapLoadScreenNickname":@""];
    
	//bail if load screen = "none"
	if([loadScreenItemId isEqualToString:@"none"]){
		return;
	}
    
	//check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
	BT_item *screenObjectToLoad = nil;
	if([loadScreenItemId length] > 1){
		screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
	}else{
		if([loadScreenNickname length] > 1){
			screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
		}else{
			if([parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapLoadScreenObject"]){
				screenObjectToLoad = [[BT_item alloc] init];
				[screenObjectToLoad setItemId:[[parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapLoadScreenObject"] objectForKey:@"itemId"]];
				[screenObjectToLoad setItemNickname:[[parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapLoadScreenObject"] objectForKey:@"itemNickname"]];
				[screenObjectToLoad setItemType:[[parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapLoadScreenObject"] objectForKey:@"itemType"]];
				[screenObjectToLoad setJsonVars:[parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapLoadScreenObject"]];
			}								
		}
	}
    
	//if right button is "home" or "goHome"
	if([loadScreenItemId isEqualToString:@"home"] || [loadScreenItemId isEqualToString:@"goHome"]){
        
		//pop to root view controller...
		BT_rotatingNavController *theNavController;
		if([appDelegate.rootApp.tabs count] > 0){
			theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
		}else{
			theNavController = [appDelegate.rootApp rootNavController];
		}	
		[theNavController popToRootViewControllerAnimated:YES];
		
		//bail
		return;
	}
	
	
	//if it's "showAudioControls"
	if([loadScreenItemId isEqualToString:@"showAudioControls"]){
		
		//delegate controls audio, bail
		[appDelegate showAudioControls];
		return;
		
	}
    
	//load next screen if it's not nil
	if(screenObjectToLoad != nil){
        
		//build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
		BT_item *tmpMenuItem = [[BT_item alloc] init];
        
		//build an NSDictionary of values for the jsonVars property
		NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId", 
                                       [parentScreenData.jsonVars objectForKey:@"navBarRightButtonTapTransitionType"], @"transitionType",
                                       nil];	
		[tmpMenuItem setJsonVars:tmpDictionary];
		[tmpMenuItem setItemId:@"0"];
        
		//load the next screen	
		[self handleTapToLoadScreen:parentScreenData:tmpMenuItem:screenObjectToLoad];
		[tmpMenuItem release];
		
	}else{
		//show message
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
	}
	
	
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//place call

+(void)placeCallWithScreenData:(BT_item *)theScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"placeCallWithScreenData nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
	
	//WE WILL NOT BE HERE IF THE DEVICE IS NOT CAPABLE OF MAKING CALLS
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	if([appDelegate.rootApp.rootDevice canMakePhoneCalls] == TRUE){
		

        /* 
         IMPORTANT. Numbers should not contain parenthesis, dashes are better.
         Exmaple: 123-123-1234 is better than (123)123-1234
         Not sure why but crazy results happen sometimes?
         */		
        
        //NSString *numberToCall = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"number":@""];
        NSString *numberToCall = [NSString stringWithFormat:@"tel:%@", [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"number":@""]];
        if([numberToCall length] > 5){
            
            #if TARGET_IPHONE_SIMULATOR
                        NSLog(@"APPIRATER NOTE: not supported on the iOS simulator.");
                        
                        //show alert
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"callsNotSupportedTitle", "Calls Not Supported") 
                                                                            message:NSLocalizedString(@"callsNotSupportedMessage", "Placing calls is not supported on this device") 
                                                                           delegate:nil
                                                                  cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                                  otherButtonTitles:nil];
                        [alertView show];
                        [alertView release];
                        
            #else
                        //not in simulator...
                        
                        
                        [BT_debugger showIt:self:[NSString stringWithFormat:@"launching dialer: %@", numberToCall]];
                        if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:numberToCall]]){
                            
                            //show alert
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil 
                                                                                message:NSLocalizedString(@"errorTitle", "~ Error ~") 
                                                                               delegate:nil
                                                                      cancelButtonTitle:NSLocalizedString(@"ok", "OK") 
                                                                      otherButtonTitles:nil];
                            [alertView show];
                            [alertView release];
                            
                        }
                        
            #endif            
            
                
        }else{
            [BT_debugger showIt:self:[NSString stringWithFormat:@"Could not launch dialer, no phone number?%@", @""]];
            
        }
        
  		
	}else{
		
		//show alert...
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"callsNotSupportedTitle", "Calls Not Supported") 
                                                        message:NSLocalizedString(@"callsNotSupportedMessage", "You need to be using an iPhone to make phone calls") 
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
		[alert show];
		[alert release];	
        
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//Email Composer methods. The delegate is the navigation controller for the screen

//sendEmailWithScreenData
+(void)sendEmailWithScreenData:(BT_item *)theScreenData:(UIImage *)imageAttachment:(NSString *)imageAttachmentName{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"sendEmailWithScreenData nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
    
	//WE SHOULD NOT BE HERE IF THE DEVICE IS NOT CAPABLE OF SENDING EMAILS
    
	//mail composer
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if(mailClass != nil){
		if([mailClass canSendMail]){
			
			//find the nav controller
			revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
			BT_rotatingNavController *theNavController;
			if([appDelegate.rootApp.tabs count] > 0){
				theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
			}else{
				theNavController = (BT_rotatingNavController *)[appDelegate.rootApp rootNavController];
			}
            
			MFMailComposeViewController *picker = [[[MFMailComposeViewController alloc] init] autorelease];
			picker.mailComposeDelegate = theNavController;
            
			//get subject
			if([theScreenData.jsonVars objectForKey:@"emailSubject"]){
				[picker setSubject:[theScreenData.jsonVars objectForKey:@"emailSubject"]];
			}
			
			//get to address
			if([theScreenData.jsonVars objectForKey:@"emailToAddress"]){
				NSArray *toRecipients = [NSArray arrayWithObject:[theScreenData.jsonVars objectForKey:@"emailToAddress"]]; 
				[picker setToRecipients:toRecipients];
			}	
			
			//attach image if included
			if(imageAttachment != nil){
				NSData *imageData = UIImageJPEGRepresentation(imageAttachment, 1.0);
				if(imageData){
					[picker addAttachmentData:imageData mimeType:@"image/jpeg" fileName:imageAttachmentName];
				}
			}				
			
			
			//get body
			if([theScreenData.jsonVars objectForKey:@"emailMessage"]){
                
				NSString *emailMessage = [theScreenData.jsonVars objectForKey:@"emailMessage"]; 
				[picker setMessageBody:emailMessage isHTML:NO];
                
			}else{
                
				//if we have a subject set...
				NSString *emailSubject = @"";
				if([theScreenData.jsonVars objectForKey:@"emailSubject"]){
					emailSubject = [theScreenData.jsonVars objectForKey:@"emailSubject"];			
				}
                
				//empty message body or the imageTitle of an image we are emailing (if it has an imageTitle)..
				NSString *imageTitle = [BT_strings getPrefString:@"emailImageTitle"];
				if([emailSubject length] < 1){
					[picker setSubject:imageTitle];
				}
				
				//erase emailImageTitle for next time...
				[BT_strings setPrefString:@"emailImageTitle":@""];
                
			}	
			
			//show it
			[theNavController presentModalViewController:picker animated:YES];
			[picker.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreenData]];
            
			
		}//can send mail
	}//if mail class
    
}


//sendEmailWithAttachmentFromScreenData
+(void)sendEmailWithAttachmentFromScreenData:(BT_item *)theScreenData:(NSData *)theAttachmentData:(NSString *)attachmentName{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"sendEmailWithAttachmentFromScreenData nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
    
	//mail composer
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if(mailClass != nil){
		if([mailClass canSendMail]){
			
			//find the nav controller
			revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
			BT_rotatingNavController *theNavController;
			if([appDelegate.rootApp.tabs count] > 0){
				theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
			}else{
				theNavController = (BT_rotatingNavController *)[appDelegate.rootApp rootNavController];
			}
            
			MFMailComposeViewController *picker = [[[MFMailComposeViewController alloc] init] autorelease];
			picker.mailComposeDelegate = theNavController;
            
			//set possible subject
			if([theScreenData.jsonVars objectForKey:@"emailSubject"]){
				[picker setSubject:[theScreenData.jsonVars objectForKey:@"emailSubject"]];
			}
			
			//set possible to address
			if([theScreenData.jsonVars objectForKey:@"emailToAddress"]){
				NSArray *toRecipients = [NSArray arrayWithObject:[theScreenData.jsonVars objectForKey:@"emailToAddress"]]; 
				[picker setToRecipients:toRecipients];
			}	
			
            //set possible email message
			if([theScreenData.jsonVars objectForKey:@"emailMessage"]){
				NSString *emailMessage = [theScreenData.jsonVars objectForKey:@"emailMessage"]; 
				[picker setMessageBody:emailMessage isHTML:NO];
			}
 			
            
			//set possible attachment
			if(theAttachmentData != nil){
				[picker addAttachmentData:theAttachmentData mimeType:@"application/octet-stream" fileName:attachmentName];
			}				
			
			
			//show it
			[theNavController presentModalViewController:picker animated:YES];
			[picker.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreenData]];
            
			
		}//can send mail
	}//if mail class
    
}



//send email with toAddress (triggered when link with "mailto" is clicked in a web-view)
+(void)sendEmailFromWebLink:(BT_item *)theScreenData:(NSString *)toAddress{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"sendEmailFromWebView: %@", toAddress]];
    
	//mail composer
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if(mailClass != nil){
		if([mailClass canSendMail]){
			
			//find the nav controller
			revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
			BT_rotatingNavController *theNavController;
			if([appDelegate.rootApp.tabs count] > 0){
				theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
			}else{
				theNavController = (BT_rotatingNavController *)[appDelegate.rootApp rootNavController];
			}		
			
			MFMailComposeViewController *picker = [[[MFMailComposeViewController alloc] init] autorelease];
			picker.mailComposeDelegate = theNavController;
            
			//set to address
			NSArray *toRecipients = [NSArray arrayWithObject:toAddress]; 
			[picker setToRecipients:toRecipients];
			
			//empty message body
			NSString *emailBody = @"";
			[picker setMessageBody:emailBody isHTML:NO];
            
			//style the model view like it's parent viewController
			[theNavController presentModalViewController:picker animated:YES];
			[picker.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreenData]];
			
		}//can send mail
	}else{
        
		
        
	}//if mail class
	
}



//////////////////////////////////////////////////////////////////////////////////////////////////
//SMS Composer method. The delegate is the navigation controller for the screen

//sms
+(void)sendTextMessageWithScreenData:(BT_item *)theScreenData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"sendTextMessageWithScreenData nickname: \"%@\" itemId: %@ itemType: %@", [theScreenData itemNickname], [theScreenData itemId], [theScreenData itemType]]];
    
	//WE SHOULD NOT BE HERE IF THE DEVICE IS NOT CAPABLE OF SENDING SMS MESSAGES
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//sms message composer
	if([appDelegate.rootApp.rootDevice canSendSMS]){
		
		//need to use classFromString method so < 4.0 devices don't crash!
		Class smsClass = (NSClassFromString(@"MFMessageComposeViewController"));
		if(smsClass != nil && [MFMessageComposeViewController canSendText]){
            
			MFMessageComposeViewController *picker = [[[MFMessageComposeViewController alloc] init] autorelease];
			if([MFMessageComposeViewController canSendText]){
				
				//find the nav controller
				revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
				BT_rotatingNavController *theNavController;
				if([appDelegate.rootApp.tabs count] > 0){
					theNavController =  (BT_rotatingNavController *)[appDelegate.rootApp.rootTabBarController selectedViewController];
				}else{
					theNavController = [appDelegate.rootApp rootNavController];
				}
				
				//set delegate
				picker.messageComposeDelegate = theNavController;
                
				//set recipients
				if([theScreenData.jsonVars objectForKey:@"textToNumber"]){
					NSArray *toRecipients = [NSArray arrayWithObject:[theScreenData.jsonVars objectForKey:@"textToNumber"]]; 
					[picker setRecipients:toRecipients];
				}
                
				//set message body
				if([theScreenData.jsonVars objectForKey:@"textMessage"]){
					[picker setBody:[theScreenData.jsonVars objectForKey:@"textMessage"]];
				}
                
				//show it
				[theNavController presentModalViewController:picker animated:YES];
				[picker.navigationBar setTintColor:[BT_viewUtilities getNavBarBackgroundColorForScreen:theScreenData]];
				
                
			}
		}
		
	}//device can send text
	
	
}

@end















