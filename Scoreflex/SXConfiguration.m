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

#import "SXConfiguration.h"

static SXConfiguration *sharedConfiguration = nil;
@interface SXConfiguration ()
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, assign) BOOL accessTokenIsAnonymous;
@end

@implementation SXConfiguration
@synthesize accessToken=_accessToken;
@synthesize deviceToken=_deviceToken;
@synthesize sid=_sid;
@synthesize playerId =_playerId;

+ (void) initialize
{
    sharedConfiguration = [[self alloc] init];
}

+ (SXConfiguration *)sharedConfiguration
{
    return sharedConfiguration;
}

#pragma mark - Access token
- (NSString *)accessToken
{
    if (_accessToken)
        return _accessToken;

    _accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:USER_DEFAULTS_ACCESS_TOKEN_KEY];
    return _accessToken;
}

- (NSString *)deviceToken
{
    if (_deviceToken)
        return _deviceToken;

    _deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:USER_DEFAULTS_DEVICE_TOKEN_KEY];
    return _deviceToken;
}

- (void) setDeviceToken:(NSString *)deviceToken
{
    _deviceToken = deviceToken;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    SXLog(@"Setting device token: %@", deviceToken);
    if (deviceToken)
        [defaults setValue:deviceToken forKey:USER_DEFAULTS_DEVICE_TOKEN_KEY];
    else
        [defaults removeObjectForKey:USER_DEFAULTS_DEVICE_TOKEN_KEY];

    [defaults synchronize];
}

- (void) setAccessToken:(NSString *)accessToken
{
    _accessToken = accessToken;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    SXLog(@"Setting access token: %@", accessToken);
    if (accessToken)
        [defaults setValue:accessToken forKey:USER_DEFAULTS_ACCESS_TOKEN_KEY];
    else
        [defaults removeObjectForKey:USER_DEFAULTS_ACCESS_TOKEN_KEY];

    [defaults synchronize];

}

- (void) setAccessToken:(NSString *)accessToken anonymous:(BOOL)anonymous
{
    self.accessToken = accessToken;
    self.accessTokenIsAnonymous = anonymous;
}

#pragma mark - Access token is anonymous
- (BOOL)accessTokenIsAnonymous
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_ACCESS_TOKEN_IS_ANONYMOUS_KEY];
}

- (void) setAccessTokenIsAnonymous:(BOOL)accessTokenIsAnonymous
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    SXLog(@"Setting access token is anonymous: %i", accessTokenIsAnonymous);
    [defaults setBool:accessTokenIsAnonymous forKey:USER_DEFAULTS_ACCESS_TOKEN_IS_ANONYMOUS_KEY];
    [defaults synchronize];

}


#pragma mark - SID

-(NSString *) playerId
{
    if (_playerId)
        return _playerId;

    _playerId = [[NSUserDefaults standardUserDefaults] valueForKey:USER_DEFAULTS_PLAYER_ID_KEY];
    return _playerId;
}

-(void) setPlayerId:(NSString *) playerId
{
    _playerId = playerId;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    SXLog(@"Setting playerId: %@", playerId);
    if (playerId)
        [defaults setValue:playerId forKey:USER_DEFAULTS_PLAYER_ID_KEY];
    else
        [defaults removeObjectForKey:USER_DEFAULTS_PLAYER_ID_KEY];
    [defaults synchronize];
}

- (NSString *)sid
{
    if (_sid)
        return _sid;

    _sid = [[NSUserDefaults standardUserDefaults] valueForKey:USER_DEFAULTS_SID_KEY];
    return _sid;
}

- (void) setSid:(NSString *)sid
{
    _sid = sid;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    SXLog(@"Setting sid: %@", sid);
    if (sid)
        [defaults setValue:sid forKey:USER_DEFAULTS_SID_KEY];
    else
        [defaults removeObjectForKey:USER_DEFAULTS_SID_KEY];
    [defaults synchronize];

}

- (BOOL) usesSandbox
{
    return [[self.baseURL absoluteString] rangeOfString:PRODUCTION_API_URL].location == NSNotFound;
}

@end
