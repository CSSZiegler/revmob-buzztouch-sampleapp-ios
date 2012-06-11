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
#import "BT_item.h"


@interface BT_audioPlayer : UIViewController <AVAudioPlayerDelegate>{
	BT_item *screenData;
	UIButton *buttonStartStop;
	UISlider *audioSlider;
	UISlider *volumeSlider;
	AVAudioPlayer *audioPlayer;
	NSString *audioFileName;
	NSString *audioFileURL;
	NSTimer *audioPlaybackTimer;
	NSTimer *audioFadeOutTimer;
	BOOL audioIsPlaying;
	BOOL audioStartOnLoad;
	int audioNumberOfLoops;
	float currentVolume;
	NSMutableData *receivedData;
	NSURLConnection *remoteConn;
	NSString *receivedMimeType;
	UILabel *audioStatusLabel;
	UILabel *audioTimerLabel;
	UILabel *audioDurationLabel;
	UILabel *volumeHighLabel;
	UILabel *volumeLowLabel;
	int expectedDownloadSize;
	int downloadInProgress;

}
@property (nonatomic, retain) BT_item *screenData;
@property (nonatomic, retain) UIButton *buttonStartStop;
@property (nonatomic, retain) UISlider *audioSlider;
@property (nonatomic, retain) UISlider *volumeSlider;
@property (nonatomic, retain) UILabel *audioTimerLabel;	
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) UILabel *audioStatusLabel;	
@property (nonatomic, retain) UILabel *audioDurationLabel;	
@property (nonatomic, retain) UILabel *volumeHighLabel;	
@property (nonatomic, retain) UILabel *volumeLowLabel;	
@property (nonatomic, retain) NSTimer *audioPlaybackTimer;
@property (nonatomic, retain) NSTimer *audioFadeOutTimer;
@property (nonatomic, retain) NSString *audioFileName;
@property (nonatomic, retain) NSString *audioFileURL;
@property (nonatomic) BOOL audioIsPlaying;
@property (nonatomic) BOOL audioStartOnLoad;
@property (nonatomic) int audioNumberOfLoops;
@property (nonatomic) float currentVolume;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *remoteConn;	
@property (nonatomic) int expectedDownloadSize;

-(id)initWithScreenData:(BT_item*)theScreenData;
-(void)loadAudioForScreen:(BT_item *)theScreenData;
-(void)updateStatusLabel:(NSString *)theString;
-(void)updateTimerLabel:(NSString *)theString;
-(void)initAudioPlayerWithLocalURL:(NSString *)theURLinFileSystem;
-(void)toggleAudio;
-(void)startAudio;
-(void)stopAudio;
-(void)hideAudioPlayer;
-(void)downloadAudioFile:(NSString *)theURL;
-(void)updateAudioTimer:(NSTimer *)timer;
-(void)audioSliderChanged:(UISlider *)sender;
-(void)volumeSliderChanged:(UISlider *)sender;
-(void)startAudioTimer;
-(void)stopAudioTimer;
-(void)turnOnControls;
-(void)turnOffControls;

@end


