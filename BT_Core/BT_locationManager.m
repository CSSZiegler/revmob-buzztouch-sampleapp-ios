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


#import "BT_locationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "revmobiossampleapp_appDelegate.h"
#import "BT_debugger.h"

//used in formats below for readability
#define LocStr(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@implementation BT_locationManager

@synthesize locationManager, updateCount, warningCount;

-(id)init{
    self = [super init];
    if (self != nil){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"INIT %@", @" (only initializing, not using)"]];


		//counter tracks updates so we can turn the updater off when we have a few location
		//updates - this save battery!
		self.updateCount = 0;
		self.warningCount = 0;

		
    }
    return self;
}

//start location updates
-(void)startLocationUpdates{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"startLocationUpdates %@", @""]];
	
	
	@try {
	
		//if we have not already done this..
		if(self.locationManager == nil){
		
			//init location manager
        	self.locationManager = [[[CLLocationManager alloc] init] autorelease];
			[self.locationManager setDelegate:self];
			[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
			[self.locationManager startUpdatingLocation];
		
		}else{
		
			[self.locationManager startUpdatingLocation];
	
		}	
	
	}@catch (NSException * e) {
	}@finally {
 	}
	
}

//stop location udpates
-(void)stopLocationUpdates{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"stopLocationUpdates %@", @""]];
	[self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"didUpdateToLocation %@", @""]];
	
	NSMutableString *update = [[[NSMutableString alloc] init] autorelease];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[update appendFormat:@"%@\n\n", [dateFormatter stringFromDate:newLocation.timestamp]];
	
	//horizontal coordinates
	if (signbit(newLocation.horizontalAccuracy)) {
	
		//negative accuracy means an invalid or unavailable measurement
		[update appendString:LocStr(@"LatLongUnavailable")];
	
	}else{
	
		//coreLocation returns positive for North & East, negative for South & West
		[update appendFormat:LocStr(@"LatLongFormat"),
		fabs(newLocation.coordinate.latitude), signbit(newLocation.coordinate.latitude) ? LocStr(@"South") : LocStr(@"North"),
		fabs(newLocation.coordinate.longitude),	signbit(newLocation.coordinate.longitude) ? LocStr(@"West") : LocStr(@"East")];
		[update appendString:@"\n"];
		[update appendFormat:LocStr(@"MeterAccuracyFormat"), newLocation.horizontalAccuracy];
	
	}
	[update appendString:@"\n\n"];
	
	//altitude
	if (signbit(newLocation.verticalAccuracy)) {
		//negative accuracy means an invalid or unavailable measurement
		[update appendString:LocStr(@"AltUnavailable")];
	} else {
		//positive and negative in altitude denote above & below sea level, respectively
		[update appendFormat:LocStr(@"AltitudeFormat"), fabs(newLocation.altitude),	(signbit(newLocation.altitude)) ? LocStr(@"BelowSeaLevel") : LocStr(@"AboveSeaLevel")];
		[update appendString:@"\n"];
		[update appendFormat:LocStr(@"MeterAccuracyFormat"), newLocation.verticalAccuracy];
	}
	[update appendString:@"\n\n"];
	
	//calculate disatance moved and time elapsed, but only if we have an "old" location
	if(oldLocation != nil) {
	
		#if __IPHONE_3_0
			// iphone > 3.0
			CLLocationDistance distanceMoved = [newLocation getDistanceFrom:oldLocation];
		#else
			// iphone > 4.0
			CLLocationDistance distanceMoved = [newLocation distanceFromLocation:oldLocation];
		#endif		
	
		NSTimeInterval timeElapsed = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
		[update appendFormat:LocStr(@"LocationChangedFormat"), distanceMoved];
		if (signbit(timeElapsed)) {
			[update appendString:LocStr(@"FromPreviousMeasurement")];
		} else {
			[update appendFormat:LocStr(@"TimeElapsedFormat"), timeElapsed];

		}
		[update appendString:@"\n\n"];
	}

	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	[appDelegate.rootApp.rootDevice setDeviceLatitude:[NSString stringWithFormat:@"%f", newLocation.coordinate.latitude]];
	[appDelegate.rootApp.rootDevice setDeviceLongitude:[NSString stringWithFormat:@"%f", newLocation.coordinate.longitude]];
	[appDelegate.rootApp.rootDevice setCanReportLocation:TRUE];
	
	//turn off updates after 10 reports. This ensures accuracy but reduces battery load.
	self.updateCount = (self.updateCount + 1);
	if(self.updateCount > 10){
		[self.locationManager stopUpdatingLocation];
	}
	
	
}

//location update errors
- (void)locationManager:(CLLocationManager *)manager  didFailWithError:(NSError *)error{
	NSMutableString *errorString = [[[NSMutableString alloc] init] autorelease];
	
	//stop updating..
	[self.locationManager stopUpdatingLocation];
	
	if ([error domain] == kCLErrorDomain || [error code] == kCLErrorDenied) {
	
		//user denied...
		[BT_debugger showIt:self:[NSString stringWithFormat:@"Location services didFailWithError. Several things can cause this. Has the user allowed location updates?%@", @""]];
	
		//alert the user on first error
		if(self.warningCount == 0){
			
			//flag so we only get one warning
			[self setWarningCount:1];
			
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
			message:@"This application cannot access your location information. The application will continue to function but may have limited capability."
			delegate:self
			cancelButtonTitle:@"OK" otherButtonTitles:nil];
			//[alertView show];
			[alertView release];	
		}
		
	}else{
	
		if ([error domain] == kCLErrorDomain) {
			//handle CoreLocation-related errors here
			switch ([error code]) {
					// This error code is usually returned whenever user taps "Don't Allow" in response to
					// being told your app wants to access the current location. Once this happens, you cannot
					// attempt to get the location again until the app has quit and relaunched.
				case kCLErrorDenied:
					[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationDenied", nil)];
					break;
					// This error code is usually returned whenever the device has no data or WiFi connectivity,
				case kCLErrorLocationUnknown:
					[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationUnknown", nil)];
					break;
					// We shouldn't ever get an unknown error code, but just in case...
				default:
					[errorString appendFormat:@"GENERIC %@ %d\n", NSLocalizedString(@"GenericLocationError", nil), [error code]];
					break;
			}
		}else{
			//handle all non-CoreLocation errors here
			[errorString appendFormat:@"Error domain: \"%@\"  Error code: %d\n", [error domain], [error code]];
			[errorString appendFormat:@"Description: \"%@\"\n", [error localizedDescription]];
		}
	
		//debug
		[BT_debugger showIt:self:[NSString stringWithFormat:@"didFailWithError %@", errorString]];
	
	}
	
	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	[appDelegate.rootApp.rootDevice setCanReportLocation:FALSE];
	
	//reset counter to it starts again next time
	self.updateCount = 0;
	

}

- (void)dealloc {
    [self.locationManager release];
    [super dealloc];
}

@end





