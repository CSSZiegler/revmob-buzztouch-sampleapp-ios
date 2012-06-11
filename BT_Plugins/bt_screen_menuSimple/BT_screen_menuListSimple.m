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
#import "BT_fileManager.h"
#import "BT_color.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"
#import "BT_cell_menuList.h"
#import "BT_screen_menuListSimple.h"

@implementation BT_screen_menuListSimple
@synthesize menuItems, myTableView;
@synthesize saveAsFileName, downloader, isLoading, didInit;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];
    
	//init screen properties
	[self setDidInit:0];
	
	//flag not loading
	[self setIsLoading:FALSE];
    
	////////////////////////////////////////////////////////////////////////////////////////
	//build the table that holds the menu items. 
	self.myTableView = [BT_viewUtilities getTableViewForScreen:[self screenData]];
	self.myTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.myTableView setDataSource:self];
	[self.myTableView setDelegate:self];
	
	//prevent scrolling?
	if([[BT_strings getStyleValueForScreen:self.screenData:@"preventAllScrolling":@""] isEqualToString:@"1"]){
		[self.myTableView setScrollEnabled:FALSE];
	}		
	[self.view addSubview:myTableView];	
	
    
	//create adView?
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"includeAds":@"0"] isEqualToString:@"1"]){
	   	[self createAdBannerView];
	}	
	
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
		[self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
		[self setDidInit:1];
	}
	
	//show adView?
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"includeAds":@"0"] isEqualToString:@"1"]){
	    [self showHideAdView];
	}
    
	
}


//load data
-(void)loadData{
	[BT_debugger showIt:self:@"loadData"];
	self.isLoading = TRUE;
	
	//prevent interaction during operation
	[myTableView setScrollEnabled:FALSE];
	[myTableView setAllowsSelection:FALSE];
    
	/*
     Screen Data scenarios
     --------------------------------
     a)	No dataURL is provided in the screen data - use the info configured in the app's configuration file
     b)	A dataURL is provided, download now if we don't have a cache, else, download on refresh.
     */
	
	self.saveAsFileName = [NSString stringWithFormat:@"screenData_%@.txt", [screenData itemId]];
	
	//do we have a URL?
	BOOL haveURL = FALSE;
	if([[BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@""] length] > 10){
		haveURL = TRUE;
	}
	
	//start by filling the list from the configuration file, use these if we can't get anything from a URL
	if([[self.screenData jsonVars] objectForKey:@"childItems"]){
        
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
        
	}
	
	//if we have a URL, fetch..
	if(haveURL){
        
		//look for a previously cached version of this screens data...
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:@"parsing cached version of screen data"];
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName]:-1];
			[self parseScreenData:staleData];
		}else{
			[BT_debugger showIt:self:@"no cached version of this screens data available."];
			[self downloadData];
		}
        
        
	}else{
		
		//show the child items in the config data
		[BT_debugger showIt:self:@"using menu items from the screens configuration data."];
		[self layoutScreen];
		
	}
	
}

//download data
-(void)downloadData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloading screen data from: %@", [BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@""]]];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//prevent interaction during operation
	[myTableView setScrollEnabled:FALSE];
	[myTableView setAllowsSelection:FALSE];
	
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
	
	//prevent interaction during operation
	[myTableView setScrollEnabled:FALSE];
	[myTableView setAllowsSelection:FALSE];
	
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
    
	//if we did not have any menu items... 
	if(self.menuItems.count < 1){
        
		for(int i = 0; i < 5; i++){	
            
			//create a menu item from the data
			BT_item *thisMenuItemData = [[BT_item alloc] init];
			[thisMenuItemData setJsonVars:nil];
			[thisMenuItemData setItemId:@""];
			[thisMenuItemData setItemType:@"BT_menuItem"];
			[self.menuItems addObject:thisMenuItemData];
			[thisMenuItemData release];
			
		}	
		
		//show message
		//[self showAlert:nil:NSLocalizedString(@"noListItems",@"This menu has no list items?"):0];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"noListItems",@"This menu has no list items?")]];
		
	}
    
	//enable interaction again (unless owner turned it off)
	if([[BT_strings getStyleValueForScreen:self.screenData:@"preventAllScrolling":@""] isEqualToString:@"1"]){
		[self.myTableView setScrollEnabled:FALSE];
	}else{
		[myTableView setScrollEnabled:TRUE];
	}
	[myTableView setAllowsSelection:TRUE];
	
	//reload table
	[self.myTableView reloadData];
	
	//flag done loading
	self.isLoading = FALSE;
	
    
}


//////////////////////////////////////////////////////////////
//UITableView delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// number of rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.menuItems count];
}



//table view cells
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *CellIdentifier = [NSString stringWithFormat:@"cell_%i", indexPath.row];
	BT_cell_menuList *cell = (BT_cell_menuList *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil){
        
		//init our custom cell
		cell = [[[BT_cell_menuList alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	}
    
	//this menu item
	BT_item *thisMenuItemData = [self.menuItems objectAtIndex:indexPath.row];
	[cell setTheMenuItemData:thisMenuItemData];
	[cell setTheParentMenuScreenData:[self screenData]];
	[cell configureCell];
	
	
	//custom background view. Must be done here so we can retain the "round" corners if this is a round table
	//this method refers to this screen's "listRowBackgroundColor" and it's position in the tap. Top and
	//bottom rows may need to be rounded if this is screen uses "listStyle":"round"
	[cell setBackgroundView:[BT_viewUtilities getCellBackgroundForListRow:[self screenData]:indexPath:[self.menuItems count]]];
	
	//return	
	return cell;	
    
}

//on row select
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[BT_debugger showIt:self:[NSString stringWithFormat:@"didSelectRowAtIndexPath: Selected Row: %i", indexPath.row]];
	
	//pass this menu item to the tapForMenuItem method
	BT_item *thisMenuItem = [self.menuItems objectAtIndex:indexPath.row];
	if([thisMenuItem jsonVars] != nil){
        
		//appDelegate
		revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
        
		//get possible itemId of the screen to load
		NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars:@"loadScreenWithItemId":@""];
		
		//get possible nickname of the screen to load
		NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars:@"loadScreenWithNickname":@""];
        
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
				if([thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]){
					screenObjectToLoad = [[BT_item alloc] init];
					[screenObjectToLoad setItemId:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
					[screenObjectToLoad setItemNickname:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
					[screenObjectToLoad setItemType:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
					[screenObjectToLoad setJsonVars:[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]];
				}								
			}
		}
        
		
		//load next screen if it's not nil
		if(screenObjectToLoad != nil){
			[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:thisMenuItem:screenObjectToLoad];
		}else{
			//show message
			[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this click?")]];
		}
		
	}else{
        
		//show message
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
        
	}
	
}

//on accessory view tap (details arrow tap)
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"accessoryButtonTappedForRowWithIndexPath: Selected Row: %i", indexPath.row]];
    
	//pass this menu item to the tapForMenuItem method
	BT_item *thisMenuItem = [self.menuItems objectAtIndex:indexPath.row];
	if([thisMenuItem jsonVars] != nil){
        
		//appDelegate
		revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
        
		//get possible itemId of the screen to load
		NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars:@"loadScreenWithItemId":@""];
		
		//get possible nickname of the screen to load
		NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars:@"loadScreenWithNickname":@""];
        
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
				if([thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]){
					screenObjectToLoad = [[BT_item alloc] init];
					[screenObjectToLoad setItemId:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
					[screenObjectToLoad setItemNickname:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
					[screenObjectToLoad setItemType:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
					[screenObjectToLoad setJsonVars:[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]];
				}								
			}
		}
        
		
		//load next screen if it's not nil
		if(screenObjectToLoad != nil){
			[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:thisMenuItem:screenObjectToLoad];
		}else{
			//show error alert
			[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
		}
		
	}else{
		//show error alert
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
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
		[self showAlert:nil:NSLocalizedString(@"downloadError", @"There was a problem downloading some data. Check your internet connection then try again."):0];
        
		//show local data if it exists
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            
			//use stale data if we have it
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[BT_debugger showIt:self:[NSString stringWithFormat:@"building screen from stale configuration data: @", [self saveAsFileName]]];
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
			[self showAlert:nil:NSLocalizedString(@"appDownloadError", @"There was a problem saving some data downloaded from the internet."):0];
            
		}
		
	}	
    
}

//allows us to check to see if we pulled-down to refresh
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
	[self checkIsLoading];
}
-(void)checkIsLoading{
	if(isLoading){
		return;
	}else{
		//how far down did we pull?
		double down = myTableView.contentOffset.y;
		if(down <= -65){
			if([[BT_strings getJsonPropertyValue:screenData.jsonVars:@"dataURL":@"1"] length] > 3){
				[self downloadData];
			}
		}
	}
}

//dealloc
-(void)dealloc{
	[screenData release];
    screenData = nil;
	[progressView release];
    progressView = nil;
	[menuItems release];
    menuItems = nil;
	[myTableView release];
    myTableView = nil;
	[saveAsFileName release];
    saveAsFileName = nil;
	[downloader release];
    downloader = nil;
    [super dealloc];
}



@end
