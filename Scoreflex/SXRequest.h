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
#import "SXResponse.h"

typedef void(^SXRequestHandler)(SXResponse *response, NSError *error);

/**
 SXRequest is a JSON serializable representation of a request to the Scoreflex API.
 It encapsulates the following aspects of an HTTP request:

 - The resource
 - The HTTP verb (GET, POST or DELETE)
 - The HTTP parameters as a dictionary
 - The handler to be invoked when the request is run.

 */

@interface SXRequest : NSObject <NSCopying, NSCoding>

@property (strong, nonatomic) NSString *resource;
@property (strong, nonatomic) SXRequestHandler handler;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSString *method;
@property (readonly) NSString *requestId;
@end
