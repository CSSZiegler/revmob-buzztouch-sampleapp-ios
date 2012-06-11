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
#import "iAd/ADBannerView.h"
#import "JSON.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"
#import "BT_viewUtilities.h"
#import "BT_viewController.h"

@implementation BT_viewController
@synthesize progressView, screenData;
@synthesize adView, adBannerView, adBannerViewIsVisible;
@synthesize hasStatusBar, hasNavBar, hasToolBar;

//initWithScreenData
-(id)initWithScreenData:(BT_item *)theScreenData{
	if((self = [super init])){
		[BT_debugger showIt:self:@"INIT"];

		//set screen data
		[self setScreenData:theScreenData];
		
	}
	 return self;
}

//show progress
-(void)showProgress{
	[BT_debugger showIt:self:@"showProgress"];
	
	//show progress view if not showing
	if(progressView == nil){
		progressView = [BT_viewUtilities getProgressView:@""];
		[self.view addSubview:progressView];
	}	
	
}

//hide progress
-(void)hideProgress{
	[BT_debugger showIt:self:@"hideProgress"];
	
	//remove progress view if already showing
	if(progressView != nil){
		[progressView removeFromSuperview];
		progressView = nil;
	}

}

//left button
-(void)navLeftTap{
	[BT_debugger showIt:self:@"navLeftTap"];

	//handle "left" transition
	[BT_viewControllerManager handleLeftButton:screenData];
	
}

//right button
-(void)navRightTap{
	[BT_debugger showIt:self:@"navRightTap"];
	
	//handle "right" transition
	[BT_viewControllerManager handleRightButton:screenData];
	
}

//show audio controls
-(void)showAudioControls{
	[BT_debugger showIt:self:@"showAudioControls"];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	[appDelegate showAudioControls];

}

//show alert
-(void)showAlert:(NSString *)theTitle:(NSString *)theMessage:(int)alertTag{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:theTitle message:theMessage delegate:self
	cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
	[alertView setTag:alertTag];
	[alertView show];
	[alertView release];
}

//"OK" clicks on UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"alertView:clickedButtonAtIndex: %i", buttonIndex]];
	
	//handles OK click after emailing an image from BT_screen_imageEmail
	if([alertView tag] == 99){
		[self.navigationController popViewControllerAnimated:YES];
	}

	//handles OK click after sharing from BT_screen_shareFacebook or BT_screen_shareTwitter
	if([alertView tag] == 199){
		[self navLeftTap];
	}
	
}


////////////////////////////////////////////
//Ad Size Methods

//createAdBannerView
-(void)createAdBannerView{
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if(classAdBannerView != nil){
		[BT_debugger showIt:self:[NSString stringWithFormat:@"createiAdBannerView: %@", @""]];
		self.adView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		self.adView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);	
		[self.adView setTag:94];
		self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
		[self.adBannerView setDelegate:self];
		[self.adBannerView setTag:955];
		if(UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [adBannerView setCurrentContentSizeIdentifier: ADBannerContentSizeIdentifierLandscape];
        }else{
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];            
        }
		[self.adView setFrame:[BT_viewUtilities frameForAdView:self:screenData]];
		[adView setBackgroundColor:[UIColor clearColor]];
		[self.adView addSubview:self.adBannerView];
        [self.view addSubview:adView];
		[self.view bringSubviewToFront:adView];        
    }
}

//showHideAdView
-(void)showHideAdView{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"showHideAdView: %@", @""]];
	if(adBannerView != nil){   
		//we may need to change the banner ad layout
		if(UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        }else{
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        }
        [UIView beginAnimations:@"positioniAdView" context:nil];
		[UIView setAnimationDuration:1.5];
        if(adBannerViewIsVisible){
            [self.adView setAlpha:1.0];
        }else{
			[self.adView setAlpha:.0];
       }
	   [UIView commitAnimations];
    }   
}

//banner view did load...
-(void)bannerViewDidLoadAd:(ADBannerView *)banner{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"iAd bannerViewDidLoadAd%@", @""]];
    if(!adBannerViewIsVisible) {                
        adBannerViewIsVisible = YES;
        [self showHideAdView];
    }
}
 
//banner view failed to get add
-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"iAd didFailToReceiveAdWithError: %@", [error localizedDescription]]];
	if (adBannerViewIsVisible){        
        adBannerViewIsVisible = NO;
        [self showHideAdView];
    }
}


//shouldAutorotateToInterfaceOrientation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

//didReceiveMemoryWarning
-(void)didReceiveMemoryWarning{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"appDelegate didReceiveMemoryWarning%@", @""]];
}

@end







