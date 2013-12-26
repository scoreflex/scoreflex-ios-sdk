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

#import "SXFacebookUtil.h"
#import <FBSession.h>
#import <FBWebDialogs.h>
#import <FBDialogs.h>
#import <FBShareDialogParams.h>
#import <FBAccessTokenData.h>
#import <FBSessionTokenCachingStrategy.h>

@implementation SXFacebookUtil
+ (BOOL) isFacebookAvailable
{
    // Is SDK installed ?
    if (!NSClassFromString(@"FBSession")) {
        return NO;
    }

    // Is app id configured ?
    NSString *appId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
    return appId ? YES : NO;
}

+ (void) login:(void(^)(NSString *accessToken, NSError *error))callback
{
    // Is FB available ?
    if (![self isFacebookAvailable]) {
        if (callback)
            callback(nil, [NSError errorWithDomain:SXErrorDomain code:1 userInfo:nil]);
        return;
    }
    void(^handler)(id, int, NSError *) = nil;
    if (callback)
        handler = ^(id session, int status, NSError *error) {
            if (error) {
                callback(nil, error);
                return;
            }

            NSString *token = [session accessTokenData].accessToken;
            callback(token, nil);
        };
    Class sessionClass = NSClassFromString(@"FBSession");
    [sessionClass openActiveSessionWithPublishPermissions:nil defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:(id)handler];
}

+ (void) logout
{
    if (![self isFacebookAvailable])
        return;

    Class sessionClass = NSClassFromString(@"FBSession");
    [[sessionClass activeSession] closeAndClearTokenInformation];
    [[sessionClass activeSession] close];
    [sessionClass setActiveSession:nil];

    Class tokenStrategy = NSClassFromString(@"FBSessionTokenCachingStrategy");
    id defaultStrategy = [tokenStrategy defaultInstance];
    [defaultStrategy clearToken];
}


+(BOOL) shareUrl:(NSString *) title text:(NSString *) text url:(NSString *) url
{
    if (![self isFacebookAvailable])
        return NO;
    
    [self login:^(NSString *accessToken, NSError *error) {
        FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
        params.link = [NSURL URLWithString:url];
        params.name = title;
        params.caption= title;
        params.description = text;
        [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            
        }];
    }];
    return YES;
        
    
}

+(BOOL) sendInvitation:(NSString *)text friends:(NSArray *) friends deepLinkPath:(NSString *) deepLink callback:(void(^)(NSArray *invitedFriends))callback
{
    if (![self isFacebookAvailable])
        return NO;
    
    [self login:^(NSString *accessToken, NSError *error) {
        
        NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys: [friends componentsJoinedByString:@","], @"suggestion", nil];
        Class sessionClass = NSClassFromString(@"FBSession");
        if (deepLink != nil) {
            [params setValue:deepLink forKey:@"data"];
        }
        [FBWebDialogs presentRequestsDialogModallyWithSession:[sessionClass activeSession]
                                                      message:text
                                                        title:text
                                                   parameters:params
                                                      handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                          if (error) {
                                                          } else {
                                                              if (result == FBWebDialogResultDialogNotCompleted) {
                                                              } else {
                                                                  if (nil != callback) {
                                                                      NSArray *parameters = [[resultURL query] componentsSeparatedByString:@"&"];
                                                                      NSMutableArray *friends = [[NSMutableArray alloc] init];
                                                                      for (NSString *parameter in parameters) {
                                                                          if ([parameter hasPrefix:@"to"]) {
                                                                              [friends addObject:[[parameter componentsSeparatedByString:@"="] objectAtIndex:1]];
                                                                          }
                                                                      }
                                                                      callback(friends);
                                                                  }
                                                              }
                                                          }}
                                                  friendCache:nil];

    }];
    return YES;
}

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    Class sessionClass = NSClassFromString(@"FBSession");
    return [[sessionClass activeSession] handleOpenURL:url];
}

@end
