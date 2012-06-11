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
#import "BT_user.h"
#import "BT_debugger.h"
#import "BT_strings.h"
#import "BT_viewControllerManager.h"


@implementation BT_user
@synthesize userId, userType, userDisplayName, userEmail, userLogInId, userLogInPassword, userIsLoggedIn, userImage;
@synthesize userAllowLocation;
 

-(id)init{
    if((self = [super init])){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"INIT"]];

		//init to empty vars
		self.userId = @"";
		self.userType = @"";
		self.userDisplayName = @"";
		self.userEmail = @"";
		self.userLogInId = @"0";
		self.userLogInPassword = @"";
		self.userIsLoggedIn = @"0";
		self.userAllowLocation = @"";
		self.userImage = nil;
		
		// if we have a guid and an email address in prefs, we are logged in
		if([[BT_strings getPrefString:@"userId"] length] > 0){
			self.userId = [BT_strings getPrefString:@"userId"];
			self.userIsLoggedIn = @"1";
		}
		
		//saved preferences may exist. The getPrefString method returns an empty string if the preference is not set
		self.userDisplayName = [BT_strings getPrefString:@"userDisplayName"];
		self.userEmail = [BT_strings getPrefString:@"userEmail"];
		self.userLogInId = [BT_strings getPrefString:@"userLogInId"];
		self.userLogInPassword = [BT_strings getPrefString:@"userLogInPassword"];
		self.userAllowLocation = [BT_strings getPrefString:@"userAllowLocation"];
			if([userAllowLocation length] < 2) self.userAllowLocation = @"allow";
		
	}
	return self;
}

- (void)dealloc {
    [super dealloc];
	[userId release];
	[userType release];
	[userDisplayName release];
	[userEmail release];
	[userLogInId release];
	[userLogInPassword release];
	[userAllowLocation release];
	[userImage release];
}


@end
