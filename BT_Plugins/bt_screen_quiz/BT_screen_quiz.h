/*
 *	Copyright 2010 - 2012, David Book, buzztouch.com
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
#import "BT_photo.h"
#import "BT_item.h"

@interface BT_screen_quiz : BT_viewController <BT_downloadFileDelegate, UIActionSheetDelegate,
                                                BTPhotoDelegate>{
	BT_downloader *downloader;
	NSString *saveAsFileName;
	int didInit;
	int didFinishOnce;
	int quizDidEnd;
	
	/* quiz properties */
	NSMutableArray *quizQuestions;
	BOOL quizShowTimer;
	BOOL quizShowCorrectAnswers;
	BOOL quizRandomizeQuestions;
	int paddingTop;
	int quizImageCornerRadius;
	int quizQuestionDelay;
	int quizPointsPerAnswer;
	int quizNumberOfQuestions;
	int quizRewardIfPointsOver;
	int quizQuestionFontSizeSmallDevice;
	int quizQuestionFontSizeLargeDevice;
	int quizButtonFontSizeSmallDevice;
	int quizButtonFontSizeLargeDevice;
	
	UIColor *quizFontColorQuestions;
	UIColor *quizFontColorAnswers;
    
	UIColor *quizButtonColorAnswers;
	UIColor *quizButtonColorCorrect;
	UIColor *quizButtonColorIncorrect;
	NSString *quizSoundEffectFileNameCorrect;
	NSString *quizSoundEffectFileNameIncorrect;
	NSString *quizSoundEffectFileNameFinished;
	
	/* quiz running properties */
	BOOL quizRunning;
	int streak;
	int numberCorrect;
	int numberIncorrect;
	int totalPoints;
	int currentQuestionIndex;
	int totalSeconds;
	BT_item *currentQuestionObject;
	
	/* quiz controls */
	UIView *startButtonBox;
	UIButton *startButton;
	UIView *answerButtonBox;
	UIToolbar *quizToolbar;
	UISegmentedControl *answerButton1;
	UISegmentedControl *answerButton2;
	UISegmentedControl *answerButton3;
	UISegmentedControl *answerButton4;
	UILabel *answerLabel1;
	UILabel *answerLabel2;
	UILabel *answerLabel3;
	UILabel *answerLabel4;
	NSTimer *countdownToStartTimer;
	UILabel *countdownToStartLabel;
	UIView *currentPointsView;
	UILabel *currentPointsLabel;
	UIImageView *currentPointsImageView;
	UILabel *currentPointLabel;
	UIImageView *bonusImageView;
	UILabel *quizTimeLabel;
	NSTimer *quizTimer;
	NSTimer *questionTransitionTimer;
	UIView *questionBox;
	UITextView *questionText;
	UIImageView *questionImageView;
	UIActivityIndicatorView *spinner;
	NSMutableArray *finishedButtons;
	UIView *rotateMessageView;
	UILabel *rotateMessageLabel;
	NSString *quizQuestionTransitionType;
	NSString *quizAnswersTransitionType;
	
}

@property (nonatomic, retain) BT_downloader *downloader;
@property (nonatomic, retain) NSString *saveAsFileName;
@property (nonatomic) int didInit;
@property (nonatomic) int didFinishOnce;
@property (nonatomic) int quizDidEnd;

/* quiz properties */
@property (nonatomic, retain) NSMutableArray *quizQuestions;
@property (nonatomic) BOOL quizShowCorrectAnswers;
@property (nonatomic) BOOL quizShowTimer;
@property (nonatomic) BOOL quizRandomizeQuestions;
@property (nonatomic) int paddingTop;
@property (nonatomic) int quizImageCornerRadius;
@property (nonatomic) int quizQuestionDelay;
@property (nonatomic) int quizPointsPerAnswer;
@property (nonatomic) int quizNumberOfQuestions;
@property (nonatomic) int quizRewardIfPointsOver;
@property (nonatomic) int quizQuestionFontSizeSmallDevice;
@property (nonatomic) int quizQuestionFontSizeLargeDevice;
@property (nonatomic) int quizButtonFontSizeSmallDevice;
@property (nonatomic) int quizButtonFontSizeLargeDevice;
@property (nonatomic, retain) UIColor *quizFontColorAnswers;
@property (nonatomic, retain) UIColor *quizFontColorQuestions;
@property (nonatomic, retain) UIColor *quizButtonColorAnswers;
@property (nonatomic, retain) UIColor *quizButtonColorCorrect;
@property (nonatomic, retain) UIColor *quizButtonColorIncorrect;
@property (nonatomic, retain) NSString *quizSoundEffectFileNameCorrect;
@property (nonatomic, retain) NSString *quizSoundEffectFileNameIncorrect;
@property (nonatomic, retain) NSString *quizSoundEffectFileNameFinished;
@property (nonatomic, retain) NSString *quizQuestionTransitionType;
@property (nonatomic, retain) NSString *quizAnswersTransitionType;


/* quiz running properties */
@property (nonatomic) BOOL quizRunning;
@property (nonatomic) int numberCorrect;
@property (nonatomic) int numberIncorrect;
@property (nonatomic) int streak;
@property (nonatomic) int totalPoints;
@property (nonatomic) int currentQuestionIndex;
@property (nonatomic) int totalSeconds;
@property (nonatomic, retain) BT_item *currentQuestionObject;


/* quiz controls */
@property (nonatomic, retain) UIView *startButtonBox;
@property (nonatomic, retain) UIButton *startButton;
@property (nonatomic, retain) UIView *answerButtonBox;
@property (nonatomic, retain) UIToolbar *quizToolbar;
@property (nonatomic, retain) UISegmentedControl *answerButton1;
@property (nonatomic, retain) UISegmentedControl *answerButton2;
@property (nonatomic, retain) UISegmentedControl *answerButton3;
@property (nonatomic, retain) UISegmentedControl *answerButton4;
@property (nonatomic, retain) UILabel *answerLabel1;
@property (nonatomic, retain) UILabel *answerLabel2;
@property (nonatomic, retain) UILabel *answerLabel3;
@property (nonatomic, retain) UILabel *answerLabel4;
@property (nonatomic, retain) NSTimer *countdownToStartTimer;
@property (nonatomic, retain) UILabel *countdownToStartLabel;
@property (nonatomic, retain) UIView *questionBox;
@property (nonatomic, retain) UITextView *questionText;
@property (nonatomic, retain) UIImageView *questionImageView;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) UIView *currentPointsView;
@property (nonatomic, retain) UIImageView *currentPointsImageView;
@property (nonatomic, retain) UILabel *currentPointsLabel;
@property (nonatomic, retain) UIImageView *bonusImageView;

@property (nonatomic, retain) UILabel *quizTimeLabel;
@property (nonatomic, retain) NSTimer *quizTimer;
@property (nonatomic, retain) NSTimer *questionTransitionTimer;
@property (nonatomic, retain) NSMutableArray *finishedButtons;
@property (nonatomic, retain) UIView *rotateMessageView;
@property (nonatomic, retain) UILabel *rotateMessageLabel;

-(void)loadData;
-(void)refreshData;
-(void)downloadData;
-(void)parseScreenData:(NSString *)theData;
-(void)layoutScreen;

/* quiz methods */
-(void)startQuiz;
-(void)answerClick:(id)sender;
-(void)countdownToStartUpdate;
-(void)countdownToStartDone;
-(void)quizRunningLoop;
-(void)transitionQuestion;
-(void)transitionPoints;
-(void)showCorrect;
-(void)showIncorrect;
-(void)quizEnded;
-(void)disableButtons;
-(void)enableButtons;
-(void)actionSheet:(UIActionSheet *)actionSheet  clickedButtonAtIndex:(NSInteger)buttonIndex;
-(void)sendQuizResultsToURL;
-(void)showQuizRewardScreen;
-(void)showFinishScreen;
-(void)setQuestionImage:(UIImage *)theImage;
-(void)photoDidFinishLoading:(BT_photo *)photo;
-(void)photoDidFailToLoad:(BT_photo *)photo;


@end







