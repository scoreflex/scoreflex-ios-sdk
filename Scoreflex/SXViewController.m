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

#import "SXViewController.h"
#import "SXView.h"
#import "SXView_private.h"
#import "Scoreflex.h"
#import "SXConfiguration.h"


@interface SXViewController () <SXViewDelegate>
@property (nonatomic, strong) NSURL *currentScoreflexURL;
@property (nonatomic, assign) BOOL isPreloading;

- (void) setState:(SXViewControllerState)state;

@end

@implementation SXViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        SXView *scoreflexView = [[SXView alloc] initWithViewController:self];
        self.scoreflexView = scoreflexView;
        self.scoreflexView.delegate = self;
        self.isPreloading = NO;
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.scoreflexView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    [self.view insertSubview:self.scoreflexView belowSubview:self.activityIndicator];

    if (self.isPreloading == NO) {
    // Open the resource
//        SXLog(@"opening resource from view controller");
        if (self.request.resource != nil)
            [self.scoreflexView openResource:self.request.resource params:self.request.params forceFullScreen:NO];
        
        [self setState:SXViewControllerStateInitial];
    } else {
        [self setState:SXViewControllerStateWebContent];
    }

    // Set the initial state


    self.isPreloading = NO;

}

-(void) load {
    [self.scoreflexView openResource:self.request.resource params:self.request.params forceFullScreen:NO];
}

- (void) preload {
    self.isPreloading = YES;
    [self.scoreflexView openResource:self.request.resource params:self.request.params forceFullScreen:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) cancelLoading {

    [self.scoreflexView cancelLoading];
    self.messageLabel.text = @"Could not connect to the server please check your internet connection";
    self.cancelled = YES;
    [self setState:SXViewControllerStateError];
    if (self.isPreloading) {
        [Scoreflex freePreloadedResource:self.request.resource];
    }
}

#pragma mark - SXViewDelegate

- (void) scoreflexView:(SXView *)scoreflexView receivedError:(NSError *)error forURL:(NSURL *)failingURL
{
    SXLog(@"received error: %@ for URL: %@", error, failingURL);
    [self.timer invalidate];
    if (!self.cancelled) {
        self.messageLabel.text = error.localizedDescription;
    }
    self.cancelled = NO;
    [self setState:SXViewControllerStateError];

}

- (void) scoreflexView:(SXView *)scoreflexView finishedLoadingURL:(NSURL *)url
{
    SXLog(@"finished loading: %@", url);
    [self.timer invalidate];
    self.timer = nil;
    if (self.isPreloading == YES) {
        NSDictionary *userInfo = @{SX_NOTIFICATION_RESOURCE_PRELOADED_PATH: self.request.resource};
        [[NSNotificationCenter defaultCenter] postNotificationName:SX_NOTIFICATION_RESOURCE_PRELOADED
                                                            object:self
                                                          userInfo:userInfo];

    }
    self.currentScoreflexURL = url;
    [self setState:SXViewControllerStateWebContent];

}

- (void) scoreflexView:(SXView *)scoreflexView startedLoadingURL:(NSURL *)url
{
    SXLog(@"started loading: %@", url);
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:SX_WEBVIEW_TIMEOUT target:self selector:@selector(cancelLoading) userInfo:nil repeats:NO];
    self.cancelled = NO;
    if ([url.host isEqualToString:@"itunes.apple.com"])
        return;
    [self setState:SXViewControllerStateLoading];
}

- (void)viewDidUnload
{
    [self setBackButton:nil];
    [self setCloseButton:nil];
    [self setActivityIndicator:nil];
    [self setRetryButton:nil];
    [self setCancelButton:nil];
    [self setMessageLabel:nil];
    [super viewDidUnload];
}

#pragma mark - Actions

- (IBAction)touchBack:(id)sender
{
    [self.scoreflexView goBack];
}

- (IBAction)touchClose:(id)sender
{
    [self.scoreflexView close];
}

- (IBAction)touchRetry:(id)sender
{
    [self setState:SXViewControllerStateInitial];
    [self.scoreflexView reload];
}

#pragma mark - State

- (void) setState:(SXViewControllerState)state
{
    switch (state) {
        case SXViewControllerStateInitial:
            [self.activityIndicator startAnimating];
            self.scoreflexView.hidden = YES;
            self.retryButton.hidden = YES;
            self.cancelButton.hidden = YES;
            self.messageLabel.hidden = YES;
            break;

        case SXViewControllerStateError:
            [self.activityIndicator stopAnimating];
            self.retryButton.hidden = NO;
            self.cancelButton.hidden = NO;
            self.messageLabel.hidden = NO;
            self.scoreflexView.hidden = YES;
            break;

        case SXViewControllerStateLoading:
            [self.activityIndicator startAnimating];
            break;

        case SXViewControllerStateWebContent:
            [self.activityIndicator stopAnimating];
            self.retryButton.hidden = YES;
            self.cancelButton.hidden = YES;
            self.messageLabel.hidden = YES;

            // Adjust the scoreflex view frame to show or hide the topbar
            if ([SXUtil isScoreflexURL:self.currentScoreflexURL]) {
                self.scoreflexView.frame = self.view.bounds;
            } else {
                CGRect frame = CGRectMake(0, self.topbarImageView.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - self.topbarImageView.frame.size.height);
                self.scoreflexView.frame = frame;
            }

            // If the scoreflex view is hidden, fade it in
            self.scoreflexView.hidden = NO;
            break;

        default:
            SXLog(@"Unknown state: %i", state);
            break;
    }

}
@end
