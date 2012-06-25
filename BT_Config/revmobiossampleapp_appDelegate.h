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
#import <AVFoundation/AVFoundation.h>
#import "BT_downloader.h"
#import "BT_application.h"
#import "BT_audioPlayer.h"
#import "RevMobAds.h"


@interface revmobiossampleapp_appDelegate : NSObject <UIApplicationDelegate, BT_downloadFileDelegate, 
							UITabBarControllerDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate, RevMobAdsDelegate>{
	
	/*
		See notes in revmobiossampleapp_appDelegate for information about....
		---Outputing debug info to the console
		---Changeing the configuration file name
	*/
	
	
	//Environment properties.
	UIWindow *window;
	UIView *refreshingView;
	UIView *globalBackgroundView;
	UIActivityIndicatorView *spinner;
	NSString *configurationFileName;
	NSString *saveAsFileName;
	NSString *modifiedFileName;
	NSString *configData;
	BT_application *rootApp;
	BT_downloader *downloader;
	BT_audioPlayer *audioPlayer;
	BOOL isDataValid;
	BOOL showDebugInfo;	
	NSMutableArray *soundEffectNames;
	NSMutableArray *soundEffectPlayers;
	NSString *allowedInputCharacters;
	NSMutableData *receivedData;
		
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIView *refreshingView;
@property (nonatomic, retain) UIView *globalBackroundView;
@property (nonatomic, retain) BT_audioPlayer *audioPlayer;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) NSString *configurationFileName;
@property (nonatomic, retain) NSString *saveAsFileName;
@property (nonatomic, retain) NSString *modifiedFileName;
@property (nonatomic, retain) NSString *configData;
@property (nonatomic, retain) BT_application *rootApp;
@property (nonatomic, retain) BT_downloader *downloader;
@property (nonatomic) BOOL showDebugInfo;
@property (nonatomic) BOOL isDataValid;
@property (nonatomic, retain) NSMutableArray *soundEffectNames;
@property (nonatomic, retain) NSMutableArray *soundEffectPlayers;
@property (nonatomic, retain) NSString *allowedInputCharacters;
@property (nonatomic, retain) NSMutableData *receivedData;

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;    
-(void)loadAppData;
-(void)downloadAppData;
-(void)configureEnvironmentUsingAppData:(NSString *)appData;
-(void)showAlert:(NSString *)theTitle:(NSString *)theMessage;
-(void)applicationDidBecomeActive:(UIApplication *)application;
-(void)showProgress;
-(void)hideProgress;
-(void)reportToCloud;

//BT_downloadFileDelegate methods
-(void)downloadFileStarted:(NSString *)message;
-(void)downloadFileInProgress:(NSString *)message;
-(void)downloadFileCompleted:(NSString *)message;

//background audio methods
-(void)initAudioPlayer;
-(void)loadAudioForScreen:(BT_item *)theScreenData;
-(void)showAudioControls;
-(void)hideAudioControls;

//sound effect method
-(void)loadSoundEffects;
-(void)playSoundEffect:(NSString *)theFileName;


@end













