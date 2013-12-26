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

#import "SXUtil.h"
#import "OpenUDID.h"
#import "SXConfiguration.h"

#import <sys/utsname.h>

NSString * const SXErrorDomain = @"SXErrorDomain";

NSInteger const SXErrorInvalidParameter = 10001;
NSInteger const SXErrorMissingMandatoryParameter = 10002;
NSInteger const SXErrorInvalidAccessToken = 11003;
NSInteger const SXErrorSecureConnectionRequired = 10005;
NSInteger const SXErrorInactigveGame = 10005;
NSInteger const SXErrorInvalidPrevNextParameter = 12011;
NSInteger const SXErrorInvalidSid = 12017;
NSInteger const SXErrorSandboxUrlRequired = 12018;
NSInteger const SXErrorInactiveGame = 12019;
NSInteger const SXErrorMissingPermissions = 12020;
NSInteger const SXErrorPlayerDoesNotExist = 12000;
NSInteger const SXErrorDeveloperDoesNotExist = 12001;
NSInteger const SXErrorGameDoesNotExist = 12002;
NSInteger const SXErrorLeaderboardConfigDoesNotExist = 12004;
NSInteger const SXErrorServiceException = 12009;

NSInteger const SXCodeLogout = 200000;
NSInteger const SXCodeCloseWebView = 200001;
NSInteger const SXCodePlayLevel = 200002;
NSInteger const SXCodeNeedsAuth = 200003;
NSInteger const SXCodeAuthGranted = 200004;
NSInteger const SXCodeMoveToNewURL = 200005;
NSInteger const SXCodeNeedsClientAuth = 200006;
NSInteger const SXCodeStartChallenge = 200007;
NSInteger const SXCodeLinkService = 200008;
NSInteger const SXCodeSendInvitation = 200009;
NSInteger const SXCodeShare = 200010;


@implementation SXUtil
+ (NSString*)base64forData:(NSData*)theData
{

    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;

    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;

            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString
{
    if (!encodedString) {
        return nil;
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *pairs = [encodedString componentsSeparatedByString:@"&"];

    for (NSString *kvp in pairs) {
        if ([kvp length] == 0) {
            continue;
        }

        NSRange pos = [kvp rangeOfString:@"="];
        NSString *key;
        NSString *val;

        if (pos.location == NSNotFound) {
            key = [kvp stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            val = @"";
        } else {
            key = [[kvp substringToIndex:pos.location]  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            val = [[kvp substringFromIndex:pos.location + pos.length]  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }

        if (!key || !val) {
            continue; // I'm sure this will bite my arse one day
        }

        [result setObject:val forKey:key];
    }
    return result;
}

+ (NSString *)percentEncodedString:(NSString *)s
{
    NSMutableString *result = [[NSMutableString alloc] init];
    for (int i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if ((c >= 'A' && c <= 'Z')
            || (c >= 'a' && c <= 'z')
            || (c >= '0' && c <= '9')
            || c == '-'
            || c == '.'
            || c == '_'
            || c == '~') {
            [result appendFormat:@"%c", c];
        } else {
            [result appendFormat:@"%%%02X", c];
        }
    }
    return [NSString stringWithString:result];
}

#pragma mark - Device


+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (NSString *)deviceIdentifier
{
    return [OpenUDID value];
}

#pragma mark - Errors

+ (NSError *)errorFromJSON:(id)json
{
    id errorJson = [json valueForKeyPath:@"error"];
    if (!errorJson)
        return nil;
    if ([errorJson isKindOfClass:[NSArray class]])
    {
        for (id detailedError in ((NSArray *)errorJson))
        {
            if (detailedError && ![detailedError isKindOfClass:[NSNull class]])
            {
                return [[NSError alloc] initWithDomain:SXErrorDomain code:[[detailedError valueForKeyPath:@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey : [detailedError valueForKeyPath:@"message"]}];
            }
        }
        return nil;
    }
    return [[NSError alloc] initWithDomain:SXErrorDomain code:[[errorJson valueForKeyPath:@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey : [errorJson valueForKeyPath:@"message"]}];
}

+ (NSString *)messageForScoreflexErrorCode:(NSInteger)errorCode
{
    NSString *result = nil;

    if (errorCode == SXErrorInvalidParameter)
        result = NSLocalizedString(@"When an invalid parameter is given", nil);
    else if (errorCode == SXErrorMissingMandatoryParameter)
        result = NSLocalizedString(@"When a mandatory parameter has been omitted", nil);
    else if (errorCode == SXErrorSecureConnectionRequired)
        result = NSLocalizedString(@"When http is used for a method where https is mandatory", nil);
    else if (errorCode == SXErrorInvalidPrevNextParameter)
        result = NSLocalizedString(@"When a developer try to use the API with wrong prev/next parameter", nil);
    else if (errorCode == SXErrorInvalidSid)
        result = NSLocalizedString(@"When receiving an invalid sid", nil);
    else if (errorCode == SXErrorSandboxUrlRequired)
        result = NSLocalizedString(@"When using production API for a game in dev mode", nil);
    else if (errorCode == SXErrorInactiveGame)
        result = NSLocalizedString(@"When using API for an inactive game", nil);
    else if (errorCode == SXErrorMissingPermissions)
        result = NSLocalizedString(@"When the provided sid has insufficient scope for a specific operation requiring more authorization", nil);
    else if (errorCode == SXErrorPlayerDoesNotExist)
        result = NSLocalizedString(@"When a player does not exist", nil);
    else if (errorCode == SXErrorDeveloperDoesNotExist)
        result = NSLocalizedString(@"When a developer does not exist", nil);
    else if (errorCode == SXErrorGameDoesNotExist)
        result = NSLocalizedString(@"When a game does not exist", nil);
    else if (errorCode == SXErrorLeaderboardConfigDoesNotExist)
        result = NSLocalizedString(@"When a leaderboard config does not exist", nil);
    else if (errorCode == SXErrorServiceException)
        result = NSLocalizedString(@"When there is a service exception", nil);

    return result;

}

#pragma mark - URL Checking

+ (BOOL) isScoreflexURL:(NSURL *)URL
{
    // Check base path
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];

    NSString *urlString = URL.absoluteString;

    // Remove protocol
    urlString = [urlString stringByReplacingOccurrencesOfString:@"http:" withString:@""];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"https:" withString:@""];

    NSString *noProtocolBaseURLString = configuration.baseURL.absoluteString;
    noProtocolBaseURLString = [noProtocolBaseURLString stringByReplacingOccurrencesOfString:@"http:" withString:@""];
    noProtocolBaseURLString = [noProtocolBaseURLString stringByReplacingOccurrencesOfString:@"https:" withString:@""];

    NSRange rangeOfBaseUrl = [urlString rangeOfString:noProtocolBaseURLString];

    return 0 == rangeOfBaseUrl.location;

}

+ (NSString *) resourceForScoreflexURL:(NSURL *)URL
{
    if (![self isScoreflexURL:URL])
        return nil;

    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];

    NSString *urlString = URL.absoluteString;
    // Remove protocol
    urlString = [urlString stringByReplacingOccurrencesOfString:@"http:" withString:@""];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"https:" withString:@""];

    NSString *noProtocolBaseURLString = configuration.baseURL.absoluteString;
    noProtocolBaseURLString = [noProtocolBaseURLString stringByReplacingOccurrencesOfString:@"http:" withString:@""];
    noProtocolBaseURLString = [noProtocolBaseURLString stringByReplacingOccurrencesOfString:@"https:" withString:@""];


    NSRange rangeOfBaseUrl = [urlString rangeOfString:noProtocolBaseURLString];


    // Compute the resource
    NSString *resource = [urlString substringFromIndex:rangeOfBaseUrl.length];
    if (URL.query) {
        NSRange rangeOfQuery = [resource rangeOfString:URL.query];
        if (rangeOfQuery.location != NSNotFound)
            resource = [resource substringToIndex:rangeOfQuery.location - 1];
    }
    return resource;
}

+ (NSDictionary *) paramsForScoreflexURL:(NSURL *)URL
{
    if (!URL.query)
        return @{};

    return [self dictionaryWithFormEncodedString:URL.query];

}

#pragma mark - UUID

+ (NSString *)UUIDString
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *result = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    return result;
}
@end
