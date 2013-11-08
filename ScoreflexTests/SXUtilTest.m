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

#import "SXUtilTest.h"
#import "SXConfiguration.h"

@implementation SXUtilTest

- (void) testIsScoreflexURL
{
    SXConfiguration *configuration = [SXConfiguration sharedConfiguration];

    configuration.baseURL = [NSURL URLWithString:@"http://www.scoreflex.com/v1/"];

    NSURL *URL = [NSURL URLWithString:@"http://www.scoreflex.com/v1/foo/bar"];
    STAssertTrue([SXUtil isScoreflexURL:URL], @"URL is scoreflex");
    STAssertEqualObjects([SXUtil resourceForScoreflexURL:URL], @"foo/bar", @"Resource is right");
    STAssertEqualObjects([SXUtil paramsForScoreflexURL:URL], @{}, @"Params are right");



    URL = [NSURL URLWithString:@"http://www.scoreflex.com/v1/foo/bar?toto=titi"];
    STAssertTrue([SXUtil isScoreflexURL:URL], @"URL is scoreflex");
    STAssertEqualObjects([SXUtil resourceForScoreflexURL:URL], @"foo/bar", @"Resource is right");
    STAssertEqualObjects([SXUtil paramsForScoreflexURL:URL], @{@"toto" : @"titi"}, @"Params are right");

    URL = [NSURL URLWithString:@"http://www.qweiuyqiwuey.com/v1/foo/bar"];
    STAssertFalse([SXUtil isScoreflexURL:URL], @"URL is not scoreflex");
    STAssertEqualObjects([SXUtil resourceForScoreflexURL:URL], nil, @"Resource is nil");
    STAssertEqualObjects([SXUtil paramsForScoreflexURL:URL], @{}, @"Params are right");

    // With different protocol
    URL = [NSURL URLWithString:@"https://www.scoreflex.com/v1/foo/bar?toto=titi"];
    STAssertTrue([SXUtil isScoreflexURL:URL], @"URL is scoreflex");
    STAssertEqualObjects([SXUtil resourceForScoreflexURL:URL], @"foo/bar", @"Resource is right");
    STAssertEqualObjects([SXUtil paramsForScoreflexURL:URL], @{@"toto" : @"titi"}, @"Params are right");


}
@end
