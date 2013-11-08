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

#import "SXRequest.h"
#import "Scoreflex.h"
#import "SXConfiguration.h"
#import "SXFacebookUtil.h"
#import "SXGooglePlusUtil.h"

@interface SXRequest ()

@property (nonatomic, strong) NSString *requestId;

@property (readonly) NSDictionary *decoratedParams;

+ (NSDictionary *)addParameterIfNotPresent:(NSString *)name value:(NSString *)value toParameters:(NSDictionary *)params;
+ (NSDictionary *)replaceParameter:(NSString *)name value:(NSString *)value toParameters:(NSDictionary *)params;
@end

@implementation SXRequest

- (id) init
{
    if (self = [super init]) {
        self.requestId = [SXUtil UUIDString];
    }
    return self;
}
-(id) copyWithZone:(NSZone *)zone
{
    SXRequest *copy = [[SXRequest allocWithZone:zone] init];
    copy.method = self.method;
    copy.handler = self.handler;
    copy.resource = self.resource;
    copy.params = [self.params copy];
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<SXRequest method=%@ resource=%@ params=%@", self.method, self.resource, self.params];
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        SXRequest *request = (SXRequest *)object;
        BOOL method = (nil == self.method && nil == request.method) || [self.method isEqual:request.method];
        BOOL params = (nil == self.params && nil == request.params) || [self.params isEqual:request.params];
        BOOL resource = (nil == self.resource && nil == request.resource) || [self.resource isEqual:request.resource];
        BOOL requestId = (nil == self.requestId && nil == request.requestId) || [self.requestId isEqual:request.requestId];
        return method && params && resource && requestId;
    }
    return [super isEqual:object];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.resource];
    [aCoder encodeObject:self.params];
    [aCoder encodeObject:self.method];
    [aCoder encodeObject:self.requestId];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init]) {
        self.resource = [aDecoder decodeObject];
        self.params = [aDecoder decodeObject];
        self.method = [aDecoder decodeObject];
        self.requestId = [aDecoder decodeObject];
    }
    return self;
}

#pragma mark - Parameters

- (NSDictionary *)params
{
    return self.decoratedParams;
}

- (NSDictionary *)decoratedParams
{
    NSDictionary *params = _params;

    // Add the language
    params = [[self class] addParameterIfNotPresent:@"lang" value:[Scoreflex languageCode] toParameters:params];

    // Add the location
    CLLocation *location = [Scoreflex location];
    if (location)
        params = [[self class] addParameterIfNotPresent:@"location" value:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] toParameters:params];

    // Add the sid for web resources
    if ([self.resource hasPrefix:@"web/"])
        params = [[self class] replaceParameter:@"sid" value:[SXConfiguration sharedConfiguration].sid toParameters:params];

    // Add handled services
    NSMutableArray *handledServices = [NSMutableArray array];

    if ([SXFacebookUtil isFacebookAvailable])
        [handledServices addObject:@"Facebook"];

    if ([SXGooglePlusUtil isGooglePlusAvailable])
        [handledServices addObject:@"Google"];

    if (handledServices.count)
        params = [[self class] addParameterIfNotPresent:@"handledServices" value:[handledServices componentsJoinedByString:@","] toParameters:params];

    return params;

}

+ (NSDictionary *)addParameterIfNotPresent:(NSString *)name value:(NSString *)value toParameters:(NSDictionary *)params
{
    if (![params valueForKey:name]) {
        NSMutableDictionary *mutable = [NSMutableDictionary dictionaryWithDictionary:params];
        [mutable setObject:value forKey:name];
        return [NSDictionary dictionaryWithDictionary:mutable];
    }
    return params;
}

+ (NSDictionary *)replaceParameter:(NSString *)name value:(NSString *)value toParameters:(NSDictionary *)params
{
    NSMutableDictionary *mutable = [NSMutableDictionary dictionaryWithDictionary:params];
    if (name && value)
        [mutable setObject:value forKey:name];
    return [NSDictionary dictionaryWithDictionary:mutable];
}

#pragma mark - Resource

- (void) setResource:(NSString *)resource
{
    // Remove any leading /
    if (resource && [resource rangeOfString:@"/"].location == 0)
        resource = resource.length > 1 ? [resource substringFromIndex:1] : @"";

    _resource = resource;
}

@end
