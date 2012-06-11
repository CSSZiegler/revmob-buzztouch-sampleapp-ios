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
#import "BT_httpEater.h"
#import "BT_httpEaterResponse.h"
#import "BT_debugger.h"

@implementation BT_httpEater

+ (BT_httpEaterResponse *)get:(id)url {
	return [self get:url headerFields:nil];
}

+ (BT_httpEaterResponse *)get:(id)url headerFields:(NSDictionary *)headerFields {
	if ([url isKindOfClass:[NSString class]]) { // Can take a string or a NSURL
		url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		url = [NSURL URLWithString:url];
	}
	
	BT_httpEaterResponse *httpResponse;
	httpResponse = [self downloadURL:url method:@"GET" body:nil headerFields:headerFields];
	
	return httpResponse;
}

+ (BT_httpEaterResponse *)post:(id)url body:(NSData *)body {
	return [self post:url body:body headerFields:nil];
}

+ (BT_httpEaterResponse *)post:(id)url body:(NSData *)body headerFields:(NSDictionary *)headerFields {
	if ([url isKindOfClass:[NSString class]]) url = [NSURL URLWithString:url]; 	// Can take a string or a NSURL
	BT_httpEaterResponse *httpResponse = [self downloadURL:url method:@"POST" body:body headerFields:headerFields];
	return httpResponse;
}


+ (BT_httpEaterResponse *)downloadURL:(NSURL *)url method:(NSString *)method body:(NSData *)body headerFields:(NSDictionary *)headerFields {
		[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadURL: %@", [url absoluteString]]];
	if (body) {
		if (body.length < 5000) {
			NSLog(@"(%d bytes) %@", body.length, [[[NSString alloc] initWithData:body encoding:NSASCIIStringEncoding] autorelease]);
		}
		else {
			NSLog(@"(%d bytes) Body is too long to display", body.length);
		}
	}
	
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:45];				
	
	[urlRequest setAllHTTPHeaderFields:headerFields];
	[urlRequest setHTTPMethod:method];
	[urlRequest setHTTPBody:body];	
	[urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	[urlRequest setHTTPShouldHandleCookies:NO];
	
	NSError *error = nil;	
	NSHTTPURLResponse *urlResponse = nil;	
	NSData *bodyResponse = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&error];	
	[urlRequest release];	
	
	return [[[BT_httpEaterResponse alloc] initWithResponse:urlResponse body:bodyResponse error:error] autorelease];
}

// Helper Methods
// --------------
+ (NSString *)queryDictionaryToString:(NSDictionary *)query {
	NSMutableArray *queryArray = [[NSMutableArray alloc] init];
	for (id key in query) {
		[queryArray addObject:[NSString stringWithFormat:@"%@=%@", key, [query objectForKey:key]]];
	}
	
	NSString *queryString = [queryArray componentsJoinedByString:@"&"];	
	[queryArray release];
	
	return queryString;
}

+ (NSURL *)urlWithProtocol:(NSString *)protocol host:(NSString *)host port:(int)port path:(NSString *)path query:(id)query {
	NSMutableString *urlString = [[NSMutableString alloc] init];
	[urlString appendFormat:@"%@://", protocol ? protocol : @"http"];
	if (host) [urlString appendString:host];
	if (port && port != 80) [urlString appendFormat:@":%d", port];
	if (path) [urlString appendFormat:@"/%@", path];
	if (query) {
		if ([query isKindOfClass:[NSDictionary class]]) [urlString appendFormat:@"?%@", [self queryDictionaryToString:query]];
		else [urlString appendFormat:@"?%@", query];
	}
	
	NSURL *url = [NSURL URLWithString:urlString];	
	[urlString release];
	return url;
}

@end




