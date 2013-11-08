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

#import "SXRequestVault.h"

#pragma mark - RequestVaultOperation
@interface SXRequestVaultOperation : NSOperation

- (id) initWithRequest:(SXRequest *)request vault:(SXRequestVault *)vault;

@property (nonatomic, strong) SXRequest *request;
@property (weak, nonatomic) SXRequestVault *vault;

@end

#pragma mark - Request vault

@interface SXRequestVault ()

- (void) save:(SXRequest *)request;

- (void) forget:(SXRequest *)request;

- (void) reachabilityNotification:(NSNotification *)notification;

- (void) reachabilityChanged:(AFNetworkReachabilityStatus)status;

- (void) addToQueue:(SXRequest *)request;

@property (readonly) NSArray *savedRequests;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation SXRequestVault

- (id) initWithClient:(SXClient *)client
{
    if (self = [super init]) {
        self.client = client;
        self.operationQueue = [[NSOperationQueue alloc] init];

        // Register for reachability notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityNotification:) name:AFNetworkingReachabilityDidChangeNotification object:nil];

        // Set initial reachability
        [self reachabilityChanged:self.client.httpClient.networkReachabilityStatus];

        // Add saved operations to queue
        for (SXRequest *request in self.savedRequests)
            [self addToQueue:request];
    }
    return self;
}

#pragma mark - Persistence
- (void) save:(SXRequest *)request
{
    @synchronized(self) {
        // Save in NSUserDefaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSArray *requestQueue = [userDefaults objectForKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];

        // Create queue if doesn't exist
        if (!requestQueue)
            requestQueue = @[];

        // Build a new queue by appending the given requested, archived
        requestQueue = [requestQueue arrayByAddingObject:[NSKeyedArchiver archivedDataWithRootObject:request]];

        // Save
        [userDefaults setObject:requestQueue forKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];
        [userDefaults synchronize];
    }
}

- (void) forget:(SXRequest *)request
{
    @synchronized(self) {

        // Save in NSUserDefaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSArray *requestQueue = [userDefaults objectForKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];
        if (!requestQueue)
            return;

        NSArray *newRequestQueue = @[];
        for (NSData *archivedRequestData in requestQueue) {
            SXRequest *archivedRequest = [NSKeyedUnarchiver unarchiveObjectWithData:archivedRequestData];

            // Skip the request to forget
            if ([request.requestId isEqual:archivedRequest.requestId])
                continue;

            // Add the archivedRequestData to the new queue
            newRequestQueue = [newRequestQueue arrayByAddingObject:archivedRequestData];
        }

        // Save
        [userDefaults setObject:newRequestQueue forKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];
        [userDefaults synchronize];
    }
}

- (NSArray *) savedRequests
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSArray *requestQueue = [userDefaults objectForKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];
    NSArray *result = @[];

    if (!requestQueue)
        return result;

    for (NSData *archivedRequestData in requestQueue) {
        result = [result arrayByAddingObject:[NSKeyedUnarchiver unarchiveObjectWithData:archivedRequestData]];
    }
    return result;
}

- (void) reset
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:USER_DEFAULTS_REQUEST_VAULT_QUEUE];
    [userDefaults synchronize];
}


#pragma mark - Operation management

- (void) add:(SXRequest *)request
{
    [self save:request];
    [self addToQueue:request];

}

- (void) addToQueue:(SXRequest *)request
{
    SXLog(@"Adding request to queue: %@", request);

    SXRequestVaultOperation *operation = [[SXRequestVaultOperation alloc] initWithRequest:request vault:self];

    [self.operationQueue addOperation:operation];
}

#pragma mark - Reachability

- (void) reachabilityNotification:(NSNotification *)notification
{
    NSNumber *status = [notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem];
    [self reachabilityChanged:status.intValue];
}

- (void) reachabilityChanged:(AFNetworkReachabilityStatus)status
{
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable:
        case AFNetworkReachabilityStatusUnknown:
            SXLog(@"Reachability changed to %i, stopping queue.", status);
            [self.operationQueue setSuspended:YES];
            break;

        default:
            SXLog(@"Reachability changed to %i, starting queue.", status);
            [self.operationQueue setSuspended:NO];
            break;
    }

}

@end

#pragma mark - Request vault operation


@implementation SXRequestVaultOperation

- (id) initWithRequest:(SXRequest *)request vault:(SXRequestVault *)vault
{
    if (self = [super init]) {
        self.request = request;
        self.vault = vault;
    }
    return self;
}

- (void) main
{
    SXRequest *requestCopy = [self.request copy];

    requestCopy.handler = ^(SXResponse *response, NSError *error) {

        SXLog(@"SXRequestVaultOperation complete with response:%@ error:%@", response, error);

        // Handle network errors
        if (error && [NSURLErrorDomain isEqualToString:error.domain] && error.code <= NSURLErrorBadURL) {

            [self.vault addToQueue:self.request];

            return;
        }

        [self.vault forget:self.request];

        if (self.request.handler)
            self.request.handler(response, error);
    };

    [self.vault.client requestAuthenticated:requestCopy];

}

@end
