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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SXResponse.h"
#import "SXView.h"

/**
 @enum SXGravity enumeration to use for the gravity of scoreflex panels
 */
typedef enum {
    SXGravityBottom,
    SXGravityTop,
} SXGravity;

/**
 Name of the notification that is sent using NSNotificationCenter sent when a challenge must be started
 */
#define SX_NOTIFICATION_START_CHALLENGE @"ScoreflexStartChallenge"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_START_CHALLENGE for the json serialized configuration of the instance
 */
#define SX_NOTIFICATION_START_CHALLENGE_CONFIG_KEY @"ScoreflexConfigKey"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_START_CHALLENGE for config id of the challenge instance
 */
#define SX_NOTIFICATION_START_CHALLENGE_CONFIG_ID_KEY @"ScoreflexConfigIdKey"

/**
 Name of the notification that is sent using NSNotificationCenter sent when Scoreflex has been initialized and is reacable
 */
#define SX_NOTIFICATION_INITIALIZED @"scoreflexInitialized"

/**
 Name of the notification that is sent using NSNotificationCenter sent when a Scoreflex resource has been preloaded successfully
 */
#define SX_NOTIFICATION_RESOURCE_PRELOADED @"scoreflexResourcePreloaded"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_RESOURCE_PRELOADED for the path of the preloaded resource
 */
#define SX_NOTIFICATION_RESOURCE_PRELOADED_PATH @"ScoreflexResourcePreloadedPath"

/**
 Name of the notification that is sent using NSNotificationCenter sent when the user changed
 */
#define SX_NOTIFICATION_USER_LOGED_IN @"scoreflexUserLoggedIn"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_USER_LOGED_IN for the new SID
 */
#define SX_NOTIFICATION_USER_LOGED_IN_SID_KEY @"scoreflexSID"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_USER_LOGED_IN for the new Access token
 */
#define SX_NOTIFICATION_USER_LOGED_IN_ACCESS_TOKEN_KEY @"scoreflexAccessToken"

/**
 Name of the notification that is sent using NSNotificationCenter sent when the game should load a level
 */
#define SX_NOTIFICATION_PLAY_LEVEL @"scoreflexPlayLevel"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_PLAY_LEVEL for the leaderboad id
 */
#define SX_NOTIFICATION_PLAY_LEVEL_LEADERBOARD_ID @"leaderboardId"

/**
 Name of the notification that is sent using NSNotificationCenter sent when the reachability of Scoreflex.com changed
 */
#define SX_NOTIFICATION_CONNECTIVITY_CHANGED @"scoreflexConnectivityChanged"

/**
 The key in the userInfo of the notificaiton SX_NOTIFICATION_CONNECTIVITY_CHANGED for the new reachibility state
 */
#define SX_NOTIFICATION_CONNECTIVITY_CHANGED_STATE @"connectivityState"

/**
 The timeout of the webview requests
 */
#define SX_WEBVIEW_TIMEOUT 10.0

/**
 The notification key for the data payload of a scoreflex push notification
 */
#define SX_PUSH_NOTIFICATION_KEY @"_sfx"

/**
  A push notification sent from the developer to the player (using scoreflex.com website)
 */
#define SX_PUSH_NOTIFICATION_TYPE_DEVELOPER_TO_PLAYER 1

/**
 A push notification sent from the player to another player (using your game)
 */
#define SX_PUSH_NOTIFICATION_TYPE_PLAYER_TO_PLAYER 2

/**
 A notification received when the player has been invited for a challenge
 */
#define SX_PUSH_NOTIFICATION_TYPE_CHALLENGE_INVITATION 100

/**
 A notification received when a challende is ended
 */
#define SX_PUSH_NOTIFICATION_TYPE_CHALLENGE_ENDED 101

/**
 A notification received when it is the player's turn in a challenge
 */
#define SX_PUSH_NOTIFICATION_TYPE_YOUR_TURN_IN_CHALLENGE 102

/**
 A notification received when a friend of the player (Facebook or Google) joins the game
 */
#define SX_PUSH_NOTIFICATION_TYPE_FRIEND_JOINED_GAME 103

/**
 A notification received when a friend of the player (Scoreflex) beat his own highscore
 */
#define SX_PUSH_NOTIFICATION_TYPE_FRIEND_BEAT_YOUR_HIGHSCORE 104

/**
 A notification received when a player get a new rank
 */
#define SX_PUSH_NOTIFICATION_TYPE_PLAYER_LEVEL_CHANGED 105


/**
 `Scoreflex` is your main interface to the Scoreflex SDK.

 ## Initialization
 Call `setClientId:secret:sandboxMode` in your `AppDelegate` to initialize the SDK:

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
    [Scoreflex setClientId:@"XXXXXX" secret:@"YYYYYY" sandboxMode:YES];

    // Override point for customization after application launch.

    return YES;
    }

 ## Accessing the Scoreflex REST API
 The Scoreflex REST API supports GET, POST, PUT and DELETE verbs. To hit the API, you use the following methods:

 - `get:params:handler:`
 - `post:params:handler:`
 - `delete:params:handler:`
 - `put:params:handler:`
 - `postEventually:params:handler:`

 ## Showing Scoreflex interface to the player

 - `showPlayerProfile:params:`
 - `showPlayerFriends:params:`
 - `showPlayerNewsFeed:`
 - `showPlayerProfileEdit:`
 - `showPlayerSettings:`
 - `showPlayerRating:`
 - `showDeveloperProfile:params:`
 - `showDeveloperGames:params:`
 - `showGameDetails:params:`
 - `showGamePlayers:params:`
 - `showLeaderboard:params:`
 - `showLeaderboardOverview:params:`
 - `showPlayerChallenges:`
 - `showSearch:`
 - `showRanksPanel:score:`
 - `showRanksPanel:score:gravity:`
 - `showRanksPanel:params:gravity:`

 */


@interface Scoreflex : NSObject

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the scoreflex SDK.

 Initialization should occur the earliest possible when your application starts.
 A good place is the `application:didFinishLaunchingWithOptions:` method of your AppDelegate.

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        [Scoreflex setClientId:@"XXXXXX" secret:@"YYYYYY" sandboxMode:YES];

        // Override point for customization after application launch.

        return YES;
    }



 @param clientId Your scoreflex client ID
 @param secret Your scoreflex secret
 @param sandboxMode Whether to use sandbox.
 */

+ (void) setClientId:(NSString *)clientId secret:(NSString *)secret sandboxMode:(BOOL)sandboxMode;

/**
 Call this method from your delegate's `handleOpenUrl:sourceApplication:annotation:`.
 */
+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

///---------------------------------------
/// @name Scoreflex variables
///---------------------------------------

/**
 Start a playing session in order to start the timer
 */
+(void) startPlayingSession;

/**
 Stop a playing sesion stop the play timer
 */
+(void) stopPlayingSession;

/**
 The ID of the current logged player or ghost player
 */

+(NSNumber *) getPlayingTime;


/**
 The ID of the current logged player or ghost player
 */
+(NSString *) getPlayerId;

///---------------------------------------
/// @name Scoreflex API Helpers
///---------------------------------------


/**
 Attaches an `SXView` to your view hierarchy
 @param view The view you want to attach
 @param gravity Determines where the widget will be attached (SXGravityTop or SXGravityBottom).
 */
+ (void) attachView:(UIView *)view gravity:(SXGravity)gravity;

/**
 Submit a score to a leaderboard and call handler
 @param leaderboardId The identifier for the level the user just finished
 @param score The score to submit
 @param handler the handler to be called on successfull submition
 */
+(void) submitScore:(NSString *) leaderboardId score:(long) score handler:(void(^)(SXResponse *response, NSError *error))handler;


/**
 Submit a score to a leaderboard and call handler
 @param leaderboardId The identifier for the level the user just finished
 @param params A key-value coding compliant object that returns an NSString for the `score` key.
 @param handler the handler to be called on successfull submition
 */
+ (void) submitScore:(NSString *) leaderboardId params:(id) params handler:(void(^)(SXResponse *response, NSError *error))handler;

/**
 Submit a score to a leaderboard and call handler
 @param leaderboardId The identifier for the level the user just finished
 @param params A key-value coding compliant object that returns an NSString for the `score` key.
 @param gravity Determines where the widget will be attached (SXGravityTop or SXGravityBottom).
 */
+ (UIView *) submitScoreAndShowRanksPanel:(NSString*) leaderboardId params:(id) params gravity:(SXGravity)gravity;

/**
 End the turn of a challenge
 @param challengeInstanceId The identifier of the challenge
 @param params A key-value coding compliant object
 @param handler the handler to be called on successfull submition
 */
+ (void) submitTurn:(NSString *)challengeInstanceId params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;


/**
 End the turn of a challenge and show challenge detail
 @param challengeInstanceId The identifier of the challenge
 @param params A key-value coding compliant object
 */
+ (void) submitTurnAndShowChallengeDetail:(NSString*) challengeInstanceId params:(id)params;


/**
 Present a full screen view of the specified resource
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `/web/players/me`
 @param params A key-value coding compliant object
 */
+ (UIViewController*) showFullScreenView:(NSString *) resource params:(id)params;

/**
 Present a panel view of the specified resource
 @param resourceThe relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `/web/players/me`
 @param params A key-value coding compliant object
 @param gravity Determines where the widget will be attached (SXGravityTop or SXGravityBottom)
 */
+ (SXView *) showPanelView:(NSString *) resource params:(id)params gavity:(SXGravity) gravity;

/**
 Returns a full screen view of the specified resource
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `/web/players/me`
 @param params A key-value coding compliant object
 */
+ (UIViewController *) getFullscreenView:(NSString *) resource params:(NSDictionary* )params;

/**
 Returns a panel view of the specified resource
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `/web/players/me`
 @param params A key-value coding compliant object
 */
+ (SXView*) getPanelView:(NSString *) resource params:(NSDictionary *) params;


///---------------------------------------
/// @name Accessing Scoreflex Views
///---------------------------------------

/**
 Shows the player profile of the player (playerId) or the logged player if playerId is nil `/web/players/:id` endpoint
 @param playerId The identifier of the player you want to show or nil for the current logged player
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerProfile:(NSString*)playerId params:(id)params;

/**
 Shows the friends of the player (playerId) or the logged player if playerId is nil `/web/players/:id/friends` endpoint
 @param playerId The identifier of the player or nil for the current logged player
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerFriends:(NSString*)playerId params:(id)params;

/**
 Shows the newsfeed of the logged player `/web/players/me/newsfeed` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerNewsFeed:(id)params;

/**
 Shows the edit profile form of the logged player `/web/players/me/edit` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerProfileEdit:(id)params;

/**
 Shows the settings form of the logged player `/web/players/me/settings` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerSettings:(id)params;

/**
 Shows the rating of the logged player `/web/players/me/rating` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerRating:(id)params;

/**
 Shows the profile of the developer (developerId) `/web/developers/:id` endpoint
 @param developerId The identifier of the developer
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showDeveloperProfile:(NSString*)developerId params:(id)params;

/**
 Shows the games of the developer (developerId) `/web/developers/:id/games` endpoint
 @param developerId The identifier of the developer
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showDeveloperGames:(NSString*)developerId params:(id)params;

/**
 Shows the details of the game (gameId) `/web/games/:id` endpoint
 @param gameId The identifier the game
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showGameDetails:(NSString*)gameId params:(id)params;

/**
 Shows the players of the game (gameId) `/web/games/:id/players` endpoint
 @param gameId The identifier of the game
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showGamePlayers:(NSString*)gameId params:(id)params;

/**
 Shows a leaderboard (leaderboardId) `/web/leaderboards/:leaderboardId` endpoint
 @param leaderboardId The identifier of the leaderboard
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showLeaderboard:(NSString*)leaderboardId params:(id)params;

/**
 Shows the overview of the leaderboard (leaderboardId) `/web/leaderboards/:leaderboardId/overview` endpoint
 @param leaderboardId The identifier of the leaderboard
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showLeaderboardOverview:(NSString*)leaderboardId params:(id)params;

/**
 Shows the challenges list of the current player `/web/challenges` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showPlayerChallenges:(id)params;

/**
 Shows the search form `/web/search` endpoint
 @param params An optional key-value coding compliant object that wil be forwarded a query string.
 */
+ (UIViewController *) showSearch:(id)params;


/**
 Attaches an `SXView` to your view hierarchy that displays the afterLevel Scoreflex widget.
 @param leaderboardId The identifier for the level the user just finished
 @param score The score just performed by the user.
 */
+ (UIView *) showRanksPanel:(NSString *)leaderboardId score:(long)score;

/**
 Attaches an `SXView` to your view hierarchy that displays the afterLevel Scoreflex widget.
 @param leaderboardId The identifier for the level the user just finished
 @param score The score just performed by the user.
 @param gravity Determines where the widget will be attached (SXGravityTop or SXGravityBottom).
 */
+ (UIView *) showRanksPanel:(NSString *)leaderboardId score:(long)score gravity:(SXGravity)gravity;

/**
 Attaches an `SXView` to your view hierarchy that displays the afterLevel Scoreflex widget.
 @param leaderboardId The identifier for the level the user just finished
 @param params A key-value coding compliant object that returns an NSString for the `score` key.
 @param gravity Determines where the widget will be attached (SXGravityTop or SXGravityBottom).
 */
+ (UIView *) showRanksPanel:(NSString *)leaderboardId params:(id)params gravity:(SXGravity)gravity;









///---------------------------------------
/// @name Accessing the Scoreflex REST API
///---------------------------------------


/**
 Perform a GET request to the API
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
    Example: `scores/best`
 @param params A dictionary with parameter names and corresponding values to be serialized as query string parameters.
 @param handler A block to be executed when the request is done executing.
 */

+ (void) get:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;

/**
 Perform a POST request to the API
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `scores/best`
 @param params A dictionary with parameter names and corresponding values that will constitute the POST request's body.
 @param handler A block to be executed when the request is done executing.
 */

+ (void) post:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;

/**
 Perform a DELETE request to the API
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 @param params A dictionary with parameter names and corresponding values to be serialized as query string parameters.
 @param handler A block to be executed when the request is done executing.
 */

+ (void) delete:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;

/**
 Perform a POST request to the API, retrying later (even after application restarts) in the case of a network error.
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `scores/best`
 @param params A dictionary with parameter names and corresponding values that will constitute the POST request's body.
 @param handler A block to be executed when the request is done executing. Note that this handler will not be executed if the request completes after a network error.
 */

+ (void) postEventually:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;

/**
 Perform a PUT request to the API
 @param resource The relative resource path, ommiting the first "/" and ommiting the API version number.
 Example: `scores/best`
 @param params A dictionary with parameter names and corresponding values that will constitute the POST request's body.
 @param handler A block to be executed when the request is done executing.
 */
+ (void) put:(NSString *)resource params:(id)params handler:(void(^)(SXResponse *response, NSError *error))handler;


///----------------
/// @name Languages
///----------------

/**
 Returns an array of strings representing valid Scoreflex language codes.
 */
+ (NSArray *)validLanguageCodes;

/**
 Returns the current language code.
 */

+ (NSString *)languageCode;

///----------------
/// @name Location
///----------------

/**
 Returns the last known location
 */

+ (CLLocation *)location;

/////----------------
///// @name Views
/////----------------
//
//+ (SXView *) view:(NSString *)resource;

///----------------
/// @name Views
///----------------
//
//+ (SXView *) view:(NSString *)resource params:(NSDictionary *)params forceFullScreen:(BOOL)forceFullScreen;
//
///-------------------------
/// @name Resource Bundle
///-------------------------

/**
 The Scoreflex bundle that holds images, nibs, etc.
 */
+(NSBundle *)bundle;

/**
 Returns the reachability state of Scoreflex.com
 */
+ (BOOL) isReachable;

///-------------------------
/// @name Preloading Scoreflex Views
///-------------------------

/**
 Preload the specified resource in a hidden webview and hold a reference of it untill it is shown or freed
 @param resource The path of the resource to preload
 */
+ (void) preloadResource:(NSString *) resource;

/**
 Free the specified resource from memory if it is not visible on screen
 @param resource The path of the resource to free
 */
+ (void) freePreloadedResource:(NSString *) resource;


///-------------------------
/// @name Handling Apple Push Notifications
///-------------------------

/**
 Set the device token of the current player (for Apple push notifications).
 device token must be reteived calling the : `registerForRemoteNotificationTypes:` method of `UIApplication` class
 and by implementing `didRegisterForRemoteNotificationsWithDeviceToken:` method in your Application delegate as follow

    - (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
    {
        NSString *newToken = [deviceToken description];
        [Scoreflex setDeviceToken:newToken];
    }


 @param deviceToken the device token of the device
 */
+ (void) setDeviceToken:(NSString*) deviceToken;

/**
 Handle the Apple push notifications, to be called in your

    - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
    {
        if([application applicationState] == UIApplicationStateInactive)
        {
            [Scoreflex handleNotification:userInfo];
            [application cancelAllLocalNotifications];
        }
    }

 and

    - (void)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        if (launchOptions != nil)
        {
            NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (dictionary != nil)
            {
                [Scoreflex handleNotification:dictionary];
                [application cancelAllLocalNotifications];
            }
        }
    }


 @param the notification dictionnary
 */
+ (BOOL) handleNotification:(NSDictionary*) notificationDictionnary;


+ (NSInteger) getPanelHeight;


@end

