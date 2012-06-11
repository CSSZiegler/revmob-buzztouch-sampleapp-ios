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
#import "iAd/ADBannerView.h"
#import "BT_rotatingTabBarController.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_debugger.h"


@implementation BT_rotatingTabBarController

//init
-(id)init{
    if((self = [super init])){
		//[BT_debugger showIt:self:[NSString stringWithFormat:@"INIT%@", @""]];
	}
	return self;
}

//should rotate
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"shouldAutorotateToInterfaceOrientation %@", @""]];
    
    
	//allow / dissallow rotations
	BOOL canRotate = TRUE;
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	if([appDelegate.rootApp.rootDevice isIPad]){
		canRotate = TRUE;
	}else{
		//should we prevent rotations on small devices?
		if([appDelegate.rootApp.jsonVars objectForKey:@"allowRotation"]){
			if([[appDelegate.rootApp.jsonVars objectForKey:@"allowRotation"] isEqualToString:@"largeDevicesOnly"]){
				canRotate = FALSE;
			}
		}
	}
    
	//can it rotate? 
	if(canRotate){
		return YES;
	}else{
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
	
	//we should not get here
	return YES;		
	
}


//will rotate
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"willRotateToInterfaceOrientation %@", @""]];
	
	//delegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//some screens need to reload...
	UIViewController *theViewController;
	int selectedTab = 0;
	if([appDelegate.rootApp.tabs count] > 0){
		selectedTab = [appDelegate.rootApp.rootTabBarController selectedIndex];
		theViewController = [[appDelegate.rootApp.rootTabBarController.viewControllers objectAtIndex:selectedTab] visibleViewController];
	}else{
		theViewController = [appDelegate.rootApp.rootNavController visibleViewController];
	}
    
    
    //If we have an ad view we may need to modify it's layout...
	for(UIView* subView in [theViewController.view subviews]){
		if(subView.tag == 94){
			for(UIView* subView_2 in [subView subviews]){
				if(subView_2.tag == 955){
					
                    ADBannerView *theAdView = (ADBannerView *)subView_2;
                    if([subView_2 respondsToSelector:@selector(setCurrentContentSizeIdentifier:)]){
                        if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
                            [theAdView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
                        }else{
                            [theAdView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];            
                        }
                    }
                    
				}
			}
			break;
		}	
	}
    
    
    //if this view controller has a property named "rotating" set it to false...This for sure
    //is used in the Image Gallery plugin...
    if ([theViewController respondsToSelector:NSSelectorFromString(@"setIsRotating")]) {
        SEL s = NSSelectorFromString(@"setIsRotating");
        [theViewController performSelector:s];
    }   
    
    
	
}

//did rotate
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"didRotateFromInterfaceOrientation %@", @""]];
	
	//delegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//some screens need to reload...
	UIViewController *theViewController;
	int selectedTab = 0;
	if([appDelegate.rootApp.tabs count] > 0){
		selectedTab = [appDelegate.rootApp.rootTabBarController selectedIndex];
		theViewController = [[appDelegate.rootApp.rootTabBarController.viewControllers objectAtIndex:selectedTab] visibleViewController];
	}else{
		theViewController = [appDelegate.rootApp.rootNavController visibleViewController];
	}
    
    //if this view controller has a property named "rotating" set it to false...This for sure
    //is used in the Image Gallery plugin...
    if ([theViewController respondsToSelector:NSSelectorFromString(@"rotating")]) {
        [theViewController setValue:0 forKey:@"rotating"];
    } 
    
    
	//some screens need to re-build their layout...If a plugin has a method called
    //"layoutScreen" we trigger it everytime the device rotates. The plugin author can
    //create this method in the UIViewController (layoutScreen) if they need something to 
    //happen after rotation occurs.
    
    
    //if this view controller has a property named "rotating" set it to false...This for sure
    //is used in the Image Gallery plugin...
    if ([theViewController respondsToSelector:NSSelectorFromString(@"setNotRotating")]) {
        SEL s = NSSelectorFromString(@"setNotRotating");
        [theViewController performSelector:s];
    }  
    
	
}

//will animate
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"didRotateFromInterfaceOrientation %@", @""]];
	
	//delegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//some screens need to reload...
	UIViewController *theViewController;
	int selectedTab = 0;
	if([appDelegate.rootApp.tabs count] > 0){
		selectedTab = [appDelegate.rootApp.rootTabBarController selectedIndex];
		theViewController = [[appDelegate.rootApp.rootTabBarController.viewControllers objectAtIndex:selectedTab] visibleViewController];
	}else{
		theViewController = [appDelegate.rootApp.rootNavController visibleViewController];
	}
    
    
	
    
	
}


//after the tabber's view loaded
- (void)viewDidLoad {
    [super viewDidLoad];
	[BT_debugger showIt:self:[NSString stringWithFormat:@"tabBarController view loaded%@", @""]];
}

//adds color overlay view
-(void)addTabColor:(UIColor *)theColor:(double)theOpacity{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"addTabColor%@", @""]];
	
	//add an overlay-view on top of the tabs so it looks colorized..    
	CGRect frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 48);
	UIView *v = [[UIView alloc] initWithFrame:frame];
	v.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[v setBackgroundColor:theColor];
	[v setAlpha:theOpacity];
	[[self tabBar] addSubview:v];
	[v release];
	
}

//dealloc
- (void)dealloc {
    [super dealloc];
}


@end





