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

#import <UIKit/UIKit.h>

@class SXViewController;
@protocol SXViewDelegate;

/**
 A `UIView` that displays Scoreflex content. An `SXView` holds a `UIWebView` that displays scoreflex web content.
 */
@interface SXView : UIView

///=================================
///@name Delegate
///=================================

/**
 The delegate for this SXView. Must implement `SXViewDelegate`;
 */
@property (nonatomic, weak) id<SXViewDelegate> delegate;

/**
 The view controller holding the SXView.
 */

@property (nonatomic, weak) UIViewController *viewController;

///=================================
///@name Closing this view
///=================================

/**
 Removes this view from the hierarchy
 */
- (void) close;

///=================================
///@name Loading scoreflex resources
///=================================



/**
 Loads the given resource in this view
 @param resource The resource to load
 */
- (void) openResource:(NSString *)resource;

/**
 Loads the given resource in this view
 @param resource The resource to load
 @param params The HTTP parameters
 */
- (void) openResource:(NSString *)resource params:(NSDictionary *)params;

/**
 Loads the given resource in this view
 @param resource The resource to load
 @param params The HTTP parameters
 @param forceFullScreen If YES, the given resource will be opened in full screen
 */

- (void) openResource:(NSString *)resource params:(NSDictionary *)params forceFullScreen:(BOOL)forceFullScreen;


///==================================
///@name Navigating Scoreflex content
///==================================

/**
 Reloads the current scoreflex page.
 */
-(void) reload;

/**
 Cancels the current loading
 */
- (void) cancelLoading;

/**
 Returns YES if the history stack of this `SXView` is not empty
 */
@property (readonly) BOOL canGoBack;

/**
 Goes back one screen, if possible
 */
-(void) goBack;

/**
Returns YES if the current screen is not the last of the history stack.
*/
@property (readonly) BOOL canGoForward;

/**
 Goes forward one screen, if possible
 */
-(void) goForward;

@end

/**
 The delegate you have to implement if you want to be aware of the inner view event
 */
@protocol SXViewDelegate <NSObject>

@optional
/**
 Method called on a loading error on the view
 @param scoreflexView the view that received the error
 @param error the error details
 @param failingURL the URL that could not be loaded
 */
- (void) scoreflexView:(SXView *)scoreflexView receivedError:(NSError *)error forURL:(NSURL *)failingURL;

/**
 Method called when loading a ressource was successfull
 @param scoreflexView The view that successfully loaded the resource
 @param url the loaded URL
 */
- (void) scoreflexView:(SXView *)scoreflexView finishedLoadingURL:(NSURL *)url;

/**
 Method called when a resource starts to load
 @param scoreflexView The view that starts to load the resource
 @param url The URL of the resource
 */
- (void) scoreflexView:(SXView *)scoreflexView startedLoadingURL:(NSURL *)url;

@end
