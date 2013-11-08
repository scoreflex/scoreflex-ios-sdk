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

#import "SXRequestTest.h"
#import "SXRequest.h"

@implementation SXRequestTest


- (void)testRequestSerialization
{
    SXRequest *request = [[SXRequest alloc] init];
    request.resource = @"theresource";
    request.params = @{
                       @"foo": @"bar",
                       @"baz": @"toto",
                       };
    request.method = @"POST";
    [self serializeDeserializeAndCompare:request];

    request.method = nil;
    request.params = nil;
    [self serializeDeserializeAndCompare:request];

    request.method = @"POST";
    [self serializeDeserializeAndCompare:request];

}

- (void) serializeDeserializeAndCompare:(id)object
{
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:@{@"object" : object}];
    id rootObject = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    SXRequest *unarchivedRequest = [rootObject valueForKey:@"object"];
    STAssertEqualObjects(object, unarchivedRequest, @"Unarchived object is equal to request");
}

- (void)testIsEqual
{
    SXRequest *request1 = [[SXRequest alloc] init];
    SXRequest *request2 = [[SXRequest alloc] init];

    STAssertFalse([request1 isEqual:request2], @"Empty requests are not equal (different requestId)");

    [request1 setValue:request2.requestId forKey:@"requestId"];
    STAssertTrue([request1 isEqual:request2], @"Empty requests with same requestId are equal");

    request1.resource = request2.resource = @"someresouce";
    STAssertTrue([request1 isEqual:request2], @"Requests just the same resource specified are equal");

    request1.resource = @"someotherresource";
    STAssertFalse([request1 isEqual:request2], @"Requests just a different resource specified are not equal");

    request1.resource = request2.resource;
    request1.params = @{@"foo" : @"bar"};
    request2.params = @{@"foo" : @"bar"};
    STAssertTrue([request1 isEqual:request2], @"Requests just the same resource and params specified are equal");

    request1.params = @{@"baz" : @"toto"};
    STAssertFalse([request1 isEqual:request2], @"Requests just the same resource and different params specified are not equal");

    request1.params = request2.params;
    request1.method = request2.method = @"POST";
    STAssertTrue([request1 isEqual:request2], @"Requests just the same resource, params and method specified are equal");

    request1.method = @"GET";
    STAssertFalse([request1 isEqual:request2], @"Requests just the same resource, params and a different method specified are not equal");

    request1.method = request2.method;

}
@end
