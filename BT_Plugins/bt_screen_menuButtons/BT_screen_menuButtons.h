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
#import "BT_viewController.h"
#import "BT_downloader.h"
#import "BT_item.h"

@interface BT_screen_menuButtons : BT_viewController <BT_downloadFileDelegate, 
													UIScrollViewDelegate>{
	
	BT_downloader *downloader;
	NSMutableArray *menuItems;
	NSMutableArray *menuItemViews;
	UIScrollView *myScrollView;
	int didInit;
	double deviceWidth;
	double deviceHeight;
	NSString *saveAsFileName;
	
	//properties filled by JSON
	NSString *buttonLayoutStyle;
	NSString *buttonLabelLayoutStyle;
	UIColor *buttonLabelFontColor;
	double buttonOpacity;
	int buttonLabelFontSize;
	int buttonSize;
	int buttonPadding;
	BOOL isLoading;

	
}

@property (nonatomic, retain) NSMutableArray *menuItems;
@property (nonatomic, retain) NSMutableArray *menuItemViews;
@property (nonatomic, retain) UIScrollView *myScrollView;
@property (nonatomic, retain) BT_downloader *downloader;
@property (nonatomic, retain) NSString *saveAsFileName;
@property (nonatomic) int didInit;
@property (nonatomic) double deviceWidth;
@property (nonatomic) double deviceHeight;
@property (nonatomic) BOOL isLoading;
@property (nonatomic, retain) NSString *buttonLayoutStyle;
@property (nonatomic, retain) NSString *buttonLabelLayoutStyle;
@property (nonatomic, retain) UIColor *buttonLabelFontColor;
@property (nonatomic) double buttonOpacity;
@property (nonatomic) int buttonLabelFontSize;
@property (nonatomic) int buttonSize;
@property (nonatomic) int buttonPadding;



-(void)menuItemTap:(id)sender;
-(void)fadeView:(UIView *)theView;
-(void)loadData;
-(void)downloadData;
-(void)layoutScreen;
-(void)parseScreenData:(NSString *)theData;
-(void)checkIsLoading;

@end






