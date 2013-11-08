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
#import "SXRequest.h"
typedef enum {
    SXViewControllerStateInitial,
    SXViewControllerStateLoading,
    SXViewControllerStateWebContent,
    SXViewControllerStateError,
} SXViewControllerState;


@class SXView;
@interface SXViewController : UIViewController
@property (nonatomic, strong) SXRequest *request;
@property (weak, nonatomic) IBOutlet UIImageView *topbarImageView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) SXView *scoreflexView;
@property (assign, nonatomic) BOOL fromTop;
@property (assign, nonatomic) BOOL cancelled;
@property (strong, nonatomic) NSTimer *timer;
- (IBAction)touchBack:(id)sender;
- (IBAction)touchClose:(id)sender;
- (IBAction)touchRetry:(id)sender;
- (void) preload;
- (void) load;
- (void) setState:(SXViewControllerState)state;
@end
