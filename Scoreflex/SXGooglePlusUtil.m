/*
 * Licensed to Scoreflex (www.scoreflex.com) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. Scoreflex licenses this
 * file to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "SXGooglePlusUtil.h"
#import <GooglePlus/GooglePlus.h>
//#import <GTMOAuth2Authentication.h>
#import <GoogleOpenSource/GoogleOpenSource.h>

@interface SXGooglePlusSignInDelegate : NSObject <GPPSignInDelegate>
@property (nonatomic, weak) id<GPPSignInDelegate> previousDelegate;
@property (nonatomic, strong) NSArray *previousScope;
@property (nonatomic, strong) void(^callback)(NSString *accessToken, NSError *error);
- (void) restore;
@end

static SXGooglePlusSignInDelegate *delegate = nil;

@implementation SXGooglePlusUtil
+ (void) initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [[SXGooglePlusSignInDelegate alloc] init];
    });
}
+ (BOOL) isGooglePlusAvailable
{
    // Is SDK installed ?
    if (!NSClassFromString(@"GPPSignIn")) {
        return NO;
    }

    Class cls = NSClassFromString(@"GPPSignIn");
    id signIn = [cls sharedInstance];
    return [signIn clientID] ? YES : NO;

}
+ (void) login:(void(^)(NSString *accessToken, NSError *error))callback
{
    if (![self isGooglePlusAvailable])
        return;

    Class cls = NSClassFromString(@"GPPSignIn");
    id signIn = [cls sharedInstance];
    delegate.previousScope = [signIn scopes];
    delegate.previousDelegate = [signIn delegate];
    delegate.callback = callback;
    [signIn setDelegate:delegate];
    [signIn setScopes:@[GOOGLE_SCOPE_LOGIN, GOOGLE_SCOPE_EMAIL]];
    [signIn authenticate];
}

+ (void) logout
{
    if (![self isGooglePlusAvailable])
        return;

    Class cls = NSClassFromString(@"GPPSignIn");
    id signIn = [cls sharedInstance];
    [signIn signOut];
}


+ (BOOL) shareUrl:(NSString *) text url:(NSString*) url {
    if (![self isGooglePlusAvailable])
        return NO;
    [self login:^(NSString *accessToken, NSError *error) {
        Class sharer = NSClassFromString(@"GPPShare");
        
        id share = [sharer sharedInstance];
        id shareBuilder = [share nativeShareDialog];
        NSURL *urlToShare = [NSURL URLWithString:url];
        [shareBuilder setPrefillText:text];
        [shareBuilder setURLToShare:urlToShare];        
        objc_msgSend(shareBuilder, @selector(open));
    }];
    return YES;
}

+ (BOOL) sendInvitation:(NSString *)text friends:(NSArray *) friends url:(NSString *)url deepLinkPath:(NSString *)deepLink {
    if (![self isGooglePlusAvailable])
        return NO;
    [self login:^(NSString *accessToken, NSError *error) {
        Class sharer = NSClassFromString(@"GPPShare");
        
        id share = [sharer sharedInstance];
        id shareBuilder = [share nativeShareDialog];
        NSURL *urlToShare;
        if (url != nil) {
            urlToShare = [NSURL URLWithString:url];
        } else {
            urlToShare = nil;
        }
        
        [shareBuilder setPrefillText:text];
        [shareBuilder setContentDeepLinkID:deepLink];
        if (urlToShare != nil) {
            [shareBuilder setURLToShare:urlToShare];
            [shareBuilder setCallToActionButtonWithLabel:@"ACCEPT" URL:urlToShare deepLinkID:deepLink];
        }
        
        if (friends != nil) {
            [shareBuilder setPreselectedPeopleIDs:friends];
        }
        
        objc_msgSend(shareBuilder, @selector(open));
    }];
    return YES;
}

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (![self isGooglePlusAvailable])
        return NO;
    Class urlHandler = NSClassFromString(@"GPPURLHandler");
    return [urlHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];

}
@end


@implementation SXGooglePlusSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    if (self.callback)
        self.callback(auth.accessToken, error);
    [self restore];


}

- (void)didDisconnectWithError:(NSError *)error
{
    if (self.callback)
        self.callback(nil, error);
    [self restore];
}

- (void) restore
{
    Class cls = NSClassFromString(@"GPPSignIn");
    id signIn = [cls sharedInstance];
    [signIn setDelegate:self.previousDelegate];
    [signIn setScopes:self.previousScope];
}
@end