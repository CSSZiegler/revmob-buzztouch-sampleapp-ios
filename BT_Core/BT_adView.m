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
#import "BT_item.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_debugger.h"
#import "BT_adView.h"

@implementation BT_adView
@synthesize theScreen, JSONdata;

-(id)initWithScreenData:(BT_item *)theScreenData{
	if((self = [super init])){
		[BT_debugger showIt:self:@"INIT"];
		
		//set screen data
		[self setTheScreen:theScreenData];
		
		/*
		//solid background properties..
		UIColor *solidBgColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColor":@"clear"]];
		NSString *solidBgOpacity = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorOpacity":@"100"];
		if([solidBgOpacity isEqualToString:@"100"]) solidBgOpacity = @"99";
		solidBgOpacity = [NSString stringWithFormat:@".%@", solidBgOpacity];
		*/
 			
		
	}
	 return self;
}


//view did load
- (void)viewDidLoad {
    [BT_debugger showIt:self:@"viewDidLoad"];
 
    [super viewDidLoad];
	


}


#pragma mark MobFox Delegate



//clean up
- (void)dealloc{
	[theScreen release];
		theScreen = nil;
	[JSONdata release];
		JSONdata = nil;
    [super dealloc];

}


@end






















