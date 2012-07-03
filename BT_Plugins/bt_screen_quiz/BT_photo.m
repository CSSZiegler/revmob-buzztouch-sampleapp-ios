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
#import "BT_debugger.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_photo.h"
#import "BT_strings.h"
#import "BT_fileManager.h"
#import "BT_imageDecompress.h"

// Private
@interface BT_photo()

// Properties
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) UIImage *photoImage;
@property (nonatomic, retain) NSString *photoPath;
@property (nonatomic, retain) NSURL *photoURL;

@property () BOOL workingInBackground;

// Private Methods
-(void)doBackgroundWork:(id <BTPhotoDelegate>)delegate;

@end


// BT_photo
@implementation BT_photo


// Properties
@synthesize imageName, photoImage, photoPath, photoURL, workingInBackground;

#pragma mark Class Methods

+(BT_photo *)photoWithImage:(UIImage *)image {
	return [[[BT_photo alloc] initWithImage:image] autorelease];
}

+(BT_photo *)photoWithFilePath:(NSString *)path {
	return [[[BT_photo alloc] initWithFilePath:path] autorelease];
}

+(BT_photo *)photoWithURL:(NSURL *)url {
	return [[[BT_photo alloc] initWithURL:url] autorelease];
}

-(id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		self.photoImage = image;
	}
	return self;
}

- (id)initWithFilePath:(NSString *)path {
	if ((self = [super init])) {
		photoPath = [path copy];
	}
	self.imageName = [BT_strings getFileNameFromURL:path];
	return self;
}

- (id)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		photoURL = [url copy];
	}
	self.imageName = [[photoURL absoluteString] lastPathComponent];	
	return self;
}

#pragma mark Photo

//loading from file or URL
-(BOOL)isImageAvailable {
	return (self.photoImage != nil);
}

//return image
-(UIImage *)image {
	return self.photoImage;
}

//get and return the image from existing image, file path or url
- (UIImage *)obtainImage {
	if (!self.photoImage) {
		
		//if we loaded the image from a URL "the last time" this image was fetched, it may be saved...
		int isCached = FALSE;
		if(self.imageName.length > 3){
			if([BT_fileManager doesLocalFileExist:self.imageName]){
				photoPath = [BT_fileManager getFilePath:self.imageName];
			 	isCached = TRUE;
			}
		}		

		//load
		UIImage *img = nil;
		if(self.photoPath){ 
			
			//read image from file
			NSError *error = nil;
			NSData *data = [NSData dataWithContentsOfFile:photoPath options:NSDataReadingUncached error:&error];
			if(!error){
				img = [[UIImage alloc] initWithData:data];
			}else{
				[BT_debugger showIt:self:[NSString stringWithFormat:@"Error loading image from: %@", error]];
			}
			
		} else if (photoURL) { 
			
			[BT_debugger showIt:self:[NSString stringWithFormat:@"Downloading image from URL: %@", [photoURL absoluteString]]];

			// Read image from URL and return
			NSURLRequest *request = [[NSURLRequest alloc] initWithURL:photoURL];
			NSError *error = nil;
			NSURLResponse *response = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			[request release];
			if(data){
				img = [[UIImage alloc] initWithData:data];

				//are we caching this image? delegate remembers was screen we are on...
				revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
				BT_item *theScreenData = [appDelegate.rootApp currentScreenData];
				
				if([[BT_strings getJsonPropertyValue:theScreenData.jsonVars:@"cacheWebImages":@"0"] isEqualToString:@"1"]){
					
					//be sure we have an image name (file name)..
					if([self.imageName length] > 3){
						[BT_fileManager saveImageToFile:img:self.imageName];
					}

				}else{
					[BT_debugger showIt:self:[NSString stringWithFormat:@"Not saving web image to cache:: %@", @""]];
				}
				
			}else{
			
				[BT_debugger showIt:self:[NSString stringWithFormat:@"Error downloading image from URL: %@", error]];
			}
			
		}

		//force the loading and caching of raw image data for speed
		[img decompress];		
		
		//store
		self.photoImage = img;
		[img release];
		
	}
	return [[self.photoImage retain] autorelease];
}

// Release if we can get it again from path or url
- (void)releasePhoto {
	if (self.photoImage && (photoPath || photoURL)) {
		self.photoImage = nil;
	}
}

//obtain image in background and notify the delegate when it has loaded
- (void)obtainImageInBackgroundAndNotify:(id <BTPhotoDelegate>)delegate {
	if (self.workingInBackground == YES) return; // Already fetching
	self.workingInBackground = YES;
	[self performSelectorInBackground:@selector(doBackgroundWork:) withObject:delegate];
}

//download image and notify delegate
- (void)doBackgroundWork:(id <BTPhotoDelegate>)delegate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//load image
	UIImage *img = [self obtainImage];
	
	//notify delegate of success or fail
	if (img) {
		[(NSObject *)delegate performSelectorOnMainThread:@selector(photoDidFinishLoading:) withObject:self waitUntilDone:NO];
	} else {
		[(NSObject *)delegate performSelectorOnMainThread:@selector(photoDidFailToLoad:) withObject:self waitUntilDone:NO];		
	}

	// Finish
	self.workingInBackground = NO;
	
	[pool release];
}

- (void)dealloc {
	[photoPath release];
	[photoURL release];
	[photoImage release];
	[imageName release];
	[super dealloc];
}




@end











