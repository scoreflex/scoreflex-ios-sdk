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

/**
 SXConfiguration is a singleton that holds configuration values for this Scoreflex installation
 */

@interface SXConfiguration : NSObject
+ (SXConfiguration *)sharedConfiguration;
@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSURL *baseURL;
@property (readonly) BOOL usesSandbox;

/// The access token used to hit the Scoreflex API
@property (readonly) NSString *accessToken;

// Thedevice token used for APNS
@property (readonly) NSString *deviceToken;

/// If the access token is anonymous
@property (readonly) BOOL accessTokenIsAnonymous;

/// The sid used to hit the Scoreflex API
@property (nonatomic, strong) NSString *sid;

@property (nonatomic, strong) NSString *playerId;

- (void) setAccessToken:(NSString *)accessToken anonymous:(BOOL)anonymous;

- (void) setDeviceToken:(NSString *)deviceToken;

@end
