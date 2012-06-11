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
#import "BT_color.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_debugger.h"
#import "BT_viewControllerManager.h"

#import "BT_background_view.h"

@implementation BT_background_view
@synthesize theScreen, JSONdata, backgroundImageView, backgroundImage, bgColorView, bgGradientView;
@synthesize imageName, imageURL, colorOpacity, imageOpacity;

-(id)initWithScreenData:(BT_item *)theScreenData{
	if((self = [super init])){
		[BT_debugger showIt:self:@"INIT"];
		
		//set screen data
		[self setTheScreen:theScreenData];
		
		//no interaction allowed in background views
		[self setUserInteractionEnabled:FALSE];
		
		//appDelegate 
		revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

		//figure out full-size frame
		CGRect fullSizeFrame = CGRectMake(0, 0, appDelegate.window.bounds.size.width, appDelegate.window.bounds.size.height);

		//set this view's frame
		[self setFrame:fullSizeFrame];
		self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self setAutoresizesSubviews:TRUE];
		
		//////////////////////////////////////////////////////////////
		// 1) Add a full-size sub-view to hold a possible solid color
		//solid background color
		
		//solid background properties..
		UIColor *solidBgColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColor":@"clear"]];
		NSString *solidBgOpacity = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorOpacity":@"100"];
		if([solidBgOpacity isEqualToString:@"100"]) solidBgOpacity = @"99";
		solidBgOpacity = [NSString stringWithFormat:@".%@", solidBgOpacity];
		
		//sub-view for background color
		bgColorView = [[UIView alloc] initWithFrame:fullSizeFrame];
		bgColorView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self setColorOpacity:[solidBgOpacity doubleValue]];
		[bgColorView setAlpha:[self colorOpacity]];
		[bgColorView setBackgroundColor:solidBgColor];
		[self addSubview:bgColorView];
		
		//////////////////////////////////////////////////////////////
		// 2) Add a full-size sub-view to hold a possible gradient background
		//gradient background color goes "on top" of solid background color
				
		UIColor *gradBgColorTop = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientTop":@""]];
		UIColor *gradBgColorBottom = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientBottom":@""]];
				
		//gradients will NOT automatically scale so we need to make it larger than the screen.
		UIView *gradView;
		if([appDelegate.rootApp.rootDevice isIPad]){
			bgGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1500, 1500)];
			gradView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1500, 1500)];
		}else{
			bgGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
			gradView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
		}
		gradView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[gradView setTag:33];
		bgGradientView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
			
		//apply gradient to gradView color
		if([[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientTop":@""] length] > 3 && [[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientBottom":@""] length] > 3){
			gradView = [BT_viewUtilities applyGradient:gradView:gradBgColorTop:gradBgColorBottom];
		}else{
			[gradView  setBackgroundColor:[UIColor clearColor]];
		}
		[self.bgGradientView addSubview:gradView];
		[self addSubview:bgGradientView];
		[gradView release];

		//////////////////////////////////////////////////////////////
		// 3) if we have an image, fix-up the image view
		
		backgroundImageView = [[UIImageView alloc] initWithFrame:fullSizeFrame];
		backgroundImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		
		NSString *backgroundImageScale = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageScale":@"center"];
		
		//set the content mode for the image...
		if([backgroundImageScale isEqualToString:@"center"]) [backgroundImageView setContentMode:UIViewContentModeCenter];
		if([backgroundImageScale isEqualToString:@"fullScreen"]) [backgroundImageView setContentMode:UIViewContentModeScaleToFill];
		if([backgroundImageScale isEqualToString:@"fullScreenPreserve"]) [backgroundImageView setContentMode:UIViewContentModeScaleAspectFit];
		if([backgroundImageScale isEqualToString:@"top"]) [backgroundImageView setContentMode:UIViewContentModeTop];
		if([backgroundImageScale isEqualToString:@"bottom"]) [backgroundImageView setContentMode:UIViewContentModeBottom];
		if([backgroundImageScale isEqualToString:@"topLeft"]) [backgroundImageView setContentMode:UIViewContentModeTopLeft];
		if([backgroundImageScale isEqualToString:@"topRight"]) [backgroundImageView setContentMode:UIViewContentModeTopRight];
		if([backgroundImageScale isEqualToString:@"bottomLeft"]) [backgroundImageView setContentMode:UIViewContentModeBottomLeft];
		if([backgroundImageScale isEqualToString:@"bottomRight"]) [backgroundImageView setContentMode:UIViewContentModeBottomRight];

		//set the image's opacity
		NSString *imageBgOpacity = [BT_strings getStyleValueForScreen:self.theScreen:@"backgroundImageOpacity":@"100"];
		if([imageBgOpacity isEqualToString:@"100"]) imageBgOpacity = @"99";
		imageBgOpacity = [NSString stringWithFormat:@".%@", imageBgOpacity];
		[self.backgroundImageView setAlpha:[imageBgOpacity doubleValue]];
		[self addSubview:self.backgroundImageView];
			
		//////////////////////////////////////////////////////////////
		// 4) find / load a possible image
		
		//image name, URL
		self.imageName = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageNameSmallDevice":@""];
		self.imageURL = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageURLSmallDevice":@""];
		if([appDelegate.rootApp.rootDevice isIPad]){
			self.imageName = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageNameLargeDevice":@""];
			self.imageURL = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageURLLargeDevice":@""];
		}
        
        //if both are blank... this is necessary so 'previous screen background' does not show on 'back button' if previous
        //screen did not have a background image set.
        if([self.imageName length] < 1 && [self.imageURL length] < 1){
            [self setImageName:@"blank.png"];
        }
        
        //if both are blank...
        if([self.imageName length] < 1 && [self.imageURL length] < 1){
            [self setImageName:@"blank.png"];
        }
		

		/* 
			Where is the background image?
			a) File exists in bundle. Use this image, ignore possible download URL
			b) File DOES NOT exist in bundle, but does exist in writeable data directory: Use it. (it was already downloaded and saved)
			c) File DOES NOT exist in bundle, and DOES NOT exist in writeable data directory and an imageURL is set: Download it, save it for next time, use it.
		*/
		
		//get the image
		if([self.imageName length] > 1){
			
			
			if([BT_fileManager doesFileExistInBundle:imageName]){
				
				[BT_debugger showIt:self:@"Image for background view exists in Xcode bundle - not downloading."];
				self.backgroundImage = [UIImage imageNamed:self.imageName];
				[self setImage:self.backgroundImage];
				
			}else{
			
				if([BT_fileManager doesLocalFileExist:imageName]){

					[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view exists in cache, not downloading: %@", [self imageName]]];
					self.backgroundImage = [BT_fileManager getImageFromFile:imageName];
					[self setImage:self.backgroundImage];

				}else{
				
					if([self.imageURL length] > 3 && [self.imageName length] > 3){
				
						[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view does not exist in cache - downloading: %@", [self imageURL]]];
						[self performSelector:@selector(downloadImage) withObject:nil afterDelay:.5];
					
					}else{
					
						[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view does not exist in xcode project, or in cache and no URL provided, not downloading: %@", [self imageName]]];

					}

					
				}
				
			}
			
		}//imageName
			
		
	}
	 return self;
}

//updates properites with new screen data
-(void)updateProperties:(BT_item *)theScreenData{

	//appDelegate 
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

	//////////////////////////////////////////////////////////////
	// 1) update the solid color
	
	//solid background properties..
	UIColor *solidBgColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColor":@"clear"]];
	NSString *solidBgOpacity = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorOpacity":@"100"];
	if([solidBgOpacity isEqualToString:@"100"]) solidBgOpacity = @"99";
	solidBgOpacity = [NSString stringWithFormat:@".%@", solidBgOpacity];
	
	//sub-view for background color
	[self setColorOpacity:[solidBgOpacity doubleValue]];
	[bgColorView setAlpha:[self colorOpacity]];
	[bgColorView setBackgroundColor:solidBgColor];
	
	//////////////////////////////////////////////////////////////
	// 2) update the gradient view
			
	UIColor *gradBgColorTop = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientTop":@""]];
	UIColor *gradBgColorBottom = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientBottom":@""]];
			
	//if our gradient view has subViews, we already applied a gradient..remove it..
	for(UIView* subView in [self.bgGradientView subviews]){
		if([subView tag] == 33){
			[subView removeFromSuperview];
		}			
	}
	
	//gradients will NOT automatically scale so we need to make it larger than the screen.
	UIView *gradView;
	if([appDelegate.rootApp.rootDevice isIPad]){
		gradView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1500, 1500)];
	}else{
		gradView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
	}
	gradView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[gradView setTag:33];
		
	//apply gradient to gradView color
	if([[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientTop":@""] length] > 3 && [[BT_strings getStyleValueForScreen:theScreenData:@"backgroundColorGradientBottom":@""] length] > 3){
		gradView = [BT_viewUtilities applyGradient:gradView:gradBgColorTop:gradBgColorBottom];
	}else{
		[gradView  setBackgroundColor:[UIColor clearColor]];
	}
	[self.bgGradientView addSubview:gradView];
	[gradView release];

	//////////////////////////////////////////////////////////////
	// 3) update the image
	
	//set the image's opacity
	NSString *imageBgOpacity = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageOpacity":@"100"];
	if([imageBgOpacity isEqualToString:@"100"]) imageBgOpacity = @"99";
	imageBgOpacity = [NSString stringWithFormat:@".%@", imageBgOpacity];
	[self.backgroundImageView setAlpha:[imageBgOpacity doubleValue]];
		
	NSString *backgroundImageScale = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageScale":@"center"];
		
	//set the content mode for the image...
	if([backgroundImageScale isEqualToString:@"center"]) [backgroundImageView setContentMode:UIViewContentModeCenter];
	if([backgroundImageScale isEqualToString:@"fullScreen"]) [backgroundImageView setContentMode:UIViewContentModeScaleToFill];
	if([backgroundImageScale isEqualToString:@"fullScreenPreserve"]) [backgroundImageView setContentMode:UIViewContentModeScaleAspectFit];
	if([backgroundImageScale isEqualToString:@"top"]) [backgroundImageView setContentMode:UIViewContentModeTop];
	if([backgroundImageScale isEqualToString:@"bottom"]) [backgroundImageView setContentMode:UIViewContentModeBottom];
	if([backgroundImageScale isEqualToString:@"topLeft"]) [backgroundImageView setContentMode:UIViewContentModeTopLeft];
	if([backgroundImageScale isEqualToString:@"topRight"]) [backgroundImageView setContentMode:UIViewContentModeTopRight];
	if([backgroundImageScale isEqualToString:@"bottomLeft"]) [backgroundImageView setContentMode:UIViewContentModeBottomLeft];
	if([backgroundImageScale isEqualToString:@"bottomRight"]) [backgroundImageView setContentMode:UIViewContentModeBottomRight];
	
		
	//////////////////////////////////////////////////////////////
	// 4) find / load a possible image
	
	//image name, URL
	self.imageName = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageNameSmallDevice":@""];
	self.imageURL = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageURLSmallDevice":@""];
	if([appDelegate.rootApp.rootDevice isIPad]){
		self.imageName = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageNameLargeDevice":@""];
		self.imageURL = [BT_strings getStyleValueForScreen:theScreenData:@"backgroundImageURLLargeDevice":@""];
	}
	//if we have an imageURL, and no imageName, figure out a name to use...
	if(self.imageName.length < 3 && self.imageURL.length > 3){
		self.imageName = [BT_strings getFileNameFromURL:self.imageURL];
	}
    
    //if both are blank... this is necessary so 'previous screen background' does not show on 'back button' if previous
    //screen did not have a background image set.
    if([self.imageName length] < 1 && [self.imageURL length] < 1){
        [self setImageName:@"blank.png"];
    }   
	

	/* 
		Where is the background image?
		a) File exists in bundle. Use this image, ignore possible download URL
		b) File DOES NOT exist in bundle, but does exist in writeable data directory: Use it. (it was already downloaded and saved)
		c) File DOES NOT exist in bundle, and DOES NOT exist in writeable data directory and an imageURL is set: Download it, save it for next time, use it.
	*/
	
	//get the image
	if([self.imageName length] > 1){
		
		
		if([BT_fileManager doesFileExistInBundle:imageName]){
			
			[BT_debugger showIt:self:@"Image for background view exists in Xcode bundle - not downloading."];
			self.backgroundImage = [UIImage imageNamed:self.imageName];
			[self setImage:self.backgroundImage];
			
		}else{
		
			if([BT_fileManager doesLocalFileExist:imageName]){

				[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view exists in cache, not downloading: %@", [self imageName]]];
				self.backgroundImage = [BT_fileManager getImageFromFile:imageName];
				[self setImage:self.backgroundImage];

			}else{
			
				if([self.imageURL length] > 3 && [self.imageName length] > 3){
			
					[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view does not exist in cache - downloading: %@", [self imageURL]]];
					[self performSelector:@selector(downloadImage) withObject:nil afterDelay:.5];
				
				}else{
				
					[BT_debugger showIt:self:[NSString stringWithFormat:@"Image for background view does not exist in xcode project, or in cache and no URL provided, not downloading: %@", [self imageName]]];

				}

				
			}
			
		}
		
	}//imageName


}


//downloadImage 
-(void)downloadImage{

	//only do this if we have an image URL
	if([self.imageURL length] > 3 && [self.imageName length] > 3){

		[BT_debugger showIt:self:@"downloadImage"];

		//start download
		BT_downloader *tmpDownloader = [[BT_downloader alloc] init];
		[tmpDownloader setUrlString:imageURL];
		[tmpDownloader setSaveAsFileName:imageName];
		[tmpDownloader setSaveAsFileType:@"image"];
		[tmpDownloader setDelegate:self];
		[tmpDownloader downloadFile];
		
		//clean up
		[tmpDownloader release];
		tmpDownloader = nil;	
	
	}
}

//set image
-(void)setImage:(UIImage *)theImage{
	[BT_debugger showIt:self:@"setImage"];
	
	if(theImage != nil){
		[self.backgroundImageView setImage:theImage];
	}
	
}


//////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
}
-(void)downloadFileCompleted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
	
	//set image we just downloaded and saved.
	if([BT_fileManager doesLocalFileExist:imageName]){
		self.backgroundImage = [BT_fileManager getImageFromFile:imageName];
		[self setImage:self.backgroundImage];
	}else{
		self.backgroundImage = [UIImage imageNamed:@"blank.png"];
		[self setImage:self.backgroundImage];
	}

	
}
//////////////////////////////////////////////////////////////


- (void)dealloc {

	[theScreen release];
		theScreen = nil;
	[JSONdata release];
		JSONdata = nil;
	[bgColorView release];
		bgColorView = nil;
	[bgGradientView release];
		bgGradientView = nil;
	[backgroundImageView release];
		backgroundImageView = nil;
	[backgroundImage release];
		backgroundImage = nil;
	[imageName release];
		imageName = nil;
	[imageURL release];
		imageURL = nil;
    [super dealloc];


}


@end






