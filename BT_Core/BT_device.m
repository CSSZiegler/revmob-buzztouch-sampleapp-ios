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
#import <MobileCoreServices/UTCoreTypes.h>
#import <MessageUI/MessageUI.h>
#import "BT_device.h"
#import "BT_debugger.h"
#import "BT_strings.h"
#import "revmobiossampleapp_appDelegate.h"

@implementation BT_device
@synthesize deviceId, deviceModel, deviceVersion, deviceWidth, deviceHeight;
@synthesize deviceLatitude, deviceLongitude, deviceConnectionType;	
@synthesize isIPad, canReportLocation, canTakePictures, canTakeVideos;
@synthesize canMakePhoneCalls, canSendEmails, canSendSMS;

-(id)init{
    if((self = [super init])){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"INIT"]];
		
		//current device instance
		UIDevice* device = [UIDevice currentDevice];
        
        //create a unique-id if we have not saved one yet.
        NSString *tmpUUID = [BT_strings getPrefString:@"BT_UUID"];
        if([tmpUUID length] > 5){
            [BT_debugger showIt:self:@"Unique UUID exists."];
            self.deviceId = tmpUUID;
        }else{
            [BT_debugger showIt:self:@"Unique UUID does not exist, creating."];
            CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
            NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
            [BT_strings setPrefString:@"BT_UUID":uuidStr];
            self.deviceId = uuidStr;
        }
        
		self.deviceModel = [device model];
		self.deviceWidth = [UIScreen mainScreen].bounds.size.width;
		self.deviceHeight = [UIScreen mainScreen].bounds.size.height;
		self.deviceLatitude = @"0";
		self.deviceLongitude = @"0";
		self.deviceConnectionType = @"";
		self.canTakePictures = FALSE;
		self.canTakeVideos = FALSE;
		self.canMakePhoneCalls = FALSE;
		self.canSendEmails = FALSE;
		self.canSendSMS = FALSE;
		self.canReportLocation = FALSE;
		
		/*
			iOS Device Screen Dimensions
			------------------------------
			iPhone / iPad Touch: 320 x 480
			iPad:	768 x 1024
		*/
		
		
		//if this is an iPad, flag it in the appDelegate.
		if(self.deviceWidth > 500){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device is an iPad."]];
			self.isIPad = TRUE;
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device is NOT an iPad."]];
			self.isIPad = FALSE;
		}
		
		//can this device make phone calls?
		NSRange modelRange = [[device model] rangeOfString:@"iPhone"];
		if(modelRange.location == NSNotFound){
			self.canMakePhoneCalls = FALSE;
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot make phone calls"]];
		}else{
			self.canMakePhoneCalls = TRUE;
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can make phone calls"]];
			
		}
		
		//can send emails? Just because device is capable doesn't mean mail's been configured.
		Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
		if(mailClass != nil){
			if([mailClass canSendMail]){
				self.canSendEmails = TRUE;
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can send emails"]];
			}
		}
		if(!self.canSendEmails){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot send emails"]];
		}

		//can send SMS? Just because device is capable doesn't mean it can send.
		Class SMSClass = (NSClassFromString(@"MFMessageComposeViewController"));
		if(SMSClass != nil){
			if([SMSClass canSendText]){
				self.canSendSMS = TRUE;
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can send SMS"]];
			}
		}
		if(!self.canSendSMS){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot send SMS"]];
		}

				
		/*
			can this device report it's location? If user has turned off services for this app only, this
			method will return true. In this case, we need to use the locationManager.didFailWithError
			method in the delgate class where we are monitoring the location. We use two different methods
			to check for the service because different versions of iOS support different methods - ugh!
		*/
		
		if([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]) {
      		self.canReportLocation = [CLLocationManager locationServicesEnabled];
    	}else{
      		CLLocationManager* locMan = [[CLLocationManager alloc] init];
      		self.canReportLocation = locMan.locationServicesEnabled;
      		[locMan release];
			locMan = nil;
		}
		if(self.canReportLocation){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can reports it's location"]];
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot reports it's location"]];
		}
		
		//camera and or video support?
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
			NSArray *media = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
			if([media containsObject:(id)kUTTypeImage]){
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can take still pictures"]];
				[self setCanTakePictures:TRUE];
			}else{
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot take still pictures"]];
			}
			
			if([media containsObject:(id)kUTTypeMovie]){
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device can take videos"]];
				[self setCanTakeVideos:TRUE];
			}else{
				[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot take videos"]];
			}
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"This device cannot take pictures or videos"]];
		}
	
	}
	return self;
}

- (void)dealloc {
    [super dealloc];
	[deviceId release];
    [deviceModel release];
    [deviceVersion release];
    [deviceLatitude release];
	[deviceLongitude release];
    [deviceConnectionType release];
	
}


@end
