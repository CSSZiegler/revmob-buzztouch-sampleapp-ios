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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_strings.h"
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"
#import "BT_button_view.h"

#import "BT_screen_menuButtons.h"

@implementation BT_screen_menuButtons
@synthesize menuItems, menuItemViews, myScrollView;
@synthesize downloader, deviceWidth, deviceHeight, saveAsFileName, didInit;
@synthesize buttonLayoutStyle, buttonLabelLayoutStyle, buttonLabelFontColor, buttonOpacity;
@synthesize	buttonLabelFontSize, buttonSize, buttonPadding, isLoading;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];

	//init screen properties
	[self setDidInit:0];
	self.buttonSize = 60;
	self.buttonPadding = 15;
	self.buttonLayoutStyle = @"grid";
	self.buttonLabelLayoutStyle = @"bottom";
	self.buttonLabelFontColor = [UIColor lightGrayColor];
	self.buttonLabelFontSize = 13;
	self.isLoading = FALSE;
	NSString *stringOpacity = @"1.0";

	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

	self.deviceWidth = [appDelegate.rootApp.rootDevice deviceWidth];
	self.deviceHeight = [appDelegate.rootApp.rootDevice deviceHeight];

	//add the content views..they get resized and updated in layoutScreen method
	self.myScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, deviceWidth, deviceHeight)];
	[self.myScrollView setShowsVerticalScrollIndicator:FALSE];
	[self.myScrollView setShowsHorizontalScrollIndicator:FALSE];
	[self.myScrollView setDelegate:self];
	self.myScrollView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);	
	
	//prevent scrolling?
	if([[BT_strings getStyleValueForScreen:self.screenData:@"preventAllScrolling":@""] isEqualToString:@"1"]){
		[self.myScrollView setScrollEnabled:FALSE];
	}		
	
	//opacity
	stringOpacity =  [NSString stringWithFormat:@".%@", [BT_strings getStyleValueForScreen:self.screenData:@"buttonOpacity":@"100"]];
	if([stringOpacity isEqualToString:@".100"]) stringOpacity = @"1.0";
	if([stringOpacity isEqualToString:@""]) stringOpacity = @"1.0";

	//layout style
	self.buttonLayoutStyle = [BT_strings getStyleValueForScreen:self.screenData:@"buttonLayoutStyle":@"grid"];
	self.buttonLabelLayoutStyle = [BT_strings getStyleValueForScreen:self.screenData:@"buttonLabelLayoutStyle":@"below"];
	
	//font color
	self.buttonLabelFontColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData:@"buttonLabelFontColor":@"#CCCCCC"]];	
					
	//convert button opacity
	self.buttonOpacity = [stringOpacity doubleValue];
	
	//some settings depend on the device size
	if([appDelegate.rootApp.rootDevice isIPad]){
	
		//use large settings
		self.buttonSize = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonSizeLargeDevice":@"60"] intValue];
		self.buttonLabelFontSize = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonLabelFontSizeLargeDevice":@"13"] intValue];
		self.buttonPadding = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonPaddingLargeDevice":@"15"] intValue];

	
	}else{
	
		//use small settings
		self.buttonSize = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonSizeSmallDevice":@"60"] intValue];
		self.buttonLabelFontSize = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonLabelFontSizeSmallDevice":@"13"] intValue];
		self.buttonPadding = [[BT_strings getStyleValueForScreen:self.screenData:@"buttonPaddingSmallDevice":@"15"] intValue];
	
	}	
	
	//add the scrollview
	[self.view addSubview:myScrollView];
	

}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self:@"viewWillAppear"];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//setup navigation bar and background
	[BT_viewUtilities configureBackgroundAndNavBar:self:[self screenData]];

	//if we have not yet inited data..
	if(self.didInit == 0){
		
		//get data
		[self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
		
		//flag
		[self setDidInit:1];
	
	}else{
		
		[self layoutScreen];
	}

}


//load data
-(void)loadData{
	[BT_debugger showIt:self:@"loadData"];
	
	//flag as loading
	self.isLoading = TRUE;
	
	/*
		Screen Data scenarios
		--------------------------------
		a)	No dataURL is provided in the screen data - use the info configured in the app's configuration file
		b)	A cached version of the screens childItems exists, use this.
		c)	A dataURL is provided, download now if we don't have a cache, else, download on refresh.
	*/

	self.saveAsFileName = [NSString stringWithFormat:@"screenData_%@.txt", [screenData itemId]];
	
	//flag in progress
	self.isLoading = TRUE;
	
	//if we have child items in the screens data (we should), parse and display those. If the screen has a dataURL
	//the refresh logic will download a refreshed version of the child-items.	
	
	if([[self.screenData jsonVars] objectForKey:@"childItems"]){
		[BT_debugger showIt:self:@"parsing menu-items from app's configuration file."];

		//init the items array
		self.menuItems = [[NSMutableArray alloc] init];

		NSArray *tmpMenuItems = [[self.screenData jsonVars] objectForKey:@"childItems"];
		for(NSDictionary *tmpMenuItem in tmpMenuItems){
			
			BT_item *thisMenuItem = [[BT_item alloc] init];
			thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
			thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
			thisMenuItem.jsonVars = tmpMenuItem;
			[self.menuItems addObject:thisMenuItem];
			[thisMenuItem release];								
		}
			
		//layout screen
		[self layoutScreen];

	}else{
	
		//look for a previously cached version of this screens data...
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:@"parsing cached version of screen data"];
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[self parseScreenData:staleData];
		}else{
			[BT_debugger showIt:self:@"no cached version of this screens data available."];
			if([[BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@""] length] > 3){
				[self downloadData];
			}
			
		}	
		
	}


}

//download data
-(void)downloadData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloading screen data from: %@", [self saveAsFileName]]];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//show progress
	[self showProgress];
	
	NSString *tmpURL = @"";
	if([[BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@""] length] > 3){
		
		//merge url variables
		tmpURL = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@""];

		///merge possible variables in URL
		NSString *useURL = [BT_strings mergeBTVariablesInString:tmpURL];
		NSString *escapedUrl = [useURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
		//fire downloader to fetch and results
		downloader = [[BT_downloader alloc] init];
		[downloader setSaveAsFileName:[self saveAsFileName]];
		[downloader setSaveAsFileType:@"text"];
		[downloader setUrlString:escapedUrl];
		[downloader setDelegate:self];
		[downloader downloadFile];	
	}
}


//parse screen data
-(void)parseScreenData:(NSString *)theData{
	[BT_debugger showIt:self:@"parseScreenData"];
	@try {	
	
		//arrays for screenData
		self.menuItems = [[NSMutableArray alloc] init];

		//create dictionary from the JSON string
		SBJsonParser *parser = [SBJsonParser new];
		id jsonData = [parser objectWithString:theData];
	   	if(!jsonData){
		
			[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
			[self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~"):NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed"):0];
			[BT_fileManager deleteFile:[self saveAsFileName]];
	
		}else{		

			if([jsonData objectForKey:@"childItems"]){
				NSArray *tmpMenuItems = [jsonData objectForKey:@"childItems"];
				for(NSDictionary *tmpMenuItem in tmpMenuItems){
					BT_item *thisMenuItem = [[BT_item alloc] init];
					thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
					thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
					thisMenuItem.jsonVars = tmpMenuItem;
					[self.menuItems addObject:thisMenuItem];
					[thisMenuItem release];						
				}
			}
			
			//layout screen
			[self layoutScreen];		
		
		}
		
	}@catch (NSException * e) {
		//delete bogus data, show alert
		[BT_fileManager deleteFile:[self saveAsFileName]];
		[self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~"):NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed"):0];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing screen data: %@", e]];
	} 

}

//build screen
-(void)layoutScreen{
	[BT_debugger showIt:self:@"layoutScreen"];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

	self.deviceWidth = [appDelegate.rootApp.rootDevice deviceWidth];
	self.deviceHeight = [appDelegate.rootApp.rootDevice deviceHeight];

	//if we are hiding the tabber we need to add some space at the bottom
	if([[BT_strings getStyleValueForScreen:[self screenData]:@"hideBottomTabBarWhenScreenLoads":@"0"] isEqualToString:@"1"]){
		self.deviceHeight += 40;
	}

	//if we are in landscape, swap width / height values
	self.deviceWidth = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? [appDelegate.rootApp.rootDevice deviceWidth] : [appDelegate.rootApp.rootDevice deviceHeight];

	//adjust scroller size...
	[self.myScrollView setFrame:CGRectMake(0, 0, deviceWidth, deviceHeight)];

	//holds each view/button for tracking what was tapped
	self.menuItemViews = [[NSMutableArray alloc] init];
	
	//we may be refreshing so we need to "empty" the scrollview
	for(UIView *subview in [self.myScrollView subviews]){	
    	[subview removeFromSuperview];
	}	
	
	//possible button layout styles: grid, verticalLeft, verticalRight, horizontalTop, horizontalBottom
	//possible label layout styles: above, top, middle, bottom, below (labels are same width as buttons)

	//default values
	int left = buttonPadding;
	int top = buttonPadding;
	int tmpCount = 0;

	//controls go in a box so we can center everything.
	/*
		IMPORTANT. If the screen uses a transparent navigation bar, the buttons will appear
		underneath the navigation bar, move them down  44 pixels to prevent this.
	*/
	if([[BT_strings getStyleValueForScreen:self.screenData:@"navBarStyle":@""] isEqualToString:@"transparent"]){
		top = (top + 44);
	}
	
	//if this is a tabbed app, remove space for bottom tabs...
	if([appDelegate.rootApp.tabs count] > 0){
		deviceHeight = (deviceHeight - 50);
	}

	//number of buttons in array
	int numButtons = [self.menuItems count];
	
	//"box size" must get larger if label is "above" or "below" the button
	int boxWidth = self.buttonSize;
	int boxHeight = self.buttonSize;
	int labelHeight = self.buttonLabelFontSize + 8;

	//if we are using "grid" layout, we need to calculate how may buttons per row so columns/rows work out
	double buttonsPerRow = floor(deviceWidth / (boxWidth + buttonPadding));
	
	//label and box frames depend on the buttonLabelLayoutStyle
	CGRect buttonRect = CGRectMake(0, 0, buttonSize, buttonSize);
	CGRect labelRect = CGRectMake(0, 0, buttonSize, labelHeight);

	//if label is above, frame for box needs to be taller.
	if([buttonLabelLayoutStyle isEqualToString:@"above"]){
		boxHeight = (boxHeight + labelHeight);
		buttonRect = CGRectMake(0, labelHeight, buttonSize, buttonSize);
		labelRect = CGRectMake(0, 0, buttonSize, labelHeight);
	}
	
	//if label is on top, above icon
	if([buttonLabelLayoutStyle isEqualToString:@"top"]){
		boxHeight = buttonSize;
		buttonRect = CGRectMake(0, 0, buttonSize, buttonSize);
		labelRect = CGRectMake(0, 0, buttonSize, labelHeight);
	}
	//label in middle
	if([buttonLabelLayoutStyle isEqualToString:@"middle"]){
		boxHeight = buttonSize;
		buttonRect = CGRectMake(0, 0, buttonSize, buttonSize);
		labelRect = CGRectMake(0, (buttonSize / 2) - (labelHeight / 2), buttonSize, labelHeight);
	}
	//label on bottom, under icon
	if([buttonLabelLayoutStyle isEqualToString:@"bottom"]){
		boxHeight = buttonSize;
		buttonRect = CGRectMake(0, 0, buttonSize, buttonSize);
		labelRect = CGRectMake(0, (buttonSize - labelHeight), buttonSize, labelHeight);
	}
	//label below box, frame for box needs to be taller.
	if([buttonLabelLayoutStyle isEqualToString:@"below"]){
		boxHeight = (boxHeight + labelHeight);
		buttonRect = CGRectMake(0, 0, buttonSize, buttonSize);
		labelRect = CGRectMake(0, buttonSize, buttonSize, labelHeight);
	}		
	
	
	//setup scroll view. It's size depends on the button layout
	int contentWidth = 0;
	int contentHeight = 0;
	
	//grid
	if([buttonLayoutStyle isEqualToString:@"grid"] || [buttonLayoutStyle isEqualToString:@""]){
		
		contentWidth = deviceWidth;
		contentHeight = ((boxHeight + labelHeight) * (numButtons + 10)) / buttonsPerRow - (deviceHeight * 1.5);
		if(contentHeight < deviceHeight) contentHeight = (deviceHeight + 50);
		self.myScrollView.frame = CGRectMake(0, 0, deviceWidth, deviceHeight);
		self.myScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
	}
	
	//verticalLeft
	if([buttonLayoutStyle isEqualToString:@"verticalLeft"]){
		
		contentWidth = (boxWidth + buttonPadding);
		contentHeight =  numButtons * (boxHeight + buttonPadding) + (boxHeight + buttonPadding) + 125;
		if(contentHeight < deviceHeight) contentHeight = (contentHeight + 100);

		self.myScrollView.frame = CGRectMake(0, 0, boxWidth + (buttonPadding * 2), deviceHeight);
		self.myScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);

	}

	//verticalRight
	if([buttonLayoutStyle isEqualToString:@"verticalRight"]){

		contentWidth = (boxWidth + buttonPadding);
		contentHeight =  numButtons * (boxHeight + buttonPadding) + (boxHeight + buttonPadding) + 125;
		if(contentHeight < deviceHeight) contentHeight = (contentHeight + 100);

		self.myScrollView.frame = CGRectMake(deviceWidth - (boxWidth + buttonPadding + buttonPadding), 0, boxWidth + (buttonPadding * 2), deviceHeight);
		self.myScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);

	}

	//horiztonalTop
	if([buttonLayoutStyle isEqualToString:@"horizontalTop"]){

		contentWidth = (numButtons + 1) * (boxWidth + buttonPadding) + 100;;
		contentHeight =  (boxHeight + labelHeight);
		if(contentWidth < deviceWidth) contentWidth = (contentWidth + 75);

		self.myScrollView.frame = CGRectMake(0, 0, deviceWidth, (boxHeight + labelHeight));
		self.myScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);

	}		

	//horiztonalBottom
	if([buttonLayoutStyle isEqualToString:@"horizontalBottom"]){

		contentWidth = (numButtons + 1) * (boxWidth + buttonPadding) + 100;
		contentHeight =  (boxHeight + labelHeight);
		if(contentWidth < deviceWidth) contentWidth = (contentWidth + 75);

		//landscape or portrait...tabbed or not...
		if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){

			//portrait mode
			self.myScrollView.frame = CGRectMake(0, (deviceHeight - boxHeight - boxHeight), deviceWidth, (boxHeight + labelHeight));
		
		}else{
			
			//landscape mode
			revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
			if([appDelegate.rootApp.tabs count] > 0){
				self.myScrollView.frame = CGRectMake(0, (deviceHeight - boxHeight - boxHeight) - (45 + boxHeight + labelHeight), deviceWidth, (boxHeight + labelHeight));
			}

	
		}
		self.myScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
	
	
	}
	

	//add each menuItem (button)		
	for(int x = 0; x < numButtons; x++){
		BT_item *thisMenuItem = [self.menuItems objectAtIndex:x];
		tmpCount++;
						
		//create the label and the box after we figured out the frames.
		UIView *buttonBox = [[UIView alloc] initWithFrame:CGRectMake(left, top, boxWidth, boxHeight)];
		[buttonBox setTag:x];

		UILabel *buttonLabel = [[UILabel alloc] initWithFrame:labelRect];
		[buttonLabel setBackgroundColor:[UIColor clearColor]];
		[buttonLabel setNumberOfLines:1];
		[buttonLabel setTextColor:buttonLabelFontColor];
		[buttonLabel setTextAlignment:UITextAlignmentCenter];
		[buttonLabel setFont:[UIFont systemFontOfSize:buttonLabelFontSize]];
		if([[thisMenuItem jsonVars] objectForKey:@"titleText"]){
			[buttonLabel setText:[[thisMenuItem jsonVars] objectForKey:@"titleText"]];
		}
		
		//init a BT_button (this is background color or image)
		BT_button_view *thisButton = [[BT_button_view alloc] initWithMenuItemData:(BT_item *)[self.menuItems objectAtIndex:x]:[self screenData]];
		[thisButton setFrame:buttonRect];
		[thisButton setAlpha:buttonOpacity];
		[thisButton setUserInteractionEnabled:YES];
		[buttonBox addSubview:thisButton];
		
		//fire the showImage function in BT_button (it runs in a background thread)
		[thisButton showImage];
		[thisButton release];
		thisButton = nil;
		
		//BT_button is a UIView, add a transparent button on top so it's "clickable"
		UIButton *tmpButton = [[UIButton alloc] initWithFrame:buttonRect];
		[tmpButton addTarget:self action:@selector(menuItemTap:) forControlEvents:UIControlEventTouchUpInside];
		[tmpButton setTag:x];
		[buttonBox addSubview:tmpButton];
		[tmpButton release];
		tmpButton = nil;
		
		//add label after backround 
		[buttonBox addSubview:buttonLabel];
		
		//add buttonBox to items array so we can refer to it when it's tapped
		[self.menuItemViews addObject:buttonBox];			

		//add to scroll view
		[myScrollView addSubview:buttonBox];

		//clean up
		[buttonBox release];
		buttonBox = nil;
		[buttonLabel release];
		buttonLabel = nil;

		/////////////////////////////////////////////////
		//left and top depend on the buttonLayoutStyle
		
		//grid (resets rows / cols in loop)
		if([buttonLayoutStyle isEqualToString:@"grid"]){
		
			//increment left
			left = (left + buttonSize + buttonPadding);
			
			//do left or top need reset?
			if(tmpCount >= buttonsPerRow){
				left = buttonPadding;
				top = (top + (buttonSize + buttonPadding));
				//if the label is "above or below" add height of label to top value
				if([buttonLabelLayoutStyle isEqualToString:@"above"] || [buttonLabelLayoutStyle isEqualToString:@"below"]){
					top += labelHeight;
				}
				//reset
				tmpCount = 0;
			}
		}
		
		//verticalLeft or verticalRight (top changes, left constant)
		if([buttonLayoutStyle isEqualToString:@"verticalLeft"] || [buttonLayoutStyle isEqualToString:@"verticalRight"]){
			top = (top + (boxHeight + buttonPadding));
		}

		//horizontalTop or horizontalBottom (left changes, top constant)
		if([buttonLayoutStyle isEqualToString:@"horizontalTop"] || [buttonLayoutStyle isEqualToString:@"horizontalBottom"]){
			left = (left + buttonSize + buttonPadding);
		}

		
	}//end for each button...


	//flag as not loading
	self.isLoading = FALSE;

}


//button tap
-(void)menuItemTap:(id)sender{
	[BT_debugger showIt:self:@"menuItemTap"];
	UIButton *tmpButton = (UIButton *)sender;
	
	//tag is index of menuItemViews array
	int i = tmpButton.tag;
	
	//trigger animation on the calling view
	UIView *tmpView = [self.menuItemViews objectAtIndex:i];			

	//home-baked button fade-out
	[self fadeView:tmpView];
	
	//send menu_item data to navigation method (delay this slightly so we can see fade effect on button)
	BT_item *thisMenuItem = [self.menuItems objectAtIndex:i];
	[self performSelector:@selector(launchScreen:) withObject:thisMenuItem afterDelay:.2];
	
}

//launch screen
-(void)launchScreen:(BT_item *)theMenuItem{
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//get the itemId of the screen to load
	NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:theMenuItem.jsonVars:@"loadScreenWithItemId":@"0"];
	
	//use the id of the screen we want to load to get it's data object from the app	
	BT_item *screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
	
	//BT_viewControllerManager will launch the next screen
	[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:theMenuItem:screenObjectToLoad];
	
}

//fade the view (button) when tapped
-(void)fadeView:(UIView *)theView{

	//fade out...
	[theView setAlpha:buttonOpacity];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.1];
	[UIView setAnimationDelegate:self];
	[theView setAlpha:0.1];
	[UIView commitAnimations];
	
	//then back in...
	[theView setAlpha:.1];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.2];
	[UIView setAnimationDelegate:self];
	[theView setAlpha:1.0];
	[UIView commitAnimations];
	
}

//left button
-(void)navLeftTap{
	[BT_debugger showIt:self:@"navLeftTap"];
	[BT_viewControllerManager handleLeftButton:screenData];
}

//right button
-(void)navRightTap{
	[BT_debugger showIt:self:@"navRightTap"];
	[BT_viewControllerManager handleRightButton:screenData];
}

//show progress
-(void)showProgress{
	[BT_debugger showIt:self:@"showProgress"];
	if(progressView == nil){
		progressView = [BT_viewUtilities getProgressView:@""];
		[self.view addSubview:progressView];
	}	
}

-(void)hideProgress{
	[BT_debugger showIt:self:@"hideProgress"];
	if(progressView != nil){
		[progressView removeFromSuperview];
		progressView = nil;
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

//allows us to check to see if we pulled-down to refresh
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
	[self checkIsLoading];
}
-(void)checkIsLoading{
	if(isLoading){
		return;
	}else{
		//how far down did we pull (or left for horizontal buttons views) ?
		double down = myScrollView.contentOffset.y;
		double left = myScrollView.contentOffset.x;

		if(down <= - 65 || left <= -65){
			if([[BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@"1"] length] > 3){
				[self downloadData];
			}
		}
	}
}



//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
	if(progressView != nil){
		UILabel *tmpLabel = (UILabel *)[progressView.subviews objectAtIndex:2];
		[tmpLabel setText:message];
	}
}
-(void)downloadFileCompleted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
	[self hideProgress];
	
	//if message contains "error", look for previously cached data...
	if([message rangeOfString:@"ERROR-1968" options:NSCaseInsensitiveSearch].location != NSNotFound){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"download error: There was a problem downloading data from the internet.%@", message]];
		//NSLog(@"Message: %@", message);
		
		//show alert
		[self showAlert:nil:NSLocalizedString(@"downloadError", @"There was a problem downloading some data. Check your internet connection then try again.")];

		//show local data if it exists
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
					
			//use stale data if we have it
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[BT_debugger showIt:self:[NSString stringWithFormat:@"building screen from stale configuration data saved at: @", [self saveAsFileName]]];
			[self parseScreenData:staleData];
			
		}else{
		
			[BT_debugger showIt:self:[NSString stringWithFormat:@"There is no local data availalbe for this screen?%@", @""]];
			
			//if we have items... else.. show alert
			if(self.menuItems.count > 0){
				[self layoutScreen];
			}		
		
		}
			
	}else{
	
	
		//parse previously saved data
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"parsing downloaded screen data.%@", @""]];
			NSString *downloadedData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName]:-1];
			[self parseScreenData:downloadedData];

		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"Error caching downloaded file: %@", [self saveAsFileName]]];
			[self layoutScreen];

			//show alert
			[self showAlert:nil:NSLocalizedString(@"appDownloadError", @"There was a problem saving some data downloaded from the internet.")];

		}			
		
	}	
	
}


//dealloc
-(void)dealloc {
	[screenData release];
		screenData = nil;
	[progressView release];
		progressView = nil;
	[menuItems release];
		menuItems = nil;
	[menuItemViews release];
		menuItemViews = nil;
	[myScrollView release];
		myScrollView = nil;
	[downloader release];
		downloader = nil;
	[saveAsFileName release];
		saveAsFileName = nil;
	[buttonLayoutStyle release];
		buttonLayoutStyle = nil;
	[buttonLabelLayoutStyle release];
		buttonLabelLayoutStyle = nil;
	[buttonLabelFontColor release];
		buttonLabelFontColor = nil;
    [super dealloc];

	
}


@end





