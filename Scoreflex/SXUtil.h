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
 This class contains static utilities that would be better implemented as categories if it wasn't for this bug:
 https://developer.apple.com/library/mac/#qa/qa2006/qa1490.html
 */

@interface SXUtil : NSObject

///-----------------------
/// @name Percent encoding
///-----------------------

+ (NSString *) percentEncodedString:(NSString *)s;

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString;

///--------------
/// @name base 64
///--------------

+ (NSString*)base64forData:(NSData*)theData;

///--------------
/// @name Device
///--------------

+ (NSString *)deviceIdentifier;

+ (NSString *)deviceModel;

///--------------
/// @name Errors
///--------------

/**
 Build an NSError from a json object.
 @param json A json object returned by the REST API.
 @return An NSError with the corresponding code, message, or nil if no error was found in json.
 */

+ (NSError *)errorFromJSON:(id)json;

/**
 Returns a generic, developer oriented, description of the given code.
 @param errorCode The scoreflex error code.
 */
+ (NSString *)messageForScoreflexErrorCode:(NSInteger)errorCode;

///--------------
/// @name URL checking
///--------------

/**
 Returns YES if the given URL is a Scoreflex URL
 @param URL the given URL
 */
+ (BOOL) isScoreflexURL:(NSURL *)URL;

/**
 Returns the resource for the given Scoreflex URL, nil if the URL is not a Scoreflex URL
 @param URL the given URL
 */
+ (NSString *) resourceForScoreflexURL:(NSURL *)URL;

/**
 Returns a dictionary of parameters for the given URL
 @param URL the given URL
 */
+ (NSDictionary *) paramsForScoreflexURL:(NSURL *)URL;

///-------------------
/// @name UUID
///-------------------

+ (NSString *)UUIDString;

@end

///-----------------
/// @name Constants
///-----------------

/**
 ## Error Domains

 The following error domain is predefined:

 - `NSString * const SXErrorDomain`

 ## Constants

 The following error codes are predefined:

 - `SXErrorInvalidParameter`
 - `SXErrorMissingMandatoryParameter`
 - `SXErrorInvalidAccessToken`
 - `SXErrorSecureConnectionRequired`
 - `SXErrorInvalidPrevNextParameter`
 - `SXErrorInvalidSid`
 - `SXErrorSandboxUrlRequired`
 - `SXErrorInactiveGame`
 - `SXErrorMissingPermissions`
 - `SXErrorPlayerDoesNotExist`
 - `SXErrorDeveloperDoesNotExist`
 - `SXErrorGameDoesNotExist`
 - `SXErrorLeaderboardConfigDoesNotExist`
 - `SXErrorServiceException`

 The following codes are also predefined:

 - `SXCodeLogout`
 - `SXCodeCloseWebView`
 - `SXCodeNeedsAuth`
 - `SXCodeAuthGranted`
 - `SXCodeMoveToNewURL`
 - `SXCodeNeedsClientAuth`

 */

extern NSString * const SXErrorDomain;
extern NSInteger const SXErrorInvalidParameter;
extern NSInteger const SXErrorMissingMandatoryParameter;
extern NSInteger const SXErrorInvalidAccessToken;
extern NSInteger const SXErrorSecureConnectionRequired;
extern NSInteger const SXErrorInvalidPrevNextParameter;
extern NSInteger const SXErrorInvalidSid;
extern NSInteger const SXErrorInactigveGame;
extern NSInteger const SXErrorSandboxUrlRequired;
extern NSInteger const SXErrorInactiveGame;
extern NSInteger const SXErrorMissingPermissions;
extern NSInteger const SXErrorPlayerDoesNotExist;
extern NSInteger const SXErrorDeveloperDoesNotExist;
extern NSInteger const SXErrorGameDoesNotExist;
extern NSInteger const SXErrorLeaderboardConfigDoesNotExist;
extern NSInteger const SXErrorServiceException;

extern NSInteger const SXCodeLogout;
extern NSInteger const SXCodeCloseWebView;
extern NSInteger const SXCodeNeedsAuth;
extern NSInteger const SXCodePlayLevel;
extern NSInteger const SXCodeAuthGranted;
extern NSInteger const SXCodeMoveToNewURL;
extern NSInteger const SXCodeNeedsClientAuth;
extern NSInteger const SXCodeStartChallenge;
extern NSInteger const SXCodeLinkService;
extern NSInteger const SXCodeSendInvitation;




