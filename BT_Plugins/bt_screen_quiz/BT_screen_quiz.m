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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "JSON.h"
#import "revmobiossampleapp_appDelegate.h"
#import "BT_fileManager.h"
#import "BT_photo.h"
#import "BT_color.h"
#import "BT_imageTools.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_strings.h"
#import "BT_viewControllerManager.h"

#import "BT_screen_quiz.h"

@implementation BT_screen_quiz
@synthesize saveAsFileName, downloader, didInit;

/* quiz properties */
@synthesize quizQuestions, quizShowTimer, quizQuestionDelay, quizPointsPerAnswer, quizRandomizeQuestions;
@synthesize quizButtonColorAnswers, quizButtonColorCorrect, quizButtonColorIncorrect, quizImageCornerRadius;
@synthesize quizSoundEffectFileNameCorrect, quizSoundEffectFileNameIncorrect, quizSoundEffectFileNameFinished;
@synthesize quizNumberOfQuestions, quizRewardIfPointsOver, quizShowCorrectAnswers, quizFontColorQuestions, quizFontColorAnswers;
@synthesize quizQuestionTransitionType, quizAnswersTransitionType, rotateMessageView, rotateMessageLabel;
@synthesize quizQuestionFontSizeSmallDevice, quizQuestionFontSizeLargeDevice, didFinishOnce, spinner;
@synthesize quizButtonFontSizeSmallDevice, quizButtonFontSizeLargeDevice, finishedButtons;

/* quiz runtime properties */
@synthesize quizRunning, numberCorrect, numberIncorrect, streak, totalPoints, totalSeconds;
@synthesize currentQuestionIndex, currentQuestionObject, quizDidEnd;

/* quiz controls */
@synthesize startButtonBox, startButton, questionBox, answerButtonBox, paddingTop;
@synthesize answerButton1, answerButton2, answerButton3, answerButton4;
@synthesize answerLabel1, answerLabel2, answerLabel3, answerLabel4;
@synthesize countdownToStartTimer, countdownToStartLabel, currentPointsView, currentPointsImageView;
@synthesize currentPointsLabel, bonusImageView, quizTimeLabel, quizTimer, questionTransitionTimer;
@synthesize questionText, questionImageView, quizToolbar;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];
    
	//init screen properties
	[self setDidInit:0];
	[self setDidFinishOnce:0];
	[self setQuizDidEnd:0];
	[self setPaddingTop:0];
    
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	////////////////////////////////////
	//init quiz properties...
	quizShowCorrectAnswers = TRUE;
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizShowCorrectAnswers":@"1"] isEqualToString:@"0"]){
		quizShowCorrectAnswers = FALSE;
	}
	quizShowTimer = TRUE;
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizShowTimer":@"1"] isEqualToString:@"0"]){
		quizShowTimer = FALSE;
	}		
	quizRandomizeQuestions = TRUE;
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizRandomizeQuestions":@"1"] isEqualToString:@"0"]){
		quizRandomizeQuestions = FALSE;
	}		
	
	//font sizes
	quizQuestionFontSizeSmallDevice = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizQuestionFontSizeSmallDevice":@"25"] intValue];
	quizQuestionFontSizeLargeDevice = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizQuestionFontSizeLargeDevice":@"55"] intValue];
	quizButtonFontSizeSmallDevice = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonFontSizeSmallDevice":@"14"] intValue];
	quizButtonFontSizeLargeDevice = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonFontSizeLargeDevice":@"40"] intValue];
	quizImageCornerRadius = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizImageCornerRadius":@"8"] intValue];
	quizQuestionDelay = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizQuestionDelay":@"2"] intValue];
	quizPointsPerAnswer = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizPointsPerAnswer":@"150"] intValue];
	quizNumberOfQuestions = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizNumberOfQuestions":@"0"] intValue];
	quizRewardIfPointsOver = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizRewardIfPointsOver":@"0"] intValue];
	
	//question, button, font colors.
	quizFontColorQuestions = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizFontColorQuestions":@"#000000"]];
	quizFontColorAnswers = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizFontColorAnswers":@"#FFFFFF"]];
	quizButtonColorAnswers = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorAnswers":@"#000000"]];
	
	//sound effects.
	quizSoundEffectFileNameCorrect = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameCorrect":@""];
	quizSoundEffectFileNameIncorrect = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameIncorrect":@""];
	quizSoundEffectFileNameFinished = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameFinished":@""];
	
	//transition types
	quizQuestionTransitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizQuestionTransitionType":@"flip"];
	quizAnswersTransitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizAnswersTransitionType":@"flip"];
    
	//if we have a transparent nav bar, move everything down...
	if([[BT_strings getStyleValueForScreen:self.screenData:@"navBarStyle":@""] isEqualToString:@"transparent"]){
		paddingTop = 44;
	}
	
	////////////////////////////////////
	//init quiz controls...
	
	double deviceWidth = self.view.bounds.size.width;
	double deviceHeight = self.view.bounds.size.height;
	
	/* 	question image
     ----------------------
     iPhone: 300 x 150
     iPad: 	748 x 350 
     */
	
	//frame for image is different for small / large devices
	UIImage *defaultQuestionImage = [UIImage imageNamed:@"quizBg_small.png"];
	int margin = 10;
	int questionBoxTop = 5;
	int questionBoxWidth = deviceWidth - 20;
	int questionBoxHeight = 150;
	int answerButtonBoxTop = questionBoxHeight + 5;
	int answerButtonBoxWidth = deviceWidth - 20;
	int answerButtonBoxHeight = deviceHeight - (160 + 88);
	int buttonHeight = (answerButtonBoxHeight / 4.5);		
	int buttonPadding = 6;
	int questionFontSize = quizQuestionFontSizeSmallDevice;
	int buttonFontSize = quizButtonFontSizeSmallDevice;
	if([appDelegate.rootApp.rootDevice isIPad]){
		defaultQuestionImage = [UIImage imageNamed:@"quizBg_large.png"];
		questionBoxHeight = 350;
		answerButtonBoxTop = questionBoxHeight + 12;
		answerButtonBoxHeight = deviceHeight - (360 + 88);
		buttonHeight = (answerButtonBoxHeight / 4.3);
		questionFontSize = quizQuestionFontSizeLargeDevice;
		buttonFontSize = quizButtonFontSizeLargeDevice;
	}
	int buttonWidth = answerButtonBoxWidth;
	
	//add the top padding (changes if we have a transparent nav bar)
	questionBoxTop += paddingTop;
	answerButtonBoxTop += paddingTop;
	//start button box is a view with two subviews. Start button is initially hidden before until the parseData method completes.
	startButtonBox = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	startButtonBox.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[startButtonBox setAlpha:0.0];
    
    //transparent mask
    UIView *startMask = [[UIView alloc] initWithFrame:CGRectMake(0, -50, 1500, 1500)];
    [startMask setBackgroundColor:[UIColor blackColor]];
    [startMask setAlpha:.60];
    [startButtonBox addSubview:startMask];
    [startMask release];
    
    //create rounded rectangle start button
    startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startButton setFrame:CGRectMake(margin, answerButtonBoxTop + 5, answerButtonBoxWidth, buttonHeight)];
    startButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [startButton addTarget:self action:@selector(startQuiz) forControlEvents:UIControlEventTouchUpInside];
    [startButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
    [startButton setTitle:NSLocalizedString(@"quizStart",@"start quiz") forState:UIControlStateNormal];
    
    //countdown to start label is initially hidden
    countdownToStartLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, answerButtonBoxTop + 20, answerButtonBoxWidth, 125)];
    countdownToStartLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [countdownToStartLabel setFont:[UIFont boldSystemFontOfSize:100]];
    [countdownToStartLabel setBackgroundColor:[UIColor clearColor]];
    [countdownToStartLabel setTextColor:[UIColor whiteColor]];
    [countdownToStartLabel setNumberOfLines:1];
    [countdownToStartLabel setText:@""];
    [countdownToStartLabel setTextAlignment:UITextAlignmentCenter];
    
    //add the countdown label, then the start button on top
    [startButtonBox addSubview:countdownToStartLabel];
    [startButtonBox addSubview:startButton];
    
    
	//do we round the question images?
	if(quizImageCornerRadius > 0){
		defaultQuestionImage = [BT_imageTools makeRoundCornerImage:defaultQuestionImage:quizImageCornerRadius:quizImageCornerRadius];
	}
    
	//position controls
	questionBox = [[UIView alloc] initWithFrame:CGRectMake(margin, questionBoxTop, questionBoxWidth, questionBoxHeight)];
	questionBox.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
    //question image view
    questionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, questionBoxWidth, questionBoxHeight)];
    [questionImageView setContentMode:UIViewContentModeScaleToFill];
    [questionImageView setClipsToBounds:TRUE];
    [questionImageView setImage:defaultQuestionImage];
    [questionBox addSubview:questionImageView];
    
    //spinner on top of question.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];		
    spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [spinner setCenter:[questionImageView center]];
    [spinner setHidesWhenStopped:TRUE];
    [questionBox addSubview:spinner];		
    
    //question text
    questionText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, questionBoxWidth, questionBoxHeight)];
    [questionText setFont:[UIFont boldSystemFontOfSize:questionFontSize]];
    [questionText setBackgroundColor:[UIColor clearColor]];
    [questionText setTextColor:quizFontColorQuestions];
    [questionText setUserInteractionEnabled:TRUE];
    [questionText setEditable:FALSE];
    [questionText setShowsVerticalScrollIndicator:FALSE];
    [questionText setShowsHorizontalScrollIndicator:FALSE];
    [questionText setText:@""];
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizQuestionFontJustify":@""] isEqualToString:@"left"]){
        [questionText setTextAlignment:UITextAlignmentLeft];
    }else{
        [questionText setTextAlignment:UITextAlignmentCenter];
    }
    [questionBox addSubview:questionText];
    
	//add the question box...
	[self.view addSubview:questionBox];
    
	//answer buttons are in a box. Initially hidden until the parseData method is complete.
	answerButtonBox = [[UIView alloc] initWithFrame:CGRectMake(10, answerButtonBoxTop, answerButtonBoxWidth, answerButtonBoxHeight)];
	[answerButtonBox setBackgroundColor:[UIColor clearColor]];
	answerButtonBox.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[answerButtonBox setAlpha:0.0];
	
	/*
     Add segemented controls to box, these act as our buttons because they look better and allow "selections"
     Because we cannot change the font-size on segemented controls, we use an empty string for the text
     then place a UILabel on top of the segemented control. Sneaky eh'		
     */
	
	//answer button 1
	answerButton1 = [BT_viewUtilities getButtonForQuiz:self:CGRectMake(4, buttonPadding, buttonWidth - 8, buttonHeight):1:quizButtonColorAnswers];
	[answerButtonBox addSubview:answerButton1];
	answerLabel1 = [BT_viewUtilities getLabelForQuizButton:CGRectMake(5, buttonPadding, buttonWidth - 10, buttonHeight):buttonFontSize:quizFontColorAnswers];	
	[answerButtonBox addSubview:answerLabel1];	
    
	//answer button 2
	answerButton2 = [BT_viewUtilities getButtonForQuiz:self:CGRectMake(4, (1 * buttonHeight) + (2 * buttonPadding), buttonWidth - 8, buttonHeight):2:quizButtonColorAnswers];
	[answerButtonBox addSubview:answerButton2];	
	answerLabel2 = [BT_viewUtilities getLabelForQuizButton:CGRectMake(5, (1 * buttonHeight) + (2 * buttonPadding), buttonWidth - 10, buttonHeight):buttonFontSize:quizFontColorAnswers];	
	[answerButtonBox addSubview:answerLabel2];	
    
	//answer button 3
	answerButton3 = [BT_viewUtilities getButtonForQuiz:self:CGRectMake(4, (2 * buttonHeight) + (3 * buttonPadding), buttonWidth - 8, buttonHeight):3:quizButtonColorAnswers];
	[answerButtonBox addSubview:answerButton3];	
	answerLabel3 = [BT_viewUtilities getLabelForQuizButton:CGRectMake(5, (2 * buttonHeight) + (3 * buttonPadding), buttonWidth - 10, buttonHeight):buttonFontSize:quizFontColorAnswers];	
	[answerButtonBox addSubview:answerLabel3];	
    
	//answer button 4
	answerButton4 = [BT_viewUtilities getButtonForQuiz:self:CGRectMake(4, (3 * buttonHeight) + (4 * buttonPadding), buttonWidth - 8, buttonHeight):4:quizButtonColorAnswers];
	[answerButtonBox addSubview:answerButton4];	
	answerLabel4 = [BT_viewUtilities getLabelForQuizButton:CGRectMake(5, (3 * buttonHeight) + (4 * buttonPadding), buttonWidth - 10, buttonHeight):buttonFontSize:quizFontColorAnswers];	
	[answerButtonBox addSubview:answerLabel4];	
    
	//add button box..
	[self.view addSubview:answerButtonBox];
	
	//current points view holds a label and image (starts out hidden then animates when we show it)
	currentPointsView = [[UIView alloc] initWithFrame:CGRectMake(0, answerButtonBoxTop - 40, 75, 75)];
	currentPointsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[currentPointsView setBackgroundColor:[UIColor clearColor]];
	[currentPointsView setAlpha:0.0];			
    
    //image view for corrent / incorrect images
    currentPointsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"goldStar.png"]];
    [currentPointsView addSubview:currentPointsImageView];
    
    //label for current points
    currentPointsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, 75, 20)];
    [currentPointsLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [currentPointsLabel setBackgroundColor:[UIColor clearColor]];
    [currentPointsLabel setTextColor:[UIColor blackColor]];
    [currentPointsLabel setNumberOfLines:1];
    [currentPointsLabel setText:@""];
    [currentPointsLabel setTextAlignment:UITextAlignmentCenter];
    [currentPointsView addSubview:currentPointsLabel];
    
    //image view for bonus images
    bonusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
    [bonusImageView setImage:[UIImage imageNamed:@"blank.png"]];
    [bonusImageView setHidden:TRUE];
    bonusImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [currentPointsView addSubview:bonusImageView];
    
	//add to sub-view
	[self.view addSubview:currentPointsView];
	
	//add start button box on top of everything as a mask
	[self.view addSubview:startButtonBox];
    
	//quizToolbar
	quizToolbar = [BT_viewUtilities getQuizToolBarForScreen:self:[self screenData]];
	[self.view addSubview:quizToolbar];
    
	//message view shows when device is in landscape mode (quizzes do not rotate)
	rotateMessageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, deviceWidth, deviceHeight - 44)];
	rotateMessageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[rotateMessageView setBackgroundColor:[UIColor blackColor]];
    
    //label goes on top
    rotateMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, deviceWidth, 50)];
    rotateMessageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [rotateMessageLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [rotateMessageLabel setBackgroundColor:[UIColor clearColor]];
    [rotateMessageLabel setTextColor:[UIColor whiteColor]];
    [rotateMessageLabel setNumberOfLines:1];
    [rotateMessageLabel setText:[NSString stringWithFormat:@"%@", NSLocalizedString(@"quizRotateMessage", @"Please rotate your device.")]];
    [rotateMessageLabel setTextAlignment:UITextAlignmentCenter];
	[self.view addSubview:rotateMessageView];
	[self.view addSubview:rotateMessageLabel];
	
	//if landscape...show the warning..
	if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
		[rotateMessageView setHidden:TRUE];
		[rotateMessageLabel setHidden:TRUE];
		[startButton setHidden:FALSE];
	}else{
		[rotateMessageView setHidden:FALSE];
		[rotateMessageLabel setHidden:FALSE];
		[startButton setHidden:TRUE];
	}
    
    
	//find the quiz timer label in the toolbar.
	quizTimeLabel = (UILabel *)[quizToolbar viewWithTag:105];
	
	//quizRunningLoop runs in background and increments seconds..
	quizTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(quizRunningLoop) userInfo:nil repeats:YES]; 
	[[NSRunLoop currentRunLoop] addTimer:quizTimer forMode:NSRunLoopCommonModes];		
	
    
}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self:@"viewWillAppear"];
}


//view did appear
-(void)viewDidAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self:@"viewDidAppear"];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//setup navigation bar and background
	[BT_viewUtilities configureBackgroundAndNavBar:self:[self screenData]];
	
	//ignore if we already inited
	if(self.didInit < 1){
		[self setDidInit:1];
		[self setQuizDidEnd:0];
		[self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
	}else{
		//we must be coming back from another screen, trigger quiz ended method if
		//we have already taken the quiz. If we have not taken a quiz yet, do nothing
		if(self.quizDidEnd > 0){
			[self quizEnded];
		}else{
			[self startQuiz];
		}
	}
    
}

//load data
-(void)loadData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"loadData%@", @""]];
	
	/*
     Screen Data scenarios
     --------------------------------
     a)	No dataURL is provided in the screen data - use the info configured in the app's configuration file
     b)	A dataURL is provided, download now if we don't have a cache, else, download on refresh.
     */
	
	self.saveAsFileName = [NSString stringWithFormat:@"screenData_%@.txt", [self.screenData itemId]];
	
	//do we have a URL?
	BOOL haveURL = FALSE;
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"dataURL":@""] length] > 10){
		haveURL = TRUE;
	}
	
	//start by filling the list from the configuration file, use these if we can't get anything from a URL
	if([[self.screenData jsonVars] objectForKey:@"childItems"]){
        
		//init the items array
		self.quizQuestions = [[NSMutableArray alloc] init];
        
		NSArray *tmpQuestions = [[self.screenData jsonVars] objectForKey:@"childItems"];
		for(NSDictionary *tmpQuestion in tmpQuestions){
			BT_item *thisQuestion = [[BT_item alloc] init];
			thisQuestion.itemId = [tmpQuestion objectForKey:@"itemId"];
			thisQuestion.itemType = [tmpQuestion objectForKey:@"itemType"];
			thisQuestion.jsonVars = tmpQuestion;
			[self.quizQuestions addObject:thisQuestion];
			[thisQuestion release];								
		}
        
	}else{
		[BT_debugger showIt:self:@"the quiz screen does not have a childItems[] array"];
	}
	
	//if we have a URL, fetch..
	if(haveURL){
        
		//look for a previously cached version of this screens data...
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:@"parsing previsouly cached quiz questions"];
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[self parseScreenData:staleData];
		}else{
			[BT_debugger showIt:self:@"no cached version of the quiz questions found"];
			[self downloadData];
		}
        
        
	}else{
		
		//show the child items in the config data
		[BT_debugger showIt:self:@"no dataURL found for this quiz screen"];
		[self layoutScreen];
		
	}
    
	
}

//refresh data
-(void)refreshData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"refreshData%@", @""]];
	[self downloadData];
}


//download data
-(void)downloadData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloading screen data and saving as: %@", [self saveAsFileName]]];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//hide the answer buttons
	[answerButtonBox setAlpha:0.0];
    
	//hide the start button
	[startButton setHidden:TRUE];
	
	//show progress
	[self showProgress];
	
	NSString *tmpURL = @"";
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"dataURL":@""] length] > 3){
		
		//merge url variables
		tmpURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"dataURL":@""];
		tmpURL = [tmpURL stringByReplacingOccurrencesOfString:@"[screenId]" withString:[self.screenData itemId]];
        
		///merge possible variables in URL
		NSString *useURL = [BT_strings mergeBTVariablesInString:tmpURL];
		NSString *escapedUrl = [useURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		//fire downloader to fetch and results
		downloader = [[BT_downloader alloc] init];
		[downloader setSaveAsFileName:[self saveAsFileName]];
		[downloader setSaveAsFileType:@"text"];
		[downloader setUrlString:escapedUrl];
		[downloader setDelegate:self];
		[downloader downloadFile];	
	}
}

//parse screen data
-(void)parseScreenData:(NSString *)theData{
	[BT_debugger showIt:self:@"parseScreenData"];
	
	@try {	
        
		//arrays for screenData
		self.quizQuestions = [[NSMutableArray alloc] init];
        
		//create dictionary from the JSON string
		SBJsonParser *parser = [SBJsonParser new];
		id jsonData = [parser objectWithString:theData];
		
	   	if(!jsonData){
            
			[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
			[self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~"):NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed"):0];
			[BT_fileManager deleteFile:[self saveAsFileName]];
            
		}else{
			
			if([jsonData objectForKey:@"childItems"]){
				NSArray *tmpQuestions = [jsonData objectForKey:@"childItems"];
				for(NSDictionary *tmpQuestion in tmpQuestions){
					BT_item *thisQuestion = [[BT_item alloc] init];
					thisQuestion.itemId = [tmpQuestion objectForKey:@"itemId"];
					thisQuestion.itemType = [tmpQuestion objectForKey:@"itemType"];
					thisQuestion.jsonVars = tmpQuestion;
					[self.quizQuestions addObject:thisQuestion];
					[thisQuestion release];								
				}
			}
			
			//layout screen
			[self layoutScreen];		
            
		}
		
	}@catch (NSException * e) {
        
		//delete bogus data, show alert
		[BT_fileManager deleteFile:[self saveAsFileName]];
		[self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~"):NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed"):0];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"error parsing screen data: %@", e]];
        
	} 	
	
    
}

//build screen (drops pins)
-(void)layoutScreen{
	[BT_debugger showIt:self:@"layoutScreen"];
	
	//show cover-view if we are in landscape mode. Quizzes only work in portrait
	if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
		[rotateMessageView setHidden:TRUE];
		[rotateMessageLabel setHidden:TRUE];
		[questionBox setAlpha:1.0];
		if(!quizRunning){
			[startButton setHidden:FALSE];
		}else{
			[answerButtonBox setAlpha:1.0];
		}
	}else{
		[rotateMessageView setHidden:FALSE];
		[rotateMessageLabel setHidden:FALSE];
		[answerButtonBox setAlpha:0.0];
		[questionBox setAlpha:0.0];
		[startButton setHidden:TRUE];
	}
	
	//this method is called after parsing the screens data, AND after rotations...
	if(!quizRunning){
		if([quizQuestions count] > 0){
            
			//hide the answer buttons
			[answerButtonBox setAlpha:0.0];
            
			//show the start button
			[startButtonBox setAlpha:1.0];
            
		}else{
			[BT_debugger showIt:self:@"This quiz screen does not have any questions?"];
		}
	}
    
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//quiz methods

//start quiz
-(void)startQuiz{
	[BT_debugger showIt:self:@"startQuiz"];
	
	//reset timer label
	[quizTimeLabel setText:@""];
	[self setQuizRunning:FALSE];
    
	//don't start unless we are in portrait mode
	if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        
		//hide the start button
		[startButton setHidden:TRUE];
		[startButtonBox setAlpha:1.0];
		[countdownToStartLabel setHidden:FALSE];
		[answerButtonBox setHidden:TRUE];
		[questionText setText:@""];
		[quizTimeLabel setText:@""];
		[self setDidFinishOnce:0];
		[self setTotalSeconds:0];
        
		//set the initial label
		[countdownToStartLabel setText:@"3"];
		
		//trigger the countdown timer to run every 1 second
		countdownToStartTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownToStartUpdate) userInfo:nil repeats:YES]; 
        
	}//portrait mode
}

//udpates on timer ticks during quiz start countdown
-(void)countdownToStartUpdate{
    
	//ignore if we are not in portrait mode
	//don't start unless we are in portrait mode
	if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        
		//change countdown label until done...
		if([countdownToStartLabel.text isEqualToString:@"3"]){
			[countdownToStartLabel setText:@"2"];
		}else if([countdownToStartLabel.text isEqualToString:@"2"]){
			[countdownToStartLabel setText:@"1"];
		}else if([countdownToStartLabel.text isEqualToString:@"1"]){
			[countdownToStartLabel setText:NSLocalizedString(@"quizGo", "go!")];
		}else if([countdownToStartLabel.text isEqualToString:NSLocalizedString(@"quizGo", "go!")]){
			
			//kill the timer..
			[countdownToStartTimer invalidate];
			
			//triger start..
			[self countdownToStartDone];		
            
		}
		
	}else{
		[countdownToStartLabel setText:@""];
	}
	
}

//countdown to start done..
-(void)countdownToStartDone{
	[BT_debugger showIt:self:@"countdownToStartDone"];
	
	//ignore this if we are not in portrait
	if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        
		//hide the start button and the countdown label
		[startButton setHidden:TRUE];
		[countdownToStartLabel setHidden:TRUE];
		[answerButtonBox setHidden:FALSE];
        
		//animate "mask" view away...
		[UIView beginAnimations:@"fadeMask" context:nil];
		[startButtonBox setAlpha:1.0];
		[startButtonBox setAlpha:0.0];
		[UIView setAnimationDuration:0.75];
		[UIView commitAnimations];
        
		//init quiz run-time vars
		[self setQuizRunning:TRUE];
		[self setTotalSeconds:0];
		[self setNumberCorrect:0];
		[self setNumberIncorrect:0];
		[self setStreak:0];
		[self setTotalPoints:0];
		[self setCurrentQuestionIndex:0];
		[currentPointsView setAlpha:0.0];
		
		//make sure we have enough questions...
		if(([quizQuestions count] <= quizNumberOfQuestions) || quizNumberOfQuestions == 0 ){
			quizNumberOfQuestions = [quizQuestions count];
		}
		
		//randomize questions if "quizRandomizeQuestions"
		if(quizRandomizeQuestions){
			NSUInteger firstQuestion = 0;
			for (int i = 0; i < [self.quizQuestions count]; i++){
				NSUInteger randomIndex = arc4random() % [self.quizQuestions count];
				[self.quizQuestions exchangeObjectAtIndex:firstQuestion withObjectAtIndex:randomIndex];
				firstQuestion +=1;
			}
		}					
        
		//transition question
		[self transitionQuestion];
        
	}//not in portrait mode
    
}

//quizRunningLoop
-(void)quizRunningLoop{
	
	//if we are showing the timer
	if(quizShowTimer){
		[quizTimeLabel setHidden:FALSE];
		//setup text in footer label
		if(quizRunning){
			
			//increment seconds
			[self setTotalSeconds:totalSeconds + 1];
			NSString *formatted = [NSString stringWithFormat:@"%d", totalSeconds];
			[quizTimeLabel setText:[BT_strings formatTimeFromSeconds:formatted]];
			
		}
		
	}else{
		[quizTimeLabel setHidden:TRUE];
	}
	
}

//transitionQuestion 
-(void)transitionQuestion{
	[BT_debugger showIt:self:@"transitionQuestion"];
    
	//be sure answers are showing..
	[answerButtonBox setAlpha:1.0];
	
	//prepare question animation block
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75];
	if([quizQuestionTransitionType isEqualToString:@"curl"]) [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:questionBox cache:NO];
	if([quizQuestionTransitionType isEqualToString:@"flip"]) [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:questionBox cache:NO];
	[UIView commitAnimations];
    
	//prepare answer animation block
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75];
	if([quizAnswersTransitionType isEqualToString:@"curl"]) [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:answerButtonBox cache:NO];
	if([quizAnswersTransitionType isEqualToString:@"flip"]) [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:answerButtonBox cache:NO];
	[UIView commitAnimations];
	
	//get the current question
	BT_item *tmpQuestion = [self.quizQuestions objectAtIndex:currentQuestionIndex];
    
	//remember this question
	[self setCurrentQuestionObject:tmpQuestion];
    
	//properties for this question
	NSString *tmpQuestionText = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"questionText":@""];
	NSString *tmpImageName = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"imageNameSmallDevice":@""];
	NSString *tmpImageURL = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"imageURLSmallDevice":@""];
	
	//should we use the large image instead?
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	if([appDelegate.rootApp.rootDevice isIPad]){
		tmpImageName = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"imageNameLargeDevice":@""];
		tmpImageURL = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"imageURLLargeDevice":@""];
	}
	
	//if we have an imageURL, and no imageName, figure out a name to use...
	if(tmpImageName.length < 3 && tmpImageURL.length > 3){
		tmpImageName = [BT_strings getFileNameFromURL:tmpImageURL];
	}
    
	//if we don't have an image, "dim" the default image...
	if([tmpImageName length] < 3){
		[spinner stopAnimating];
        
		UIImage *defaultQuestionImage = [UIImage imageNamed:@"quizBg_small.png"];
		if([appDelegate.rootApp.rootDevice isIPad]){
			defaultQuestionImage = [UIImage imageNamed:@"quizBg_large.png"];
		}
		[self setQuestionImage:defaultQuestionImage];
		[questionImageView setAlpha:0.1];
        
	}else{
        
		//show this questions image...
		[self setQuestionImage:[UIImage imageNamed:@"blank.png"]];
		[questionImageView setAlpha:1.0];
		[self.spinner startAnimating];
		
		//photo could be in the bundle, in the cache, or at a URL
		UIImage *tmpImage = nil;
		if([BT_fileManager doesFileExistInBundle:tmpImageName]){
			tmpImage = [UIImage imageNamed:tmpImageName];
			[self setQuestionImage:tmpImage];
		}else{
			if([BT_fileManager doesLocalFileExist:tmpImageName]){
				tmpImage = [BT_fileManager getImageFromFile:tmpImageName];
				[self setQuestionImage:tmpImage];
			}else{
				if([tmpImageURL length] > 3){
                    
					//custom image downloader thing-a-ma-jig
					BT_photo *bt_photo = [BT_photo photoWithURL:[NSURL URLWithString:tmpImageURL]];
					if([bt_photo isImageAvailable]){
						[self setQuestionImage:[bt_photo image]];
					}else{
						[bt_photo obtainImageInBackgroundAndNotify:self];
					}
					
				}else{
					
					//image does not exist in bundle..and.. not imageURL was provided
					[self.spinner stopAnimating];
					[self setQuestionImage:[UIImage imageNamed:@"noImage.png"]];
                    
				}
				
				
			}
		}
        
	}//tmpImageName
	
    
	//set question text - blank if "none" is used.
	if([tmpQuestionText caseInsensitiveCompare:@"none"] == NSOrderedSame ){
		[self.questionText setText:@""];
	}else{
		[self.questionText setText:tmpQuestionText];
	}
	
	//tmp array of answers..3 are incorrect, 1 is correct
	NSMutableArray *tmpAnswers = [[NSMutableArray alloc] init];
	[tmpAnswers addObject:[BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"incorrectText1":@""]];
	[tmpAnswers addObject:[BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"incorrectText2":@""]];
	[tmpAnswers addObject:[BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"incorrectText3":@""]];
	[tmpAnswers addObject:[BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"correctAnswerText":@""]];
	
	//randomize the answers..	
	NSUInteger firstAnswer = 0;
	for (int i = 0; i < [tmpAnswers count]; i++){
		NSUInteger randomIndex = random() % [tmpAnswers count];
		[tmpAnswers exchangeObjectAtIndex:firstAnswer withObjectAtIndex:randomIndex];
		firstAnswer +=1;
	}
	
	//set the answers text...
	[answerLabel1 setText:[tmpAnswers objectAtIndex:0]];
	[answerLabel2 setText:[tmpAnswers objectAtIndex:1]];
	[answerLabel3 setText:[tmpAnswers objectAtIndex:2]];
	[answerLabel4 setText:[tmpAnswers objectAtIndex:3]];
	
	//clean up
	[tmpAnswers release];
	tmpAnswers = nil;
	
	//change button colors if "quizButtonColorAnswers" 
	if(quizShowCorrectAnswers){
        
		//button colors
		quizButtonColorAnswers = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorAnswers":@"#000000"]];
        
		[answerButton1 setTintColor:quizButtonColorAnswers];
		[answerButton2 setTintColor:quizButtonColorAnswers];
		[answerButton3 setTintColor:quizButtonColorAnswers];
		[answerButton4 setTintColor:quizButtonColorAnswers];
	}
	
	//allow answer selection
	[self enableButtons];	
    
    
}

//transitions correct
-(void)transitionPoints{
	[BT_debugger showIt:self:@"transitionPoints"];
    
	//fade in
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[currentPointsView setAlpha:0.0];
	[currentPointsView setAlpha:1.0];
	[UIView commitAnimations];
	
	//fade out
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2.5];
	[currentPointsView setAlpha:1.0];
	[currentPointsView setAlpha:0.0];
	[UIView commitAnimations];
    
	
}

//answer click
-(void)answerClick:(id)sender{
	[BT_debugger showIt:self:@"startQuiz"];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//prevent another answer selection
	[self disableButtons];	
	
	//holds the answer
	NSString *selAnswer = @"";	
	
	//the index of the answer clicked...
	int selIndex = [sender tag];
	
	//get the text from the appropriate answer label
	if(selIndex == 1) selAnswer = [answerLabel1 text];
	if(selIndex == 2) selAnswer = [answerLabel2 text];
	if(selIndex == 3) selAnswer = [answerLabel3 text];
	if(selIndex == 4) selAnswer = [answerLabel4 text];
	
	//get the current question...
	BT_item *tmpQuestion = [quizQuestions objectAtIndex:currentQuestionIndex];
	NSString *tmpAnswer = [BT_strings getJsonPropertyValue:tmpQuestion.jsonVars:@"correctAnswerText":@""];
	
	//increment the question
	currentQuestionIndex = (currentQuestionIndex + 1);
    
	//change button colors if "quizShowCorrectAnswers" 
	if(quizShowCorrectAnswers){
        
		//correct button color
		quizButtonColorCorrect = [BT_color getColorFromHexString:@"#336600"];
		if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorCorrect":@""] length] > 3){
			quizButtonColorCorrect = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorCorrect":@""]];
		}
		//incorrect button color
		quizButtonColorIncorrect = [BT_color getColorFromHexString:@"#990000"];
		if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorIncorrect":@""] length] > 3){
			quizButtonColorIncorrect = [BT_color getColorFromHexString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizButtonColorIncorrect":@""]];
		}		
        
		//color each button...
		if([answerLabel1.text isEqualToString:tmpAnswer]){
			[answerButton1 setTintColor:quizButtonColorCorrect];
		}else{
			[answerButton1 setTintColor:quizButtonColorIncorrect];
		}
		if([answerLabel2.text isEqualToString:tmpAnswer]){
			[answerButton2 setTintColor:quizButtonColorCorrect];
		}else{
			[answerButton2 setTintColor:quizButtonColorIncorrect];
		}
		if([answerLabel3.text isEqualToString:tmpAnswer]){
			[answerButton3 setTintColor:quizButtonColorCorrect];
		}else{
			[answerButton3 setTintColor:quizButtonColorIncorrect];
		}
		if([answerLabel4.text isEqualToString:tmpAnswer]){
			[answerButton4 setTintColor:quizButtonColorCorrect];
		}else{
			[answerButton4 setTintColor:quizButtonColorIncorrect];
		}				
	}
    
	//correct or incorrect?
	if([tmpAnswer isEqualToString:selAnswer]){
        
		//answer was correct...
		
		//do we play sound effect?
		if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameCorrect":@""] length] > 3){
			[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameCorrect":@""]];
		}
        
		//flags / points...
		numberCorrect = (numberCorrect + 1);
		streak = (streak + 1);
		
		//determine how many points we earned for this answer
		int pointsPerRight = quizPointsPerAnswer;
		
		//assume we are not in bonus..
		UIImage *tmpBonusImg = [UIImage imageNamed:@"blank.png"];
        
		//bonusImage for right "in a row"
		if(streak > 9){
			pointsPerRight = (pointsPerRight * 10);
			tmpBonusImg = [UIImage imageNamed:@"10X.png"];
		}else if (streak > 8){
			pointsPerRight = (pointsPerRight * 9);
			tmpBonusImg = [UIImage imageNamed:@"9X.png"];
		}else if (streak > 7){
			pointsPerRight = (pointsPerRight * 8);
			tmpBonusImg = [UIImage imageNamed:@"8X.png"];
		}else if (streak > 6){
			pointsPerRight = (pointsPerRight * 7);
			tmpBonusImg = [UIImage imageNamed:@"7X.png"];
		}else if (streak > 5){
			pointsPerRight = (pointsPerRight * 6);
			tmpBonusImg = [UIImage imageNamed:@"6X.png"];
		}else if (streak > 4){
			pointsPerRight = (pointsPerRight * 5);
			tmpBonusImg = [UIImage imageNamed:@"5X.png"];
		}else if (streak > 3){
			pointsPerRight = (pointsPerRight * 4);
			tmpBonusImg = [UIImage imageNamed:@"4X.png"];
		}else if (streak > 2){
			pointsPerRight = (pointsPerRight * 3);
			tmpBonusImg = [UIImage imageNamed:@"3X.png"];
		}
		
		//set the bonus image
		[self.bonusImageView setImage:tmpBonusImg];
		[bonusImageView setHidden:FALSE];
        
		//figure out totalPoints
		totalPoints = (totalPoints + pointsPerRight);
		
		//set points label
		[currentPointsLabel setText:[NSString stringWithFormat:@"%d", totalPoints]];
		
		//animate
		[self showCorrect];
		
		
	}else{
		
		//answer was incorrect
        
		//do we play sound effect?
		if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameIncorrect":@""] length] > 3){
			[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameIncorrect":@""]];
		}
        
		//flags
		numberIncorrect = (numberIncorrect + 1);
		streak = 0;
        
		//set points label
		[currentPointsLabel setText:@""];
		
		//hide bonus image
		[bonusImageView setHidden:TRUE];
		
		//animate
		[self showIncorrect];
	}
    
}

//show correct
-(void)showCorrect{
	[BT_debugger showIt:self:@"showCorrect"];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//change image
	[currentPointsImageView setImage:[UIImage imageNamed:@"goldStar.png"]];
	
	//play possible sound effect...
	if([quizSoundEffectFileNameCorrect length] > 3){
		[appDelegate playSoundEffect:quizSoundEffectFileNameCorrect];
	}
	
	//figure out points...
	[self transitionPoints];
	
	//move to next question or end?
	if(currentQuestionIndex >= quizNumberOfQuestions){
        
		//end after delay
		[self setQuizDidEnd:1];
		[self performSelector:@selector(quizEnded) withObject:nil afterDelay:quizQuestionDelay];
        
	}else{
        
		//go to next question after delay
		[self performSelector:@selector(transitionQuestion) withObject:nil afterDelay:quizQuestionDelay];
        
	}
    
}

//show incorrect
-(void)showIncorrect{
	[BT_debugger showIt:self:@"showIncorrect"];
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//change image
	[currentPointsImageView setImage:[UIImage imageNamed:@"wrong.png"]];
	
	//play possible sound effect...
	if([quizSoundEffectFileNameIncorrect length] > 3){
		[appDelegate playSoundEffect:quizSoundEffectFileNameIncorrect];
	}
	
	//figure out points...
	[self transitionPoints];
	
	//move to next question or end?
	if((currentQuestionIndex >= quizNumberOfQuestions) || (currentQuestionIndex + 1 > [self.quizQuestions count]) ){
        
		//end after delay
		[self setQuizDidEnd:1];
		[self performSelector:@selector(quizEnded) withObject:nil afterDelay:quizQuestionDelay];
        
	}else{
        
		//go to next question after delay
		[self performSelector:@selector(transitionQuestion) withObject:nil afterDelay:quizQuestionDelay];
        
        
	}
	
    
}

//quizEnded
-(void)quizEnded{
	[BT_debugger showIt:self:@"quizEnded"];
    
	//ignore this if the quiz never ended (we never started a quiz)
	if(self.quizDidEnd > 0){
        
		//appDelegate
		revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
        
		//clear question and timer label
		[questionText setText:@""];
		[quizTimeLabel setText:@""];
		
		//show the start button again
		[startButtonBox setAlpha:1.0];
		[startButton setHidden:FALSE];
        
		//show question image
		[questionImageView setAlpha:1.0];
		
		//hide answers..
		[answerButtonBox setHidden:TRUE];
		
		//flag quiz is not running
		[self setQuizRunning:FALSE];
		
		//setup action sheet
		NSString *elapsedTime = [BT_strings formatTimeFromSeconds:[NSString stringWithFormat:@"%d", totalSeconds]];
		NSString *quizResultMessage = [NSString stringWithFormat:@"%@: %d\n%@: %d\n%@: %d\n%@: %@", NSLocalizedString(@"quizCorrectAnswers", @"Correct Answers"), numberCorrect, NSLocalizedString(@"quizIncorrectAnswers", @"Incorrect Answers"), numberIncorrect, NSLocalizedString(@"quizTotalScore", @"Total Score"), totalPoints, NSLocalizedString(@"quizElapsedTime", @"Elapsed Time"), elapsedTime];  
		
		//did user earn a reward?
		BOOL earnedReward = FALSE;
		if(totalPoints > quizRewardIfPointsOver){
			earnedReward = TRUE;
		}
		
		//do we play finished sound effect? Play reward sound if we have one, or the non-reward sound.
		if(earnedReward && self.didFinishOnce == 0){
			if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameReward":@""] length] > 3){
				[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameReward":@""]];
			}else{
				if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameFinished":@""] length] > 3){
					[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameFinished":@""]];
				}
			}
		}else{
			if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameFinished":@""] length] > 3){
				[appDelegate playSoundEffect:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"quizSoundEffectFileNameFinished":@""]];
			}
		}
		
		//flag the didFinishOnce so sound effect doens't play again if "back" pressed
		[self setDidFinishOnce:1];
		
		//do we have a reward screen setup?
		BT_item *rewardScreenObjectToLoad = nil;
		BOOL haveRewardScreen = FALSE;
		NSString *quizRewardScreenItemId = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizRewardScreenItemId":@""];
		NSString *quizRewardScreenNickname = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizRewardScreenNickname":@""];
		if([quizRewardScreenItemId length] > 1){
			rewardScreenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:quizRewardScreenItemId];
		}else{
			if([quizRewardScreenNickname length] > 1){
				rewardScreenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:quizRewardScreenNickname];
			}else{
				if([screenData.jsonVars objectForKey:@"quizRewardScreenObject"]){
					rewardScreenObjectToLoad = [[BT_item alloc] init];
					[rewardScreenObjectToLoad setItemId:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemId"]];
					[rewardScreenObjectToLoad setItemNickname:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemNickname"]];
					[rewardScreenObjectToLoad setItemType:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemType"]];
					[rewardScreenObjectToLoad setJsonVars:[screenData.jsonVars objectForKey:@"quizRewardScreenObject"]];
				}								
			}
		}	
		if(rewardScreenObjectToLoad != nil){
			haveRewardScreen = TRUE;
		}
		
		//do we have a finished screen setup?
		BT_item *finishScreenObjectToLoad = nil;
		BOOL haveFinishScreen = FALSE;
		NSString *quizFinishScreenItemId = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizFinishScreenItemId":@""];
		NSString *quizFinishScreenNickname = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizFinishScreenNickname":@""];
		if([quizFinishScreenItemId length] > 1){
			finishScreenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:quizFinishScreenItemId];
		}else{
			if([quizFinishScreenNickname length] > 1){
				finishScreenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:quizFinishScreenNickname];
			}else{
				if([screenData.jsonVars objectForKey:@"quizFinishScreenObject"]){
					finishScreenObjectToLoad = [[BT_item alloc] init];
					[finishScreenObjectToLoad setItemId:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemId"]];
					[finishScreenObjectToLoad setItemNickname:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemNickname"]];
					[finishScreenObjectToLoad setItemType:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemType"]];
					[finishScreenObjectToLoad setJsonVars:[screenData.jsonVars objectForKey:@"quizFinishScreenObject"]];
				}								
			}
		}	
		if(finishScreenObjectToLoad != nil){
			haveFinishScreen = TRUE;
		}	
		
		//buttons for action sheet
		finishedButtons = [[NSMutableArray alloc] init];
		
		//earned reward screen
		if(haveRewardScreen && earnedReward){
			[finishedButtons addObject:NSLocalizedString(@"quizShowReward", @"Show Reward")];
		}else{
			//regular finish screen
			if(haveFinishScreen){
				[finishedButtons addObject:NSLocalizedString(@"continue", @"Continue")];
			}
		}
        
 		
		//try again button...
		[finishedButtons addObject:NSLocalizedString(@"quizTryAgain", @"Try Again")];
		
		//action sheet
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:quizResultMessage
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
		//add the buttons
		for (int i = 0; i < [finishedButtons count]; i++) {
			[actionSheet addButtonWithTitle:[finishedButtons objectAtIndex:i]];
		}
		
		//add cancel button
		[actionSheet addButtonWithTitle:NSLocalizedString(@"quit", @"Quit")];
		actionSheet.destructiveButtonIndex = [finishedButtons count];
		[actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
        
		//is this a tabbed app?
		if([appDelegate.rootApp.tabs count] > 0){
			[actionSheet showFromTabBar:[appDelegate.rootApp.rootTabBarController tabBar]];
		}else{
			[actionSheet showFromToolbar:self.quizToolbar];
		}
		[actionSheet release];
        
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        //SEND QUIZ RESULTS IN BACKGROUND
        [NSThread detachNewThreadSelector: @selector(sendQuizResultsToURL) toTarget:self withObject:nil];

 		
        
	}//self.quizDidEnd == 0
	
}

//disable, enable buttons
-(void)disableButtons{
	[answerButton1 setEnabled:FALSE];
	[answerButton2 setEnabled:FALSE];
	[answerButton3 setEnabled:FALSE];
	[answerButton4 setEnabled:FALSE];
}
-(void)enableButtons{
	[answerButton1 setEnabled:TRUE];
	[answerButton2 setEnabled:TRUE];
	[answerButton3 setEnabled:TRUE];
	[answerButton4 setEnabled:TRUE];
}


//send quiz results to URL...
-(void)sendQuizResultsToURL{
	
	//this runs in it's own thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc ] init];
    
        //must have sendResultsToURL value...
        if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"sendResultsToURL":@""] length] > 3){
        
     
            //the sendResultsToURL data URL
            NSMutableString *sendResultsToURL = [[NSMutableString alloc] initWithString:@""];
            [sendResultsToURL appendString:[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"sendResultsToURL":@""]];
     
            //append quiz results to the scoreboard URL (for remote backends, helps developers track score results)
            [sendResultsToURL appendString:[NSString stringWithFormat:@"&totalPoints=%i", [self totalPoints]]];
            [sendResultsToURL appendString:[NSString stringWithFormat:@"&totalSeconds=%d", [self totalSeconds]]];
            [sendResultsToURL appendString:[NSString stringWithFormat:@"&numberQuestions=%i", [self quizNumberOfQuestions]]];
            [sendResultsToURL appendString:[NSString stringWithFormat:@"&numberCorrect=%i", [self numberCorrect]]];
            [sendResultsToURL appendString:[NSString stringWithFormat:@"&numberIncorrect=%i", [self numberIncorrect]]];
             
            //merge fields in URL
            NSString *useURL = [BT_strings mergeBTVariablesInString:sendResultsToURL];
            [BT_debugger showIt:self:[NSString stringWithFormat:@"sendQuizResultsToURL:%@", sendResultsToURL]];
            
            
            //clean-up URL, encode as UTF8
            NSURL *escapedURL = [NSURL URLWithString:[useURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];	
            
            //make the http request
            NSMutableURLRequest  *theRequest = [NSMutableURLRequest requestWithURL:escapedURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];	
            [theRequest setHTTPMethod:@"GET"];  
            NSURLConnection *theConnection;
            if((theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self])){
                //ingore returned data...
            }else{
                [BT_debugger showIt:self:[NSString stringWithFormat:@"sendQuizResultsToURL: ERROR. Could not send results to %@", sendResultsToURL]];
            }            
            
        }else{
            [BT_debugger showIt:self:[NSString stringWithFormat:@"sendQuizResultsToURL This quiz does not have a send results to URL setup. Not sending results anywhere.%@", @""]];
        }
    
	//release pool
	[pool release];    
    
}

//show quiz reward screen
-(void)showQuizRewardScreen{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"showQuizRewardScreen %@", @""]];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//get possible itemId of the screen to load
	NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizRewardScreenItemId":@""];
	
	//get possible nickname of the screen to load
	NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizRewardScreenNickname":@""];
    
	//bail if load screen = "none"
	if([loadScreenItemId isEqualToString:@"none"]){
		return;
	}
	
	//check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
	BT_item *screenObjectToLoad = nil;
	if([loadScreenItemId length] > 1){
		screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
	}else{
		if([loadScreenNickname length] > 1){
			screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
		}else{
			if([screenData.jsonVars objectForKey:@"quizRewardScreenObject"]){
				screenObjectToLoad = [[BT_item alloc] init];
				[screenObjectToLoad setItemId:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemId"]];
				[screenObjectToLoad setItemNickname:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemNickname"]];
				[screenObjectToLoad setItemType:[[screenData.jsonVars objectForKey:@"quizRewardScreenObject"] objectForKey:@"itemType"]];
				[screenObjectToLoad setJsonVars:[screenData.jsonVars objectForKey:@"quizRewardScreenObject"]];
			}								
		}
	}
	
	//load next screen if it's not nil
	if(screenObjectToLoad != nil){
        
		//build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
		BT_item *tmpMenuItem = [[BT_item alloc] init];
        
		//build an NSDictionary of values for the jsonVars property
		NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId", 
                                       [self.screenData.jsonVars objectForKey:@"quizRewardScreenTransitionType"], @"transitionType",
                                       nil];	
		[tmpMenuItem setJsonVars:tmpDictionary];
		[tmpMenuItem setItemId:@"0"];
        
		//load the next screen	
		[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:tmpMenuItem:screenObjectToLoad];
		[tmpMenuItem release];
		
	}else{
		//show debug
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
	}	
    
}



//show finish screen
-(void)showFinishScreen{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"showFinishScreen %@", @""]];
    
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
    
	//get possible itemId of the screen to load
	NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizFinishScreenItemId":@""];
	
	//get possible nickname of the screen to load
	NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:screenData.jsonVars:@"quizFinishScreenNickname":@""];
    
	//bail if load screen = "none"
	if([loadScreenItemId isEqualToString:@"none"]){
		return;
	}
	
	//check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
	BT_item *screenObjectToLoad = nil;
	if([loadScreenItemId length] > 1){
		screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
	}else{
		if([loadScreenNickname length] > 1){
			screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
		}else{
			if([screenData.jsonVars objectForKey:@"quizFinishScreenObject"]){
				screenObjectToLoad = [[BT_item alloc] init];
				[screenObjectToLoad setItemId:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemId"]];
				[screenObjectToLoad setItemNickname:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemNickname"]];
				[screenObjectToLoad setItemType:[[screenData.jsonVars objectForKey:@"quizFinishScreenObject"] objectForKey:@"itemType"]];
				[screenObjectToLoad setJsonVars:[screenData.jsonVars objectForKey:@"quizFinishScreenObject"]];
			}								
		}
	}
	
	//load next screen if it's not nil
	if(screenObjectToLoad != nil){
        
		//build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
		BT_item *tmpMenuItem = [[BT_item alloc] init];
        
		//build an NSDictionary of values for the jsonVars property
		NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId", 
                                       [self.screenData.jsonVars objectForKey:@"quizFinishScreenTransitionType"], @"transitionType",
                                       nil];	
		[tmpMenuItem setJsonVars:tmpDictionary];
		[tmpMenuItem setItemId:@"0"];
        
		//load the next screen	
		[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:tmpMenuItem:screenObjectToLoad];
		[tmpMenuItem release];
		
	}else{
		//show debug
		[BT_debugger showIt:self:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
	}	
    
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//delegate method for action sheet clicks
-(void)actionSheet:(UIActionSheet *)actionSheet  clickedButtonAtIndex:(NSInteger)buttonIndex {
    
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	//quit
	if([buttonTitle isEqual:NSLocalizedString(@"quit", @"Quit")]){	
		[self navLeftTap];
	}		
    
	//show reward
	if([buttonTitle isEqual:NSLocalizedString(@"quizShowReward", @"Show Reward")]){	
		[self showQuizRewardScreen];
	}		
    
	//show continue
	if([buttonTitle isEqual:NSLocalizedString(@"continue", @"Continue")]){	
		[self showFinishScreen];
	}	
	
	//try again
	if([buttonTitle isEqual:NSLocalizedString(@"quizTryAgain", @"Try Again")]){	
		[self startQuiz];
	}
	
    
}


//sets the question images
-(void)setQuestionImage:(UIImage *)theImage{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"setQuestionImage: %@", @""]];
	[self.spinner stopAnimating];
	
	//do we round the corners?
	if(quizImageCornerRadius > 0){
		theImage = [BT_imageTools makeRoundCornerImage:theImage:quizImageCornerRadius:quizImageCornerRadius];
	}	
	[self.questionImageView setImage:theImage];
	[self.questionImageView setAlpha:1.0];
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//BT_photo delegate methods

//photo finished loading..
-(void)photoDidFinishLoading:(BT_photo *)photo{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"photoDidFinishLoading: %@", @""]];
	[self setQuestionImage:[photo image]];
}

//photo failed to load
-(void)photoDidFailToLoad:(BT_photo *)photo {
	[BT_debugger showIt:self:[NSString stringWithFormat:@"photoDidFailToLoad: %@", @""]];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	if([appDelegate.rootApp.rootDevice isIPad]){
		[self setQuestionImage:[UIImage imageNamed:@"quizBg_large.png"]];
	}else{
		[self setQuestionImage:[UIImage imageNamed:@"quizBg_small.png"]];
	}
}



//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
	if(self.progressView != nil){
		UILabel *tmpLabel = (UILabel *)[self.progressView.subviews objectAtIndex:2];
		[tmpLabel setText:message];
	}
}
-(void)downloadFileCompleted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
	[self hideProgress];
	//NSLog(@"Message: %@", message);
    
	//if message contains "error", look for previously cached data...
	if([message rangeOfString:@"ERROR-1968" options:NSCaseInsensitiveSearch].location != NSNotFound){
        
		//show alert
		[self showAlert:nil:NSLocalizedString(@"downloadError", @"There was a problem downloading some data. Check your internet connection then try again."):0];
        
		[BT_debugger showIt:self:[NSString stringWithFormat:@"download error: There was a problem downloading data from the internet.%@", @""]];
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            
			//use stale data if we have it
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[BT_debugger showIt:self:[NSString stringWithFormat:@"building screen from stale configuration data saved at: @", [self saveAsFileName]]];
			[self parseScreenData:staleData];
			
		}else{
			
			[BT_debugger showIt:self:[NSString stringWithFormat:@"There is no local data available for this screen?%@", @""]];
			[self layoutScreen];
		}
        
	}else{
        
		//parse previously saved data
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:[NSString stringWithFormat:@"parsing downloaded screen data.%@", @""]];
			NSString *downloadedData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName]:-1];
			[self parseScreenData:downloadedData];
            
		}else{
			[BT_debugger showIt:self:[NSString stringWithFormat:@"Error caching downloaded file: %@", [self saveAsFileName]]];
			[self layoutScreen];
            
			//show alert
			[self showAlert:nil:NSLocalizedString(@"appDownloadError", @"There was a problem saving some data downloaded from the internet."):0];
            
		}	
		
	}	
	
}


//dealloc
-(void)dealloc{
	[screenData release];
    screenData = nil;
	[progressView release];
    progressView = nil;
	[downloader release];
    downloader = nil;
	[saveAsFileName release];
    saveAsFileName = nil;
	[quizQuestions release];
    quizQuestions = nil;
	[quizFontColorQuestions release];
    quizFontColorQuestions = nil;
	[quizFontColorAnswers release];
    quizFontColorAnswers = nil;
	[quizButtonColorAnswers release];
    quizButtonColorAnswers = nil;
	[quizButtonColorCorrect release];
    quizButtonColorCorrect = nil;
	[quizButtonColorIncorrect release];
    quizButtonColorIncorrect = nil;
	[quizSoundEffectFileNameCorrect release];
    quizSoundEffectFileNameCorrect = nil;
	[quizSoundEffectFileNameIncorrect release];
    quizSoundEffectFileNameIncorrect = nil;
	[quizSoundEffectFileNameFinished release];
    quizSoundEffectFileNameFinished = nil;
	[currentQuestionObject release];
    currentQuestionObject = nil;
	[startButtonBox release];
    startButtonBox = nil;
	[startButton release];
    startButton = nil;
	[answerButtonBox release];
    answerButtonBox = nil;
	[answerButton1 release];
    answerButton1 = nil;
	[answerButton2 release];
    answerButton2 = nil;
	[answerButton3 release];
    answerButton3 = nil;
	[answerButton4 release];
    answerButton4 = nil;
	[answerLabel1 release];
    answerLabel1 = nil;
	[answerLabel2 release];
    answerLabel2 = nil;
	[answerLabel3 release];
    answerLabel3 = nil;
	[answerLabel4 release];
    answerLabel4 = nil;
	[countdownToStartTimer release];
    countdownToStartTimer = nil;
	[countdownToStartLabel release];
    countdownToStartLabel = nil;
	[currentPointsView release];
    currentPointsView = nil;
	[currentPointsImageView release];
    currentPointsImageView = nil;
	[currentPointsLabel release];
    currentPointsLabel = nil;
	[bonusImageView release];
    bonusImageView = nil;
	[quizTimeLabel release];
    quizTimeLabel = nil;
	[quizTimer release];
    quizTimer = nil;
	[questionTransitionTimer release];
    questionTransitionTimer = nil;
	[questionBox release];
    questionBox = nil;
	[questionText release];
    questionText = nil;
	[questionImageView release];
    questionImageView = nil;
	[quizQuestionTransitionType release];
    quizQuestionTransitionType = nil;
	[quizAnswersTransitionType release];
    quizAnswersTransitionType = nil;
	[quizToolbar release];
    quizToolbar = nil;
	[finishedButtons release];
    finishedButtons = nil;
	[rotateMessageView release];
    rotateMessageView = nil;
	[rotateMessageLabel release];
    rotateMessageLabel = nil;
	[spinner release];
    spinner = nil;
	[super dealloc];
	
}


@end
