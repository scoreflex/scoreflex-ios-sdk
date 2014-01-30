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

#import "Scoreflex.h"
#import "SXConfiguration.h"
#import "SXClient.h"
#import "SXViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SXGooglePlusUtil.h"
#import "SXFacebookUtil.h"
//#import <NSJSONSerialization.h>

static NSMutableArray *_notificationStack = nil;
static NSMutableDictionary *_preloadedWebview = nil;
static double _startPlayingTime;
static CLLocationManager *LocationManager = nil;
static BOOL _isReachable = NO;

@interface Scoreflex ()
+ (NSString *)scoreflexLanguageCodeForLocaleLanguageCode:(NSString *)localeLanguageCode;
+ (void) attachView:(UIView *)view gravity:(SXGravity)gravity;
@end

@implementation Scoreflex

+ (void) initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LocationManager = [[CLLocationManager alloc] init];
        _preloadedWebview = [[NSMutableDictionary alloc] init];
    });
}
+ (void) setClientId:(NSString *)clientId secret:(NSString *)secret sandboxMode:(BOOL)sandboxMode
{
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
    configuration.clientId = clientId;
    configuration.clientSecret = secret;
    configuration.baseURL = [NSURL URLWithString:sandboxMode ? SANDBOX_API_URL : PRODUCTION_API_URL];

    // Fetch anonymous access token right away
    BOOL isFetching = [[SXClient sharedClient] fetchAnonymousAccessTokenIfNeededAndCall:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_INITIALIZED
                                                            object:self
                                                          userInfo:nil];
        [Scoreflex setIsReachable:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
    if (NO == isFetching) {
        [self get:@"/network/ping" params:nil handler:^(SXResponse *response, NSError *error) {
            if (nil == error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_INITIALIZED
                                                                    object:self
                                                                  userInfo:nil];
                [Scoreflex setIsReachable:YES];
                return;
            }
            [Scoreflex setIsReachable:NO];

        }];
    }

    // Handle the notification if some are here
    NSMutableArray *stack = [Scoreflex getNotificationStack];
    if ([stack count] > 0)
    {
        NSDictionary *notificationData = [stack lastObject];
        [stack removeObject:notificationData];
        [Scoreflex handleScoreflexNotification:notificationData];
    }
}

+(NSMutableArray *) getNotificationStack
{
    if (_notificationStack == nil)
    {
        _notificationStack = [[NSMutableArray alloc] init];
    }
    return _notificationStack;
}

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([SXFacebookUtil handleURL:url sourceApplication:sourceApplication annotation:annotation])
        return YES;

    return [SXGooglePlusUtil handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - API Helpers
+(void) startPlayingSession
{
    _startPlayingTime = [[NSDate date] timeIntervalSince1970];
}
+(void) stopPlayingSession
{
    _startPlayingTime = -1;
}

+(NSNumber*) getPlayingTime
{
    if (_startPlayingTime > 0) {
        return [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] - _startPlayingTime];
    }
    return [NSNumber numberWithInt:0];
}

+ (UIView *) showRanksPanel:(NSString *)leaderboardId score:(long)score
{
    return [self showRanksPanel:leaderboardId score:score gravity:SXGravityBottom];
}

+ (UIView *) showRanksPanel:(NSString *)leaderboardId score:(long)score gravity:(SXGravity)gravity
{
    return [self showRanksPanel:leaderboardId params:@{
     @"score" : [NSString stringWithFormat:@"%ld", score],
     } gravity:gravity];

}

+ (UIView *) showRanksPanel:(NSString *)leaderboardId params:(id)params gravity:(SXGravity)gravity
{
    NSString *resource = [NSString stringWithFormat:@"/web/scores/%@/ranks", leaderboardId];
    UIView *view = [Scoreflex view:resource params:params forceFullScreen:NO];
    [self attachView:view gravity:gravity];
    return view;
}

+(void) submitScore:(NSString *) leaderboardId score:(long) score handler:(void(^)(SXResponse *response, NSError *error))handler {
    NSDictionary *params = @{@"score": [NSNumber numberWithLong:score]};
    NSString *resource = [NSString stringWithFormat:@"/scores/%@", leaderboardId];
    [self postEventually:resource params:params handler:handler];
}

+(void) submitScore:(NSString *) leaderboardId params:(id) params handler:(void(^)(SXResponse *response, NSError *error))handler {
    NSString *resource = [NSString stringWithFormat:@"/scores/%@", leaderboardId];
    [self postEventually:resource params:params handler:handler];
}

+ (UIView*) submitScoreAndShowRanksPanel:(NSString*) leaderboardId params:(id) params gravity:(SXGravity)gravity
{
    [self submitScore:leaderboardId params:params handler:^(SXResponse *response, NSError *error) {

    }];
    return [self showRanksPanel:leaderboardId params:params gravity:gravity];
}

+ (void) submitTurn:(NSString *)challengeInstanceId params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    NSError *error;
    NSNumber *playingTime = [self getPlayingTime];
    NSMutableDictionary *parameterWithPlayingTime = [NSMutableDictionary dictionaryWithDictionary:params];
    [parameterWithPlayingTime setValue:[playingTime stringValue] forKey:@"playingTime"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:parameterWithPlayingTime options:0 error:&error];
    NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    NSDictionary *parameters = @{@"body":bodyString};
    [self postEventually:[NSString stringWithFormat:@"/challenges/instances/%@/turns", challengeInstanceId] params:parameters handler:handler];

}

+(void) submitTurnAndShowChallengeDetail:(NSString*) challengeInstanceId params:(id)params
{
    [self submitTurn:challengeInstanceId params:params handler:^(SXResponse *response, NSError *error) {
       [self showFullScreenView:[NSString stringWithFormat:@"/web/challenges/instances/%@", challengeInstanceId] params:params];
    }];
}

+ (UIViewController *) showFullScreenView:(NSString *) resource params:(id)params
{
    SXViewController *viewController = (SXViewController*)[Scoreflex getFullscreenView:resource params:params];

    // Present the controller modally
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *controller = [rootViewController modalViewController];
    if (controller != nil) {
        [controller dismissModalViewControllerAnimated:NO];
    }

    viewController.fromTop = NO;
    [rootViewController presentViewController:viewController animated:YES completion:nil];
    return viewController;
}

+ (SXView *) showPanelView:(NSString *) resource params:(id)params gavity:(SXGravity) gravity
{
//    SXView *view = [Scoreflex view:resource params:params forceFullScreen:NO];
    SXView *view = [Scoreflex getPanelView:resource params:params];
    [self attachView:view gravity:gravity];
    return view;
}

#pragma mark - UIView manipulation
+ (void) attachView:(UIView *)view gravity:(SXGravity)gravity
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (!rootViewController) {
        NSLog(@"Missing root view controller, couldn't attach view");
        return;
    }

    UIView *parent = rootViewController.view;
    CGFloat y;

    switch (gravity) {
        case SXGravityBottom:
            y = parent.bounds.size.height - [self getPanelHeight];
            view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
            break;

        default:
            y = 0;
            view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
            break;
    }

    // Set the frame
    CGRect frame = CGRectMake(0, y, parent.bounds.size.width, [Scoreflex getPanelHeight]);
    view.frame = frame;
    [parent addSubview:view];

    // Add a drop shadow
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = .3f;
    view.layer.shadowRadius = 3;
    view.layer.masksToBounds = NO;

    /*
     This is commented out because it breaks User Interface rotation.

     // Define the shadow path for better performance
     CGMutablePathRef shadowPath = CGPathCreateMutable();
     CGPathAddRect(shadowPath, NULL, view.bounds);
     view.layer.shadowPath = shadowPath;
     CGPathRelease(shadowPath);
     */
}


#pragma mark - REST API Access
+ (void) post:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    SXClient *client = [SXClient sharedClient];
    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"POST";
    request.resource = resource;
    request.handler = handler;
    request.params = params;
    [client requestAuthenticated:request];
}

+ (void) get:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    SXClient *client = [SXClient sharedClient];
    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"GET";
    request.resource = resource;
    request.handler = handler;
    request.params = params;
    [client requestAuthenticated:request];
}

+ (void) delete:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    SXClient *client = [SXClient sharedClient];
    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"DELETE";
    request.resource = resource;
    request.handler = handler;
    request.params = params;
    [client requestAuthenticated:request];
}

+ (void) put:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    SXClient *client = [SXClient sharedClient];
    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"PUT";
    request.resource = resource;
    request.handler = handler;
    request.params = params;
    [client requestAuthenticated:request];
}



+ (void) postEventually:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler
{
    SXClient *client = [SXClient sharedClient];
    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"POST";
    request.resource = resource;
    request.handler = handler;
    request.params = params;
    [client requestEventually:request];
}

#pragma mark - Language

+ (NSArray *)validLanguageCodes
{
    static NSArray *result = nil;
    if (!result)
        result = @[@"af", @"ar", @"be",
                   @"bg", @"bn", @"ca", @"cs", @"da", @"de", @"el", @"en", @"en_GB", @"en_US",
                   @"es", @"es_ES", @"es_MX", @"et", @"fa", @"fi", @"fr", @"fr_FR", @"fr_CA",
                   @"he", @"hi", @"hr", @"hu", @"id", @"is", @"it", @"ja", @"ko", @"lt", @"lv",
                   @"mk", @"ms", @"nb", @"nl", @"pa", @"pl", @"pt", @"pt_PT", @"pt_BR", @"ro",
                   @"ru", @"sk", @"sl", @"sq", @"sr", @"sv", @"sw", @"ta", @"th", @"tl", @"tr",
                   @"uk", @"vi", @"zh", @"zh_CN", @"zh_TW", @"zh_HK",
                   ];
    return result;
}

+ (NSString *)languageCode
{
    NSArray *preferredLanguageCodes = [NSLocale preferredLanguages];
    return [self scoreflexLanguageCodeForLocaleLanguageCode:preferredLanguageCodes.count ? [preferredLanguageCodes objectAtIndex:0] : @"en"];
}

+ (NSString *)scoreflexLanguageCodeForLocaleLanguageCode:(NSString *)localeLanguageCode
{
    NSString *code = [localeLanguageCode stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    if ([[self validLanguageCodes] containsObject:code])
        return code;
    return @"en";
}

+ (void) setDeviceToken:(NSString*) deviceToken;
{
    deviceToken = [deviceToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    [[SXConfiguration sharedConfiguration] setDeviceToken:deviceToken];
    NSDictionary *params = [NSDictionary dictionaryWithObject:deviceToken forKey:@"token"];
    [Scoreflex postEventually:@"/notifications/deviceTokens" params:params handler:^(SXResponse *response, NSError *error) {

    }];
}

+ (BOOL) isInitialized
{
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
    return !(configuration.clientId == nil);
}

+(NSString *) getPlayerId {
   return [[SXConfiguration sharedConfiguration] playerId];
}

+ (BOOL) shareOnGoogle:(NSString *) text url:(NSString *) url {
    return [SXGooglePlusUtil shareUrl:text url:url];
}

+ (BOOL) sendGoogleInvitation:(NSString *)text friends:(NSArray *) friends url:(NSString *)url deepLinkPath:(NSString *)deepLink {
    return [SXGooglePlusUtil sendInvitation:text friends:friends url:url deepLinkPath:deepLink];
}

+ (BOOL) shareOnFacebook:(NSString *)title text:(NSString *)text url:(NSString *) url {
    return [SXFacebookUtil shareUrl:title text:text url:url];
}

+ (BOOL) sendFacebookInvitation:(NSString*)text friends:(NSArray*) friends deepLinkPath:(NSString *) deepLink {
    return [SXFacebookUtil sendInvitation:text friends:friends deepLinkPath:deepLink callback:^(NSArray *invitedFriends) {
        NSString *friends = [NSString stringWithFormat:@"Facebook:%@", [invitedFriends componentsJoinedByString:@",Facebook:"]];
        [Scoreflex postEventually:[NSString stringWithFormat:@"/social/invitations/%@",friends] params:nil handler:nil];
    } ];
}

+ (void) handleScoreflexNotification:(NSDictionary*) scoreflexNotification
{
    NSNumber *code = [scoreflexNotification objectForKey:@"code"];
    NSDictionary *data = [scoreflexNotification objectForKey:@"data"];
    int codeInt = [code intValue];
    NSString *targetPlayerId = [data objectForKey:@"targetPlayerId"];
    NSString *localPlayerId = [self getPlayerId];
    if (localPlayerId == nil) {
        return;
    }
 
    if (codeInt == SX_PUSH_NOTIFICATION_TYPE_CHALLENGE_INVITATION || codeInt == SX_PUSH_NOTIFICATION_TYPE_CHALLENGE_ENDED ||
        codeInt == SX_PUSH_NOTIFICATION_TYPE_YOUR_TURN_IN_CHALLENGE)
    {
        if (![localPlayerId isEqualToString:targetPlayerId]) {
            NSLog(@"Wrong player id");
            [Scoreflex showFullScreenView:@"/web/challenges" params:nil];
            return;
        }
        NSString *challengeResource =  [NSString stringWithFormat:@"/web/challenges/instances/%@", [data objectForKey:@"challengeInstanceId"]];
        [Scoreflex showFullScreenView:challengeResource params:nil];
    }
    else if (codeInt == SX_PUSH_NOTIFICATION_TYPE_FRIEND_JOINED_GAME)
    {
        NSString *friendResource =  [NSString stringWithFormat:@"/web/players/%@", [data objectForKey:@"friendId"]];
        [Scoreflex showFullScreenView:friendResource params:nil];

    }
    else if (codeInt == SX_PUSH_NOTIFICATION_TYPE_FRIEND_BEAT_YOUR_HIGHSCORE)
    {
        NSString *leaderboardResource =  [NSString stringWithFormat:@"/web/leaderboards/%@", [data objectForKey:@"leaderboardId"]];
        if (![localPlayerId isEqualToString:targetPlayerId]) {
            NSLog(@"Wrong player id");
            [Scoreflex showFullScreenView:leaderboardResource params:nil];
            return;
        }

        NSString *friendId = [data objectForKey:@"friendId"];
        NSDictionary *params = @{@"friendsOnly": @"true", @"focus":friendId};
        
        [Scoreflex showFullScreenView:leaderboardResource params:params];
    }
    else if (codeInt == SX_PUSH_NOTIFICATION_TYPE_PLAYER_LEVEL_CHANGED)
    {
        [Scoreflex showFullScreenView:@"/web/players/me" params:nil];
    }
}

+ (NSInteger) getPanelHeight {
    return   ([[UIScreen mainScreen] bounds].size.height / 480) * PANEL_HEIGHT;
}

+ (void) setIsReachable:(BOOL)isReachable {
    if (_isReachable != isReachable) {
        NSDictionary *userInfo = @{SX_NOTIFICATION_CONNECTIVITY_CHANGED_STATE: [NSNumber numberWithBool:isReachable]};

        [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_CONNECTIVITY_CHANGED_STATE
                                                            object:self
                                                          userInfo:userInfo];
    }
    _isReachable = isReachable;
}

+ (BOOL) isReachable {
    return _isReachable;
}

+ (BOOL) handleNotification:(NSDictionary*) notificationDictionnary
{
    if (notificationDictionnary == nil)
    {
        return NO;
    }
    
    NSDictionary *customField = [notificationDictionnary objectForKey:@"custom"];
    if (customField == nil)
    {
        return NO;
    }
    
    NSDictionary *scoreflexData = [customField objectForKey:SX_PUSH_NOTIFICATION_KEY];
    if (scoreflexData == nil)
    {
        return NO;
    }
    
    NSNumber *code = [scoreflexData objectForKey:@"code"];
    if ([code intValue] >= SX_PUSH_NOTIFICATION_TYPE_CHALLENGE_INVITATION)
    {
        if ([Scoreflex isInitialized])
        {
            [Scoreflex handleScoreflexNotification:scoreflexData];
        }
        else
        {
            [[Scoreflex getNotificationStack] addObject:scoreflexData];
        }
        return YES;
    }
    
    return NO;
}

+ (BOOL) handleApplicationLaunchWithOption:(NSDictionary*) launchOptions
{
    if (launchOptions == nil)
	{
        return NO;
    }
	NSDictionary *notificationDictionnary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    return [self handleNotification:notificationDictionnary];
}

#pragma mark - Location

+ (CLLocation *)location
{
    return LocationManager.location;
}


#pragma mark - preload

+(void) showViewController:(SXViewController *)controller {
    if (![self isReachable]) {
        return;
    }

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:controller animated:YES completion:nil];
}


+ (void) preloadResource:(NSString *) resource {
    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";

    if ([_preloadedWebview valueForKey:resource] != nil) {
        return;
    }

    SXRequest *request = [[SXRequest alloc] init];
    request.resource = resource;
    request.method = @"GET";
    request.params = nil;
    SXViewController *viewController = [[SXViewController alloc] initWithNibName:@"SXViewController" bundle:[Scoreflex bundle]];
    viewController.request = request;
    [viewController preload];
    [_preloadedWebview setValue:viewController forKey:resource];

}

+ (void) freePreloadedResource:(NSString *) resource {
    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";

    if (resource == nil) {
        for (NSString *key in _preloadedWebview) {
            SXViewController *view = [_preloadedWebview valueForKey:key];
            [view.scoreflexView close];
        }
        [_preloadedWebview removeAllObjects];
        return;
    }
    SXViewController *view = [_preloadedWebview valueForKey:resource];
    if (nil != view) {
        [view.scoreflexView close];
    }
    [_preloadedWebview removeObjectForKey:resource];
}

#pragma mark - Views

+ (SXView *) getPanelView:(NSString *)resource
{
    SXView *result = [[SXView alloc] initWithFrame:CGRectZero];
    [result openResource:resource];
    return result;
}

+ (UIViewController *) getFullscreenView:(NSString *) resource params:(NSDictionary* )params
{

    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";
    SXViewController *controller = [_preloadedWebview valueForKey:resource];
    if (controller != nil) {
        [_preloadedWebview removeObjectForKey:resource];
        return controller;
    }
    SXViewController *viewController = [[SXViewController alloc] initWithNibName:@"SXViewController" bundle:[Scoreflex bundle]];
    [viewController.scoreflexView openResource:resource params:params forceFullScreen:YES];
    return viewController;
}

+ (SXView*) getPanelView:(NSString *) resource params:(NSDictionary *) params
{
    SXView *panelView = [[SXView alloc] initWithFrame:CGRectZero];
    [panelView openResource:resource params:params forceFullScreen:NO];
    return panelView;
}

+ (SXView *) view:(NSString *)resource
{
    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";

    SXViewController *controller = [_preloadedWebview valueForKey:resource];
    if (controller != nil) {
        [self showViewController:controller];
        [_preloadedWebview removeObjectForKey:resource];
        return controller.scoreflexView;
    }

    SXView *result = [[SXView alloc] initWithFrame:CGRectZero];
    [result openResource:resource];
    return result;
}

#pragma mark - Show Scoreflex resource

+ (UIViewController *) showPlayerProfile:(NSString*)playerId params:(id)params
{
    if (nil == playerId)
        playerId = @"me";

    return [self showFullScreenView:[NSString stringWithFormat:@"/web/players/%@", playerId] params:params];
}

+ (UIViewController *) showPlayerFriends:(NSString*)playerId params:(id)params
{
    if (nil == playerId)
        playerId = @"me";
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/players/%@/friends", playerId] params:params];
}

+ (UIViewController *) showPlayerNewsFeed:(id)params
{
    return [self showFullScreenView:@"/web/players/me/newsfeed" params:params];
}

+ (UIViewController *) showPlayerProfileEdit:(id)params
{
    return [self showFullScreenView:@"/web/players/me/edit" params:params];
}

+ (UIViewController *) showPlayerSettings:(id)params
{
    return [self showFullScreenView:@"/web/players/me/settings" params:params];
}

+ (UIViewController *) showPlayerRating:(id)params
{
    return [self showFullScreenView:@"/web/players/me/rating" params:params];
}

+ (UIViewController *) showDeveloperProfile:(NSString*)developerId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/developers/%@", developerId] params:params];
}

+ (UIViewController *) showDeveloperGames:(NSString*)developerId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/developers/%@/games", developerId] params:params];
}

+ (UIViewController *) showGameDetails:(NSString*)gameId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/games/%@", gameId] params:params];
}

+ (UIViewController *) showGamePlayers:(NSString*)gameId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/games/%@/players", gameId] params:params];
}

+ (UIViewController *) showLeaderboard:(NSString*)leaderboardId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/leaderboards/%@", leaderboardId] params:params];
}

+ (UIViewController *) showLeaderboardOverview:(NSString*)leaderboardId params:(id)params
{
    return [self showFullScreenView:[NSString stringWithFormat:@"/web/leaderboards/%@/overview", leaderboardId] params:params];
}

+ (UIViewController *) showPlayerChallenges:(id)params
{
    return [self showFullScreenView:@"/web/challenges" params:params];
}

+ (UIViewController *) showSearch:(id)params
{
    return [self showFullScreenView:@"/web/search" params:params];
}

#pragma mark - Views
+ (SXView *) view:(NSString *)resource params:(NSDictionary *)params forceFullScreen:(BOOL)forceFullScreen
{
    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";

    SXViewController *controller = [_preloadedWebview valueForKey:resource];
    if (controller != nil) {

        [self showViewController:controller];
        [_preloadedWebview removeObjectForKey:resource];
        return controller.scoreflexView;
    }
    SXView *result = [[SXView alloc] initWithFrame:CGRectZero];
    [result openResource:resource params:params forceFullScreen:forceFullScreen];
    return result;
}


#pragma mark - Bundle

static NSBundle * ScoreflexBundle = nil;
+(NSBundle *)bundle
{
    if (!ScoreflexBundle) {
        ScoreflexBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"ScoreflexResources.bundle" ofType:nil]];
    }
    return ScoreflexBundle;
}


@end
