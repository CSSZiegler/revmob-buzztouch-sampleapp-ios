#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RevMobAdvertisement <NSObject>

@required

- (void)fetchServerDataForAppID:(NSString *)appID withDelegate:(id)delegate;

- (void)update:(NSDictionary *)dict withDelegate:(id)delegate;

- (void)show;

- (BOOL)isLoaded;

@end