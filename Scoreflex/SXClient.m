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

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
#import "AFJSONRequestOperation.h"
#import "SXUtil.h"
#import "SXClient.h"
#import "SXConfiguration.h"
#import "SXRequestVault.h"
#import "Scoreflex.h"
#import "Scoreflex_private.h"

#pragma mark - SXJSONRequestOperation

static NSMutableArray *tokenFetchedHandlers;

///** privatise */
//



@interface SXJSONRequestOperation : AFJSONRequestOperation
+ (NSString *) scoreflexAuthorizationHeaderValueForRequest:(NSURLRequest *)request;
@end

@implementation SXJSONRequestOperation

+ (NSString *) scoreflexAuthorizationHeaderValueForRequest:(NSURLRequest *)request
{
    NSString *method = request.HTTPMethod.uppercaseString;

    // GET requests do not need signing
    if ([@"GET" isEqualToString:method])
        return nil;

    // Step 1: add HTTP method uppercase
    NSMutableString *buffer = [[NSMutableString alloc] initWithString:method];
    [buffer appendString:@"&"];

    // Step 2: add scheme://host/path
    [buffer appendString:[SXUtil percentEncodedString:[NSString stringWithFormat:@"%@://%@%@", request.URL.scheme, request.URL.host, request.URL.path]]];

    // Gather GET params
    NSDictionary *getParams = [SXUtil dictionaryWithFormEncodedString:request.URL.query];

    // Gather POST params
    NSDictionary *postParams = [SXUtil dictionaryWithFormEncodedString:[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]];

    // Step 3: add params
    [buffer appendString:@"&"];
    NSArray *paramNames = [[[NSSet setWithArray:getParams.allKeys] setByAddingObjectsFromArray:postParams.allKeys].allObjects sortedArrayUsingSelector:@selector(compare:)];

    if (paramNames.count) {
        NSString *last = paramNames.lastObject;
        for (NSString *paramName in paramNames) {
            NSString *val = [postParams valueForKey:paramName];
            if (!val)
                val = [getParams valueForKey:paramName];

            [buffer appendString:[SXUtil percentEncodedString:[NSString stringWithFormat:@"%@=%@", [SXUtil percentEncodedString:paramName], [SXUtil percentEncodedString:val]]]];

            if (![last isEqualToString:paramName]) {
                [buffer appendString:@"%26"];
            }
        }
    }

    // TODO: add the body here when we support other content types
    // than application/x-www-form-urlencoded
    [buffer appendString:@"&"];

    // Sign the buffer with the client secret using HMacSha1
    const char *cKey  = [[SXConfiguration sharedConfiguration].clientSecret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [buffer cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *hash = [SXUtil base64forData:HMAC];

    return [NSString stringWithFormat:@"Scoreflex sig=\"%@\", meth=\"0\"", [SXUtil percentEncodedString:hash]];
}


- (id) initWithRequest:(NSURLRequest *)urlRequest
{
    // Make sure the request is mutable
    if (![urlRequest isKindOfClass:[NSMutableURLRequest class]])
        [NSException raise:@"Immutable NSURLRequest." format:NSLocalizedString(@"Url requests from AFNetworking should be mutable, please check that the AFNetworking version you are using is compatible with Scoreflex.", nil)];
    NSMutableURLRequest *mutableRequest = (NSMutableURLRequest *)urlRequest;

    // Add the authorization header
    NSString *authorizationHeader = [[self class] scoreflexAuthorizationHeaderValueForRequest:mutableRequest];
    if (authorizationHeader)
        [mutableRequest addValue:authorizationHeader forHTTPHeaderField:@"X-Scoreflex-Authorization"];

    return [super initWithRequest:mutableRequest];

}

@end


#pragma mark - HandlerPair

@interface HandlerPair : NSObject

@property (copy) void (^success)(AFHTTPRequestOperation *, id);
@property (copy) void (^error)(AFHTTPRequestOperation *, NSError *);

@end

@implementation HandlerPair

@end

#pragma mark - SXHttpClient

@interface SXHTTPClient : AFHTTPClient

@end

@implementation SXHTTPClient

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    [self registerHTTPOperationClass:[SXJSONRequestOperation class]];

    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];

    return self;
}
@end

#pragma mark - SXClient

@interface SXClient ()

/**
 The designated initializer
 @param url The base URL for this client
 */
- (id) initWithBaseURL:(NSURL *)url;

/// The AFHTTPClient
@property (strong, nonatomic) SXHTTPClient *jsonHttpClient;

/// The request vault
@property (strong, nonatomic) SXRequestVault *requestVault;

- (void) checkMethod:(SXRequest *)request;

@end

@implementation SXClient

+ (SXClient *)sharedClient
{
    static SXClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [SXConfiguration sharedConfiguration].baseURL;
        SXLog(@"Scoreflex base URL: %@", baseURL);
        sharedClient = [[SXClient alloc] initWithBaseURL:baseURL];
        sharedClient.requestVault = [[SXRequestVault alloc] initWithClient:sharedClient];
    });
    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    if (self = [super init]) {
        self.jsonHttpClient = [[SXHTTPClient alloc] initWithBaseURL:url];
        [self.jsonHttpClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (status == AFNetworkReachabilityStatusNotReachable) {
                [Scoreflex setIsReachable:YES];
            } else {
                [Scoreflex setIsReachable:NO];
            }

        }];
        self.isFetchingAccessToken = false;
        tokenFetchedHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark HTTP Access
- (AFHTTPClient *)httpClient
{
    return self.jsonHttpClient;
}

#pragma mark - Access Token
- (BOOL)fetchAnonymousAccessTokenIfNeeded {
    [self fetchAnonymousAccessTokenAndCall:nil failure:nil nbRetry:0];
    return YES;
}

- (BOOL)fetchAnonymousAccessTokenIfNeededAndCall:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    if (![SXConfiguration sharedConfiguration].accessToken) {
        [self fetchAnonymousAccessTokenAndCall:success failure:failure nbRetry:0];
        return YES;
    }
    return NO;
}

- (void) fetchAnonymousAccessTokenAndCall:(void (^)(AFHTTPRequestOperation *operation, id responseObject))handler failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure nbRetry:(NSInteger) nbRetry {
    if (YES == self.isFetchingAccessToken) {
        HandlerPair *pair = [[HandlerPair alloc] init];
        pair.success = handler;
        pair.error = failure;
        @synchronized(tokenFetchedHandlers) {
            [tokenFetchedHandlers addObject:pair];
        }
        return;
    }
    self.isFetchingAccessToken = YES;
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];

    NSDictionary *params = @{@"clientId" :          configuration.clientId,
                             @"devicePlatform" :    @"iOS",
                             @"deviceModel" :       [SXUtil deviceModel],
                             @"deviceId" :          [SXUtil deviceIdentifier]};

    NSString *resource = @"oauth/anonymousAccessToken";

    SXLog(@"Fetching anonymous access token");

    [self.jsonHttpClient postPath:resource parameters:params success:^(AFHTTPRequestOperation *operation, id response) {
        // Success

        SXJSONRequestOperation *jsonOperation = (SXJSONRequestOperation *)operation;
        id responseJson = jsonOperation.responseJSON;
        NSString *sid = [responseJson valueForKeyPath:@"sid"];
        //        SXLog(@"received SID: %@", sid);
        NSString *accessToken = [responseJson valueForKeyPath:@"accessToken.token"];

        // Do we have an accessToken and an SID ?
        if (sid && accessToken && sid.length && accessToken.length) {
            SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
            [configuration setAccessToken:accessToken anonymous:YES];
            configuration.sid = sid;
            NSString *playerId =  [responseJson valueForKeyPath:@"me.id"];
            configuration.playerId = playerId;

            self.isFetchingAccessToken = NO;
            NSDictionary *userInfo = @{SX_NOTIFICATION_USER_LOGED_IN_SID_KEY: sid,
                                       SX_NOTIFICATION_USER_LOGED_IN_ACCESS_TOKEN_KEY:accessToken};

            [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_USER_LOGED_IN
                                                                object:self
                                                             userInfo:userInfo];
            if (nil != handler) {
                handler(operation,response);
            }
            @synchronized(tokenFetchedHandlers) {
                for (HandlerPair *pair in tokenFetchedHandlers) {
                    if (nil != pair.success)
                        pair.success(operation, response);
                }
                [tokenFetchedHandlers removeAllObjects];
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Error
        SXLog(@"Could not fetch anonymous access token: %@", error);
        if (nbRetry <= 0) {
            self.isFetchingAccessToken = NO;
            if (nil != failure) {
                failure(operation, error);
            }
            @synchronized(tokenFetchedHandlers) {
                for (HandlerPair *pair in tokenFetchedHandlers) {
                    if (nil != pair.error)
                        pair.error(operation, error);
                }
                [tokenFetchedHandlers removeAllObjects];
            }
            return ;
        }
        // Retry in 60 seconds
        double delayInSeconds = RETRY_INTERVAL;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.isFetchingAccessToken = NO;
            if (nbRetry > 0) {
                [self fetchAnonymousAccessTokenAndCall:handler failure:failure nbRetry:nbRetry - 1];
            }
        });
    }];

}

- (void) fetchAnonymousAccessTokenAndRunRequest:(SXRequest *)request
{

    [self fetchAnonymousAccessTokenAndCall:^(AFHTTPRequestOperation *operation, id response) {
         [self requestAuthenticated:request];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (request.handler) {
             request.handler(nil, error);
        }
    } nbRetry:0];
}

#pragma mark - REST API Access

- (void)requestAuthenticated:(SXRequest *)request
{
    // Do not fetch nil requests
    if (!request)
        return;

    // Fetch access token if needed then run request
    if (![SXConfiguration sharedConfiguration].accessToken) {
        [self fetchAnonymousAccessTokenAndRunRequest:request];
        return;
    }
    else {
        SXLog(@"accessToken: %@", [SXConfiguration sharedConfiguration].accessToken);
    }

    // We have an access token

    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:request.params];
    [params setObject:[SXConfiguration sharedConfiguration].accessToken forKey:@"accessToken"];

    // The success handler

    void(^success)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id response) {
        if ([operation isKindOfClass:[SXJSONRequestOperation class]]) {
            SXJSONRequestOperation *jsonOperation = (SXJSONRequestOperation *)operation;

            NSError *jsonError = [SXUtil errorFromJSON:jsonOperation.responseJSON];
            if (jsonError) {
                if (request.handler)
                    request.handler(nil, jsonError);

            } else {
                SXResponse *response = [[SXResponse alloc] init];
                response.object = jsonOperation.responseJSON;

                if (request.handler)
                    request.handler(response, nil);
            }
        }
    };

    // The failure handler

    void(^failure)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        id json = ((SXJSONRequestOperation *) operation).responseJSON;
        NSError *jsonError = [SXUtil errorFromJSON:json];
        if (jsonError) {

            // Handle invalid access token by requesting a new one.
            if (jsonError.code == SXErrorInvalidAccessToken) {

                SXLog(@"Invalid access token: %@", jsonError);

                // null out the access token

                SXConfiguration *configuration = [SXConfiguration sharedConfiguration];
                configuration.sid = nil;
                [configuration setAccessToken:nil anonymous:YES];
                configuration.playerId = nil;
                // Retry in 60 secs

                double delayInSeconds = RETRY_INTERVAL;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self requestAuthenticated:request];
                });

            } else if (request.handler)
                request.handler(nil, jsonError);

        } else if (request.handler) {
            request.handler(nil, error);
        }
    };

    // Run the request

    NSString *method = request.method.uppercaseString;


    [self checkMethod:request];

    SXLog(@"Performing request: %@", request);

    if ([@"POST" isEqualToString:method]) {
        [self.jsonHttpClient postPath:request.resource parameters:params success:success failure:failure];
    } else if ([@"GET" isEqualToString:method]) {
        [self.jsonHttpClient getPath:request.resource parameters:params success:success failure:failure];
    } else if ([@"DELETE" isEqualToString:method]) {
        [self.jsonHttpClient deletePath:request.resource parameters:params success:success failure:failure];
    } else if ([@"PUT" isEqualToString:method]) {
        [self.jsonHttpClient putPath:request.resource parameters:params success:success failure:failure];
    }
}

- (void) checkMethod:(SXRequest *)request
{
    static NSArray *allowedMethods = nil;
    if (!allowedMethods)
        allowedMethods = @[@"GET", @"POST", @"DELETE"];

    NSString *method = request.method.uppercaseString;
    if (!method || ![allowedMethods containsObject:method])
        [NSException raise:@"InvalidHTTPVerb" format:@"Supported verbs are GET, POST, DELETE."];

    return;
}

- (void) requestEventually:(SXRequest *)request
{
    [self checkMethod:request];

    [self.requestVault add:request];
}
@end