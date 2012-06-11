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
#import "BT_downloader.h"
#import "JSON.h"
#import "BT_strings.h"
#import "BT_fileManager.h"
#import "BT_audioPlayer.h"
#import "BT_dates.h"
#import "BT_color.h"
#import "BT_application.h"
#import "BT_viewControllerManager.h"
#import "BT_debugger.h"
#import "BT_background_view.h"
#import "revmobiossampleapp_appDelegate.h"
#import "RevMobAds.h"

@implementation revmobiossampleapp_appDelegate
@synthesize window, refreshingView, globalBackroundView, spinner, configurationFileName, saveAsFileName, modifiedFileName;
@synthesize configData, rootApp, downloader, showDebugInfo, isDataValid, audioPlayer;
@synthesize soundEffectNames, soundEffectPlayers, allowedInputCharacters, receivedData;


/*
didFinishLaunchingWithOptions
this method fires when the application first launches. This is different than when it becomes
the active application in a multi-tasking environment
*/


-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{    
    
	//set the configuration file name
	configurationFileName = @"BT_config.txt";

	//show debug in output window?
	showDebugInfo = TRUE;
	
	//init the allowed input characters string. ONLY these characters will be allowed in input fields.
	allowedInputCharacters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.@!$";
	
	/*
		Debugging Output
		---------------------------------------------------------------------------
		Set showDebugInfo to TRUE to print details to the console.
		To see the console, choose Run > Show Console while the simulator or a connected device
		is running. Nearly every method has output to show you details about how the program
		is executing. It looks like lots of data (it is), but it's very useful for understanding how
		the application is behaving.
	*/
	
	/*
		Application Configuration File / Data
		---------------------------------------------------------------------------
		One file holds all the configuration data associated with the application. This file must exist
		in the applications bundle (drag it into Xcode if it's not already there). This file is normally
		named BT_config.txt and can be read / edited with a normal text editor. If this configuration data
		uses a dataURL, a remote server will be polled for content changes. Changes will be downloaded and 
		saved locally. Once	this happens, the BT_config.txt file is no longer used and instead the application 
		refers to it's newly downloaded and cached data. In other words, if a dataURL is used then the 
		configuration file in the Xcode project is only referenced so it can find the buzztouchAppId, buzztouchAPIKey,
		and dataURL. After that, it uses the data that was saved from the URL.  
		If no dataURL is provided, the file in the bundle will be read and parsed everytime the app is started.
	*/


	/*
		TURN OFF ZOMBIES BEFORE RELEASING THIS APPLICATION!
		If you're unsure what "debugging zombies" are, ignore this. If you do, be sure to
		turn them off before releasing this application. The NSLog message below prints a reminder
		to the output console if you have left Zombies on. You're using the output console, right?
	*/
		if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")){
			NSString *message = @"";
			message = [message stringByAppendingString:@"\n#####################################################################################################################"];
			message = [message stringByAppendingString:@"\nZOMBIES ENABLED, TURN THIS OFF BEFORE RELEASING THIS APPLICATION!"];
			message = [message stringByAppendingString:@"\nDouble click executables > [app name] > arguments: Remove NSZombieEnabled = YES"];
			message = [message stringByAppendingString:@"\n#####################################################################################################################\n\n"];
			NSLog(@"%@", message);	
		}	


		//initialize a temporary buzztouch app to assign to the rootApp property 
		BT_application *tmpApp = [[BT_application alloc] init];
		
		//initialize a temporary window to assign to the window property
		UIWindow *tmpWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		self.window = tmpWindow;
		[tmpWindow release];
		
		if(!tmpApp){
		
			//show error message
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"errorTitle",@"~ Error ~")
			message:NSLocalizedString(@"appInitError", @"There was a problem initializing the application.") delegate:self
			cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
			[alertView show];
			[alertView release];
			
		}else{
		
			//assign the local app property
			self.rootApp = tmpApp;
			[tmpApp release];
		
			//make the window active
			[self.window makeKeyAndVisible];

			//init audio player in background thread. Do this before building the interface in case home-screen has audio.
			[NSThread detachNewThreadSelector: @selector(initAudioPlayer) toTarget:self withObject:nil];

			//load sound effect players in background thread. Do this before building the interface is case home-screen uses sound effects.
			[NSThread detachNewThreadSelector: @selector(loadSoundEffects) toTarget:self withObject:nil];

			//load the applications data
			[self loadAppData];

		
		} //tmpApp	
		
		//return	
		return TRUE;
		
}

/*
		loadAppData method, where is the app's configuration data?
		-----------------------------------------------------------------------------------
		a) If a cached version of the app's configuration data is available, use that (then check for updates)
		b) If no cached version is available, use the data in the bundle (then check for updates)
		c) If no cached version is available, and no dataURL is provided in the bundle config file, use the bundle config data.
		
*/
-(void)loadAppData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"refreshAppData%@", @""]];	
	
	//set the saveAsFileName and the modified file name (only used if configuration data is pulled from a remote server
	self.saveAsFileName = @"cachedAppConfig.txt";
	self.modifiedFileName = @"appModified.txt";
	self.configData = @"";

	//get the name of the configuration file
	NSString *bundleFileName = [self configurationFileName]; 
	if([bundleFileName length] < 4){
		[BT_debugger showIt:self:@"There is no config.txt file configured in revmobiossampleapp_appDelegate.m?"];
		bundleFileName = @"thereIsNoFileName.txt";
	}
	
	//check for cached version of configuration data
	if([BT_fileManager doesLocalFileExist:self.saveAsFileName]){
	
		//read the configuration data from the cache
		self.configData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"Parsing configuration data from application cache.%@", @""]];
	
	}else{
	
		if([BT_fileManager doesFileExistInBundle:bundleFileName]){
	
			//read the configuration data from the proejct bundle
			self.configData = [BT_fileManager readTextFileFromBundleWithEncoding:configurationFileName:-1];
			[BT_debugger showIt:self:[NSString stringWithFormat:@"Parsing configuration data included in the project bundle.%@", @""]];


			//parse the BT_config.txt file in bundle data. If we don't have a dataURL, 
			//remove the possible cached verion of configuration data so app does not use cached version.
			//This approaches forces the app to use the BT_config.txt file and not the cached data.

			//create dictionary from the JSON string
			SBJsonParser *parser = [SBJsonParser new];
			id jsonData = [parser objectWithString:self.configData];
	   		if(jsonData){
				if([[jsonData objectForKey:@"BT_appConfig"] objectForKey:@"BT_items"]){
					NSArray *tmpItems = [[jsonData objectForKey:@"BT_appConfig"] objectForKey:@"BT_items"];
					NSDictionary *thisApp = [tmpItems objectAtIndex:0];
						if([thisApp objectForKey:@"dataURL"]){
							if([[thisApp objectForKey:@"dataURL"] length] < 1){
								[BT_fileManager deleteFile:saveAsFileName];
							}
						}else{
							[BT_fileManager deleteFile:saveAsFileName];
						}
				}//BT_items
			}//jsonData


		}
	}

	
	//validate the configruation data
	if([self.configData length] > 5){
		
		if(![self.rootApp validateApplicationData:self.configData]){

			//show message in log, delete bogus data from the cache
			[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing application data.%@", @""]];
			[self showAlert:nil:NSLocalizedString(@"appDataInvalid", "The configuration data for this application is invalid.")];

			//delete bogus data (if it was in the cache)
			[BT_fileManager deleteFile:self.saveAsFileName];
		
		}else{
			
			//configure envrionment
			[self configureEnvironmentUsingAppData:self.configData];

		}
		
	}else{
	
		[BT_debugger showIt:self:[NSString stringWithFormat:@"could not read application configuration data.%@", @""]];
		[self showAlert:nil:NSLocalizedString(@"appDataInvalid", "The configuration data for this application is invalid.")];
	
	}
	
}//load data


//builds interface using the apps configuration data
-(void)configureEnvironmentUsingAppData:(NSString *)appData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"configureEnvironmentUsingAppData%@", @""]];

	//if not audio player was already initialized, we are refreshing... kill it.
	if(self.audioPlayer != nil){
		[self.audioPlayer stopAudio];
		[self.audioPlayer.audioPlayer setCurrentTime:0];
	}
	
	//always hide the status bar (themes or screens may show it)
	[[UIApplication sharedApplication] setStatusBarHidden:TRUE animated:FALSE];

	//ask the application to parse the configuration data
	if(![self.rootApp parseJSONData:appData]){

		[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing bundle application data: %@", @""]];
		[self showAlert:nil:NSLocalizedString(@"appParseError", "There was a problem parsing some configuration data. Please make sure that it is well-formed.")];
		
	}else{	

		//remove all previous sub-views (if we are refreshing)
		for (UIView *view in self.window.subviews){
			[view removeFromSuperview];
		}

		//ask the app to build it's inteface
		[self.rootApp buildInterface];
		
		/*
			Background Logic
			-------------------------
			a) A full size view is always present "underneath" the applications view.
			b) If the global theme uses an image or a color, it will always show, else, it will be transparent
			c) If a screen over-rides the global themes background, it will render "over" the themes background.
			d) The view for the background is identified by a tag so individual screens can modify it.
		*/

		CGRect fullSizeFrame = CGRectMake(0, 0, self.window.bounds.size.width, self.window.bounds.size.height);
		globalBackgroundView = [[UIView alloc] initWithFrame:fullSizeFrame];
		globalBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[globalBackgroundView setBackgroundColor:[UIColor clearColor]];
		[globalBackgroundView setTag:1968]; // my favorite number ;-)
		
		//Create a dummy screen object, needed to init a the background view object
		BT_item *dummyScreen = [[BT_item alloc] init];
		[dummyScreen setItemId:@"unusedInThisContext"];
		[dummyScreen setItemType:@"unusedInThisContext"];
		
		//background view object
		BT_background_view *tmpBackground = [[BT_background_view alloc] initWithScreenData:dummyScreen];
		[tmpBackground setTag:9999];
		[globalBackgroundView addSubview:tmpBackground];
		[dummyScreen release];
		[tmpBackground release];
	
		//add app's navigation controller (or tab controller)
		if([self.rootApp.tabs count] > 0){
			[self.rootApp.rootTabBarController.view addSubview:globalBackgroundView];
			[self.rootApp.rootTabBarController.view sendSubviewToBack:globalBackgroundView];
			[self.window addSubview:[self.rootApp.rootTabBarController view]];
			[self.window bringSubviewToFront:[self.rootApp.rootTabBarController view]];
		}else{
			if([self.rootApp.screens count] > 0){
				[self.rootApp.rootNavController.view addSubview:globalBackgroundView];
				[self.rootApp.rootNavController.view sendSubviewToBack:globalBackgroundView];
				[self.window addSubview:[self.rootApp.rootNavController view]];
				[self.window bringSubviewToFront:[self.rootApp.rootNavController view]];
			}
		}
		
		//all done, make sure progress is hidden..
		[self hideProgress];
		
		//if we didn't have any screens, show an error
		if([self.rootApp.screens count] < 1){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This application does not have any screens to display?%@",@""]];
			[self showAlert:nil:NSLocalizedString(@"appNoScreensError", @"No screens to display.")];
			
			//remove cached data (it must be bogus)...
			[BT_fileManager deleteFile:self.saveAsFileName];
			
		}
		
		//report to cloud after a slight delay (so UI doesn't get consufed)
		[self performSelector:@selector(reportToCloud) withObject:nil afterDelay:.3];
		
		
	}//app parsed it's configuration data
}




/*
	This method downloads application configuration data from a remote server.
	The downloader delegate methods at the end of this file handle the results
*/
-(void)downloadAppData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadAppData%@", @""]];

	//make sure we have a dataURL
	if([[self.rootApp dataURL] length] > 3){
	
		//show progress
		[self showProgress];
		
		//the dataURL may contain merge fields...
		NSString *tmpURL = [BT_strings mergeBTVariablesInString:[self.rootApp dataURL]];
		
		//clean up URL
		NSString *escapedUrl = [tmpURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		//download data (when it's done it will continue, see downloadFileCompleted at bottom)
		downloader = [[BT_downloader alloc] init];
		[downloader setSaveAsFileName:[self saveAsFileName]];
		[downloader setSaveAsFileType:@"return"];
		[downloader setUrlString:escapedUrl];
		[downloader setDelegate:self];
		[downloader downloadFile];
	
	}

}


//show progress
-(void)showProgress{
	[BT_debugger showIt:self:@"showProgress"];

		//build a semi-transparent overlay view (it's huge so it covers all screen sizes, regardless of rotation)
		self.refreshingView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		self.refreshingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.refreshingView setBackgroundColor:[UIColor blackColor]];
		[self.refreshingView setAlpha:.75];

		//build the spinner
		self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		self.spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[self.spinner startAnimating];
		[self.spinner setCenter:[self.refreshingView center]];
		[self.refreshingView addSubview:spinner];
		
		//add the view to the window
		[self.window addSubview:refreshingView];
		[self.window bringSubviewToFront:refreshingView];
}

//hide progress
-(void)hideProgress{
	[BT_debugger showIt:self:@"hideProgress"];
	if(refreshingView != nil){
		[refreshingView removeFromSuperview];
		refreshingView = nil;
	}
	if(spinner != nil){
		[spinner removeFromSuperview];
		spinner = nil;
	}
}




//helper method to show alerts
-(void)showAlert:(NSString *)theTitle:(NSString *)theMessage{
	[self hideProgress];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:theTitle message:theMessage delegate:self
	cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


//when app becomes active again
- (void)applicationDidBecomeActive:(UIApplication *)application{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"applicationDidBecomeActive%@", @""]];
		
	//make sure we have an app...
	if(self.rootApp != nil){
	
		//report to cloud (not all apps do this)
		[self reportToCloud];
	
		//if we have a location manager, re-set it's "counter" and turn it back on.
		if(self.rootApp.rootLocationManager != nil){
			[self.rootApp.rootLocationManager setUpdateCount:0];
			[self.rootApp.rootLocationManager.locationManager startUpdatingLocation];
		}
		
	}
    NSString *REVMOB_ID = @"4f340cc09dcb890003003a6a";
    [RevMobAds showPopupWithAppID:REVMOB_ID withDelegate:nil];
    [RevMobAds showFullscreenAdWithAppID:REVMOB_ID];
}

/*
	This method makes a simple http request to a remote server. It's primary purpose is to 
	track users, devices, and application updates. Not all users like this - be sure to honor their requests to
	prevent this. Do this by using a settings screen and give them a choice to turn off
	location / device tracking. If a user turns of device tracking, BT_strings does not
	merge location information in URL's.
*/

-(void)reportToCloud{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"reportToCloud%@", @""]];
	
	//app's configuration data must have  a "dataURL" and a "reportToCloudURL"...
	NSString *useURL = @"";
	if([self.rootApp.jsonVars objectForKey:@"dataURL"] && [self.rootApp.jsonVars objectForKey:@"reportToCloudURL"]){
		if([[self.rootApp.jsonVars objectForKey:@"dataURL"] length] > 3 && [[self.rootApp.jsonVars objectForKey:@"reportToCloudURL"] length] > 3){
			useURL = [self.rootApp.jsonVars objectForKey:@"reportToCloudURL"];
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"not reporting to cloud, no reportToCloudURL%@", @""]];
		}
	}else{
		[BT_debugger showIt:self:[NSString stringWithFormat:@"not reporting to cloud, no reportToCloudURL%@", @""]];
	}
	
	if([useURL length] > 3){
	
		//the dataURL may contain merge fields...
		NSString *tmpURL = [BT_strings mergeBTVariablesInString:useURL];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"reporting to cloud at : %@", useURL]];
		
		//clean-up URL, encode as UTF8
		NSURL *escapedURL = [NSURL URLWithString:[tmpURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];	

		//make the http request
		NSMutableURLRequest  *theRequest = [NSMutableURLRequest requestWithURL:escapedURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];	
		[theRequest setHTTPMethod:@"GET"];  
		NSURLConnection *theConnection;
		if((theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self])){
			//prepare to accept data
			receivedData = [[NSMutableData data] retain];
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"reportToCloud error? Could not init request%@", @""]];
		}
	}
}

//delegate methods for reportToCloud data-fetch
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[receivedData setLength:0];	
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	if(data != nil){
		[receivedData appendData:data];
	}
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"reportToCloud FAILED with error: %@", [error localizedDescription]]];
	[connection release];
	connection = nil;
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
	[connection release];
	connection = nil;
	
	//save data as "lastModified" file
	NSString *dStringData = [[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];  
	if([dStringData length] > 3){
	
		//returned data format: {"lastModifiedUTC":"2011-02-22 02:13:25"}
		NSString *lastModified = @"";
		NSString *previousModified = @"";
		
		//parse returned JSON data
		SBJsonParser *parser = [SBJsonParser new];
  		id jsonData = [parser objectWithString:dStringData];
  		if(jsonData){
			if([jsonData objectForKey:@"lastModifiedUTC"]){
				lastModified = [jsonData objectForKey:@"lastModifiedUTC"];
				[BT_debugger showIt:self:[NSString stringWithFormat:@"lastModified (value on server): %@", lastModified]];
			}
		}
		
		//parse previous saved data
		if([BT_fileManager doesLocalFileExist:self.modifiedFileName]){
			NSString *previousData = [BT_fileManager readTextFileFromCacheWithEncoding:self.modifiedFileName:-1];
			SBJsonParser *parser = [SBJsonParser new];
  			id jsonData = [parser objectWithString:previousData];
  			if(jsonData){
				if([jsonData objectForKey:@"lastModifiedUTC"]){
					previousModified = [jsonData objectForKey:@"lastModifiedUTC"];
					[BT_debugger showIt:self:[NSString stringWithFormat:@"previousModified (value on device): %@", previousModified]];
				}
			}
		}
				
		//save a copy of the lastModified text for next time..
		BOOL saved = [BT_fileManager saveTextFileToCacheWithEncoding:dStringData:self.modifiedFileName:-1];
		if(saved){};
			
		//if value are not emtpy, and different....ask user to confirm refresh...
		if([lastModified length] > 3 && [previousModified length] > 3){
			if(![lastModified isEqualToString:previousModified]){
				
				//show alert with confirmation...
				UIAlertView *modifiedAlert = [[UIAlertView alloc] 
					initWithTitle:nil 
					message:NSLocalizedString(@"updatesAvailable", "This app's content has changed, would you like to refresh?") 
					delegate:self 
					cancelButtonTitle:NSLocalizedString(@"no", "NO") 
					otherButtonTitles:NSLocalizedString(@"yes", "YES"), nil];
				[modifiedAlert setTag:12];
				[modifiedAlert show];
				[modifiedAlert release];

			}
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"%@ does not exist in the cache. Not checking for updates.", self.modifiedFileName]];
		
		}
	}
	
	//clean up data
	[dStringData release];
	
}

//alert view delgate methods
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"alertView clickedButtonAtIndex: %d", buttonIndex]];
	int alertTag = [alertView tag];
	
	// 0 = no, 1 = yes
	if(buttonIndex == 0){
		//do nothing...
	}
	if(buttonIndex == 1 && alertTag == 12){
		//refresh entire app contents
		[self downloadAppData];
	}
	
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods. Called when refreshing app data.
-(void)downloadFileStarted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
}
-(void)downloadFileCompleted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileCompleted%@", @""]];
	[self hideProgress];
	
	//NSLog(@"%@", $message);
	//message returns from downloader is the application data or an error message
	if([message rangeOfString:@"ERROR-1968" options:NSCaseInsensitiveSearch].location != NSNotFound){
		
		[BT_debugger showIt:self:[NSString stringWithFormat:@"the download process reported an error?: %@", message]];
		[self showAlert:nil:NSLocalizedString(@"downloadError", @"There was a problem downloading some data from the internet. If you're not connected to the internet, connect then try again.")];

	}else{
	
		//save the version we just downloaded...
		if([BT_fileManager saveTextFileToCacheWithEncoding:message:[self saveAsFileName]:-1]){
			
			//the data we just got must be valid
			if([self.rootApp validateApplicationData:message]){
					
				//delete previously cached data (this does not remove the config file we just created)
				[BT_fileManager deleteAllLocalData];
			
				//rebuild environment using the data we just got
				[self configureEnvironmentUsingAppData:message];
			
			}else{
				
				[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing downloaded app config data%@", @""]];
				[self showAlert:nil:NSLocalizedString(@"appParseError", @"There was a problem parsing the app's configuration data. Please make sure that it is well-formed.")];
			
			}
			
		}else{

			[BT_debugger showIt:self:[NSString stringWithFormat:@"error saving downloaded app config data%@", @""]];
			[self showAlert:nil:NSLocalizedString(@"errorSavingData", @"There was a problem saving some data to the devices cache?")];

		}
		
	}//no error
	
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//tab-bar controller delegate methods (we may not use these if we don't have a tabbed app)
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"tabBarController selected: %i", [tabBarController selectedIndex]]];

	//play possible sound effect
	if(self.rootApp != nil){
		if([self.rootApp.tabs count] > 0){

			//always hide the audio controls when changing tabs
			[self hideAudioControls];

			//data associated with the tab we just tapped
			BT_item *selectedTabData = [self.rootApp.tabs objectAtIndex:[tabBarController selectedIndex]];
		
			//the screen we are leaving may have an audio file that is
			//configured with "audioStopsOnScreenExit" so we may need to turn it off
			if([[BT_strings getJsonPropertyValue:self.rootApp.currentScreenData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:self.rootApp.currentScreenData.jsonVars:@"audioFileURL":@""] length] > 3){
				[BT_debugger showIt:self:[NSString stringWithFormat:@"stopping sound on screen exit%@", @""]];
				if([[BT_strings getJsonPropertyValue:self.rootApp.currentScreenData.jsonVars:@"audioStopsOnScreenExit":@"0"] isEqualToString:@"1"]){
					if(self.audioPlayer != nil){
						[self.audioPlayer stopAudio];
					}
				}
			}		
			
			//data associated with the screen we are about to load
			NSString *screenToLoadId = [BT_strings getJsonPropertyValue:selectedTabData.jsonVars:@"homeScreenItemId":@""];
			BT_item *screenToLoadData = [self.rootApp getScreenDataByItemId:screenToLoadId];
		
			//play possible sound effect attached to this menu item
			if([[BT_strings getJsonPropertyValue:selectedTabData.jsonVars:@"soundEffectFileName":@""] length] > 3){
				[self playSoundEffect:[BT_strings getJsonPropertyValue:selectedTabData.jsonVars:@"soundEffectFileName":@""]];
			}
			
			if([[BT_strings getJsonPropertyValue:screenToLoadData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:screenToLoadData.jsonVars:@"audioFileURL":@""] length] > 3){
				
				//start audio in different thread to prevent UI blocking
				[NSThread detachNewThreadSelector: @selector(loadAudioForScreen:) toTarget:self withObject:screenToLoadData];

			}
			
			//remember the screen we are loading in the rootApp
			[self.rootApp setCurrentScreenData:screenToLoadData];
			
		}
	}
	
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//audio player (screen background sound) methods

//inits audio player
-(void)initAudioPlayer{
	
	//this runs in it's own thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc ] init];
	
		[BT_debugger showIt:self:[NSString stringWithFormat:@"initAudioPlayer in background thread %@", @""]];
	
		//create the player
		self.audioPlayer = [[BT_audioPlayer alloc] initWithScreenData:nil];
		[self.audioPlayer.view setTag:999];
		
	//release pool
	[pool release];
	
}

//load audio for screen
-(void)loadAudioForScreen:(BT_item *)theScreenData{

	//this runs in it's own thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
		[BT_debugger showIt:self:[NSString stringWithFormat:@"loadAudioForScreen with itemId: %@", [theScreenData itemId]]];
	
	
		//theScreenData must have an "audioFileName" or an "audioFileURL" or ignore this...
		if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""] length] > 3 || [[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""] length] > 3){
	
			//tell audio player to load itself (this can take a moment depending on the size of the audio file)
			//[self.audioPlayer loadAudioForScreen];
			if(self.audioPlayer != nil){
				
				
				//get the file name for the existing audio player...
				NSString *playingAudioFileName = [BT_strings getJsonPropertyValue:self.audioPlayer.screenData.jsonVars:@"audioFileName":@""];
				NSString *playingAudioFileURL = [BT_strings getJsonPropertyValue:self.audioPlayer.screenData.jsonVars:@"audioFileURL":@""];
				if(playingAudioFileName.length < 3 && playingAudioFileURL.length > 3){
					playingAudioFileName = [BT_strings getFileNameFromURL:playingAudioFileURL];
				}
								
				//figure out the next file name if we're using a URL
				NSString *nextAudioFileName = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileName":@""];
				NSString *nextAudioFileURL = [BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"audioFileURL":@""];
				if(nextAudioFileName.length < 3 && nextAudioFileURL.length > 3){
					nextAudioFileName = [BT_strings getFileNameFromURL:nextAudioFileURL];
				}				
				
				//if the audio player already has the same audio track loaded...ignore
				if(![playingAudioFileName isEqualToString:nextAudioFileName]){
				
					[self.audioPlayer stopAudio];
					[self.audioPlayer loadAudioForScreen:theScreenData];
				
				}else{
				
					//the same track is already loaded...make sure it's playing
					[BT_debugger showIt:self:[NSString stringWithFormat:@"audio track already loaded: %@", nextAudioFileName]];
					[self.audioPlayer startAudio];
					
				}
			}
		
		}//audioFileName

	//release pool
	[pool release];

}


//show audio controls on top of the current view
-(void)showAudioControls{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"showAudioControls %@", @""]];
	
	//show the audio players view
	if(self.audioPlayer != nil){
		
		//we need to know what view to show it in...
		BT_rotatingNavController *theNavController;
		if([self.rootApp.tabs count] > 0){
			theNavController =  (BT_rotatingNavController *)[self.rootApp.rootTabBarController selectedViewController];
		}else{
			theNavController = [self.rootApp rootNavController];
		}		
		
		//find center of screen for current device orientation
		CGPoint tmpCenter;
		UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
		if(deviceOrientation == UIInterfaceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight) {
			tmpCenter = CGPointMake([self.rootApp.rootDevice deviceHeight] / 2, ([self.rootApp.rootDevice deviceWidth] / 2));;
		}else{
			tmpCenter = CGPointMake([self.rootApp.rootDevice deviceWidth] / 2, [self.rootApp.rootDevice deviceHeight] / 2);;
		}
		
		//if the view isn't already on the nav controller..add it. audioPlayer view has tag "999"
		BOOL havePlayerView = FALSE;
		for(UIView *view in theNavController.view.subviews) {
		   	if([view tag] == 999){
				havePlayerView = TRUE;
				break;			
		   	}
		}
		//add the subview to this controller if we don't already have it
		if(!havePlayerView){
			[theNavController.view addSubview:[self.audioPlayer view]];
		}
		
		//bring it to the front
		[theNavController.view bringSubviewToFront:[self.audioPlayer view]];

		//makie it visible
		[self.audioPlayer.view setHidden:FALSE];
		
		//center it
		[self.audioPlayer.view setCenter:tmpCenter];
  		
	}
	
}


//hide audio controls
-(void)hideAudioControls{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"hideAudioControls %@", @""]];

	//move the the audio players view off the screen and hide it
	if(self.audioPlayer != nil){
	
		//we need to know what view to hide it from...
		BT_rotatingNavController *theNavController;
		if([self.rootApp.tabs count] > 0){
			theNavController =  (BT_rotatingNavController *)[self.rootApp.rootTabBarController selectedViewController];
		}else{
			theNavController = [self.rootApp rootNavController];
		}		
		
		//find the audioPlayer's view on the controller. audioPlayer view has tag "999"
		for(UIView *view in theNavController.view.subviews) {
		   	if([view tag] == 999){
				
				//move it, hide it
				[view setCenter:CGPointMake(-500, -500)];
				[view setHidden:TRUE];
				break;			
		   	}
		}

	}

}


///////////////////////////////////////////////////////////////////////
//sound effect methods

//load sound effects
-(void)loadSoundEffects{
	//this runs in it's own thread
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ];
	
    [BT_debugger showIt:self:[NSString stringWithFormat:@"loadSoundEffects SOUNDS NOT LOADING. SEE appDelegete.m, line 846 %@", @""]];
    
	
	//fill an array of sound effect file names
	self.soundEffectNames = [[NSMutableArray alloc] init];	
	
    /*
    [self.soundEffectNames addObject:@"basso.mp3"];
	[self.soundEffectNames addObject:@"blow.mp3"];
	[self.soundEffectNames addObject:@"bottle.mp3"];
	[self.soundEffectNames addObject:@"frog.mp3"];
	[self.soundEffectNames addObject:@"funk.mp3"];
	[self.soundEffectNames addObject:@"glass.mp3"];
	[self.soundEffectNames addObject:@"hero.mp3"];
	[self.soundEffectNames addObject:@"morse.mp3"];
	[self.soundEffectNames addObject:@"ping.mp3"];
	[self.soundEffectNames addObject:@"pop.mp3"];
	[self.soundEffectNames addObject:@"purr.mp3"];
	[self.soundEffectNames addObject:@"right.mp3"];
	[self.soundEffectNames addObject:@"sosumi.mp3"];
	[self.soundEffectNames addObject:@"submarine.mp3"];
	[self.soundEffectNames addObject:@"tink.mp3"];
     */
    
	//setup audio session for background sounds. Allow iPod to continue if it's already playing.
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
	[[AVAudioSession sharedInstance] setActive: YES error: nil];

	//fill an array of pre-loaded sound effect players
	self.soundEffectPlayers = [[NSMutableArray alloc] init];	
	for(int x = 0; x < [self.soundEffectNames count]; x++){
	
		NSString *theFileName = [self.soundEffectNames objectAtIndex:x];
		if([BT_fileManager doesFileExistInBundle:theFileName]){
			NSURL *soundFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], theFileName]];
			NSError *error;
			AVAudioPlayer *tmpPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileUrl error:&error];
			[tmpPlayer setNumberOfLoops:0];
			[tmpPlayer prepareToPlay];
			[tmpPlayer setDelegate:self];
			[self.soundEffectPlayers addObject:tmpPlayer];
			[tmpPlayer release];
		}
		
	}
	
    
	//release pool
	[pool release];
	
}

-(void)playSoundEffect:(NSString *)theFileName{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"playSoundEffect %@", theFileName]];
	if([theFileName length] > 3){
	
		/*
			play sound effect logic
			a) Check the soundEffectNames array for the file name
			b) if it exists, we already instantiated an audio-player object in the soundEffectPlayers array
			c) Find the index of the player, then play it
	
		*/
		
		if([self.soundEffectNames containsObject:theFileName]){
			int playerIndex = [self.soundEffectNames indexOfObject:theFileName];
			//we already initialized a player for this sound. Find it, play it.
			AVAudioPlayer *tmpPlayer = (AVAudioPlayer *)[self.soundEffectPlayers objectAtIndex:playerIndex];
			if(tmpPlayer){
				[tmpPlayer play];
			}
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"playSoundInBundle:ERROR. This sound effect is not included in the list of available sounds: %@", theFileName]];
		}
	}
	
}

//didReceiveMemoryWarning
-(void)didReceiveMemoryWarning{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"appDelegate didReceiveMemoryWarning%@", @""]];
}



//dealloc
- (void)dealloc {
	[super dealloc];
	[window release];
	[refreshingView release];
		refreshingView = nil;
	[globalBackroundView release];
		globalBackroundView = nil;
	[audioPlayer release];
		audioPlayer = nil;
	[spinner release];
		spinner = nil;
	[configurationFileName release];
		configurationFileName = nil;
	[saveAsFileName release];
		saveAsFileName = nil;
	[modifiedFileName release];
		modifiedFileName = nil;
	[configData release];
		configData = nil;
	[rootApp release];
		rootApp = nil;
	[downloader	release];
		downloader = nil;
	[audioPlayer release];
		audioPlayer = nil;
	[allowedInputCharacters release];
		allowedInputCharacters = nil;
	[receivedData release];
		receivedData = nil;
	[super dealloc];
}





@end










