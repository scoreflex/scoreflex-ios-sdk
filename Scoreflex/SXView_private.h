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

@interface SXView (Private)

@property (nonatomic, assign) BOOL isLoggingView;

///=================================
///@name Initializer
///=================================


/**
 Initializes a full screen SXView with the given view controller
 @param viewController the UIViewController
 */
- (id) initWithViewController:(UIViewController *)viewController;

/**
 Method called when the logged user has changed, used to refresh the view
 @param the notification
 */
-(void) userLoggedIn:(NSNotification *) notification;


@end


