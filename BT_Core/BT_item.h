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

@interface BT_item: NSObject{

	/*
		Example Item Types: 
		-----------------
		"BT_app", "BT_theme", "BT_tab", "BT_screen"
		"BT_image", "BT_menuItem", "BT_buttonItem", 
		"BT_mapLocation"
			
		Images
		------------------
		Some objects that use this class as a container for their data use images, some do not. 
		Image are most common in this class when it's used for a menu item or button. When
		images are used they may be included in the Xcode project or they may come from a URL.			
	
	*/

	NSString *itemId;
	NSString *itemNickname;
	NSString *itemType;
	NSString *sortableColumnValue;
	NSDictionary *jsonVars;
	UIImage *image;
	NSString *imageName;
	NSString *imageURL;
	BOOL isHomeScreen;

}

@property (nonatomic, retain) NSString *itemId;
@property (nonatomic, retain) NSString *itemNickname;
@property (nonatomic, retain) NSString *itemType;
@property (nonatomic, retain) NSString *sortableColumnValue;
@property (nonatomic, retain) NSDictionary *jsonVars;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic) BOOL isHomeScreen;

-(void)downloadImage;

@end







