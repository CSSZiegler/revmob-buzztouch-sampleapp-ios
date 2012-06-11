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
#import <AVFoundation/AVFoundation.h>
#import "BT_rotatingNavController.h"
#import "BT_rotatingTabBarController.h"
#import "BT_downloader.h"
#import "BT_user.h"
#import "BT_device.h"
#import "BT_item.h"
#import "BT_uploadItem.h"
#import "BT_locationManager.h"
#import "BT_networkState.h"
#import "BT_application.h"


@interface BT_application : NSObject <UINavigationControllerDelegate, BT_downloadFileDelegate> {

	//downloader
	BT_downloader *downloader;
	NSString *dataURL;

	//app data
	NSDictionary *jsonVars;
	NSMutableArray *themes;
	NSMutableArray *tabs;
	NSMutableArray *screens;

	//navigation controllers
	BT_rotatingNavController *rootNavController;
	BT_rotatingTabBarController *rootTabBarController;
	
	//environment variables
	BT_item *rootTheme;
	BT_user *rootUser;
	BT_device *rootDevice;
	BT_locationManager *rootLocationManager;
	BT_networkState *rootNetworkState;
	
	//holds configuration data for the current menu item tapped
	BT_item *currentMenuItemData;
	
	//holds configuration data for the previosly tapped menu item
	BT_item *previousMenuItemData;

	//holds configuration data for the currently screen loaded
	BT_item *currentScreenData;

	//holds configuration data for the previously screen loaded
	BT_item *previousScreenData;
	
	//holds configuration data for the most recent file upload
	BT_uploadItem *currentItemUpload;
	
	//holds data for previous animation type
	NSMutableArray *transitionTypeHistory;
	
}
@property (nonatomic, retain) BT_downloader *downloader;
@property (nonatomic, retain) NSString *dataURL;
@property (nonatomic, retain) NSDictionary *jsonVars;
@property (nonatomic, retain) NSMutableArray *tabs;
@property (nonatomic, retain) NSMutableArray *screens;
@property (nonatomic, retain) NSMutableArray *themes;
@property (nonatomic, retain) BT_rotatingNavController *rootNavController;
@property (nonatomic, retain) BT_rotatingTabBarController *rootTabBarController;
@property (nonatomic, retain) BT_item *rootTheme;
@property (nonatomic, retain) BT_user *rootUser;
@property (nonatomic, retain) BT_device *rootDevice;
@property (nonatomic, retain) BT_locationManager *rootLocationManager;
@property (nonatomic, retain) BT_networkState *rootNetworkState;
@property (nonatomic, retain) BT_item *currentMenuItemData;
@property (nonatomic, retain) BT_item *previousMenuItemData;
@property (nonatomic, retain) BT_item *currentScreenData;
@property (nonatomic, retain) BT_item *previousScreenData;
@property (nonatomic, retain) BT_uploadItem *currentItemUpload;
@property (nonatomic, retain) NSMutableArray *transitionTypeHistory;


-(BOOL)validateApplicationData:(NSString *)theAppData;
-(BOOL)parseJSONData:(NSString *)appDataString;
-(void)buildInterface;
-(BT_item *)getScreenDataByItemId:(NSString *)theScreenItemId;
-(BT_item *)getScreenDataByNickname:(NSString *)theScreenNickname;
-(BT_item *)getThemeDataByItemId:(NSString *)theThemeItemId;





@end











