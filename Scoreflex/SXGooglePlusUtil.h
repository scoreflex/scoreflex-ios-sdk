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

#define GOOGLE_SCOPE_EMAIL @"https://www.googleapis.com/auth/userinfo.email"
#define GOOGLE_SCOPE_LOGIN @"https://www.googleapis.com/auth/plus.login"

@interface SXGooglePlusUtil : NSObject
+ (BOOL) isGooglePlusAvailable;
+ (void) login:(void(^)(NSString *accessToken, NSError *error))callback;
+ (void) logout;
+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
@end
