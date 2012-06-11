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
#import "BT_rotatingNavController.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_debugger.h"
#import "JSON.h"
#import "BT_viewUtilities.h"
#import "BT_item.h"
#import <QuartzCore/QuartzCore.h>




@implementation BT_rotatingNavController

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


/*
 This core navigation method determines what type of transition to use
 before pushing the next view controller. Before pushing the controller, it refers to the currentMenuItemData
 object remembered in the app's delegate. 	
 */
-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
	
	//appDelegate.rootApp remembers the last screen that loaded and the last menu item that was tapped...
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	BT_item *theMenuItemData = [appDelegate.rootApp currentMenuItemData];
    
	//debug
	[BT_debugger showIt:self:[NSString stringWithFormat:@"pushViewController for screen: %@", [appDelegate.rootApp.currentScreenData itemId]]];
    
    
	//animated or not?
	if([theMenuItemData.jsonVars objectForKey:@"transitionType"]){
		NSString *theTransition = [theMenuItemData.jsonVars objectForKey:@"transitionType"];
		NSArray *supportedAnimations = [NSArray arrayWithObjects:@"curl", @"flip", @"fade", @"grow", @"slideUp", @"slideDown", nil];
		if([supportedAnimations containsObject:theTransition]){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"transition type: %@", theTransition]];
			
			//add the transition to the history so we can reverse it.
			[appDelegate.rootApp.transitionTypeHistory addObject:theTransition];
			
			//curl
			if([theTransition isEqualToString:@"curl"]){
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.75];
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:NO];
				[super pushViewController:viewController animated:NO];
				[UIView commitAnimations];
			}
			
			//flip
			if([theTransition isEqualToString:@"flip"]){
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.75];
				[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:NO];
				[super pushViewController:viewController animated:NO];
				[UIView commitAnimations];
			}
			
			//fade
			if([theTransition isEqualToString:@"fade"]){
				CATransition * animation = [CATransition animation];
				animation.type = kCATransitionFade;
				[animation setDuration:0.35];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				[super pushViewController:viewController animated:NO];
			}
			
			//grow
			if([theTransition isEqualToString:@"grow"]){
				[UIView beginAnimations:nil context:nil]; 
				self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
				[UIView setAnimationDuration:0.5];
				self.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
				[UIView commitAnimations];
				[super pushViewController:viewController animated:NO];
			}		
			
			//slideUp
			if([theTransition isEqualToString:@"slideUp"]){
				CATransition * animation = [CATransition animation];
				[animation setType:kCATransitionPush];
				[animation setSubtype:kCATransitionFromTop];
				[animation setDuration:0.35];
				[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				[super pushViewController:viewController animated:NO];
			}		
            
			//slideDown
			if([theTransition isEqualToString:@"slideDown"]){
				CATransition * animation = [CATransition animation];
				[animation setType:kCATransitionPush];
				[animation setSubtype:kCATransitionFromBottom];
				[animation setDuration:0.35];
				[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				[super pushViewController:viewController animated:NO];
			}		
			
			//bail
			return;
			
		}//supported animation
		
	}
	
	//add the transition to the history so we can reverse it.
	[appDelegate.rootApp.transitionTypeHistory addObject:@""];
    
	//if we are here, this screen does not use an animation (or the animation is not supported)
	[super pushViewController:viewController animated:animated];
	
    
}


//over-ride the generic pop method so we can use a custom animation
-(UIViewController *)popViewControllerAnimated:(BOOL)animated{
	
	//delegate.
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//the screen that was tapped is remembered in the app's delegate
	[BT_debugger showIt:self:[NSString stringWithFormat:@"popViewControllerAnimated for screen: %@", [appDelegate.rootApp.currentScreenData itemId]]];
    
	//previous transition is the last item in the history array
	NSString *theTransition = @"";
	if([appDelegate.rootApp.transitionTypeHistory count] > 0){
		theTransition = [appDelegate.rootApp.transitionTypeHistory lastObject];
		[appDelegate.rootApp.transitionTypeHistory removeLastObject];
	}
	
	//animated or not?
	if([theTransition length] > 1){
		NSArray *supportedAnimations = [NSArray arrayWithObjects:@"curl", @"flip", @"fade", @"grow", @"slideUp", @"slideDown", nil];
		if([supportedAnimations containsObject:theTransition]){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"transition type: %@", theTransition]];
            
            
			UIViewController *viewController;
			//curl
			if([theTransition isEqualToString:@"curl"]){
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.75];
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
				viewController = [super popViewControllerAnimated:NO];
				[UIView commitAnimations];
			}
			
			//flip
			if([theTransition isEqualToString:@"flip"]){
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.75];
				[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:NO];
				viewController = [super popViewControllerAnimated:NO];
				[UIView commitAnimations];
			}
			
			//fade
			if([theTransition isEqualToString:@"fade"]){
				CATransition * animation = [CATransition animation];
				animation.type = kCATransitionFade;
				[animation setDuration:0.35];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				viewController = [super popViewControllerAnimated:NO];
			}
			
			//grow
			if([theTransition isEqualToString:@"grow"]){
				[UIView beginAnimations:nil context:nil]; 
				self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
				[UIView setAnimationDuration:0.5];
				self.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
				[UIView commitAnimations];	
				viewController = [super popViewControllerAnimated:NO];
			}		
			
			//slideUp (this slides down when popping)
			if([theTransition isEqualToString:@"slideUp"]){
				CATransition * animation = [CATransition animation];
				[animation setType:kCATransitionPush];
				[animation setSubtype:kCATransitionFromBottom];
				[animation setDuration:0.35];
				[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				viewController = [super popViewControllerAnimated:NO];
			}		
            
			//slideDown (this slides up when popping)
			if([theTransition isEqualToString:@"slideDown"]){
				CATransition * animation = [CATransition animation];
				[animation setType:kCATransitionPush];
				[animation setSubtype:kCATransitionFromTop];
				[animation setDuration:0.35];
				[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
				[[self.view layer] addAnimation:animation forKey:@"Animate"];	
				viewController = [super popViewControllerAnimated:NO];
			}	
            
			//return		
			return viewController;
            
		}//supported animation
        
	}
	
	//if we are here, this screen does not use an animation (or the animation is not supported)
	return [super popViewControllerAnimated:animated];
	
	
}


//email Compose sheet canceled / closed 
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {	
	[BT_debugger showIt:self:@"mailComposeController:didFinishComposingMail"];
	[self dismissModalViewControllerAnimated:YES];
	
	//delegate.
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//if this is an iPad AND our "currentScreenData" is BT_screen_imageEmail
	if([appDelegate.rootApp.rootDevice isIPad]){
		if([[appDelegate.rootApp.currentScreenData.jsonVars objectForKey:@"itemType"] isEqualToString:@"BT_screen_imageEmail"]){
			
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"emailImageDone", "Re-load this screen to re-start the process or to send another message") delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
			[alertView show];
			[alertView release];
			
		}
		
	}//is iPad
    
}


//SMS Compose sheet canceled / closed 
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
	[BT_debugger showIt:self:@"messageComposeViewController:didFinishComposingSMS"];
	[self dismissModalViewControllerAnimated:YES];
	
}



//will rotate
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"willRotateToInterfaceOrientation %@", @""]];
	NSLog(@"Will rotate to...");
	
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
    if ([theViewController respondsToSelector:NSSelectorFromString(@"setNotRotating")]) {
        SEL s = NSSelectorFromString(@"setNotRotating");
        [theViewController performSelector:s];
    }    
    
    
    
	//some screens need to re-build their layout...If a plugin has a method called
    //"layoutScreen" we trigger it everytime the device rotates. The plugin author can
    //create this method in the UIViewController (layoutScreen) if they need something to 
    //happen after rotation occurs.
    
    
    //if this view controller has a "layoutScreen" method, trigger it...
    if([theViewController respondsToSelector:@selector(layoutScreen)]){
        SEL s = NSSelectorFromString(@"layoutScreen");
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




@end








