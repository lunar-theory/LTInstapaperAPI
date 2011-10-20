//
// LTInstapaperAPI.m
//
// Created by David E. Wheeler on 2/3/11.
// Copyright (c) 2011, Lunar/Theory, LLC.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer. Redistributions in binary
// form must reproduce the above copyright notice, this list of conditions and
// the following disclaimer in the documentation and/or other materials
// provided with the distribution. Neither the name of the Lunar/Theory, LLC
// nor the names of its contributors may be used to endorse or promote
// products derived from this software without specific prior written
// permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
// CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
// NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "LTInstapaperAPI.h"
#import "NSData+Base64.h"

#define kAuthURL @"https://www.instapaper.com/api/authenticate"
#define kAddURL  @"https://www.instapaper.com/api/add"

@interface LTInstapaperAPI ()
@property (nonatomic, strong) NSURLConnection *conn;
- (NSMutableURLRequest *)requestForURL:(NSString *)url;
@end

@implementation LTInstapaperAPI

@synthesize delegate, username, password, conn;

- (id)initWithUsername:(NSString *)user password:(NSString *)pass delegate:(id<LTInstapaperAPIDelegate>)dgate {
	if (self = [super init]) {
        self.username = user;
        self.password = pass;
        self.delegate = dgate;
    }
    return self;
}


- (void)authenticate {
    authenticating = YES;
    self.conn = [NSURLConnection connectionWithRequest:[self requestForURL:kAuthURL] delegate:self];
}

- (void) add:(NSString *)body {
    authenticating = NO;
    NSMutableURLRequest *request = [self requestForURL:kAddURL];
    NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:postData];
    [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField: @"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u", postData.length] forHTTPHeaderField:@"Content-Length"];
    self.conn = [NSURLConnection connectionWithRequest:request delegate:self];
}

// This should perhaps be in a category on NSString.
- (NSString *)urlEncodeString:(NSString *)string {
	NSString* encoded = (__bridge_transfer NSString*) CFURLCreateStringByAddingPercentEscapes(
        kCFAllocatorDefault,
        (__bridge CFStringRef) string,
        NULL,
        CFSTR("!*'();:@&=+$,/?%#[]"),
        kCFStringEncodingUTF8
    );
	return encoded;
}

- (void)addURL:(NSString *)url {
    [self add:[NSString stringWithFormat:@"url=%@", [self urlEncodeString:url]]];
}

- (void)addURL:(NSString *)url title:(NSString *)title {
    [self add:[NSString stringWithFormat:@"url=%@&title=%@",
               [self urlEncodeString:url],
               [self urlEncodeString:title]
               ]];
}

- (void)addURL:(NSString *)url title:(NSString *)title selection:(NSString *)selection {
    [self add:[NSString stringWithFormat:@"url=%@&title=%@&selection=%@",
               [self urlEncodeString:url],
               [self urlEncodeString:title],
               [self urlEncodeString:selection]
               ]];
}

- (NSMutableURLRequest *)requestForURL:(NSString *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 15.0];
    [request setValue:[NSString stringWithFormat:@"Basic %@",
                       [[[NSString stringWithFormat:@"%@:%@",username, password]
                         dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString]]
   forHTTPHeaderField:@"Authorization"];
    return request;
}

#pragma mark -
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    if (authenticating) {
        [delegate instapaper:self authDidFinishWithCode:response.statusCode];
        authenticating = NO;
    } else {
        [delegate instapaper:self addDidFinishWithCode:response.statusCode];
    }        
    [connection cancel];
    self.conn = nil;
}

@end
