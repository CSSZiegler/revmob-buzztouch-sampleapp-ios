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

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <CoreFoundation/CoreFoundation.h>
#import "BT_reachability.h"
 
#define kShouldPrintReachabilityFlags 0
 
static void PrintReachabilityFlags(SCNetworkReachabilityFlags    flags, const char* comment){
#if kShouldPrintReachabilityFlags
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
            comment
            );
#endif
}
 
 
@implementation Reachability
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info){
    #pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(NSObject*) info isKindOfClass: [Reachability class]], @"info was wrong class in ReachabilityCallback");
 
    //We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
    // in case someon uses the Reachablity object in a different thread.
    NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
    
    Reachability* noteObject = (Reachability*) info;
    // Post a notification to notify the client that the network reachability changed.
    [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];
    
    [myPool release];
}
 
- (BOOL) startNotifier{
    BOOL retVal = NO;
    SCNetworkReachabilityContext    context = {0, self, NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)){
        if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)){
            retVal = YES;
        }
    }
    return retVal;
}
 
- (void) stopNotifier{
    if(reachabilityRef!= NULL){
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}
 
- (void) dealloc{
    [self stopNotifier];
    if(reachabilityRef!= NULL){
        CFRelease(reachabilityRef);
    }
    [super dealloc];
}
 
+ (Reachability*) reachabilityWithHostName: (NSString*) hostName{
    Reachability* retVal = NULL;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if(reachability!= NULL){
        retVal= [[[self alloc] init] autorelease];
        if(retVal!= NULL){
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}
 
+ (Reachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    Reachability* retVal = NULL;
    if(reachability!= NULL){
        retVal= [[[self alloc] init] autorelease];
        if(retVal!= NULL){
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}
 
+(Reachability*) reachabilityForInternetConnection{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self reachabilityWithAddress: &zeroAddress];
}
 
+(Reachability*) reachabilityForLocalWiFi{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    Reachability* retVal = [self reachabilityWithAddress: &localWifiAddress];
    if(retVal!= NULL){
        retVal->localWiFiRef = YES;
    }
    return retVal;
}
 
#pragma mark Network Flag Handling
 
- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags{
    PrintReachabilityFlags(flags, "localWiFiStatusForFlags");
 
    BOOL retVal = NotReachable;
    if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect)){
        retVal = ReachableViaWiFi;  
    }
    return retVal;
}
 
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags{
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0){
        // if target host is not reachable
        return NotReachable;
    }
 
    BOOL retVal = NotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0){
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = ReachableViaWiFi;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)){
            // ... and the connection is on-demand (or on-traffic) if the
            //     calling application is using the CFSocketStream or higher APIs
 
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
            {
                // ... and no [user] intervention is needed
                retVal = ReachableViaWiFi;
            }
        }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN){
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = ReachableViaWWAN;
    }
    return retVal;
}
 
- (BOOL) connectionRequired{
    //NSAssert(reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)){
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    return NO;
}
 
- (NetworkStatus) currentReachabilityStatus{
    //NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
    NetworkStatus retVal = NotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)){
        if(localWiFiRef){
            retVal = [self localWiFiStatusForFlags: flags];
        }else{
            retVal = [self networkStatusForFlags: flags];
        }
    }
    return retVal;
}
@end




