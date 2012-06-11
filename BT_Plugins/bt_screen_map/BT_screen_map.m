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
#import "BT_color.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_strings.h"
#import "BT_viewControllerManager.h"
#import "BT_mapAnnotation.h"
#import "BT_mapAnnotationView.h"
#import "BT_mapZoomLevel.h"

#import "BT_screen_map.h"

@implementation BT_screen_map
@synthesize mapView, mapLocations, didInitialPinDrop;
@synthesize mapToolbar, driveToLocation, saveAsFileName, downloader, didInitMap;


//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self:@"viewDidLoad"];
	[super viewDidLoad];

	//init screen properites
	[self setMapToolbar:nil];
	[self setDidInitMap:0];
	
	//the height of the mapView depends on whether or not we are showing a bottom tool bar. 
	int mapHeight = self.view.bounds.size.height;
	int mapWidth = self.view.bounds.size.width;
	int mapTop = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0 : 0;
	if([[BT_strings getStyleValueForScreen:self.screenData:@"navBarStyle":@""] isEqualToString:@"hidden"]){
		mapTop = 0;
	}
	
	//get the bottom toolbar (utility may return nil depending on this screens data)
	mapToolbar = [BT_viewUtilities getMapToolBarForScreen:self:[self screenData]];
	if(mapToolbar != nil){
		mapToolbar.tag = 49;
		mapHeight = (mapHeight - 44);
	}
			
	//map type? "standard", "satellite" or "hybrid"
	MKMapType mapType = MKMapTypeStandard;
	NSString *tmpMapType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"defaultMapType":@""];
	if([tmpMapType length] > 1){
		if([tmpMapType isEqualToString:@"terrain"]) mapType = MKMapTypeSatellite;
		if([tmpMapType isEqualToString:@"hybrid"]) mapType = MKMapTypeHybrid;
	}
	
	//show device location? defaults to no
	BOOL showUserLocation = FALSE;
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"showUserLocation":@"0"] isEqualToString:@"1"]){
		showUserLocation = TRUE;
	}
	
	//mapView
	self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, mapTop, mapWidth, mapHeight)];
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.mapView.showsUserLocation = showUserLocation; 
	self.mapView.mapType = mapType;
	[self.mapView setZoomEnabled:TRUE];
	[self.mapView setScrollEnabled:TRUE];
	self.mapView.delegate = self;
	[self.view addSubview:mapView];		

	//add the toolbar if we have one (utility may return nil depending on this screens data)
	if(mapToolbar != nil){
		[self.view addSubview:mapToolbar];
	}	
	
	//create adView?
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"includeAds":@"0"] isEqualToString:@"1"]){
	   	[self createAdBannerView];
	}
	
}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self:@"viewWillAppear"];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//setup navigation bar and background
	[BT_viewUtilities configureBackgroundAndNavBar:self:[self screenData]];

	//if we have not inited map..
	if(self.didInitMap == 0){
		[self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
		[self setDidInitMap:1];
	}

	//show adView?
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"includeAds":@"0"] isEqualToString:@"1"]){
	    [self showHideAdView];
	}


}

//load data
-(void)loadData{
	[BT_debugger showIt:self:@"loadData"];
	self.didInitialPinDrop = 0;
	
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
		self.mapLocations = [[NSMutableArray alloc] init];

		//load list from screen data
		NSArray *tmpLocations = [[self.screenData jsonVars] objectForKey:@"childItems"];
		for(NSDictionary *tmpLocation in tmpLocations){
			BT_item *thisLocation = [[BT_item alloc] init];
			thisLocation.itemId = [tmpLocation objectForKey:@"itemId"];
			thisLocation.itemType = [tmpLocation objectForKey:@"itemType"];
			thisLocation.jsonVars = tmpLocation;
			[self.mapLocations addObject:thisLocation];
			[thisLocation release];	
		}

	}
	
	//if we have a URL, fetch..
	if(haveURL){
	
		//look for a previously cached version of this screens data...
		if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
			[BT_debugger showIt:self:@"parsing cached version of screen data"];
			NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName:-1];
			[self parseScreenData:staleData];
		}else{
			[BT_debugger showIt:self:@"no cached version of this screens data available."];
			[self downloadData];
		}
			
	
	}else{
		
		//show the child items in the config data
		[BT_debugger showIt:self:@"using locations from the app's configuration file."];
		[self layoutScreen];
		
	}
	
}

//refresh is a help for download
-(void)refreshData{
	[self downloadData];
}

//download data
-(void)downloadData{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloading screen data from: %@", [self saveAsFileName]]];
	
	//flag this as the current screen
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;	
	
	//show progress
	[self showProgress];
	
	NSString *tmpURL = @"";
	if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"dataURL":@""] length] > 3){
		
		//merge url variables
		tmpURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"dataURL":@""];

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
	
		//array of questions
		self.mapLocations = [[NSMutableArray alloc] init];

		//create dictionary from the JSON string
		SBJsonParser *parser = [SBJsonParser new];
		id jsonData = [parser objectWithString:theData];
     	if(!jsonData){
		
			[BT_debugger showIt:self:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
			[self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~"):NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed"):0];
			[BT_fileManager deleteFile:[self saveAsFileName]];
	
		}else{

			if([jsonData objectForKey:@"childItems"]){
				NSArray *tmpLocations = [jsonData objectForKey:@"childItems"];
				for(NSDictionary *tmpLocation in tmpLocations){
					BT_item *thisLocation = [[BT_item alloc] init];
					thisLocation.itemId = [tmpLocation objectForKey:@"itemId"];
					thisLocation.itemType = [tmpLocation objectForKey:@"itemType"];
					thisLocation.jsonVars = tmpLocation;
					[self.mapLocations addObject:thisLocation];
					[thisLocation release];		
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

	//the height of the mapView depends on whether or not we are showing a bottom tool bar. 
	int mapHeight = self.view.bounds.size.height;
	int mapWidth = self.view.bounds.size.width;
	int mapTop = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0 : 0;
	if([[BT_strings getStyleValueForScreen:self.screenData:@"navBarStyle":@""] isEqualToString:@"hidden"]){
		mapTop = 0;
	}
	
	//get the bottom toolbar (utility may return nil depending on this screens data)
	if(mapToolbar != nil){
		mapHeight = (mapHeight - 44);
	}
	
	//webView
	[self.mapView setFrame:CGRectMake(0, mapTop, mapWidth, mapHeight)]; 

	//remove possible previous pins and start over..
	int x = 0;
	for(x = 0; x < [self.mapView.annotations count]; x++){
		//do not remove users annotation
		if(self.mapView.userLocation != [self.mapView.annotations objectAtIndex:x]){
			[self.mapView removeAnnotation:[self.mapView.annotations objectAtIndex:x]];
		}
	}	

	//add pins 
	for(int i = 0; i < [self.mapLocations count]; i++){
		BT_item *thisMapLocation = [self.mapLocations objectAtIndex:i];
		if([thisMapLocation.jsonVars objectForKey:@"latitude"]){
			if([thisMapLocation.jsonVars objectForKey:@"longitude"]){
				if([[thisMapLocation.jsonVars objectForKey:@"latitude"] length] > 0 && [[thisMapLocation.jsonVars objectForKey:@"longitude"] length] > 0){

					//location object
					CLLocationCoordinate2D tmpLocation;
					tmpLocation.latitude = [[thisMapLocation.jsonVars objectForKey:@"latitude"] doubleValue];
					tmpLocation.longitude = [[thisMapLocation.jsonVars objectForKey:@"longitude"] doubleValue];
				
					//annotation object
					BT_mapAnnotation *tmpAnnotation = [[BT_mapAnnotation alloc] initWithCoordinate:tmpLocation];
					[tmpAnnotation setTitle:[thisMapLocation.jsonVars objectForKey:@"title"]];
					[tmpAnnotation setSubtitle:[thisMapLocation.jsonVars objectForKey:@"subTitle"]];
					tmpAnnotation.listIndex = i;
					[self.mapView addAnnotation:tmpAnnotation];	
				
					//release
					[tmpAnnotation release];
			
			
				}//latitude / longitude length > 0
			}//longitude		
		} //latitude
	}//end for each location
	
	//center map after a slight delay to be sure all the pins dropped..
	[self performSelector:@selector(centerMap) withObject:nil afterDelay:1.0];
	
}


//centers map
-(void)centerMap{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:centerMap %@", @""]];
	
	//if there is ONLY one location, center the location and zoom in to the singleLocationDefaultZoom level
	if([self.mapLocations count] == 1){
		if([self.screenData.jsonVars objectForKey:@"singleLocationDefaultZoom"]){
			if([[self.screenData.jsonVars objectForKey:@"singleLocationDefaultZoom"] length] > 0){
				
				//zoom will depend on what version in control panel (older version used decimals)
				//zoom values are between 1 - 28 (one being the furthest away, 28 super close)
				double tmpZoom = [[self.screenData.jsonVars objectForKey:@"singleLocationDefaultZoom"] doubleValue];
				if(tmpZoom < 1){
					tmpZoom = 13; 
				}
				
				//show debug
				[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:zooming to level: %f", tmpZoom]];
				
				//get the first location in the list (the only location)
				BT_item *thisMapLocation = [self.mapLocations objectAtIndex:0];
				if([thisMapLocation.jsonVars objectForKey:@"latitude"]){
					if([thisMapLocation.jsonVars objectForKey:@"longitude"]){
						if([[thisMapLocation.jsonVars objectForKey:@"latitude"] length] > 0 && [[thisMapLocation.jsonVars objectForKey:@"longitude"] length] > 0){

							//location object
							CLLocationCoordinate2D tmpLocation;
							tmpLocation.latitude = [[thisMapLocation.jsonVars objectForKey:@"latitude"] doubleValue];
							tmpLocation.longitude = [[thisMapLocation.jsonVars objectForKey:@"longitude"] doubleValue];
							[self.mapView setCenterCoordinate:tmpLocation animated:TRUE];
							
							//select the one and only annotation so the bubble shows
							[self.mapView selectAnnotation:[self.mapView.annotations objectAtIndex:0] animated:TRUE];
							
							//zoom in
    						[self.mapView setCenterCoordinate:tmpLocation zoomLevel:tmpZoom animated:YES];
							
						}
					}
				}
			
			}
		}
	}

	//if multiple locations...
	if([self.mapView.annotations count] > 1) {

		//top left
		CLLocationCoordinate2D topLeftCoord;
		topLeftCoord.latitude = -90;
		topLeftCoord.longitude = 180;
		
		//bottom right
		CLLocationCoordinate2D bottomRightCoord;
		bottomRightCoord.latitude = 90;
		bottomRightCoord.longitude = -180;

		//region
		MKCoordinateRegion region;
	
		//analyze each annotation
		NSObject <MKAnnotation> *annotation;
		for(annotation in self.mapView.annotations){
			topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
			topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
			bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
			bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
		}
		
		//add some margin around the markers so they all show. More margin if we are in landscape
		if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
			region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
			region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
			region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1;
			region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1;
		}else{
			region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.3;
			region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.3;
			region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * .8;
			region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * .8;
		}
		
		
		region = [self.mapView regionThatFits:region];
		[self.mapView setRegion:region animated:YES];	
		
	}//more than zero annotations

}

//centers device location
-(void)centerDeviceLocation{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:centerDeviceLocation %@", @""]];
	
	//turn on user location it wasn't already
	if(!self.mapView.showsUserLocation){
		[self.mapView setShowsUserLocation:TRUE];
	}
	
	
	//we may not have a device location... (ignore simulator values, their bogus!)
	if(self.mapView.userLocation){
	
		//convert lat/lon to strings so we can test the length..
		NSString *tmpLat = [NSString stringWithFormat:@"%f", self.mapView.userLocation.coordinate.latitude];
		NSString *tmpLon = [NSString stringWithFormat:@"%f", self.mapView.userLocation.coordinate.longitude];
	
		if([tmpLat length] > 3 && [tmpLon length] > 3){
			//simulator is -180.000000
			if(self.mapView.userLocation.coordinate.latitude != -180.000000){
		
				//center on location
				CLLocationCoordinate2D tmpLocation;
				tmpLocation.latitude = self.mapView.userLocation.coordinate.latitude;
				tmpLocation.longitude = self.mapView.userLocation.coordinate.longitude;
				[self.mapView setCenterCoordinate:tmpLocation animated:TRUE];
				
				//select the one and only annotation so the bubble shows
				[self.mapView selectAnnotation:self.mapView.userLocation animated:TRUE];
							
				//zoom in
    			[self.mapView setCenterCoordinate:tmpLocation zoomLevel:15 animated:YES];
				
			}		
		}
	}
	
}

//shows map type
-(void)showMapType:(id)sender{
	if([sender tag] == 1){
		[self.mapView setMapType:MKMapTypeStandard];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"showMapType: %@", @"standard"]];
	}
	if([sender tag] == 2){
		[self.mapView setMapType:MKMapTypeSatellite];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"showMapType: %@", @"terrain"]];
	}
	if([sender tag] == 3){
		[self.mapView setMapType:MKMapTypeHybrid];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"showMapType: %@", @"hybrid"]];
	}	
}



//////////////////////////////////////////////////////////////////////////////////////////////////
//map view delegate methods

//region will change
-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:regionWillChangeAnimated %@", @""]];
}

//region did change
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:regionDidChangeAnimated %@", @""]];
}

//view for annotation
- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:viewForAnnotation %@", @""]];

	//used to get the listIndex of each location
	BT_mapAnnotation *tmpAnnotation = annotation;

	//return the userLocation marker, or the customized view for this location
	if(annotation == self.mapView.userLocation){
		self.mapView.userLocation.title = @"You are here";
		
		//fire geocoder	
		MKReverseGeocoder *geoCoder = [[MKReverseGeocoder alloc] initWithCoordinate:self.mapView.userLocation.coordinate];
		geoCoder.delegate = self;
		[geoCoder start];		
		
		//let map place default blue pin
		return nil;
		
	}else{
		
		//the location item..
		BT_item *tmpLocation = [self.mapLocations objectAtIndex:tmpAnnotation.listIndex];
		
		BT_mapAnnotationView *annotationView = [[BT_mapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotationView"];
		annotationView.animatesDrop = TRUE;
		[annotationView setEnabled:YES];
		[annotationView setCanShowCallout:YES];
		[annotationView setPinColor:MKPinAnnotationColorRed];
		
		//we may have set a custom color for this location's marker...
		if([[BT_strings getJsonPropertyValue:tmpLocation.jsonVars:@"pinColor":@""] isEqualToString:@"green"]) [annotationView setPinColor:MKPinAnnotationColorGreen];
		if([[BT_strings getJsonPropertyValue:tmpLocation.jsonVars:@"pinColor":@""] isEqualToString:@"purple"]) [annotationView setPinColor:MKPinAnnotationColorPurple];
		if([[BT_strings getJsonPropertyValue:tmpLocation.jsonVars:@"pinColor":@""] isEqualToString:@"red"]) [annotationView setPinColor:MKPinAnnotationColorRed];
		
		//button type depends on what we are doing with the "tap" 
		UIButton *theButton = nil;
		
		//info if showing directions...details button if showing another screen...
		NSString *tmpLoadScreenId = [BT_strings getJsonPropertyValue:tmpLocation.jsonVars:@"loadScreenWithItemId":@""];
		NSString *tmpLoadScreenNickname = [BT_strings getJsonPropertyValue:tmpLocation.jsonVars:@"loadScreenWithNickname":@""];

		//ignore if button type is "none"
		if([tmpLoadScreenId isEqualToString:@"showDirections"]){
			theButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
		}else{
			if([tmpLoadScreenId length] > 1 || [tmpLoadScreenNickname length] > 1 || [tmpLocation.jsonVars objectForKey:@"loadScreenObject"]){
				theButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			}
		}
				
		//if we have a button... add the appropriate tag + action (the tag tells us what location was tapped
		if(theButton != nil){
			[theButton setTag:[annotation listIndex]];
			[theButton addTarget:self action:@selector(calloutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
			
		}
		
		//set the button. If it's nil, no button will show
		annotationView.rightCalloutAccessoryView = theButton;

		//return the view
		return annotationView;
	
	}//userLocation
	
	//shouldn't be here
	return nil;
}

//handles button taps in callout bubbles
-(void)calloutButtonTapped:(id)sender{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:calloutButtonTapped%@", @""]];
	
	//tapped location
	BT_item *tappedLocation = [self.mapLocations objectAtIndex:[sender tag]];

	//build a menu-item from the data for this location. This allows us to call the
	//BT_viewControllerManager:tapForMenuItem method. That method "understands"
	//how to do the transition, sound, load screen, etc.
	
	//if "callOutTapLoadScreenWithItemId":"showDirections"
	if([tappedLocation.jsonVars objectForKey:@"loadScreenWithItemId"] || [tappedLocation.jsonVars objectForKey:@"loadScreenWithNickname"] || [tappedLocation.jsonVars objectForKey:@"loadScreenObject"]){
		if([[tappedLocation.jsonVars objectForKey:@"loadScreenWithItemId"] isEqualToString:@"showDirections"]){
			[self showDirectionsToLocation:tappedLocation];
		}else{
			if([[tappedLocation.jsonVars objectForKey:@"loadScreenWithItemId"] length] > 0 || [[tappedLocation.jsonVars objectForKey:@"loadScreenWithNickname"] length] > 0 || [tappedLocation.jsonVars objectForKey:@"loadScreenObject"]){
				
				//appDelegate
				revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

				//get the itemId of the screen to load
				NSString *callOutTapLoadScreenWithItemId = [BT_strings getJsonPropertyValue:tappedLocation.jsonVars:@"loadScreenWithItemId":@""];

				//get the nickname of the screen to load
				NSString *callOutTapLoadScreenNickname = [BT_strings getJsonPropertyValue:tappedLocation.jsonVars:@"loadScreenWithNickname":@""];
				
				//use item id if we had it...
				BT_item *screenObjectToLoad = nil;
				if([callOutTapLoadScreenWithItemId length] > 1){
					screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:callOutTapLoadScreenWithItemId];
				}else{
					if([callOutTapLoadScreenNickname length] > 1){
						screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:callOutTapLoadScreenNickname];
					}
				}
				
				//if we still don't have a screen to load, check for a loadScreenObject
				if(screenObjectToLoad == nil){
					if([tappedLocation.jsonVars objectForKey:@"loadScreenObject"]){
						screenObjectToLoad = [[BT_item alloc] init];
						[screenObjectToLoad setItemId:[[tappedLocation.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
						[screenObjectToLoad setItemNickname:[[tappedLocation.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
						[screenObjectToLoad setItemType:[[tappedLocation.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
						[screenObjectToLoad setJsonVars:[tappedLocation.jsonVars objectForKey:@"loadScreenObject"]];
					}
				}		
		
				//the tap-method handler needs a menu item
				BT_item *tmpMenuData = [[BT_item alloc] init];
				[tmpMenuData setItemId:@"notUsedInThisContext"];
				
				//dictionary for menu item
				NSDictionary *menuDict = [NSDictionary dictionaryWithObjectsAndKeys:
				@"notUsedInThisContext", @"itemId", 
				@"BT_menuItem", @"itemType", 
				[BT_strings getJsonPropertyValue:tappedLocation.jsonVars:@"transitionType":@""], @"transitionType", 
				[BT_strings getJsonPropertyValue:tappedLocation.jsonVars:@"soundEffectFileName":@""], @"soundEffectFileName", 
				nil];
				[tmpMenuData setJsonVars:menuDict];
				
				//BT_viewControllerManager will launch the next screen
				[BT_viewControllerManager handleTapToLoadScreen:[self screenData]:tmpMenuData:screenObjectToLoad];
				
				//clean up				
				[tmpMenuData release];
				
			}
		}
	}
	
}


//shows directions to a location
-(void)showDirectionsToLocation:(BT_item *)theLocation{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:showDirectionsToLocation%@", @""]];
	
	//remember the location to drive to
	[self setDriveToLocation:theLocation];
	
	//we tapped a location bubble, save it as the driveToLocation for action sheet
	UIActionSheet *actionSheet = [[UIActionSheet alloc] 
					initWithTitle:NSLocalizedString(@"routeDrivingDirections", "Do you want to open the native maps application to route directions?")
					delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", "Cancel") destructiveButtonTitle:nil
					otherButtonTitles:NSLocalizedString(@"ok", "OK"), nil];
	[actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];

	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

	//is this a tabbed app?
	if([appDelegate.rootApp.tabs count] > 0){
		[actionSheet showFromTabBar:[appDelegate.rootApp.rootTabBarController tabBar]];
	}else{
		if(self.mapToolbar != nil){
			[actionSheet showFromToolbar:self.mapToolbar];
		}else{
			[actionSheet showInView:[self view]];
		}
	}	
	[actionSheet release];	


}
 
//when each annotation is added 
-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views { 
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:didAddAnnotationViews %@", @""]];
  
} 

//start loading
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:mapViewWillStartLoadingMap %@", @""]];
	[self showProgress];
}

//done loading
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:mapViewDidFinishLoadingMap %@", @""]];
	[self hideProgress];
}

//error loading
-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"mapView:mapViewDidFailLoadingMap %@", @""]];
	[self hideProgress];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//action sheet delegate methods. Shows when 'show directions' confirmation is tapped.
-(void)actionSheet:(UIActionSheet *)actionSheet  clickedButtonAtIndex:(NSInteger)buttonIndex {
	[BT_debugger showIt:self:[NSString stringWithFormat:@"actionSheet:clickedButtonAtIndex %@", @""]];
	if(buttonIndex == 0){

		//must have the devices current location..
		revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	

		//from location
		NSString *fromLat = [appDelegate.rootApp.rootDevice deviceLatitude];
		NSString *fromLon = [appDelegate.rootApp.rootDevice deviceLongitude];

		//to location
		BT_item *toLocation = [self driveToLocation];
		NSString *theTitle = [toLocation.jsonVars objectForKey:@"title"];
		NSString *subTitle = [toLocation.jsonVars objectForKey:@"subTitle"];
		NSString *toLat = [toLocation.jsonVars objectForKey:@"latitude"];
		NSString *toLon = [toLocation.jsonVars objectForKey:@"longitude"];
		[BT_debugger showIt:self:[NSString stringWithFormat:@"loading Maps, driving directions to: %@ (%@) Lat: %@ Lon: %@", theTitle, subTitle, toLat, toLon]];

		/*
			Maps URL Params
			--------------------
			saddr	=starting address
			daddr	=destination address
			z		=zoom level (1 - 20)
			t		=the map type, "m" map, "k" satellite, "h" hybrid, "p" terrain
		*/

		if([fromLat length] > 3 && [fromLon length] > 3 && [toLat length] > 3 && [toLon length] > 3){
			NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@,%@&daddr=%@,%@", fromLat, fromLon, toLat, toLon];
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: urlString]];
		}else{
			
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"locationNotSupported", "It appears that device location information is unavailable. This feature will not work without location information.") delegate:self
			cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
			[alertView show];
			[alertView release];			
		}


	}else{
		//do nothing, alert closes automatically
	}
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//geocoder delegate methods
-(void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"reverseGeocoder:didFailWithError %@", @""]];
}
-(void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"reverseGeocoder:didFindPlacemark %@", @""]];
	
	//appDelegate
	revmobiossampleapp_appDelegate *appDelegate = (revmobiossampleapp_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//show users location
	self.mapView.userLocation.title = [NSString stringWithFormat:@"Your %@", [appDelegate.rootApp.rootDevice deviceModel]];
	self.mapView.userLocation.subtitle = [NSString stringWithFormat:@"%@, %@", [placemark thoroughfare], [placemark locality]];
	[self.mapView selectAnnotation:self.mapView.userLocation animated:YES];
	
	//free geocoder
	[geocoder release];
	
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
	if(progressView != nil){
		UILabel *tmpLabel = (UILabel *)[progressView.subviews objectAtIndex:2];
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
			[BT_debugger showIt:self:[NSString stringWithFormat:@"building screen from stale configuration data: @", [self saveAsFileName]]];
			[self parseScreenData:staleData];
			
		}else{
		
			[BT_debugger showIt:self:[NSString stringWithFormat:@"There is no local data availalbe for this screen?%@", @""]];
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

		}//fileExists	
		
	}//error	
	
}

//dealloc
-(void)dealloc {
	[screenData release];
		screenData = nil;
	[progressView release];
		progressView = nil;
	[mapLocations release];
		mapLocations = nil;
	[mapView release];
		mapView = nil;
	[mapToolbar release];
		mapToolbar = nil;
	[driveToLocation release];
		driveToLocation = nil;
	[downloader release];
		downloader = nil;
	[saveAsFileName release];
		saveAsFileName = nil;
    [super dealloc];
	
}


@end
