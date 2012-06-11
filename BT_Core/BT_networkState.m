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
#import <SystemConfiguration/SystemConfiguration.h>
#import "BT_reachability.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_networkState.h"
#import "BT_debugger.h"

@implementation BT_networkState

//init
-(id)init{
    if((self = [super init])){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"INIT %@", @""]];

		// Observe the kNetworkReachabilityChangedNotification. 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	 
		//Change the host name here to change the server your monitoring
		hostReach = [[Reachability reachabilityWithHostName: @"http://www.google.com"] retain];
		[hostReach startNotifier];
		[self updateReachability:hostReach];
		
		internetReach = [[Reachability reachabilityForInternetConnection] retain];
		[internetReach startNotifier];
		[self updateReachability:internetReach];
	 
		wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
		[wifiReach startNotifier];
		[self updateReachability:wifiReach];		
		
	}
	return self;
}

//when reachability changes.
- (void)updateReachability:(Reachability*) curReach{
    //NSLog(@"BT_networkState: updateReachability");
		NetworkStatus netStatus = [curReach currentReachabilityStatus];
		NSString* statusString= @"";
		NSString *deviceString = @"";
		switch (netStatus){
			case NotReachable:{
				statusString = @"WiFi Not Available";
				deviceString = @"";
				break;
			}
			case ReachableViaWWAN:{
				statusString = @"WWAN Available";
				deviceString = @"WAN";
				break;
			}
			case ReachableViaWiFi:{
				statusString= @"WiFi Available";
				deviceString = @"WIFI";
				break;
		  }
		}
		
	//remember in delegate
	[BT_debugger showIt:self:[NSString stringWithFormat:@"Monitoring Connection: %@", statusString]];
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	[appDelegate.rootApp.rootDevice setDeviceConnectionType:deviceString];
		
}


//reachability changed
- (void) reachabilityChanged: (NSNotification* )note{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    [self updateReachability:curReach];
}
 

- (void)dealloc {
    [super dealloc];

}


@end






