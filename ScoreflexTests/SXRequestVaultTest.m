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

#import "SXRequestVaultTest.h"
#import "SXRequestVault.h"
#import "Scoreflex.h"
#import <objc/message.h>

@implementation SXRequestVaultTest

- (void)testPersistence
{
    [Scoreflex setClientId:@"" secret:@"" sandboxMode:YES];

    SXRequest *request1 = [[SXRequest alloc] init];
    request1.method = @"GET";
    request1.resource = @"/foo";

    SXRequest *request2 = [[SXRequest alloc] init];
    request2.method = @"POST";
    request2.resource = @"/bar";
    request2.params = @{@"foo":@"bar"};

    SXRequestVault *vault = [[SXRequestVault alloc] initWithClient:[SXClient sharedClient]];
    [vault reset];

    STAssertEquals(0, (int)[objc_msgSend(vault, @selector(savedRequests)) count], @"Vault is empty");

    // Save the first request
    objc_msgSend(vault, @selector(save:), request1);

    STAssertEqualObjects(request1, [objc_msgSend(vault, @selector(savedRequests)) lastObject], @"request1 is the only saved request");

    // Save the second request
    objc_msgSend(vault, @selector(save:), request2);
    STAssertEqualObjects(request2, [objc_msgSend(vault, @selector(savedRequests)) lastObject], @"request2 is the last saved request");
    STAssertEquals(2, (int)[objc_msgSend(vault, @selector(savedRequests)) count], @"Vault has 2 requests");

    // Params, method and resource are preserved
    SXRequest *savedRequest2 = [objc_msgSend(vault, @selector(savedRequests)) lastObject];
    STAssertEqualObjects(request2.params, savedRequest2.params, @"Params are preserved");
    STAssertEqualObjects(request2.resource, savedRequest2.resource, @"Resource is preserved");
    STAssertEqualObjects(request2.method, savedRequest2.method, @"Method are preserved");

    // Forget the second request
    objc_msgSend(vault, @selector(forget:), request2);
    STAssertEqualObjects(request1, [objc_msgSend(vault, @selector(savedRequests)) lastObject], @"request1 is the only saved request");
    STAssertEquals(1, (int)[objc_msgSend(vault, @selector(savedRequests)) count], @"Vault has 1 request1");

}
@end
