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
#import "BT_screen_settingsLocation.h"


@implementation BT_screen_settingsLocation
@synthesize menuItems, myTableView, currentUserSetting, lastIndexPath;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];

	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//get users current setting
	[self setCurrentUserSetting:[appDelegate.rootApp.rootUser userAllowLocation]];
	
	////////////////////////////////////////////////////////////////////////////////////////
	//build the table that holds the menu items. Global table styles come from the app's theme
	//if this screen's data has not over-ridden them.
	self.myTableView = [BT_viewUtilities getTableViewForScreen:[self screenData]];
	[self.myTableView setDataSource:self];
	[self.myTableView setDelegate:self];
	[self.view addSubview:myTableView];		
	
	//menu items are hard-coded this screen
	self.menuItems = [[NSMutableArray alloc] init];
	
	//items
	BT_settingData *tmpData;
	
	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"allowLocation"];
	[tmpData setSettingLabel:@"Prevent Location Reports"];
	[tmpData setSettingValue:@"prevent"];
	[self.menuItems addObject:tmpData];
	[tmpData release];

	tmpData = [[BT_settingData alloc] init];
	[tmpData setSettingName:@"allowLocation"];
	[tmpData setSettingLabel:@"Allow Location Reports"];
	[tmpData setSettingValue:@"allow"];
	[self.menuItems addObject:tmpData];
	[tmpData release];

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
	
	//is this current setting?
	if([[thisSettingItemData settingValue] isEqualToString:currentUserSetting]){
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		[self setLastIndexPath:indexPath];
	}else{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	//custom background view. Must be done here so we can retain the "round" corners if this is a round table
	[cell setBackgroundView:[BT_viewUtilities getCellBackgroundForListRow:[self screenData]:indexPath:[self.menuItems count]]];
	
	return cell;	
	
}

//on row select
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[BT_debugger showIt:self:@"didSelectRowAtIndexPath"];
	
	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//selected setting object
	BT_settingData *thisSettingData = [self.menuItems objectAtIndex:indexPath.row];

	//remember
	[BT_strings setPrefString:@"userAllowLocation":[thisSettingData settingValue]];
	[appDelegate.rootApp.rootUser setUserAllowLocation:[thisSettingData settingValue]];
	
	//unselect previous selection, select this selection	
	int newRow = [indexPath row];
	int oldRow = [lastIndexPath row];
	if (newRow != oldRow){
			UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
			newCell.accessoryType = UITableViewCellAccessoryCheckmark;

			UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:lastIndexPath];
			oldCell.accessoryType = UITableViewCellAccessoryNone;

			lastIndexPath = indexPath;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	

	
}


//dealloc
-(void)dealloc{
    [super dealloc];
	[screenData release];
	[progressView release];
	[menuItems release];
	[myTableView release];
	[currentUserSetting release];
	[lastIndexPath release];
}


@end





