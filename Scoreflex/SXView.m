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

#import "SXView.h"
#import "SXClient.h"
#import "SXConfiguration.h"
#import "SXFacebookUtil.h"
#import "SXViewController.h"
#import "Scoreflex.h"
#import "SXGooglePlusUtil.h"

@interface SXView () <UIWebViewDelegate>

///============================
///@name Setting things up
///============================
- (void) prepare;

@property (nonatomic, weak) UIWebView *webView;

///=================================
///@name Loading scoreflex resources
///=================================

- (void) setResource:(NSString *)resource params:(NSDictionary *)params;

- (void) setURL:(NSURL *)url;

- (void) openURL:(NSURL *)url forceFullScreen:(BOOL)forceFullScreen;

///============================
///@name Authentication
///============================

/**
 A code to check against after successful auth
 */
@property (nonatomic, strong) NSString *authState;

/**
 Where to go after succesful auth
 */
@property (nonatomic, strong) NSURL *authNextURL;

/**
 Triggers user authentication in the web view.
 @param fullScreen Should the webView be fullScreen
 @param disableNativeLogin Set to YES if the device cannot do native login
 @param service "Facebook" or "Google" or nil (to let user choose)
 */
- (void) authenticateUserFullScreen:(BOOL)fullScreen disableNativeLogin:(BOOL)disableNativeLogin service:(NSString *)service;

///============================
///@name Handling web callbacks
///============================

/**
 The entry point to handling web callbacks
 @param request The NSURLRequest that the webView wants to load
 @return YES if we handled the callback
 */
- (BOOL)handleWebCallback:(NSURLRequest *)request;

/**
 Deactivate scoreflex
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleInactiveGameError:(NSDictionary *)params;

/**
 Secure connection required: load the https: version of the current webView resource.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleSecureConnectionRequiredError:(NSDictionary *)params;


/**
 Invalid SID: invalidate SID and AccessToken, retrieve anonymous ones.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleInvalidSIDError:(NSDictionary *)params;

/**
 Generic error handling: nothing in production, exception in sandbox mode.
 @param code The error code
 @return YES if we handled the callback
 */
- (BOOL) handleGenericError:(NSInteger)code;

/**
 Logs out the user, deletes Access Token and SID, remove Cookies, request and anonymous Access Token.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleLogout:(NSDictionary *)params;

/**
 Transform the oauth code that should be in the params to request an authenticated Access Token.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleAuthGranted:(NSDictionary *)params;

/**
 Trigger iOS Facebook/Google native authentication if we are in full screen.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleNeedsClientAuth:(NSDictionary *)params;

/**
 Starts the oauth authentication flow.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleNeedsAuth:(NSDictionary *)params;

/**
 Trigger iOS Facebook/Google native authentication if we are in full screen.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleLinkService:(NSDictionary *)params;

/**
 Closes this view.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleCloseWebView:(NSDictionary *)params;

/**
 Loads the requested url.
 @param params The query parameters
 @return YES if we handled the callback
 */
- (BOOL) handleMoveToNewUrl:(NSDictionary *)params;

/**
 returns the nextURL contained in the provided json data or nil
 @param jsonData A key-value coding compliant JSON object
 */
- (NSURL *) nextURLFromJSON:(id)jsonData;


/**
 Performs native authentication against the service specified in params
 and sets the web view to nextResource
 @param params
 @param nextResource
 @return YES if we handled the callback
 */
- (BOOL) nativeLogin:(NSDictionary *)params nextResource:(NSString *)nextResource;

@end

@implementation SXView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self prepare];
    }
    return self;
}

- (id) initWithViewController:(UIViewController *)viewController
{
    if (self = [super initWithFrame:viewController.view.bounds]) {
        self.viewController = viewController;
        [self prepare];
    }
    return self;
}

-(void) userLoggedIn:(NSNotification *) notification
{
    [self reload];
//    NSLog(@"received event");
//   [[NSNotificationCenter defaultCenter]
//    [self setURL:[[self.webView request] URL]];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self prepare];
}

- (void) prepare
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.bounds];
    webView.backgroundColor = [UIColor clearColor];
    [self addSubview:webView];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.webView = webView;
    self.webView.delegate = self;
    self.webView.hidden = YES;
    self.webView.scrollView.bounces = NO;
    // When not in full screen mode, start at alpha = 0
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:SX_NOTIFICATION_USER_LOGED_IN object:nil];
    if (!self.viewController)
        self.alpha = 0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Closing

- (void) close
{
    if (!self.viewController) {
        [self removeFromSuperview];
    } else {

        if (((SXViewController*)self.viewController).fromTop == YES) {
            CGRect destRect = CGRectMake(0, -self.viewController.view.frame.size.height, self.viewController.view.frame.size.width, self.viewController.view.frame.size.height);
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
            {
                destRect = CGRectMake(self.viewController.view.frame.size.height, 0, self.viewController.view.frame.size.width, self.viewController.view.frame.size.height);
            }
            [UIView animateWithDuration:0.5f
                             animations:^{
                                 self.viewController.view.frame = destRect;
                             }  completion:^(BOOL finished) {
                                [self.viewController dismissViewControllerAnimated:NO completion:nil];
                             }];

        } else {

            [self.viewController dismissViewControllerAnimated:YES completion:nil];
            self.viewController = nil;
        }
    }
}

-(void) loadUrlAfterLoggedIn:(NSString *) resource params:(NSDictionary*)params {

    SXRequest *request = [[SXRequest alloc] init];
    request.resource = resource;
    request.method = @"GET";
    request.params = params;

    if (self.viewController) {
        [((SXViewController*)self.viewController) setState:SXViewControllerStateInitial];
    }

    [[SXClient sharedClient]  fetchAnonymousAccessTokenAndCall:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (self.viewController) {
            ((SXViewController*)self.viewController) .request = request;
            [((SXViewController*)self.viewController) load];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (self.viewController) {
            ((SXViewController*)self.viewController).request = request;
            ((SXViewController*)self.viewController) .messageLabel.text = [error localizedDescription];
            [((SXViewController*)self.viewController)  setState:SXViewControllerStateError];
        }
    } nbRetry:0];
}

#pragma mark - Resource & URL

- (void) setResource:(NSString *)resource params:(NSDictionary *)params
{
    if (!resource) {
        SXLog(@"setResource: nil resource provided");
        return;
    }

    if (!params)
        params = @{};

    if ([SXConfiguration sharedConfiguration].sid != nil)
    {
        SXRequest *request = [[SXRequest alloc] init];
        request.resource = resource;
        request.method = @"GET";
        request.params = params;

        NSMutableURLRequest *urlRequest = [[SXClient sharedClient].httpClient requestWithMethod:request.method path:request.resource parameters:request.params];

    // Force http
        urlRequest.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@#start", [urlRequest.URL.  absoluteString stringByReplacingOccurrencesOfString:@"https:" withString:@"http:"]]];
        [self.webView loadRequest:urlRequest];
    } else  {
        [self loadUrlAfterLoggedIn:resource params:params];
    }


}

- (void) setURL:(NSURL *)url
{

    if (![SXUtil isScoreflexURL:url])
        [NSException raise:@"IllegalURL" format:@"Not a Scoreflex URL: %@", url.absoluteString];

    [self setResource:[SXUtil resourceForScoreflexURL:url] params:[SXUtil paramsForScoreflexURL:url]];
}

- (void) openNewView:(NSString*) resource params:(NSDictionary *) params
{
    SXViewController *viewController = [[SXViewController alloc] initWithNibName:@"SXViewController" bundle:[Scoreflex bundle]];
    self.viewController = viewController;
    if ([SXConfiguration sharedConfiguration].sid != nil)
    {
        SXRequest *request = [[SXRequest alloc] init];
        request.resource = resource;
        request.method = @"GET";
        request.params = params;

        // Create a view controller
        viewController.request = request;
    } else {
        [self loadUrlAfterLoggedIn:resource params:params];
    }
    // Present the controller modally
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *controller = [rootViewController modalViewController];
    if (controller != nil) {
        [controller dismissModalViewControllerAnimated:NO];
    }
    if (self.frame.size.height == [Scoreflex getPanelHeight] && self.frame.origin.y == 0) {
        CGRect sourceRect = CGRectMake(0, -[[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        CGRect destRect = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        {
            sourceRect = CGRectMake([[UIScreen mainScreen] bounds].size.height, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
            destRect = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        }
        viewController.view.frame = sourceRect;

        viewController.fromTop = YES;
        [UIView animateWithDuration:0.5f
                         animations:^{
                             viewController.view.frame = destRect;
                         } completion:^(BOOL finished) {

                         }];
        [rootViewController presentViewController:viewController animated:NO completion:nil];

    } else {
        viewController.fromTop = NO;
        [rootViewController presentViewController:viewController animated:YES completion:nil];
    }
}

- (void) openResource:(NSString *)resource
{
    [self openResource:resource params:nil];
}

- (void) openResource:(NSString *)resource params:(NSDictionary *)params
{
    [self openResource:resource params:params forceFullScreen:NO];
}

- (void) openResource:(NSString *)resource params:(NSDictionary *)params forceFullScreen:(BOOL)forceFullScreen
{
    if (!forceFullScreen || self.viewController) {
        if ([SXConfiguration sharedConfiguration].sid != nil) {
            [self setResource:resource params:params];
        } else {
            [self loadUrlAfterLoggedIn:resource params:params];
        }
        return;
    }

//    dispatch_async(dispatch_get_main_queue(), ^{
        // Create a request
        SXViewController *viewController = [[SXViewController alloc] initWithNibName:@"SXViewController" bundle:[Scoreflex bundle]];
        self.viewController = viewController;
        if ([SXConfiguration sharedConfiguration].sid != nil)
        {
            SXRequest *request = [[SXRequest alloc] init];
            request.resource = resource;
            request.method = @"GET";
            request.params = params;

        // Create a view controller
            viewController.request = request;
        } else {
            [self loadUrlAfterLoggedIn:resource params:params];
        }
}

- (void) openURL:(NSURL *)url forceFullScreen:(BOOL)forceFullScreen
{
    if (![SXUtil isScoreflexURL:url])
        [NSException raise:@"IllegalURL" format:@"Not a Scoreflex URL: %@", url.absoluteString];
    if (forceFullScreen && self.viewController == nil)
        [self openNewView:[SXUtil resourceForScoreflexURL:url] params:[SXUtil paramsForScoreflexURL:url]];
    else
        [self openResource:[SXUtil resourceForScoreflexURL:url] params:[SXUtil paramsForScoreflexURL:url] forceFullScreen:forceFullScreen];
}


#pragma mark - Navigating Scoreflex Content

- (void) cancelLoading {
    [self.webView stopLoading];
}

- (void) reload
{
    if (nil == self.webView.request  || nil == self.webView.request.URL ||  [[self.webView.request.URL absoluteString] length] == 0) {
        if (self.viewController) {
            [self openResource:((SXViewController*)self.viewController).request.resource params:((SXViewController*)self.viewController).request.params forceFullScreen:NO];
        }
    } else {
        SXLog(@"Calling reload of the webview %@ end of url", [self.webView.request.URL absoluteString]);
        [self openURL:self.webView.request.URL forceFullScreen:YES];
    }
}

- (BOOL) canGoBack
{
    return self.webView.canGoBack;
}

- (BOOL) canGoForward
{
    return self.webView.canGoForward;
}

- (void) goBack
{
    [self.webView goBack];
}

- (void) goForward
{
    [self.webView goForward];
}

#pragma mark - Web view delegate
- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL result = ![self handleWebCallback:request];

    if (result
        && [self.delegate respondsToSelector:@selector(scoreflexView:startedLoadingURL:)])
        [self.delegate scoreflexView:self startedLoadingURL:request.URL];

    return result;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{

    // Ignore WebKitErrorFrameLoadInterruptedByPolicyChange as we generate a lot of these
    // when the web callback handles things.
    if ([@"WebKitErrorDomain" isEqualToString:error.domain] && 102 == error.code)
        return;

    if ([self.delegate respondsToSelector:@selector(scoreflexView:receivedError:forURL:)])
        [self.delegate scoreflexView:self receivedError:error forURL:webView.request.URL];
}


- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    self.webView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        self.alpha = 1;
    }];
    if ([self.delegate respondsToSelector:@selector(scoreflexView:finishedLoadingURL:)])
        [self.delegate scoreflexView:self finishedLoadingURL:webView.request.URL];
}
#pragma mark - Handling web callbacks

- (BOOL) handleWebCallback:(NSURLRequest *)request
{
    NSURL *URL = request.URL;
    if (![WEB_CALLBACK_RESOURCE isEqualToString:[SXUtil resourceForScoreflexURL:URL]])
        return NO;

    NSDictionary *queryParameters = [SXUtil dictionaryWithFormEncodedString:URL.query];
    NSInteger status = [[queryParameters valueForKey:@"status"] integerValue];
    NSInteger code = [[queryParameters valueForKey:@"code"] integerValue];

    if (!status || !code)
        return NO;

    // Successes
    if (300 > status) {

        if (code == SXCodeMoveToNewURL)
            return [self handleMoveToNewUrl:queryParameters];

        else if (code == SXCodeCloseWebView)
            return [self handleCloseWebView:queryParameters];

        else if (code == SXCodeNeedsAuth)
            return [self handleNeedsAuth:queryParameters];

        else if (code == SXCodeAuthGranted)
            return [self handleAuthGranted:queryParameters];

        else if (code == SXCodeLogout)
            return [self handleLogout:queryParameters];

        else if (code == SXCodeNeedsClientAuth)
            return [self handleNeedsClientAuth:queryParameters];

        else if (code == SXCodeStartChallenge)
            return [self handleStartChallenge:queryParameters];

        else if (code == SXCodePlayLevel)
            return [self handlePlayLevel:queryParameters];

        else if (code == SXCodeLinkService)
            return [self handleLinkService:queryParameters];
        
        else if (code == SXCodeSendInvitation)
            return [self handleInvitation:queryParameters];
        
        else if (code == SXCodeShare)
            return [self handleShare:queryParameters];

    } else {
        if (404 == status)
            return false;

        if (code == SXErrorInvalidSid)
            return [self handleInvalidSIDError:queryParameters];

        else if (code == SXErrorSecureConnectionRequired)
            return [self handleSecureConnectionRequiredError:queryParameters];

        else if (code == SXErrorInactigveGame)
            return [self handleInactiveGameError:queryParameters];
    }

    return NO;
}

- (BOOL) handleInactiveGameError:(NSDictionary *)params
{
    [self close];
    return YES;
}

- (BOOL) handleSecureConnectionRequiredError:(NSDictionary *)params
{
    NSURL *URL = self.webView.request.URL;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[URL.absoluteString stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"]]]];
    return YES;
}

- (BOOL) handlePlayLevel:(NSDictionary *) params
{
    NSString *dataParam = [params valueForKey:@"data"];
    NSData *paramData = [dataParam dataUsingEncoding:NSUTF8StringEncoding];
    id dataJson = [NSJSONSerialization JSONObjectWithData:paramData options:0 error:nil];

    if (dataJson == nil) {
        // let the developer see the error
        return NO;
    }
    NSDictionary *userInfo = @{@"leaderboardId":[dataJson valueForKey:@"leaderboardId"]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_PLAY_LEVEL
                                                        object:self
                                                      userInfo:userInfo];
    return YES;
}

- (BOOL) handleStartChallenge:(NSDictionary *) params
{
    NSString *dataParam = [params valueForKey:@"data"];
    NSData *paramData = [dataParam dataUsingEncoding:NSUTF8StringEncoding];
    id dataJson = [NSJSONSerialization JSONObjectWithData:paramData options:0 error:nil];

    if (dataJson == nil) {
        // let the developer see the error
        return NO;
    }
    NSDictionary *instanceGetParams = @{@"fields": @"core,turn,outcome,config"};

    [Scoreflex get:[NSString stringWithFormat:@"challenges/instances/%@", [dataJson valueForKey:@"challengeInstanceId"]] params:instanceGetParams
           handler:^(SXResponse *response, NSError *error) {
               NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[response object], SX_NOTIFICATION_START_CHALLENGE_CONFIG_KEY, nil];

//               [NSDictionary dictionaryWithObjects:[response object], [dataJson valueForKey:@"challengeConfigId"] forKey:SX_NOTIFICATION_START_CHALLENGE_CONFIG_KEY, SX_NOTIFICATION_START_CHALLENGE_CONFIG_ID_KEY];
               [Scoreflex startPlayingSession];
               [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_START_CHALLENGE
                                                                  object:self
                                                                 userInfo:userInfo];
           }];
    return YES;
}

- (BOOL) handleInvalidSIDError:(NSDictionary *)params
{
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
    [configuration setAccessToken:nil anonymous:YES];
    configuration.sid = nil;
    configuration.playerId = nil;
    [[SXClient sharedClient] fetchAnonymousAccessTokenIfNeeded];
    return YES;
}

- (BOOL) handleGenericError:(NSInteger)code
{
    NSString *message = [SXUtil messageForScoreflexErrorCode:code];

    if (message)
        SXLog(@"%@", message);
    else
        SXLog(@"%@", [NSString stringWithFormat:NSLocalizedString(@"An error occurred (code=%i)", nil), code]);

    // In sandbox mode, we let the developer see the error page.
    if ([SXConfiguration sharedConfiguration].usesSandbox)
        return NO;

    // In production, the error is handled by doing nothing
    return YES;
}

- (BOOL) handleLogout:(NSDictionary *)params
{
    // Clear Access token, SID
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
    [configuration setAccessToken:nil anonymous:YES];
    configuration.sid = nil;
    configuration.playerId = nil;

    // Clear cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = storage.cookies;
    for (NSHTTPCookie *cookie in cookies)
        [storage deleteCookie:cookie];

    [SXFacebookUtil logout];

    [SXGooglePlusUtil logout];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Fetch anonymous access token
    [[SXClient sharedClient] fetchAnonymousAccessTokenIfNeeded];

    [self close];
    return YES;
}

- (BOOL) handleAuthGranted:(NSDictionary *)params
{

    NSString *dataString = [params valueForKey:@"data"];
    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[dataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    if (error) {
        SXLog(@"Invalid json received in the data parameter: %@", dataString);

        // Handle by doing nothing
        return YES;
    }

    if (!self.authState) {
        SXLog(@"Error authenticating as we have no recorded state to check against");

        // Handle by doing nothing
        return YES;
    }

    NSString *state = [dataJson valueForKey:@"state"];
    if (![self.authState isEqualToString:state]) {
        SXLog(@"Error authenticating as the returned state doesn't match the one we recorded: %@ != %@", state, self.authState);

        // Handle by doing nothing
        return YES;
    }

    // Get the oauth code
    NSString *codeString = [dataJson valueForKey:@"code"];

    if (!codeString) {
        SXLog(@"Error authenticating, no oauth code returned");

        // Handle by doing nothing
        return YES;
    }

    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];

    // Transform that code into a token
    NSMutableDictionary *oauthParams = [NSMutableDictionary dictionaryWithDictionary:@{
                                        @"code" : codeString,
                                        @"clientId" : configuration.clientId,
                                        @"devicePlatform" : @"iOS",
                                        @"deviceModel" : [SXUtil deviceModel],
                                        }];
    NSString *udid = [SXUtil deviceIdentifier];
    if (udid)
        [oauthParams setValue:udid forKey:@"deviceId"];

    SXRequest *request = [[SXRequest alloc] init];
    request.method = @"POST";
    request.resource = @"/oauth/accessToken";
    request.params = [NSDictionary dictionaryWithDictionary:oauthParams];
    request.handler = ^(SXResponse *response, NSError *error) {

        if (error) {
            SXLog(@"Error: %@", error.localizedDescription);
            return;
        }

        NSString *accessToken = [response.object valueForKeyPath:@"accessToken.token"];
        if (!accessToken) {
            SXLog(@"Error authenticating, server didn't return an access token");
            return;
        }

        NSString *sid = [response.object valueForKeyPath:@"sid"];
        if (!sid) {
            SXLog(@"Error authenticating, server didn't return an sid");
            return;
        }



        [configuration setAccessToken:accessToken anonymous:NO];
        configuration.sid = sid;
        NSString *playerId = [response.object valueForKeyPath:@"me.id"];
        configuration.playerId = playerId;

        NSDictionary *userInfo = @{SX_NOTIFICATION_USER_LOGED_IN_SID_KEY: sid,
                                   SX_NOTIFICATION_USER_LOGED_IN_ACCESS_TOKEN_KEY:accessToken};
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_USER_LOGED_IN
                                                            object:self
                                                          userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:SX_NOTIFICATION_USER_LOGED_IN object:nil];
        if (self.authNextURL)
            [self openURL:self.authNextURL forceFullScreen:NO];
    };

    // Send the request.
    SXClient *client = [SXClient sharedClient];
    [client requestAuthenticated:request];

    return YES;
}

- (BOOL) handleLinkService:(NSDictionary *)params
{
    NSString *data = [params valueForKeyPath:@"data"];
    if (!data)
        return NO;

    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"Could not parse json data:%@", error);
        return NO;
    }

    NSString *service = [dataJson valueForKey:@"service"];
    return [self nativeLogin:params nextResource:[NSString stringWithFormat:@"/web/linkExternallyAuthenticated/%@", service]];
}

- (BOOL) handleNeedsClientAuth:(NSDictionary *)params
{
    return [self nativeLogin:params nextResource:@"/oauth/web/authorizeExternallyAuthenticated"];
}

- (BOOL) nativeLogin:(NSDictionary *)params nextResource:(NSString *)nextResource
{
    NSString *data = [params valueForKeyPath:@"data"];
    if (!data)
        return NO;

    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"Could not parse json data:%@", error);
        return NO;
    }

    NSURL *nextURL = [self nextURLFromJSON:dataJson];
    if (nextURL) {
        self.authNextURL = nextURL;
    }

    NSString *service = [dataJson valueForKeyPath:@"service"];
    if ([@"Facebook" isEqualToString:service] && ![SXFacebookUtil isFacebookAvailable])
        return NO;

    if ([@"Google" isEqualToString:service] && ![SXGooglePlusUtil isGooglePlusAvailable])
        return NO;

    // Full screen mode only
    if (!self.viewController)
        return NO;

    if (![@[@"Google", @"Facebook"] containsObject:service]) {
        SXLog(@"Unknown service: %@", service);
        return NO;
    } else {
        void(^callback)(NSString *accessToken, NSError *error) = ^(NSString *accessToken, NSError *error) {

            // TODO: error management here
            if (error) {
                SXLog(@"Native login error: %@", error);
                return;
            }

            // A random state
            self.authState = [SXUtil UUIDString];

            if (accessToken) {
                SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"clientId" :          configuration.clientId,
                                         @"service" :           service,
                                         @"serviceAccessToken" :accessToken,
                                         @"state" :             self.authState ? self.authState : [NSNull null],
                                         @"devicePlatform" :    @"iOS",
                                         @"deviceModel" :       [SXUtil deviceModel],
                                         @"deviceId" : [SXUtil deviceIdentifier],
                                         }];
                // Is the access token anonymous ? If so communicate it.
                if (configuration.accessToken && configuration.accessTokenIsAnonymous)
                    [params setValue:configuration.accessToken forKey:@"anonymousAccessToken"];
                if (self.authNextURL) {
                    [params setValue:self.authNextURL forKey:@"next"];
                }
                [self openResource:nextResource params:params];
            }
        };
        if ([@"Facebook" isEqualToString:service]) {
            [SXFacebookUtil login:callback];
        }

        if ([@"Google" isEqualToString:service]) {
            [SXGooglePlusUtil login:callback];

        }
    }


    return YES;
}

-(BOOL) handleShare:(NSDictionary *) params
{
    NSString *data = [params valueForKeyPath:@"data"];
    if (!data)
        return NO;
    
    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"Could not parse json data:%@", error);
        return NO;
    }
    NSString *service = [dataJson valueForKeyPath:@"service"];
    
    if ([@"Facebook" isEqualToString:service] && ![SXFacebookUtil isFacebookAvailable])
        return NO;
    
    if ([@"Google" isEqualToString:service] && ![SXGooglePlusUtil isGooglePlusAvailable])
        return NO;
    
    NSString *text = [dataJson valueForKey:@"text"];
    NSString *url = [dataJson valueForKey:@"url"];
    
    if ([@"Facebook" isEqualToString:service])
    {
        NSString *title = [dataJson valueForKey:@"title"];
        [Scoreflex shareOnFacebook:title text:text url:url];
    }
    if ([@"Google" isEqualToString:service])
    {
        [Scoreflex shareOnGoogle:text url:url];
    }
    return YES;
}

-(BOOL) handleInvitation:(NSDictionary *)params
{
    NSString *data = [params valueForKeyPath:@"data"];
    if (!data)
        return NO;

    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"Could not parse json data:%@", error);
        return NO;
    }
    NSString *service = [dataJson valueForKeyPath:@"service"];
    
    if ([@"Facebook" isEqualToString:service] && ![SXFacebookUtil isFacebookAvailable])
        return NO;
    
    if ([@"Google" isEqualToString:service] && ![SXGooglePlusUtil isGooglePlusAvailable])
        return NO;
    
    NSString *text = [dataJson valueForKey:@"text"];
    NSArray *friends = [dataJson valueForKey:@"targetIds"];
    
    if ([@"Facebook" isEqualToString:service])
    {
        return [Scoreflex sendFacebookInvitation:text friends:friends deepLinkPath:@"invited"];
    }
    
    if ([@"Google" isEqualToString:service])
    {
        NSString *url = [dataJson valueForKey:@"url"];
        return [Scoreflex sendGoogleInvitation:text friends:friends url:url deepLinkPath:@"invited"];
    }
    return NO;
}

- (BOOL) handleNeedsAuth:(NSDictionary *)params
{
    NSString *dataString = [params valueForKey:@"data"];

    NSError *error = nil;

    id dataJson = [NSJSONSerialization JSONObjectWithData:[dataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        SXLog(@"Invalid json received in the data parameter: %@", error);
        return YES;
    }

    // Remember where we ought to go once auth is successful
    // Note that we can't use the "redirectUri" parameter of the
    // authorize call
    // as it is intended to be registered on the server side (see oauth
    // spec).

    self.authNextURL = [self nextURLFromJSON:dataJson];

    // Full mode ?
    NSString *modeString = [dataJson valueForKey:@"mode"];

    NSString *service = [dataJson valueForKey:@"service"];
    [self authenticateUserFullScreen:[@"full" isEqualToString:modeString] disableNativeLogin:NO service:service];

    return YES;
}

- (BOOL) handleCloseWebView:(NSDictionary *)params
{
    [self close];
    return YES;
}

- (BOOL) handleMoveToNewUrl:(NSDictionary *)params
{
    NSString *dataString = [params valueForKey:@"data"];
    NSError *error = nil;
    id dataJson = [NSJSONSerialization JSONObjectWithData:[dataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        SXLog(@"Invalid json received in the data parameter");
        return YES;
    }

    NSString *urlString = [dataJson valueForKeyPath:@"url"];

    if (!urlString) {
        SXLog (@"Move to new URL requested but no url provided");
        return YES;
    }

    NSURL *URL = [NSURL URLWithString:urlString];
    if (!URL) {
        SXLog (@"Invalid URL provided: %@", urlString);
        return YES;
    }

    NSString *modeString = [dataJson valueForKeyPath:@"mode"];

    [self openURL:URL forceFullScreen:[@"full" isEqualToString:modeString]];

    return YES;
}

#pragma mark - Authentication

- (void) authenticateUserFullScreen:(BOOL)fullScreen disableNativeLogin:(BOOL)disableNativeLogin service:(NSString *)service
{
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                   @"clientId" : configuration.clientId,
                                   @"devicePlatform" : @"iOS",
                                   @"deviceModel" : [SXUtil deviceModel],
                                   }];


    // Is the access token anonymous ? If so communicate it.
    if (configuration.accessToken && configuration.accessTokenIsAnonymous)
        [params setValue:configuration.accessToken forKey:@"anonymousAccessToken"];

    if (service)
        [params setValue:service forKey:@"service"];

    // A random state
    self.authState = [SXUtil UUIDString];
    [params setValue:self.authState forKey:@"state"];

    // Open authorize resource in the web view
    [self openResource:@"/oauth/web/authorize" params:params forceFullScreen:fullScreen];
}

- (NSURL *)nextURLFromJSON:(id)dataJson
{
    NSString *nextURLString = [dataJson valueForKey:@"nextUrl"];
    if (nextURLString) {
        NSURL *nextURL = [NSURL URLWithString:nextURLString];
        if (!nextURL) {
            SXLog(@"Invalid next URL: %@", nextURLString);
        }

        NSString *resource = [SXUtil resourceForScoreflexURL:nextURL];
        if (!resource) {
            SXLog(@"Not a scoreflex URL: %@", nextURLString);
        } else {
            SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
            return [NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?%@", configuration.baseURL.absoluteString, resource, nextURL.query]  stringByReplacingOccurrencesOfString:@"https:" withString:@"http:"]];
        }
    }
    return nil;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
