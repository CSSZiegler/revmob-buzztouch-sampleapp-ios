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
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"
#import "BT_strings.h"
#import "BT_settingData.h"
#import "BT_cell_settings.h"
#import "BT_screen_settingsDevice.h"


@implementation BT_screen_settingsDevice
@synthesize menuItems, myTableView, currentUserSetting;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];
		
	//build the table to display the list of menu items
	self.myTableView = [BT_viewUtilities getTableViewForScreen:[self screenData]];
	[self.myTableView setDataSource:self];
	[self.myTableView setDelegate:self];
	[self.view addSubview:myTableView];		
		
	//menu items are hard-coded this screen
	self.menuItems = [[NSMutableArray alloc] init];
						
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
	
	//load table data
	[self performSelector:(@selector(loadTable)) withObject:nil afterDelay:0.1];

}


//clear cache
-(void)clearCache{
	[BT_debugger showIt:self:@"clearCache"];
	
	//remove all saved data
	[BT_fileManager deleteAllLocalData];
	
	//show message
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"cacheCleared", "All cached-data has been removed from this device.") delegate:self
	cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
	[alertView show];
	[alertView release];
		
	//reload table after a moment
	[self performSelector:(@selector(loadTable)) withObject:nil afterDelay:0.5];
	
}

//reload table
-(void)loadTable{
	
	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//menu items are hard-coded this screen
	self.menuItems = [[NSMutableArray alloc] init];
	
	//info from UIDevice 
	BT_settingData *tmpData;
	NSString *tmp;
	
	//model info localized
	UIDevice* device = [UIDevice currentDevice];
	tmp = [NSString stringWithFormat:@"%@: %@ %@", [device localizedModel], [device systemName], [device systemVersion]];
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmp];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	//camera support
	NSString *tmpCamera = NSLocalizedString(@"cameraSupportNo", "Still Camera: NO");
	if([appDelegate.rootApp.rootDevice canTakePictures]){
		tmpCamera = NSLocalizedString(@"cameraSupportYes", "Still Camera: YES");
	}
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmpCamera];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];
	
	//video camera support
	NSString *tmpVideo = NSLocalizedString(@"videoCameraSupportNo", "Video Camera: NO");
	if([appDelegate.rootApp.rootDevice canTakeVideos]){
   		tmpVideo = NSLocalizedString(@"videoCameraSupportYes", "Video Camera: YES");
	}	
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmpVideo];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	//resolution
	tmp = [NSString stringWithFormat:@"%@ %i x %i", NSLocalizedString(@"display", "Display:"), [appDelegate.rootApp.rootDevice deviceWidth], [appDelegate.rootApp.rootDevice deviceHeight]];
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmp];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	//can make phone calls?
	NSString *tmpCalls = NSLocalizedString(@"phoneCallSupportNo", "Can Make Calls: NO");
	if([appDelegate.rootApp.rootDevice canMakePhoneCalls]){
		tmpCalls = NSLocalizedString(@"phoneCallSupportYes", "Can Make Calls: YES");
	}
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmpCalls];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];
	
	//can send emails?
	NSString *tmpEmails = NSLocalizedString(@"emailSupportNo", "Can Send Email: NO");
	if([appDelegate.rootApp.rootDevice canSendEmails]){
		tmpEmails = NSLocalizedString(@"emailSupportYes", "Can Send Email: YES");
	}
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmpEmails];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];	

	//can send sms?
	NSString *tmpSMS = NSLocalizedString(@"smsSupportNo", "Can Send SMS: NO");
	if([appDelegate.rootApp.rootDevice canSendSMS]){
		tmpSMS = NSLocalizedString(@"smsSupportYes", "Can Send SMS: YES");
	}
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmpSMS];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];	
	
	//local data cache
	int tmpSize = [BT_fileManager getLocalDataSizeInt];
	tmp = [NSString stringWithFormat:@"%@ %@ (%i files)", NSLocalizedString(@"cache",@"Cache:"), [BT_fileManager stringFromFileSize:tmpSize], [BT_fileManager countLocalFiles]];
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmp];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	//last row is "clear cache" row
	tmp = [NSString stringWithFormat:@"%@", NSLocalizedString(@"clearCache",@"Clear Cache")];
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"notUsedOnThisScreen"];
	[tmpData setSettingLabel:tmp];
	[tmpData setSettingValue:@""];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	//reload table
	[self.myTableView reloadData];
	
	
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

	static NSString *CellIdentifier = @"Cell";
	BT_cell_settings *cell = (BT_cell_settings *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
	
		//init our custom cell
		cell = [[[BT_cell_settings alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
	}
	
	//this menu item
	BT_settingData *thisSettingItemData = [self.menuItems objectAtIndex:indexPath.row];
	[cell setTheSettingsItemData:thisSettingItemData];
	[cell setTheParentMenuScreenData:[self screenData]];
	[cell configureCell];
	
	//custom background view. Must be done here so we can retain the "round" corners if this is a round table
	[cell setBackgroundView:[BT_viewUtilities getCellBackgroundForListRow:[self screenData]:indexPath:[self.menuItems count]]];
	
	return cell;	
	
}

//on row select
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[BT_debugger showIt:self:@"didSelectRowAtIndexPath"];
	
	//clear cache if this is the last row...
	if(indexPath.row == ([self.menuItems count] - 1)){
		[self clearCache];
	}
	
}

//dealloc
-(void)dealloc {
    [super dealloc];
	[screenData release];
	[progressView release];
	[menuItems release];
	[myTableView release];
	[currentUserSetting release];
}


@end





